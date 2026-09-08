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
  static const String _keyIdeas = 'ink_wright_ideas';
  static const String _keyCodex = 'ink_wright_codex';
  static const String _keyMindMap = 'ink_wright_mind_map';
  static const String _keyCharacters = 'ink_wright_characters';
  static const String _keyWriterStats = 'ink_wright_writer_stats';
  static const String _keyActiveBookId = 'ink_wright_active_book_id';
  static const String _keyActiveChapterId = 'ink_wright_active_chapter_id';
  static const String _keyDarkMode = 'ink_wright_dark_mode';
  static const String _keyFontFamily = 'ink_wright_font_family';

  Timer? _saveDebounceTimer;
  bool _isSaving = false;
  DateTime? _lastSaved;

  bool get isSaving => _isSaving;
  DateTime? get lastSaved => _lastSaved;

  // Load All Books
  Future<List<BookModel>?> loadBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyBooks);
      if (jsonString == null || jsonString.isEmpty) return null;

      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return list.map((item) => BookModel.fromMap(item as Map<String, dynamic>)).toList();
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
      };
    } catch (e) {
      return {
        'darkMode': false,
        'activeBookId': null,
        'activeChapterId': null,
        'fontFamily': 'Lora',
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
      ]);

      _lastSaved = DateTime.now();
    } catch (e) {
      // Graceful error logging
    } finally {
      _isSaving = false;
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
    Duration debounceDuration = const Duration(milliseconds: 800),
    VoidCallback? onSaved,
  }) {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(debounceDuration, () async {
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
      );
      onSaved?.call();
    });
  }

  void dispose() {
    _saveDebounceTimer?.cancel();
  }
}

