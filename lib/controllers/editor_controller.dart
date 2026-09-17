import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_model.dart';
import '../models/chapter_model.dart';
import '../models/chapter_snapshot_model.dart';
import '../models/idea_snippet_model.dart';
import '../models/writer_stats_model.dart';
import '../models/codex_entry_model.dart';
import '../models/writing_sprint_model.dart';
import '../models/mind_map_node_model.dart';
import '../models/character_model.dart';
import '../models/character_relationship_model.dart';
import '../models/sprint_history_model.dart';
import '../models/revision_comment_model.dart';
import '../formatters/writer_text_formatter.dart';
import 'markdown_editing_controller.dart';
import '../services/persistence_service.dart';
import '../services/import_service.dart';
import '../services/initial_sample_data_service.dart';
import '../services/chapter_operations_service.dart';
import '../services/mind_map_layout_service.dart';

class EditorController extends ChangeNotifier {
  final PersistenceService _persistenceService = PersistenceService();

  static const String _prefKeyCursorPos = 'ink_last_cursor_position';

  bool _isDarkMode = false;
  bool _isZenMode = false;
  final bool _isAutoSaveEnabled = true;

  late BookModel _activeBook;
  late ChapterModel _activeChapter;
  late WriterStatsModel _writerStats;
  List<BookModel> _allBooks = [];
  List<IdeaSnippetModel> _ideas = [];
  List<CodexEntryModel> _codexEntries = [];
  List<MindMapNodeModel> _mindMapNodes = [];
  List<CharacterModel> _characters = [];

  WritingSprintModel? _activeSprint;
  String _selectedFontFamily = 'Lora';
  double _fontSize = 16.5;
  double _lineHeight = 1.65;
  double _maxEditorWidth = 720.0;
  bool _isTypewriterMode = false;
  bool _isRevisionMode = false;

  // New: character relationships, sprint history
  List<CharacterRelationshipModel> _relationships = [];
  List<SprintHistoryModel> _sprintHistory = [];

  final MarkdownEditingController textEditingController = MarkdownEditingController();
  final FocusNode focusNode = FocusNode();

  // Undo / Redo history
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  bool _isPerformingUndoRedo = false;
  String _lastRecordedText = '';

  // Debounce for text change auto-save
  Timer? _textChangeDebounceTimer;
  Timer? _autoBackupTimer;
  DateTime? _lastSavedTime;
  DateTime? _lastAutoBackupTime;
  bool _isSaving = false;

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get isZenMode => _isZenMode;
  bool get isAutoSaveEnabled => _isAutoSaveEnabled;
  bool get isLiveMarkdownEnabled => textEditingController.isLiveMarkdownEnabled;
  bool get isSaving => _isSaving;
  DateTime? get lastSavedTime => _lastSavedTime;
  DateTime? get lastAutoBackupTime => _lastAutoBackupTime;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  BookModel get activeBook => _activeBook;
  ChapterModel get activeChapter => _activeChapter;
  WriterStatsModel get writerStats => _writerStats;
  List<BookModel> get allBooks => List.unmodifiable(_allBooks);
  // Each idea and codex entry is strictly individual per book
  List<IdeaSnippetModel> get ideas =>
      _ideas.where((i) => i.bookId == _activeBook.id).toList();
  List<CodexEntryModel> get codexEntries =>
      _codexEntries.where((c) => c.bookId == _activeBook.id).toList();

  List<IdeaSnippetModel> get allIdeas => List.unmodifiable(_ideas);
  List<CodexEntryModel> get allCodexEntries => List.unmodifiable(_codexEntries);

  // Each mind map is strictly individual per book
  List<MindMapNodeModel> get mindMapNodes =>
      _mindMapNodes.where((n) => n.bookId == _activeBook.id).toList();

  // Characters are strictly individual per book
  List<CharacterModel> get characters =>
      _characters.where((c) => c.bookId == _activeBook.id).toList();

  int get activeChapterIndex =>
      _activeBook.chapters.indexWhere((c) => c.id == _activeChapter.id);
  int get totalChapters => _activeBook.chapters.length;
  bool get hasNextChapter {
    final idx = activeChapterIndex;
    return idx != -1 && idx < _activeBook.chapters.length - 1;
  }
  bool get hasPreviousChapter {
    final idx = activeChapterIndex;
    return idx > 0;
  }
  List<CharacterModel> get allCharacters => List.unmodifiable(_characters);

  WritingSprintModel? get activeSprint => _activeSprint;
  String get selectedFontFamily => _selectedFontFamily;
  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  double get maxEditorWidth => _maxEditorWidth;
  bool get isTypewriterMode => _isTypewriterMode;
  bool get isRevisionMode => _isRevisionMode;

  // Relationships filtered per active book
  List<CharacterRelationshipModel> get relationships =>
      _relationships.where((r) => r.bookId == _activeBook.id).toList();
  List<CharacterRelationshipModel> get allRelationships => List.unmodifiable(_relationships);

  // Sprint history filtered per active book
  List<SprintHistoryModel> get sprintHistory =>
      _sprintHistory.where((s) => s.bookId == _activeBook.id).toList();
  List<SprintHistoryModel> get allSprintHistory => List.unmodifiable(_sprintHistory);

  // Revision comments for active chapter
  List<RevisionCommentModel> get activeChapterComments => _activeChapter.comments;

  EditorController() {
    _initializeInitialState();
    _loadPersistedData();
    _startAutoBackupTimer();
  }

  void _initializeInitialState() {
    final initial = InitialSampleDataService.create();
    _allBooks = initial.allBooks;
    _activeBook = initial.activeBook;
    _activeChapter = initial.activeChapter;
    _ideas = initial.ideas;
    _codexEntries = initial.codexEntries;
    _mindMapNodes = initial.mindMapNodes;
    _characters = initial.characters;
    _writerStats = initial.writerStats;

    textEditingController.text = _activeChapter.content;
    _lastRecordedText = _activeChapter.content;
    textEditingController.addListener(_onTextChanged);
  }

  // Session & Data Persistence
  Future<void> _loadPersistedData() async {
    try {
      final savedBooks = await _persistenceService.loadBooks();
      final savedIdeas = await _persistenceService.loadIdeas();
      final savedCodex = await _persistenceService.loadCodexEntries();
      final savedNodes = await _persistenceService.loadMindMapNodes();
      final savedCharacters = await _persistenceService.loadCharacters();
      final savedStats = await _persistenceService.loadWriterStats();
      final prefs = await _persistenceService.loadPreferences();

      final sharedPrefs = await SharedPreferences.getInstance();
      final lastCursor = sharedPrefs.getInt(_prefKeyCursorPos) ?? 0;

      if (savedBooks != null && savedBooks.isNotEmpty) {
        _allBooks = savedBooks;
        final savedBookId = prefs['activeBookId'] as String?;
        _activeBook = _allBooks.firstWhere(
          (b) => b.id == savedBookId,
          orElse: () => _allBooks.first,
        );

        if (_activeBook.chapters.isNotEmpty) {
          final savedChapterId = prefs['activeChapterId'] as String?;
          _activeChapter = _activeBook.chapters.firstWhere(
            (c) => c.id == savedChapterId,
            orElse: () => _activeBook.chapters.first,
          );
        } else {
          addNewChapter('Capítulo 1');
        }

        textEditingController.removeListener(_onTextChanged);
        textEditingController.isDarkMode = _isDarkMode;
        textEditingController.text = _activeChapter.content;
        _lastRecordedText = _activeChapter.content;
        if (lastCursor >= 0 && lastCursor <= textEditingController.text.length) {
          textEditingController.selection = TextSelection.collapsed(offset: lastCursor);
        } else {
          textEditingController.selection = TextSelection.collapsed(offset: textEditingController.text.length);
        }
        textEditingController.addListener(_onTextChanged);
      }

      if (savedIdeas != null) {
        _ideas = savedIdeas.map((i) {
          if (i.bookId.isEmpty) {
            return i.copyWith(bookId: _activeBook.id.isNotEmpty ? _activeBook.id : 'b_tutorial');
          }
          return i;
        }).toList();
      }
      if (savedCodex != null) {
        _codexEntries = savedCodex.map((c) {
          if (c.bookId.isEmpty) {
            return c.copyWith(bookId: _activeBook.id.isNotEmpty ? _activeBook.id : 'b_tutorial');
          }
          return c;
        }).toList();
      }
      if (savedNodes != null) _mindMapNodes = savedNodes;
      if (savedCharacters != null) _characters = savedCharacters;
      if (savedStats != null) _writerStats = savedStats;

      final savedSprintHistory = await _persistenceService.loadSprintHistory();
      final savedRelationships = await _persistenceService.loadRelationships();
      if (savedSprintHistory != null) _sprintHistory = savedSprintHistory;
      if (savedRelationships != null) _relationships = savedRelationships;

      _isDarkMode = prefs['darkMode'] as bool? ?? _isDarkMode;
      textEditingController.isDarkMode = _isDarkMode;
      _selectedFontFamily = prefs['fontFamily'] as String? ?? _selectedFontFamily;
      _fontSize = (prefs['fontSize'] as num?)?.toDouble() ?? _fontSize;
      _lineHeight = (prefs['lineHeight'] as num?)?.toDouble() ?? _lineHeight;
      _maxEditorWidth = (prefs['maxEditorWidth'] as num?)?.toDouble() ?? _maxEditorWidth;
      _isTypewriterMode = prefs['typewriterMode'] as bool? ?? _isTypewriterMode;

      notifyListeners();
    } catch (_) {}
  }

  Future<void> saveCurrentSession() async {
    _saveCurrentData(debounced: false);
  }

  Future<void> flushPendingSave() async {
    await _persistenceService.flushPendingSave();
  }

  void _saveCurrentData({bool debounced = true}) {
    // Save cursor position safely to shared preferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_prefKeyCursorPos, textEditingController.selection.baseOffset);
    }).catchError((_) {});

    if (debounced) {
      _isSaving = true;
      _persistenceService.scheduleDebouncedSave(
        books: _allBooks,
        ideas: _ideas,
        codexEntries: _codexEntries,
        mindMapNodes: _mindMapNodes,
        characters: _characters,
        writerStats: _writerStats,
        activeBookId: _activeBook.id,
        activeChapterId: _activeChapter.id,
        isDarkMode: _isDarkMode,
        fontFamily: _selectedFontFamily,
        fontSize: _fontSize,
        lineHeight: _lineHeight,
        maxEditorWidth: _maxEditorWidth,
        typewriterMode: _isTypewriterMode,
        onSaved: () {
          _lastSavedTime = _persistenceService.lastSaved;
          _isSaving = false;
          notifyListeners();
        },
      );
    } else {
      _persistenceService.saveAllData(
        books: _allBooks,
        ideas: _ideas,
        codexEntries: _codexEntries,
        mindMapNodes: _mindMapNodes,
        characters: _characters,
        writerStats: _writerStats,
        activeBookId: _activeBook.id,
        activeChapterId: _activeChapter.id,
        isDarkMode: _isDarkMode,
        fontFamily: _selectedFontFamily,
        fontSize: _fontSize,
        lineHeight: _lineHeight,
        maxEditorWidth: _maxEditorWidth,
        typewriterMode: _isTypewriterMode,
      );
      _lastSavedTime = DateTime.now();
      _isSaving = false;
    }
  }

  // Text changes handler with Debounce & Undo Stack
  void _onTextChanged() {
    if (_isPerformingUndoRedo) return;

    final currentText = textEditingController.text;

    // Record undo history if significant change
    if ((currentText.length - _lastRecordedText.length).abs() > 4 ||
        currentText.endsWith(' ') ||
        currentText.endsWith('\n')) {
      _undoStack.add(_lastRecordedText);
      if (_undoStack.length > 50) _undoStack.removeAt(0);
      _redoStack.clear();
      _lastRecordedText = currentText;
    }

    _textChangeDebounceTimer?.cancel();
    _textChangeDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      final oldWordCount = _activeChapter.wordCount;

      _activeChapter = _activeChapter.copyWith(
        content: currentText,
        lastEdited: DateTime.now(),
      );

      final updatedChapters = _activeBook.chapters.map((ch) {
        return ch.id == _activeChapter.id ? _activeChapter : ch;
      }).toList();

      _activeBook = _activeBook.copyWith(
        chapters: updatedChapters,
        lastEdited: DateTime.now(),
      );

      _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();

      // Update writer stats words today
      final newWordCount = _activeChapter.wordCount;
      final delta = newWordCount - oldWordCount;
      if (delta > 0) {
        _writerStats = _writerStats.copyWith(
          wordsToday: _writerStats.wordsToday + delta,
          totalWordsWritten: _writerStats.totalWordsWritten + delta,
        );
      }

      _saveCurrentData(debounced: true);
      notifyListeners();
    });
  }

  // --- UNDO / REDO ---

  void undo() {
    if (!canUndo) return;
    _isPerformingUndoRedo = true;
    _redoStack.add(textEditingController.text);
    final previousText = _undoStack.removeLast();
    _lastRecordedText = previousText;
    textEditingController.text = previousText;
    textEditingController.selection = TextSelection.collapsed(offset: previousText.length);

    _activeChapter = _activeChapter.copyWith(content: previousText, lastEdited: DateTime.now());
    _isPerformingUndoRedo = false;
    _saveCurrentData(debounced: true);
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _isPerformingUndoRedo = true;
    _undoStack.add(textEditingController.text);
    final nextText = _redoStack.removeLast();
    _lastRecordedText = nextText;
    textEditingController.text = nextText;
    textEditingController.selection = TextSelection.collapsed(offset: nextText.length);

    _activeChapter = _activeChapter.copyWith(content: nextText, lastEdited: DateTime.now());
    _isPerformingUndoRedo = false;
    _saveCurrentData(debounced: true);
    notifyListeners();
  }

  // --- ACTIONS ---

  void setFontFamily(String font) {
    _selectedFontFamily = font;
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size.clamp(12.0, 32.0);
    _saveCurrentData(debounced: true);
    notifyListeners();
  }

  void setLineHeight(double height) {
    _lineHeight = height.clamp(1.2, 2.5);
    _saveCurrentData(debounced: true);
    notifyListeners();
  }

  void setMaxEditorWidth(double width) {
    _maxEditorWidth = width;
    _saveCurrentData(debounced: true);
    notifyListeners();
  }

  void toggleTypewriterMode() {
    _isTypewriterMode = !_isTypewriterMode;
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  /// Exports the entire library and settings as a clean .inkwright JSON payload
  String exportBackupJson() {
    return _persistenceService.generateBackupJson(
      books: _allBooks,
      ideas: _ideas,
      codexEntries: _codexEntries,
      mindMapNodes: _mindMapNodes,
      characters: _characters,
      writerStats: _writerStats,
      activeBookId: _activeBook.id,
      activeChapterId: _activeChapter.id,
      isDarkMode: _isDarkMode,
      fontFamily: _selectedFontFamily,
      fontSize: _fontSize,
      lineHeight: _lineHeight,
      maxEditorWidth: _maxEditorWidth,
      typewriterMode: _isTypewriterMode,
    );
  }

  /// Restores library from a .inkwright backup payload
  bool restoreFromBackupJson(String rawJson) {
    final data = _persistenceService.parseBackupJson(rawJson);
    if (data == null) return false;

    final books = data['books'] as List<BookModel>?;
    if (books == null || books.isEmpty) return false;

    final prefs = (data['preferences'] as Map<String, dynamic>?) ?? {};
    final savedBookId = prefs['activeBookId'] as String?;
    _activeBook = _allBooks.firstWhere(
      (b) => b.id == savedBookId,
      orElse: () => _allBooks.first,
    );

    _ideas = ((data['ideas'] as List<IdeaSnippetModel>?) ?? _ideas).map((i) {
      if (i.bookId.isEmpty) {
        return i.copyWith(bookId: _activeBook.id.isNotEmpty ? _activeBook.id : 'b_tutorial');
      }
      return i;
    }).toList();
    _codexEntries = ((data['codex'] as List<CodexEntryModel>?) ?? _codexEntries).map((c) {
      if (c.bookId.isEmpty) {
        return c.copyWith(bookId: _activeBook.id.isNotEmpty ? _activeBook.id : 'b_tutorial');
      }
      return c;
    }).toList();
    _mindMapNodes = (data['mindMap'] as List<MindMapNodeModel>?) ?? _mindMapNodes;
    _characters = (data['characters'] as List<CharacterModel>?) ?? _characters;
    if (data['writerStats'] != null) {
      _writerStats = data['writerStats'] as WriterStatsModel;
    }

    if (_activeBook.chapters.isNotEmpty) {
      final savedChId = prefs['activeChapterId'] as String?;
      _activeChapter = _activeBook.chapters.firstWhere(
        (c) => c.id == savedChId,
        orElse: () => _activeBook.chapters.first,
      );
    }

    _selectedFontFamily = prefs['fontFamily'] as String? ?? _selectedFontFamily;
    _fontSize = (prefs['fontSize'] as num?)?.toDouble() ?? _fontSize;
    _lineHeight = (prefs['lineHeight'] as num?)?.toDouble() ?? _lineHeight;
    _maxEditorWidth = (prefs['maxEditorWidth'] as num?)?.toDouble() ?? _maxEditorWidth;
    _isTypewriterMode = prefs['typewriterMode'] as bool? ?? _isTypewriterMode;

    textEditingController.removeListener(_onTextChanged);
    textEditingController.text = _activeChapter.content;
    _lastRecordedText = _activeChapter.content;
    _undoStack.clear();
    _redoStack.clear();
    textEditingController.addListener(_onTextChanged);

    _saveCurrentData(debounced: false);
    notifyListeners();
    return true;
  }

  void toggleThemeMode() {
    _isDarkMode = !_isDarkMode;
    textEditingController.isDarkMode = _isDarkMode;
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void toggleLiveMarkdown() {
    textEditingController.isLiveMarkdownEnabled = !textEditingController.isLiveMarkdownEnabled;
    notifyListeners();
  }

  void toggleZenMode() {
    _isZenMode = !_isZenMode;
    notifyListeners();
  }

  void switchBook(String bookId) {
    final book = _allBooks.firstWhere((b) => b.id == bookId, orElse: () => _activeBook);
    selectBook(book);
  }

  void selectBook(BookModel book) {
    _activeBook = book;
    if (book.chapters.isNotEmpty) {
      _activeChapter = book.chapters.first;
      textEditingController.removeListener(_onTextChanged);
      textEditingController.text = _activeChapter.content;
      _lastRecordedText = _activeChapter.content;
      _undoStack.clear();
      _redoStack.clear();
      textEditingController.addListener(_onTextChanged);
    } else {
      addNewChapter('Capítulo 1');
    }
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void selectChapter(ChapterModel chapter) {
    _activeChapter = chapter;
    textEditingController.removeListener(_onTextChanged);
    textEditingController.text = chapter.content;
    _lastRecordedText = chapter.content;
    _undoStack.clear();
    _redoStack.clear();
    textEditingController.addListener(_onTextChanged);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void addNewChapter(String title, {String povCharacter = '', String notes = ''}) {
    final newChapterNum = _activeBook.chapters.length + 1;
    final newChapter = ChapterModel(
      id: 'ch_${DateTime.now().millisecondsSinceEpoch}',
      bookId: _activeBook.id,
      chapterNumber: newChapterNum,
      title: title.trim().isEmpty ? 'Capítulo $newChapterNum' : title.trim(),
      content: '',
      lastEdited: DateTime.now(),
      notes: notes.trim(),
      povCharacter: povCharacter.trim(),
    );

    final updatedChapters = List<ChapterModel>.from(_activeBook.chapters)..add(newChapter);
    _activeBook = _activeBook.copyWith(chapters: updatedChapters);
    _activeChapter = newChapter;

    textEditingController.removeListener(_onTextChanged);
    textEditingController.text = '';
    _lastRecordedText = '';
    _undoStack.clear();
    _redoStack.clear();
    textEditingController.addListener(_onTextChanged);

    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void goToNextChapter() {
    final idx = activeChapterIndex;
    if (idx != -1 && idx < _activeBook.chapters.length - 1) {
      selectChapter(_activeBook.chapters[idx + 1]);
    }
  }

  void goToPreviousChapter() {
    final idx = activeChapterIndex;
    if (idx > 0) {
      selectChapter(_activeBook.chapters[idx - 1]);
    }
  }

  void updateActiveChapterTitle(String newTitle) {
    if (newTitle.trim().isEmpty || newTitle.trim() == _activeChapter.title) return;
    final updated = _activeChapter.copyWith(title: newTitle.trim(), lastEdited: DateTime.now());
    _activeChapter = updated;
    final updatedChapters = _activeBook.chapters.map((c) => c.id == updated.id ? updated : c).toList();
    _activeBook = _activeBook.copyWith(chapters: updatedChapters);
    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();
    _saveCurrentData(debounced: true);
    notifyListeners();
  }

  void updateChapterDetails(
    String chapterId, {
    String? title,
    String? notes,
    String? povCharacter,
    bool? isCompleted,
  }) {
    final updatedChapters = _activeBook.chapters.map((c) {
      if (c.id == chapterId) {
        return c.copyWith(
          title: title ?? c.title,
          notes: notes ?? c.notes,
          povCharacter: povCharacter ?? c.povCharacter,
          isCompleted: isCompleted ?? c.isCompleted,
          lastEdited: DateTime.now(),
        );
      }
      return c;
    }).toList();

    _activeBook = _activeBook.copyWith(chapters: updatedChapters);
    if (_activeChapter.id == chapterId) {
      _activeChapter = updatedChapters.firstWhere((c) => c.id == chapterId);
    }
    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void reorderChapters(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    moveChapter(oldIndex, newIndex);
  }

  void moveChapter(int oldIndex, int newIndex) {
    if (oldIndex == newIndex || oldIndex < 0 || oldIndex >= _activeBook.chapters.length) return;
    final updatedList = ChapterOperationsService.moveChapter(_activeBook.chapters, oldIndex, newIndex);
    _activeBook = _activeBook.copyWith(chapters: updatedList);
    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void createNewBook(String title, String subtitle, int targetWordCount, {String genre = 'Ficción', String coverEmoji = '📖'}) {
    final newBook = BookModel(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      genre: genre,
      targetWordCount: targetWordCount,
      status: BookStatus.outlining,
      chapters: [],
      lastEdited: DateTime.now(),
      coverEmoji: coverEmoji,
      coverColorHex: 0xFF18181B,
      tags: [genre],
      synopsis: subtitle,
    );

    _allBooks.insert(0, newBook);

    // Initialize an isolated, clean starter node for this new book's mind map
    final starterNode = MindMapNodeModel(
      id: 'node_${DateTime.now().millisecondsSinceEpoch}',
      bookId: newBook.id,
      title: 'Premisa: $title',
      description: 'Define aquí el conflicto principal, la meta del protagonista y el tono de la historia.',
      act: PlotAct.act1Exposition,
      type: PlotNodeType.turningPoint,
      dx: 80,
      dy: 120,
      connectedToIds: [],
      colorHex: 0xFF18181B,
      iconEmoji: '💡',
    );
    _mindMapNodes.add(starterNode);

    selectBook(newBook);
  }

  /// Importa un libro completo con sus capítulos detectados
  void importNewBook(ImportedBookData data) {
    final bookId = 'b_${DateTime.now().millisecondsSinceEpoch}';
    final chapters = <ChapterModel>[];

    for (int i = 0; i < data.chapters.length; i++) {
      final chData = data.chapters[i];
      chapters.add(ChapterModel(
        id: 'ch_${DateTime.now().millisecondsSinceEpoch}_$i',
        bookId: bookId,
        chapterNumber: i + 1,
        title: chData.title,
        content: chData.content,
        lastEdited: DateTime.now(),
        notes: '',
        povCharacter: '',
      ));
    }

    final targetWords = data.totalWords > 0 ? (data.totalWords * 1.2).round() : 80000;

    final newBook = BookModel(
      id: bookId,
      title: data.title,
      subtitle: data.subtitle.isNotEmpty ? data.subtitle : (data.author.isNotEmpty ? 'Por ${data.author}' : ''),
      genre: data.genre.isNotEmpty ? data.genre : 'Ficción',
      targetWordCount: targetWords,
      status: BookStatus.drafting,
      chapters: chapters,
      lastEdited: DateTime.now(),
      coverEmoji: '📚',
      coverColorHex: 0xFF18181B,
      tags: [data.genre.isNotEmpty ? data.genre : 'Ficción', 'Importado'],
      synopsis: data.synopsis,
    );

    _allBooks.insert(0, newBook);

    // Nodo inicial del mapa mental
    final starterNode = MindMapNodeModel(
      id: 'node_${DateTime.now().millisecondsSinceEpoch}',
      bookId: newBook.id,
      title: 'Premisa: ${newBook.title}',
      description: data.synopsis.isNotEmpty
          ? data.synopsis
          : 'Manuscrito importado con ${chapters.length} capítulos.',
      act: PlotAct.act1Exposition,
      type: PlotNodeType.turningPoint,
      dx: 80,
      dy: 120,
      connectedToIds: [],
      colorHex: 0xFF18181B,
      iconEmoji: '📚',
    );
    _mindMapNodes.add(starterNode);

    selectBook(newBook);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  /// Importa capítulos dentro del libro activo actual
  void importChaptersIntoActiveBook(List<ImportedChapterData> importedChapters) {
    if (importedChapters.isEmpty) return;

    final currentCount = _activeBook.chapters.length;
    final newChapters = <ChapterModel>[];

    for (int i = 0; i < importedChapters.length; i++) {
      final chData = importedChapters[i];
      newChapters.add(ChapterModel(
        id: 'ch_${DateTime.now().millisecondsSinceEpoch}_$i',
        bookId: _activeBook.id,
        chapterNumber: currentCount + i + 1,
        title: chData.title,
        content: chData.content,
        lastEdited: DateTime.now(),
        notes: '',
        povCharacter: '',
      ));
    }

    final updatedChapters = List<ChapterModel>.from(_activeBook.chapters)..addAll(newChapters);
    _activeBook = _activeBook.copyWith(
      chapters: updatedChapters,
      lastEdited: DateTime.now(),
    );

    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();

    selectChapter(newChapters.first);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void toggleChapterCompletion(String chapterId) {
    final updatedChapters = _activeBook.chapters.map((ch) {
      if (ch.id == chapterId) {
        return ch.copyWith(isCompleted: !ch.isCompleted);
      }
      return ch;
    }).toList();

    _activeBook = _activeBook.copyWith(chapters: updatedChapters);
    if (_activeChapter.id == chapterId) {
      _activeChapter = _activeChapter.copyWith(isCompleted: !_activeChapter.isCompleted);
    }
    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  bool deleteChapter(String chapterId) {
    if (_activeBook.chapters.length <= 1) {
      return false;
    }

    final reindexed = ChapterOperationsService.removeAndReindex(_activeBook.chapters, chapterId);
    _activeBook = _activeBook.copyWith(chapters: reindexed);
    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();

    if (_activeChapter.id == chapterId) {
      selectChapter(reindexed.first);
    } else {
      _saveCurrentData(debounced: false);
      notifyListeners();
    }
    return true;
  }

  /// Splits the specified chapter at [splitPosition] into two chapters.
  ChapterModel? splitChapter(String chapterId, int splitPosition, {String? newChapterTitle}) {
    final currentText = chapterId == _activeChapter.id
        ? textEditingController.text
        : _activeBook.chapters.firstWhere((ch) => ch.id == chapterId, orElse: () => _activeChapter).content;

    final result = ChapterOperationsService.splitChapter(
      chapters: _activeBook.chapters,
      bookId: _activeBook.id,
      chapterId: chapterId,
      splitPosition: splitPosition,
      currentContent: currentText,
      newChapterTitle: newChapterTitle,
    );
    if (result == null) return null;

    _activeBook = _activeBook.copyWith(chapters: result.updatedChapters);
    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();

    if (_activeChapter.id == chapterId) {
      _activeChapter = result.updatedOriginal;
      textEditingController.removeListener(_onTextChanged);
      textEditingController.text = result.updatedOriginal.content;
      _lastRecordedText = result.updatedOriginal.content;
      _undoStack.clear();
      _redoStack.clear();
      textEditingController.addListener(_onTextChanged);
    }

    _saveCurrentData(debounced: false);
    notifyListeners();
    return result.newChapter;
  }

  /// Merges the chapter with [chapterId] and the subsequent chapter in the book.
  bool mergeChapterWithNext(String chapterId) {
    final chapterIndex = _activeBook.chapters.indexWhere((ch) => ch.id == chapterId);
    if (chapterIndex == -1 || chapterIndex >= _activeBook.chapters.length - 1) {
      return false;
    }

    final current = _activeBook.chapters[chapterIndex];
    final next = _activeBook.chapters[chapterIndex + 1];

    final currentContent = current.id == _activeChapter.id
        ? textEditingController.text
        : current.content;
    final nextContent = next.id == _activeChapter.id
        ? textEditingController.text
        : next.content;

    final result = ChapterOperationsService.mergeChapterWithNext(
      chapters: _activeBook.chapters,
      chapterId: chapterId,
      currentChapterContent: currentContent,
      nextChapterContent: nextContent,
    );
    if (result == null) return false;

    _activeBook = _activeBook.copyWith(chapters: result.updatedChapters);
    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();

    _mindMapNodes = _mindMapNodes.map((node) {
      if (node.linkedChapterId == result.deletedChapterId) {
        return node.copyWith(linkedChapterId: result.mergedChapter.id);
      }
      return node;
    }).toList();

    if (_activeChapter.id == current.id || _activeChapter.id == next.id) {
      _activeChapter = result.mergedChapter;
      textEditingController.removeListener(_onTextChanged);
      textEditingController.text = result.mergedContent;
      _lastRecordedText = result.mergedContent;
      _undoStack.clear();
      _redoStack.clear();
      textEditingController.addListener(_onTextChanged);
    }

    _saveCurrentData(debounced: false);
    notifyListeners();
    return true;
  }

  /// Creates an instant snapshot of the specified chapter (or active chapter) with an optional custom label
  ChapterSnapshotModel? createChapterSnapshot(
    String chapterId, {
    String? label,
    String? customContent,
  }) {
    final index = _activeBook.chapters.indexWhere((c) => c.id == chapterId);
    if (index == -1) return null;

    final targetChapter = _activeBook.chapters[index];
    final snapshotContent = customContent ??
        (targetChapter.id == _activeChapter.id
            ? textEditingController.text
            : targetChapter.content);

    final snapshot = ChapterOperationsService.createSnapshot(
      targetChapter: targetChapter,
      content: snapshotContent,
      label: label,
    );

    final updatedSnapshots = List<ChapterSnapshotModel>.from(targetChapter.snapshots)
      ..insert(0, snapshot);

    final updatedChapter = targetChapter.copyWith(
      snapshots: updatedSnapshots,
      lastEdited: snapshot.createdAt,
    );

    final updatedChapters = List<ChapterModel>.from(_activeBook.chapters);
    updatedChapters[index] = updatedChapter;

    _activeBook = _activeBook.copyWith(chapters: updatedChapters);
    if (_activeChapter.id == chapterId) {
      _activeChapter = updatedChapter;
    }
    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();

    _saveCurrentData(debounced: false);
    notifyListeners();
    return snapshot;
  }

  /// Restores a snapshot into the chapter, creating an automatic safety snapshot of the current state before replacing
  bool restoreChapterSnapshot(String chapterId, String snapshotId) {
    final currentText = _activeChapter.id == chapterId
        ? textEditingController.text
        : _activeBook.chapters.firstWhere((c) => c.id == chapterId, orElse: () => _activeChapter).content;

    final result = ChapterOperationsService.restoreSnapshot(
      chapters: _activeBook.chapters,
      chapterId: chapterId,
      snapshotId: snapshotId,
      currentContent: currentText,
    );
    if (result == null) return false;

    _activeBook = _activeBook.copyWith(chapters: result.updatedChapters);
    if (_activeChapter.id == chapterId) {
      _activeChapter = result.restoredChapter;
      textEditingController.removeListener(_onTextChanged);
      _undoStack.add(textEditingController.text);
      textEditingController.text = result.restoredChapter.content;
      _lastRecordedText = result.restoredChapter.content;
      textEditingController.addListener(_onTextChanged);
    }
    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();

    _saveCurrentData(debounced: false);
    notifyListeners();
    return true;
  }

  /// Deletes a snapshot from a chapter
  bool deleteChapterSnapshot(String chapterId, String snapshotId) {
    final index = _activeBook.chapters.indexWhere((c) => c.id == chapterId);
    if (index == -1) return false;

    final targetChapter = _activeBook.chapters[index];
    final updatedSnapshots = ChapterOperationsService.deleteSnapshot(
      chapter: targetChapter,
      snapshotId: snapshotId,
    );

    final updatedChapter = targetChapter.copyWith(snapshots: updatedSnapshots);
    final updatedChapters = List<ChapterModel>.from(_activeBook.chapters);
    updatedChapters[index] = updatedChapter;

    _activeBook = _activeBook.copyWith(chapters: updatedChapters);
    if (_activeChapter.id == chapterId) {
      _activeChapter = updatedChapter;
    }
    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();

    _saveCurrentData(debounced: false);
    notifyListeners();
    return true;
  }

  /// Replaces all occurrences of [query] with [replacement] across ALL chapters of the active book.
  /// Returns the total number of occurrences replaced.
  int replaceAllInBook(String query, String replacement, {bool caseSensitive = false}) {
    if (query.isEmpty) return 0;
    flushPendingSave();

    final currentText = textEditingController.text;
    final regex = RegExp(RegExp.escape(query), caseSensitive: caseSensitive);

    int totalReplaced = 0;
    final updatedChapters = _activeBook.chapters.map((ch) {
      final baseContent = ch.id == _activeChapter.id ? currentText : ch.content;
      final matchCount = regex.allMatches(baseContent).length;
      if (matchCount > 0) {
        totalReplaced += matchCount;
        final newContent = baseContent.replaceAll(regex, replacement);
        return ch.copyWith(content: newContent, lastEdited: DateTime.now());
      }
      return ch;
    }).toList();

    if (totalReplaced > 0) {
      _activeBook = _activeBook.copyWith(chapters: updatedChapters);
      final activeIdx = updatedChapters.indexWhere((c) => c.id == _activeChapter.id);
      if (activeIdx != -1) {
        _activeChapter = updatedChapters[activeIdx];
        textEditingController.removeListener(_onTextChanged);
        _undoStack.add(textEditingController.text);
        textEditingController.text = _activeChapter.content;
        _lastRecordedText = _activeChapter.content;
        textEditingController.addListener(_onTextChanged);
      }
      _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();
      _saveCurrentData(debounced: false);
      notifyListeners();
    }

    return totalReplaced;
  }

  bool deleteBook(String bookId) {
    if (_allBooks.length <= 1) {
      return false;
    }

    _allBooks = _allBooks.where((b) => b.id != bookId).toList();
    _mindMapNodes.removeWhere((n) => n.bookId == bookId);
    _characters.removeWhere((c) => c.bookId == bookId);
    _ideas.removeWhere((i) => i.bookId == bookId);
    _codexEntries.removeWhere((c) => c.bookId == bookId);

    if (_activeBook.id == bookId) {
      selectBook(_allBooks.first);
    } else {
      _saveCurrentData(debounced: false);
      notifyListeners();
    }
    return true;
  }

  // --- CHARACTERS ACTIONS ---

  void addCharacter(CharacterModel character) {
    final scoped = character.bookId.isEmpty ? character.copyWith(bookId: _activeBook.id) : character;
    _characters.insert(0, scoped);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void updateCharacter(CharacterModel updated) {
    _characters = _characters.map((c) => c.id == updated.id ? updated : c).toList();
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void deleteCharacter(String characterId) {
    _characters.removeWhere((c) => c.id == characterId);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void insertCharacterToEditor(CharacterModel character) {
    final buffer = StringBuffer();
    buffer.writeln('\n\n## Ficha de Personaje: ${character.name}');
    buffer.writeln('**Rol:** ${character.role} | **Arquetipo:** ${character.archetype}');
    if (character.quote.isNotEmpty) {
      buffer.writeln('> ${character.quote}');
    }
    if (character.traits.isNotEmpty) {
      buffer.writeln('**Rasgos:** ${character.traits.join(', ')}');
    }
    if (character.motivation.isNotEmpty) {
      buffer.writeln('**Motivación:** ${character.motivation}');
    }
    if (character.flawOrGhost.isNotEmpty) {
      buffer.writeln('**Conflicto / Fantasma:** ${character.flawOrGhost}');
    }
    if (character.writtenBiography.isNotEmpty) {
      buffer.writeln('\n### Biografía & Trasfondo\n${character.writtenBiography}');
    }
    buffer.writeln('\n');
    insertTextToEditor(buffer.toString());
  }

  // --- IDEAS ACTIONS ---

  void addIdea(IdeaSnippetModel idea) {
    final scoped = idea.bookId.isEmpty ? idea.copyWith(bookId: _activeBook.id) : idea;
    _ideas.insert(0, scoped);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void updateIdea(IdeaSnippetModel updated) {
    _ideas = _ideas.map((item) {
      if (item.id == updated.id) {
        final bookId = updated.bookId.isNotEmpty ? updated.bookId : item.bookId;
        return updated.copyWith(bookId: bookId.isNotEmpty ? bookId : _activeBook.id);
      }
      return item;
    }).toList();
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void deleteIdea(String ideaId) {
    _ideas.removeWhere((item) => item.id == ideaId);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void toggleIdeaPin(String ideaId) {
    _ideas = _ideas.map((item) {
      if (item.id == ideaId) {
        return item.copyWith(isPinned: !item.isPinned);
      }
      return item;
    }).toList();
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void insertIdeaToEditor(IdeaSnippetModel idea) {
    insertTextToEditor('\n\n/* Fragmento de Idea: ${idea.title} */\n${idea.content}\n\n');
  }

  void insertTextToEditor(String snippetText) {
    final text = textEditingController.text;
    final selection = textEditingController.selection;

    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, snippetText);
      textEditingController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + snippetText.length),
      );
    } else {
      final newText = text + snippetText;
      textEditingController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  // --- CODEX ACTIONS ---

  void addCodexEntry(CodexEntryModel entry) {
    final scoped = entry.bookId.isEmpty ? entry.copyWith(bookId: _activeBook.id) : entry;
    _codexEntries.insert(0, scoped);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void updateCodexEntry(CodexEntryModel updated) {
    _codexEntries = _codexEntries.map((item) {
      if (item.id == updated.id) {
        final bookId = updated.bookId.isNotEmpty ? updated.bookId : item.bookId;
        return updated.copyWith(bookId: bookId.isNotEmpty ? bookId : _activeBook.id);
      }
      return item;
    }).toList();
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void deleteCodexEntry(String entryId) {
    _codexEntries.removeWhere((item) => item.id == entryId);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void toggleCodexPin(String entryId) {
    _codexEntries = _codexEntries.map((item) {
      if (item.id == entryId) {
        return item.copyWith(isPinned: !item.isPinned);
      }
      return item;
    }).toList();
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  // --- WRITING SPRINT ACTIONS ---

  void startSprint({required int durationMinutes, required int targetWords}) {
    _activeSprint = WritingSprintModel(
      startTime: DateTime.now(),
      durationMinutes: durationMinutes,
      targetWords: targetWords,
      startingWordCount: WriterTextFormatter.countWords(textEditingController.text),
      isActive: true,
    );
    notifyListeners();
  }

  void stopSprint() {
    if (_activeSprint != null) {
      _activeSprint = _activeSprint!.copyWith(isActive: false);
      notifyListeners();
    }
  }

  // --- WRITER STATS ACTIONS ---

  void updateDailyGoal(int newGoalWords) {
    if (newGoalWords <= 0) return;
    _writerStats = _writerStats.copyWith(dailyGoalWords: newGoalWords);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  // --- MIND MAP PLOT ACTIONS ---

  void addMindMapNode(MindMapNodeModel node) {
    final scopedNode = node.bookId.isEmpty ? node.copyWith(bookId: _activeBook.id) : node;
    _mindMapNodes.add(scopedNode);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void updateMindMapNode(MindMapNodeModel updated) {
    _mindMapNodes = _mindMapNodes.map((n) {
      if (n.id == updated.id) {
        return updated;
      }
      return n;
    }).toList();
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void updateMindMapNodePosition(String nodeId, Offset newPos) {
    _mindMapNodes = _mindMapNodes.map((n) {
      if (n.id == nodeId) {
        return n.copyWith(dx: newPos.dx, dy: newPos.dy);
      }
      return n;
    }).toList();
    _saveCurrentData(debounced: true);
    notifyListeners();
  }

  void connectMindMapNodes(String fromId, String toId) {
    _mindMapNodes = MindMapLayoutService.connectNodes(_mindMapNodes, fromId, toId);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void disconnectMindMapNodes(String fromId, String toId) {
    _mindMapNodes = MindMapLayoutService.disconnectNodes(_mindMapNodes, fromId, toId);
    notifyListeners();
  }

  void duplicateMindMapNode(String nodeId) {
    final index = _mindMapNodes.indexWhere((n) => n.id == nodeId);
    if (index != -1) {
      final clone = MindMapLayoutService.duplicateNode(_mindMapNodes[index]);
      _mindMapNodes.add(clone);
      notifyListeners();
    }
  }

  void autoArrangeMindMapNodes() {
    _mindMapNodes = MindMapLayoutService.autoArrangeNodes(
      allNodes: _mindMapNodes,
      activeBookId: _activeBook.id,
    );
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void deleteMindMapNode(String nodeId) {
    _mindMapNodes = MindMapLayoutService.deleteNode(_mindMapNodes, nodeId);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  // --- CHARACTER RELATIONSHIPS ---

  void addRelationship(CharacterRelationshipModel relationship) {
    final scoped = relationship.bookId.isEmpty
        ? relationship.copyWith(bookId: _activeBook.id)
        : relationship;
    _relationships.insert(0, scoped);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void updateRelationship(CharacterRelationshipModel updated) {
    _relationships = _relationships
        .map((r) => r.id == updated.id ? updated : r)
        .toList();
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void deleteRelationship(String relationshipId) {
    _relationships.removeWhere((r) => r.id == relationshipId);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  List<CharacterRelationshipModel> relationshipsForCharacter(String characterId) {
    return _relationships
        .where((r) =>
            r.bookId == _activeBook.id &&
            (r.fromCharacterId == characterId || r.toCharacterId == characterId))
        .toList();
  }

  // --- SPRINT HISTORY ---

  void recordSprintHistory({
    required int durationMinutes,
    required int targetWords,
    required int wordsWritten,
    required DateTime startTime,
    required bool completed,
  }) {
    final entry = SprintHistoryModel(
      id: 'sprint_${DateTime.now().millisecondsSinceEpoch}',
      bookId: _activeBook.id,
      chapterId: _activeChapter.id,
      chapterTitle: _activeChapter.title,
      startTime: startTime,
      endTime: DateTime.now(),
      durationMinutes: durationMinutes,
      targetWords: targetWords,
      wordsWritten: wordsWritten,
      completed: completed,
    );
    _sprintHistory.insert(0, entry);
    if (_sprintHistory.length > 200) {
      _sprintHistory = _sprintHistory.sublist(0, 200);
    }
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void clearSprintHistory() {
    _sprintHistory.removeWhere((s) => s.bookId == _activeBook.id);
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  // --- REVISION MODE & COMMENTS ---

  void toggleRevisionMode() {
    _isRevisionMode = !_isRevisionMode;
    notifyListeners();
  }

  void setRevisionMode(bool value) {
    if (_isRevisionMode == value) return;
    _isRevisionMode = value;
    notifyListeners();
  }

  void addRevisionComment(RevisionCommentModel comment) {
    final scoped = comment.chapterId.isEmpty
        ? comment.copyWith(chapterId: _activeChapter.id)
        : comment;
    final updatedComments = List<RevisionCommentModel>.from(_activeChapter.comments)
      ..insert(0, scoped);
    _updateActiveChapterComments(updatedComments);
  }

  void toggleRevisionComment(String commentId) {
    final updated = _activeChapter.comments.map((c) {
      if (c.id == commentId) return c.copyWith(isResolved: !c.isResolved);
      return c;
    }).toList();
    _updateActiveChapterComments(updated);
  }

  void deleteRevisionComment(String commentId) {
    final updated = _activeChapter.comments
        .where((c) => c.id != commentId)
        .toList();
    _updateActiveChapterComments(updated);
  }

  void _updateActiveChapterComments(List<RevisionCommentModel> comments) {
    _activeChapter = _activeChapter.copyWith(comments: comments);
    final updatedChapters = _activeBook.chapters
        .map((c) => c.id == _activeChapter.id ? _activeChapter : c)
        .toList();
    _activeBook = _activeBook.copyWith(chapters: updatedChapters);
    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void _startAutoBackupTimer() {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      performSilentAutoBackup();
    });
  }

  Future<void> performSilentAutoBackup() async {
    try {
      final backupJson = exportBackupJson();
      await _persistenceService.saveSilentAutoBackup(backupJson);
      _lastAutoBackupTime = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Error en auto-respaldo silencioso: $e');
    }
  }

  @override
  void dispose() {
    _autoBackupTimer?.cancel();
    _textChangeDebounceTimer?.cancel();
    _persistenceService.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
