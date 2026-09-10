import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_model.dart';
import '../models/idea_snippet_model.dart';
import '../models/codex_entry_model.dart';
import '../models/mind_map_node_model.dart';
import '../models/writer_stats_model.dart';
import '../models/character_model.dart';

class PersistenceService {
  static const String _keyBooks = 'ink_wright_books';
  static const String _keyBooksBackup = 'ink_wright_books_backup';
  static const String _keyIdeas = 'ink_wright_ideas';
  static const String _keyCodex = 'ink_wright_codex';
  static const String _keyMindMap = 'ink_wright_mind_map';
  static const String _keyCharacters = 'ink_wright_characters';
  static const String _keyWriterStats = 'ink_wright_writer_stats';
  static const String _keyActiveBookId = 'ink_wright_active_book_id';
  static const String _keyActiveChapterId = 'ink_wright_active_chapter_id';
  static const String _keyDarkMode = 'ink_wright_dark_mode';
  static const String _keyFontFamily = 'ink_wright_font_family';
  static const String _keyFontSize = 'ink_wright_font_size';
  static const String _keyLineHeight = 'ink_wright_line_height';
  static const String _keyMaxEditorWidth = 'ink_wright_max_editor_width';
  static const String _keyTypewriterMode = 'ink_wright_typewriter_mode';

  Timer? _saveDebounceTimer;
  Future<void> Function()? _pendingSaveAction;
  bool _isSaving = false;
  DateTime? _lastSaved;

  bool get isSaving => _isSaving;
  DateTime? get lastSaved => _lastSaved;

  // Load All Books
  Future<List<BookModel>?> loadBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyBooks);
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
          return list.map((item) => BookModel.fromMap(item as Map<String, dynamic>)).toList();
        } catch (e) {
          debugPrint('Error loading primary books: $e. Falling back to backup...');
        }
      }

      // Try backup if primary failed or empty
      final backupString = prefs.getString(_keyBooksBackup);
      if (backupString != null && backupString.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(backupString) as List<dynamic>;
          return list.map((item) => BookModel.fromMap(item as Map<String, dynamic>)).toList();
        } catch (e) {
          debugPrint('Error loading backup books: $e');
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Load All Ideas
  Future<List<IdeaSnippetModel>?> loadIdeas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyIdeas);
      if (jsonString == null || jsonString.isEmpty) return null;

      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return list.map((item) => IdeaSnippetModel.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }

  // Load Codex Entries
  Future<List<CodexEntryModel>?> loadCodexEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyCodex);
      if (jsonString == null || jsonString.isEmpty) return null;

      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return list.map((item) => CodexEntryModel.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }

  // Load Mind Map Nodes
  Future<List<MindMapNodeModel>?> loadMindMapNodes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyMindMap);
      if (jsonString == null || jsonString.isEmpty) return null;

      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return list.map((item) => MindMapNodeModel.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }

  // Load Characters
  Future<List<CharacterModel>?> loadCharacters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyCharacters);
      if (jsonString == null || jsonString.isEmpty) return null;

      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return list.map((item) => CharacterModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }

  // Load Writer Stats
  Future<WriterStatsModel?> loadWriterStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyWriterStats);
      if (jsonString == null || jsonString.isEmpty) return null;

      return WriterStatsModel.fromMap(jsonDecode(jsonString) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Load User Preferences
  Future<Map<String, dynamic>> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'darkMode': prefs.getBool(_keyDarkMode) ?? false,
        'activeBookId': prefs.getString(_keyActiveBookId),
        'activeChapterId': prefs.getString(_keyActiveChapterId),
        'fontFamily': prefs.getString(_keyFontFamily) ?? 'Lora',
        'fontSize': prefs.getDouble(_keyFontSize) ?? 16.5,
        'lineHeight': prefs.getDouble(_keyLineHeight) ?? 1.65,
        'maxEditorWidth': prefs.getDouble(_keyMaxEditorWidth) ?? 720.0,
        'typewriterMode': prefs.getBool(_keyTypewriterMode) ?? false,
      };
    } catch (e) {
      return {
        'darkMode': false,
        'activeBookId': null,
        'activeChapterId': null,
        'fontFamily': 'Lora',
        'fontSize': 16.5,
        'lineHeight': 1.65,
        'maxEditorWidth': 720.0,
        'typewriterMode': false,
      };
    }
  }

  // Save All Data immediately
  Future<void> saveAllData({
    required List<BookModel> books,
    required List<IdeaSnippetModel> ideas,
    required List<CodexEntryModel> codexEntries,
    required List<MindMapNodeModel> mindMapNodes,
    required List<CharacterModel> characters,
    required WriterStatsModel writerStats,
    String? activeBookId,
    String? activeChapterId,
    bool? isDarkMode,
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    double? maxEditorWidth,
    bool? typewriterMode,
  }) async {
    _isSaving = true;
    try {
      final prefs = await SharedPreferences.getInstance();

      final booksJson = jsonEncode(books.map((b) => b.toMap()).toList());
      final ideasJson = jsonEncode(ideas.map((i) => i.toMap()).toList());
      final codexJson = jsonEncode(codexEntries.map((c) => c.toMap()).toList());
      final mindMapJson = jsonEncode(mindMapNodes.map((n) => n.toMap()).toList());
      final charactersJson = jsonEncode(characters.map((c) => c.toJson()).toList());
      final statsJson = jsonEncode(writerStats.toMap());

      // Save previous valid books to backup key before overwriting
      final existingBooks = prefs.getString(_keyBooks);
      if (existingBooks != null && existingBooks.isNotEmpty) {
        await prefs.setString(_keyBooksBackup, existingBooks);
      }

      await Future.wait([
        prefs.setString(_keyBooks, booksJson),
        prefs.setString(_keyIdeas, ideasJson),
        prefs.setString(_keyCodex, codexJson),
        prefs.setString(_keyMindMap, mindMapJson),
        prefs.setString(_keyCharacters, charactersJson),
        prefs.setString(_keyWriterStats, statsJson),
        if (activeBookId != null) prefs.setString(_keyActiveBookId, activeBookId),
        if (activeChapterId != null) prefs.setString(_keyActiveChapterId, activeChapterId),
        if (isDarkMode != null) prefs.setBool(_keyDarkMode, isDarkMode),
        if (fontFamily != null) prefs.setString(_keyFontFamily, fontFamily),
        if (fontSize != null) prefs.setDouble(_keyFontSize, fontSize),
        if (lineHeight != null) prefs.setDouble(_keyLineHeight, lineHeight),
        if (maxEditorWidth != null) prefs.setDouble(_keyMaxEditorWidth, maxEditorWidth),
        if (typewriterMode != null) prefs.setBool(_keyTypewriterMode, typewriterMode),
      ]);

      _lastSaved = DateTime.now();
    } catch (e) {
      debugPrint('Error in saveAllData: $e');
    } finally {
      _isSaving = false;
    }
  }

  // Flush any pending debounced save immediately (e.g. when app goes to background)
  Future<void> flushPendingSave() async {
    if (_saveDebounceTimer != null && _saveDebounceTimer!.isActive) {
      _saveDebounceTimer!.cancel();
      final action = _pendingSaveAction;
      _pendingSaveAction = null;
      if (action != null) {
        await action();
      }
    }
  }

  // Debounced Save (useful during typing)
  void scheduleDebouncedSave({
    required List<BookModel> books,
    required List<IdeaSnippetModel> ideas,
    required List<CodexEntryModel> codexEntries,
    required List<MindMapNodeModel> mindMapNodes,
    required List<CharacterModel> characters,
    required WriterStatsModel writerStats,
    String? activeBookId,
    String? activeChapterId,
    bool? isDarkMode,
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    double? maxEditorWidth,
    bool? typewriterMode,
    Duration debounceDuration = const Duration(milliseconds: 800),
    VoidCallback? onSaved,
  }) {
    _saveDebounceTimer?.cancel();
    _pendingSaveAction = () async {
      await saveAllData(
        books: books,
        ideas: ideas,
        codexEntries: codexEntries,
        mindMapNodes: mindMapNodes,
        characters: characters,
        writerStats: writerStats,
        activeBookId: activeBookId,
        activeChapterId: activeChapterId,
        isDarkMode: isDarkMode,
        fontFamily: fontFamily,
        fontSize: fontSize,
        lineHeight: lineHeight,
        maxEditorWidth: maxEditorWidth,
        typewriterMode: typewriterMode,
      );
      onSaved?.call();
    };

    _saveDebounceTimer = Timer(debounceDuration, () async {
      final action = _pendingSaveAction;
      _pendingSaveAction = null;
      if (action != null) {
        await action();
      }
    });
  }

  String generateBackupJson({
    required List<BookModel> books,
    required List<IdeaSnippetModel> ideas,
    required List<CodexEntryModel> codexEntries,
    required List<MindMapNodeModel> mindMapNodes,
    required List<CharacterModel> characters,
    required WriterStatsModel writerStats,
    String? activeBookId,
    String? activeChapterId,
    bool? isDarkMode,
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    double? maxEditorWidth,
    bool? typewriterMode,
  }) {
    final payload = {
      'format': 'inkwright_backup',
      'version': '2.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'books': books.map((b) => b.toMap()).toList(),
      'ideas': ideas.map((i) => i.toMap()).toList(),
      'codex': codexEntries.map((c) => c.toMap()).toList(),
      'mindMap': mindMapNodes.map((n) => n.toMap()).toList(),
      'characters': characters.map((c) => c.toJson()).toList(),
      'writerStats': writerStats.toMap(),
      'preferences': {
        'activeBookId': activeBookId,
        'activeChapterId': activeChapterId,
        'isDarkMode': isDarkMode ?? false,
        'fontFamily': fontFamily ?? 'Lora',
        'fontSize': fontSize ?? 16.5,
        'lineHeight': lineHeight ?? 1.65,
        'maxEditorWidth': maxEditorWidth ?? 720.0,
        'typewriterMode': typewriterMode ?? false,
      },
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Map<String, dynamic>? parseBackupJson(String rawJson) {
    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      if (!map.containsKey('books')) return null;

      final booksList = (map['books'] as List<dynamic>?)
              ?.map((item) => BookModel.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [];
      final ideasList = (map['ideas'] as List<dynamic>?)
              ?.map((item) => IdeaSnippetModel.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [];
      final codexList = (map['codex'] as List<dynamic>?)
              ?.map((item) => CodexEntryModel.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [];
      final mindMapList = (map['mindMap'] as List<dynamic>?)
              ?.map((item) => MindMapNodeModel.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [];
      final charactersList = (map['characters'] as List<dynamic>?)
              ?.map((item) => CharacterModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      final stats = map.containsKey('writerStats') && map['writerStats'] != null
          ? WriterStatsModel.fromMap(map['writerStats'] as Map<String, dynamic>)
          : null;

      final prefs = map['preferences'] as Map<String, dynamic>? ?? {};

      return {
        'books': booksList,
        'ideas': ideasList,
        'codex': codexList,
        'mindMap': mindMapList,
        'characters': charactersList,
        'writerStats': stats,
        'preferences': prefs,
      };
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _saveDebounceTimer?.cancel();
  }
}

