import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/chapter_model.dart';
import '../models/idea_snippet_model.dart';
import '../models/writer_stats_model.dart';
import '../models/codex_entry_model.dart';
import '../models/soundscape_model.dart';
import '../models/writing_sprint_model.dart';
import '../formatters/writer_text_formatter.dart';

class EditorController extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isZenMode = false;
  final bool _isAutoSaveEnabled = true;

  late BookModel _activeBook;
  late ChapterModel _activeChapter;
  late WriterStatsModel _writerStats;
  List<BookModel> _allBooks = [];
  List<IdeaSnippetModel> _ideas = [];
  List<CodexEntryModel> _codexEntries = [];
  List<SoundscapeModel> _soundscapes = [];
  
  SoundscapeModel? _activeSoundscape;
  bool _isPlayingAmbience = false;

  WritingSprintModel? _activeSprint;
  String _selectedFontFamily = 'Lora'; // Lora, Merriweather, Playfair Display, JetBrains Mono

  final TextEditingController textEditingController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get isZenMode => _isZenMode;
  bool get isAutoSaveEnabled => _isAutoSaveEnabled;

  BookModel get activeBook => _activeBook;
  ChapterModel get activeChapter => _activeChapter;
  WriterStatsModel get writerStats => _writerStats;
  List<BookModel> get allBooks => List.unmodifiable(_allBooks);
  List<IdeaSnippetModel> get ideas => List.unmodifiable(_ideas);
  List<CodexEntryModel> get codexEntries => List.unmodifiable(_codexEntries);
  List<SoundscapeModel> get soundscapes => List.unmodifiable(_soundscapes);

  SoundscapeModel? get activeSoundscape => _activeSoundscape;
  bool get isPlayingAmbience => _isPlayingAmbience;
  WritingSprintModel? get activeSprint => _activeSprint;
  String get selectedFontFamily => _selectedFontFamily;

  EditorController() {
    _initializeInitialState();
  }

  void _initializeInitialState() {
    // Initial sample chapters for "The Whispering Pines"
    final ch1 = ChapterModel(
      id: 'ch_1',
      bookId: 'b_1',
      chapterNumber: 1,
      title: 'The Fog Across Blackwood',
      content: '''The lantern flickered violently as Silas pushed open the heavy oak door. Beyond the threshold lay the valley of Blackwood, shrouded in an ethereal mint-colored mist that seemed to breathe with a rhythm of its own.

"You should not have returned, Silas," Martha murmured from the shadows of the hearth. Her fingers trembled around the antique silver compass.

Silas didn't answer immediately. He set his leather journal on the mahogany desk and unbuttoned his damp cloak. "The map doesn't lie, Martha. What we buried thirty years ago was never meant to stay underground."''',
      lastEdited: DateTime.now().subtract(const Duration(hours: 2)),
      isCompleted: true,
      notes: 'Introduce Silas motivation early. Establish tension with Martha.',
      povCharacter: 'Silas Vance',
    );

    final ch2 = ChapterModel(
      id: 'ch_2',
      bookId: 'b_1',
      chapterNumber: 2,
      title: 'Echoes of the Silver Compass',
      content: '''The clock in the bell tower struck three. Every chime resonated through the stone walls, carrying the weight of forgotten promises.

Silas traced the etched runes along the compass rim. The needle spun wildly, settling not toward true north, but toward the ruins of St. Jude's Abbey.''',
      lastEdited: DateTime.now().subtract(const Duration(minutes: 45)),
      isCompleted: false,
      notes: 'Foreshadowing the discovery in Chapter 4.',
      povCharacter: 'Silas Vance',
    );

    final ch3 = ChapterModel(
      id: 'ch_3',
      bookId: 'b_1',
      chapterNumber: 3,
      title: 'Secrets in the Sanctuary',
      content: '''Step by step, the damp leaves crunched beneath his boots. The sanctuary stood silent, wrapped in ivy and old secrets waiting to be written.''',
      lastEdited: DateTime.now().subtract(const Duration(days: 1)),
      isCompleted: false,
      notes: 'Key turning point in Act 1.',
      povCharacter: 'Martha Thorne',
    );

    // Initial Sample Books
    final book1 = BookModel(
      id: 'b_1',
      title: 'The Whispering Pines',
      subtitle: 'A Gothic Mystery Novel',
      genre: 'Mystery / Thriller',
      coverEmoji: '🌲',
      coverColorHex: 0xFF38C793,
      targetWordCount: 65000,
      chapters: [ch1, ch2, ch3],
      lastEdited: DateTime.now(),
      status: BookStatus.drafting,
      tags: ['Gothic', 'Atmospheric', 'Mystery'],
      synopsis: 'A former cartographer returns to his ancestral home only to discover that the maps he drew in his youth are redrawing themselves.',
    );

    final book2 = BookModel(
      id: 'b_2',
      title: 'Chronicles of Solitude',
      subtitle: 'Essays on Literary Focus',
      genre: 'Non-Fiction / Philosophy',
      coverEmoji: '📜',
      coverColorHex: 0xFF4A90E2,
      targetWordCount: 40000,
      chapters: [
        ChapterModel(
          id: 'ch_b2_1',
          bookId: 'b_2',
          chapterNumber: 1,
          title: 'The Art of Deep Attention',
          content: 'In an age of relentless notification, quiet focus is the ultimate revolutionary act for the writer.',
          lastEdited: DateTime.now().subtract(const Duration(days: 3)),
          isCompleted: true,
        ),
      ],
      lastEdited: DateTime.now().subtract(const Duration(days: 2)),
      status: BookStatus.outlining,
      tags: ['Essays', 'Mindfulness', 'Craft'],
      synopsis: 'Explorations into modern solitude, deep work rituals, and the sacred space of the written word.',
    );

    _allBooks = [book1, book2];
    _activeBook = book1;
    _activeChapter = ch1;
    textEditingController.text = _activeChapter.content;

    // Initial Ideas
    _ideas = [
      IdeaSnippetModel(
        id: 'idea_1',
        title: 'Silas\'s Secret Relic',
        content: 'The silver compass doesn\'t track magnetic north; it points toward emotional resonance or buried memories.',
        category: IdeaCategory.plotTwist,
        colorHex: 0xFF38C793,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isPinned: true,
        tags: ['Relic', 'Magic System', 'Plot'],
      ),
      IdeaSnippetModel(
        id: 'idea_2',
        title: 'Dialogue Fragment',
        content: '"We don\'t write to remember the past, Martha. We write so the past stops haunting us."',
        category: IdeaCategory.dialogue,
        colorHex: 0xFFF5A623,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        isPinned: true,
        tags: ['Dialogue', 'Silas', 'Theme'],
      ),
      IdeaSnippetModel(
        id: 'idea_3',
        title: 'St. Jude\'s Architecture',
        content: 'High Gothic arches, stained glass depicting forgotten constellations, smells of damp peat and candle wax.',
        category: IdeaCategory.worldbuilding,
        colorHex: 0xFF9013FE,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        isPinned: false,
        tags: ['Setting', 'Description'],
      ),
    ];

    // Initial Worldbuilding Codex
    _codexEntries = [
      CodexEntryModel(
        id: 'codex_1',
        bookId: 'b_1',
        name: 'Silas Vance',
        type: CodexType.character,
        role: 'Protagonist / Former Cartographer',
        description: 'A quiet, observant cartographer haunted by the maps of his youth. Wears a damp wool cloak and carries a silver notebook.',
        traits: ['Methodical', 'Secretive', 'Perceptive', 'Guilt-ridden'],
        secrets: 'He deliberately altered the boundary lines of St. Jude\'s Abbey thirty years ago to protect Martha.',
        avatarEmoji: '🧭',
        isPinned: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      CodexEntryModel(
        id: 'codex_2',
        bookId: 'b_1',
        name: 'Martha Thorne',
        type: CodexType.character,
        role: 'Keeper of St. Jude\'s Hearth',
        description: 'Cousin to Silas and guardian of the family archives. Holds intimate knowledge of the abbey\'s true origins.',
        traits: ['Resilient', 'Sharp-tongued', 'Protective'],
        secrets: 'She possesses the second half of the silver compass key.',
        avatarEmoji: '🕯️',
        isPinned: true,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      CodexEntryModel(
        id: 'codex_3',
        bookId: 'b_1',
        name: 'Blackwood Valley',
        type: CodexType.location,
        role: 'Primary Setting',
        description: 'A dense, mist-enshrouded river valley flanked by towering ancient pines and crumbling stone shrines.',
        traits: ['Gothic', 'Isolated', 'Perpetual Fog', 'Whispering Winds'],
        secrets: 'The mist thickens whenever secret truths are spoken aloud near the water.',
        avatarEmoji: '🌲',
        isPinned: false,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      CodexEntryModel(
        id: 'codex_4',
        bookId: 'b_1',
        name: 'The Silver Compass',
        type: CodexType.artifact,
        role: 'Central Mystery Relic',
        description: 'An ancient brass and silver compass etched with celestial runes instead of directional markers.',
        traits: ['Ancient', 'Runed', 'Resonant'],
        secrets: 'Points toward lost architectural ruins buried deep beneath Blackwood Valley.',
        avatarEmoji: '🧭',
        isPinned: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    // Initial Soundscapes
    _soundscapes = [
      const SoundscapeModel(
        id: 'snd_1',
        title: 'Rain on Slate Roof',
        category: 'Nature',
        iconEmoji: '🌧️',
        description: 'Soothing rhythmic raindrops pattering gently on an old library skylight.',
        colorHex: 0xFF4A90E2,
      ),
      const SoundscapeModel(
        id: 'snd_2',
        title: 'Roaring Hearth Fire',
        category: 'Cozy',
        iconEmoji: '🪵',
        description: 'Warm crackling embers and soft timber pops in a subterranean sanctuary.',
        colorHex: 0xFFF5A623,
      ),
      const SoundscapeModel(
        id: 'snd_3',
        title: 'Midnight Library',
        category: 'Focus',
        iconEmoji: '☕',
        description: 'Subtle paper rustles, distant grandfather clock ticks, and ambient calm.',
        colorHex: 0xFF38C793,
      ),
      const SoundscapeModel(
        id: 'snd_4',
        title: 'Whispering Forest',
        category: 'Nature',
        iconEmoji: '🌲',
        description: 'Gentle mountain breeze soughing through high canopy pines.',
        colorHex: 0xFF7ED321,
      ),
      const SoundscapeModel(
        id: 'snd_5',
        title: 'Deep Binaural Void',
        category: 'Deep Work',
        iconEmoji: '🌌',
        description: '432Hz deep focus alpha waves designed to unlock effortless creative flow.',
        colorHex: 0xFF9013FE,
      ),
    ];

    _activeSoundscape = _soundscapes.first;

    // Initial Stats
    _writerStats = WriterStatsModel(
      dailyGoalWords: 2000,
      wordsToday: 1420,
      streakDays: 12,
      totalWordsWritten: 48950,
      writingTimeTodayMinutes: 45,
      weeklyProgress: {
        'Mon': 1850,
        'Tue': 2100,
        'Wed': 1420,
        'Thu': 1900,
        'Fri': 2250,
        'Sat': 1600,
        'Sun': 1420,
      },
      wordsPerMinuteAvg: 42,
      focusScore: 94,
    );

    // Listen to text changes for real-time word counting & sprint updates
    textEditingController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final currentContent = textEditingController.text;
    if (currentContent != _activeChapter.content) {
      final oldWordCount = _activeChapter.wordCount;
      _activeChapter = _activeChapter.copyWith(
        content: currentContent,
        lastEdited: DateTime.now(),
      );

      final newWordCount = _activeChapter.wordCount;
      final wordDiff = newWordCount - oldWordCount;

      if (wordDiff != 0) {
        final newWordsToday = (_writerStats.wordsToday + wordDiff).clamp(0, 99999);
        _writerStats = _writerStats.copyWith(
          wordsToday: newWordsToday,
          totalWordsWritten: (_writerStats.totalWordsWritten + wordDiff).clamp(0, 999999),
        );

        if (_activeSprint != null && _activeSprint!.isActive) {
          final sprintWordsWritten = (_activeSprint!.wordsWritten + wordDiff).clamp(0, 99999);
          final isCompleted = sprintWordsWritten >= _activeSprint!.targetWords;
          _activeSprint = _activeSprint!.copyWith(
            wordsWritten: sprintWordsWritten,
            isCompleted: isCompleted,
          );
        }
      }

      // Update in active book chapter list
      final updatedChapters = _activeBook.chapters.map((c) {
        return c.id == _activeChapter.id ? _activeChapter : c;
      }).toList();

      _activeBook = _activeBook.copyWith(
        chapters: updatedChapters,
        lastEdited: DateTime.now(),
      );

      _updateBookInList(_activeBook);
      notifyListeners();
    }
  }

  void _updateBookInList(BookModel book) {
    final index = _allBooks.indexWhere((b) => b.id == book.id);
    if (index != -1) {
      _allBooks[index] = book;
    }
  }

  // Action Methods
  void toggleThemeMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleZenMode() {
    _isZenMode = !_isZenMode;
    notifyListeners();
  }

  void setFontFamily(String fontName) {
    _selectedFontFamily = fontName;
    notifyListeners();
  }

  void toggleSoundscape(SoundscapeModel soundscape) {
    if (_activeSoundscape?.id == soundscape.id) {
      _isPlayingAmbience = !_isPlayingAmbience;
    } else {
      _activeSoundscape = soundscape;
      _isPlayingAmbience = true;
    }
    notifyListeners();
  }

  void stopAmbience() {
    _isPlayingAmbience = false;
    notifyListeners();
  }

  void startSprint({required int durationMinutes, required int targetWords}) {
    _activeSprint = WritingSprintModel(
      durationMinutes: durationMinutes,
      targetWords: targetWords,
      startingWordCount: WriterTextFormatter.countWords(textEditingController.text),
      startTime: DateTime.now(),
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

  void selectBook(BookModel book) {
    _activeBook = book;
    if (book.chapters.isNotEmpty) {
      _activeChapter = book.chapters.first;
      textEditingController.text = _activeChapter.content;
    }
    notifyListeners();
  }

  void selectChapter(ChapterModel chapter) {
    _activeChapter = chapter;
    textEditingController.text = chapter.content;
    notifyListeners();
  }

  void toggleChapterCompletion(String chapterId) {
    final updatedChapters = _activeBook.chapters.map((c) {
      if (c.id == chapterId) {
        return c.copyWith(isCompleted: !c.isCompleted);
      }
      return c;
    }).toList();

    _activeBook = _activeBook.copyWith(chapters: updatedChapters);
    _updateBookInList(_activeBook);

    if (_activeChapter.id == chapterId) {
      _activeChapter = _activeChapter.copyWith(isCompleted: !_activeChapter.isCompleted);
    }
    notifyListeners();
  }

  void addNewChapter(String title) {
    final newChapterNumber = _activeBook.chapters.length + 1;
    final newChapter = ChapterModel(
      id: 'ch_${DateTime.now().millisecondsSinceEpoch}',
      bookId: _activeBook.id,
      chapterNumber: newChapterNumber,
      title: title.isEmpty ? 'Chapter $newChapterNumber' : title,
      content: '',
      lastEdited: DateTime.now(),
    );

    final updatedChapters = [..._activeBook.chapters, newChapter];
    _activeBook = _activeBook.copyWith(chapters: updatedChapters, lastEdited: DateTime.now());
    _updateBookInList(_activeBook);
    selectChapter(newChapter);
  }

  void addIdea(IdeaSnippetModel idea) {
    _ideas = [idea, ..._ideas];
    notifyListeners();
  }

  void toggleIdeaPin(String ideaId) {
    _ideas = _ideas.map((idea) {
      if (idea.id == ideaId) {
        return idea.copyWith(isPinned: !idea.isPinned);
      }
      return idea;
    }).toList();
    notifyListeners();
  }

  void deleteIdea(String ideaId) {
    _ideas.removeWhere((i) => i.id == ideaId);
    notifyListeners();
  }

  void addCodexEntry(CodexEntryModel entry) {
    _codexEntries = [entry, ..._codexEntries];
    notifyListeners();
  }

  void toggleCodexPin(String entryId) {
    _codexEntries = _codexEntries.map((e) {
      if (e.id == entryId) {
        return e.copyWith(isPinned: !e.isPinned);
      }
      return e;
    }).toList();
    notifyListeners();
  }

  void deleteCodexEntry(String entryId) {
    _codexEntries.removeWhere((e) => e.id == entryId);
    notifyListeners();
  }

  void insertTextToEditor(String text) {
    WriterTextFormatter.insertAtCursor(textEditingController, text);
    notifyListeners();
  }

  void insertIdeaToEditor(IdeaSnippetModel idea) {
    WriterTextFormatter.insertAtCursor(
      textEditingController,
      '\n\n/* Note: ${idea.title} */\n${idea.content}\n\n',
    );
    notifyListeners();
  }

  void createNewBook({
    required String title,
    required String subtitle,
    required String genre,
    required int targetWordCount,
  }) {
    final newBook = BookModel(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      genre: genre,
      coverEmoji: '📖',
      coverColorHex: 0xFF38C793,
      targetWordCount: targetWordCount,
      chapters: [
        ChapterModel(
          id: 'ch_${DateTime.now().millisecondsSinceEpoch}',
          bookId: 'b_${DateTime.now().millisecondsSinceEpoch}',
          chapterNumber: 1,
          title: 'Chapter 1: The Beginning',
          content: '',
          lastEdited: DateTime.now(),
        ),
      ],
      lastEdited: DateTime.now(),
      status: BookStatus.drafting,
      tags: [genre, 'Draft'],
      synopsis: 'A new literary work in progress.',
    );

    _allBooks = [newBook, ..._allBooks];
    selectBook(newBook);
  }

  @override
  void dispose() {
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
