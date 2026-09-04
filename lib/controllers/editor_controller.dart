import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/chapter_model.dart';
import '../models/idea_snippet_model.dart';
import '../models/writer_stats_model.dart';
import '../models/codex_entry_model.dart';
import '../models/soundscape_model.dart';
import '../models/writing_sprint_model.dart';
import '../models/mind_map_node_model.dart';
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
  List<MindMapNodeModel> _mindMapNodes = [];

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
  List<MindMapNodeModel> get mindMapNodes => List.unmodifiable(_mindMapNodes);

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
      content: '''The lantern flickered violently as Silas pushed open the heavy oak door. Beyond the threshold lay the valley of Blackwood, shrouded in an ethereal mist that seemed to breathe with a rhythm of its own.

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
      chapterNumber: 3,
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
      title: 'The Cipher of St. Jude',
      subtitle: 'A Gothic mystery of lost maps & silver compasses',
      genre: 'Gothic Mystery',
      targetWordCount: 65000,
      status: BookStatus.drafting,
      chapters: [ch1, ch2, ch3],
      lastEdited: DateTime.now().subtract(const Duration(minutes: 45)),
      coverEmoji: '🧭',
      coverColorHex: 0xFF38C793,
      tags: ['Gothic', 'Mystery', 'Cartography'],
      synopsis: 'Silas Vance uncovers an ancient silver compass that reveals secrets of St. Jude Abbey.',
    );

    final book2 = BookModel(
      id: 'b_2',
      title: 'Chronicles of Aethelgard',
      subtitle: 'Epic high fantasy world-building',
      genre: 'High Fantasy',
      targetWordCount: 90000,
      status: BookStatus.outlining,
      chapters: [],
      lastEdited: DateTime.now().subtract(const Duration(days: 3)),
      coverEmoji: '⚔️',
      coverColorHex: 0xFF4A90E2,
      tags: ['High Fantasy', 'Dragons', 'Epic'],
      synopsis: 'A kingdom divided by five elemental crests must unite before the eclipse.',
    );

    _allBooks = [book1, book2];
    _activeBook = book1;
    _activeChapter = ch1;

    // Load active chapter content into text controller
    textEditingController.text = _activeChapter.content;
    textEditingController.addListener(_onTextChanged);

    // Initial Sample Ideas
    _ideas = [
      IdeaSnippetModel(
        id: 'i_1',
        title: 'The Tallow Candle Clue',
        content: 'The tallow candle burns with a blue flame whenever someone lies near the abbey altar.',
        category: IdeaCategory.plotTwist,
        colorHex: 0xFFF5A623,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        tags: ['Abbey', 'Clue', 'Act 2'],
        isPinned: true,
      ),
      IdeaSnippetModel(
        id: 'i_2',
        title: 'Martha’s Hidden Guild Ring',
        content: 'Martha carries a heavy brass ring inside her velvet pouch with the seal of the Cartographer Guild.',
        category: IdeaCategory.character,
        colorHex: 0xFF38C793,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        tags: ['Martha', 'Guild', 'Backstory'],
        isPinned: false,
      ),
      IdeaSnippetModel(
        id: 'i_3',
        title: 'Fog Atmosphere Description',
        content: 'The fog tasted of salt and peat, sticking to wool coats like damp spiderwebs.',
        category: IdeaCategory.general,
        colorHex: 0xFF9013FE,
        createdAt: DateTime.now(),
        tags: ['Atmosphere', 'Sensory'],
        isPinned: true,
      ),
    ];

    // Initial Sample Codex Entries (Worldbuilding)
    _codexEntries = [
      CodexEntryModel(
        id: 'codex_1',
        bookId: 'b_1',
        name: 'Silas Vance',
        type: CodexType.character,
        role: 'Protagonist / Cartographer',
        description: 'Former cartographer of the Guild. Obsessed with completing the map of St. Jude Abbey.',
        traits: ['Methodical', 'Secretive', 'Perceptive'],
        secrets: 'Hides a missing shadow stolen in the mountain pass.',
        avatarEmoji: '🧙‍♂️',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        isPinned: true,
      ),
      CodexEntryModel(
        id: 'codex_2',
        bookId: 'b_1',
        name: 'St. Jude Abbey Ruins',
        type: CodexType.location,
        role: 'Central Mystery Location',
        description: 'A 14th-century monastery built atop subterranean basalt vaults.',
        traits: ['Ancient', 'Gothic', 'Fog-shrouded'],
        secrets: 'Houses the silver compass vault behind the bell tower.',
        avatarEmoji: '🏰',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        isPinned: true,
      ),
      CodexEntryModel(
        id: 'codex_3',
        bookId: 'b_1',
        name: 'The Silver Compass',
        type: CodexType.artifact,
        role: 'Relic / Plot Catalyst',
        description: 'An ancient brass and silver instrument that tracks echoes of historic lies.',
        traits: ['Etched Runes', 'Magnetic Anomaly'],
        secrets: 'Only responds when held by a member of the Guild.',
        avatarEmoji: '🧭',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isPinned: false,
      ),
    ];

    // Initial Soundscapes
    _soundscapes = [
      const SoundscapeModel(
        id: 'snd_1',
        title: 'Rain on Monastery Glass',
        category: 'Nature',
        iconEmoji: '🌧️',
        description: 'Gentle raindrops falling on cathedral stained glass',
        colorHex: 0xFF38C793,
      ),
      const SoundscapeModel(
        id: 'snd_2',
        title: 'Midnight Library Fire',
        category: 'Ambient',
        iconEmoji: '🔥',
        description: 'Crackling fireplace & paper rustling',
        colorHex: 0xFFF5A623,
      ),
      const SoundscapeModel(
        id: 'snd_3',
        title: 'Soft Foggy Café',
        category: 'Urban',
        iconEmoji: '☕',
        description: 'Low chatter and distant rain',
        colorHex: 0xFF4A90E2,
      ),
      const SoundscapeModel(
        id: 'snd_4',
        title: 'Blackwood Forest Breeze',
        category: 'Nature',
        iconEmoji: '🌲',
        description: 'Rustling pine needles and gentle wind',
        colorHex: 0xFF9013FE,
      ),
    ];
    _activeSoundscape = _soundscapes[0];

    // Initial Story Mind Map Plot Nodes
    _mindMapNodes = [
      MindMapNodeModel(
        id: 'node_1',
        bookId: 'b_1',
        title: 'Inciting Incident: The Silver Compass Found',
        description: 'Silas unearths the silver compass inside his late father cartography desk.',
        act: PlotAct.act1Exposition,
        type: PlotNodeType.turningPoint,
        dx: 60,
        dy: 120,
        connectedToIds: ['node_2'],
        colorHex: 0xFF38C793,
        iconEmoji: '🧭',
      ),
      MindMapNodeModel(
        id: 'node_2',
        bookId: 'b_1',
        title: 'Act I Climax: Arrival at Blackwood Valley',
        description: 'Silas reaches Blackwood Valley amidst thick fog and receives Martha warning.',
        act: PlotAct.act1Exposition,
        type: PlotNodeType.mainPlot,
        dx: 340,
        dy: 120,
        connectedToIds: ['node_3', 'node_4'],
        colorHex: 0xFF4A90E2,
        iconEmoji: '🌫️',
      ),
      MindMapNodeModel(
        id: 'node_3',
        bookId: 'b_1',
        title: 'Subplot: Martha’s Guild Secrets',
        description: 'Martha reveals her connection to the Guild of Cartographers.',
        act: PlotAct.act2RisingAction,
        type: PlotNodeType.subplot,
        dx: 620,
        dy: 40,
        connectedToIds: ['node_5'],
        colorHex: 0xFFF5A623,
        iconEmoji: '📜',
      ),
      MindMapNodeModel(
        id: 'node_4',
        bookId: 'b_1',
        title: 'Midpoint: The Mirror Vault Revealed',
        description: 'The silver compass unlocks the hidden vault beneath St. Jude Abbey bell tower.',
        act: PlotAct.midpoint,
        type: PlotNodeType.turningPoint,
        dx: 620,
        dy: 240,
        connectedToIds: ['node_5'],
        colorHex: 0xFF9013FE,
        iconEmoji: '🏛️',
      ),
      MindMapNodeModel(
        id: 'node_5',
        bookId: 'b_1',
        title: 'Act III Climax: Confrontation in the Storm',
        description: 'Silas confronts the Guild master as the bell tolls for the final revelation.',
        act: PlotAct.act3Climax,
        type: PlotNodeType.mainPlot,
        dx: 900,
        dy: 140,
        connectedToIds: [],
        colorHex: 0xFFE74C3C,
        iconEmoji: '⚡',
      ),
    ];

    // Initial Writer Stats
    _writerStats = WriterStatsModel(
      wordsToday: 1420,
      dailyGoalWords: 2000,
      streakDays: 7,
      totalWordsWritten: 42650,
      writingTimeTodayMinutes: 48,
      wordsPerMinuteAvg: 32,
      focusScore: 92,
      weeklyProgress: {
        'Mon': 1850,
        'Tue': 2100,
        'Wed': 1420,
        'Thu': 1950,
        'Fri': 2300,
        'Sat': 1600,
        'Sun': 1420,
      },
    );
  }

  // Text changes handler
  void _onTextChanged() {
    final currentText = textEditingController.text;

    // Update chapter word count & active book stats
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

    notifyListeners();
  }

  // --- ACTIONS ---

  void setFontFamily(String font) {
    _selectedFontFamily = font;
    notifyListeners();
  }

  void toggleThemeMode() {
    _isDarkMode = !_isDarkMode;
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
      textEditingController.text = _activeChapter.content;
    } else {
      addNewChapter('Capítulo 1');
    }
    notifyListeners();
  }

  void selectChapter(ChapterModel chapter) {
    _activeChapter = chapter;
    textEditingController.text = chapter.content;
    notifyListeners();
  }

  void addNewChapter(String title) {
    final newChapterNum = _activeBook.chapters.length + 1;
    final newChapter = ChapterModel(
      id: 'ch_${DateTime.now().millisecondsSinceEpoch}',
      bookId: _activeBook.id,
      chapterNumber: newChapterNum,
      title: title.isEmpty ? 'Capítulo $newChapterNum' : title,
      content: '',
      lastEdited: DateTime.now(),
      notes: '',
      povCharacter: '',
    );

    final updatedChapters = List<ChapterModel>.from(_activeBook.chapters)..add(newChapter);
    _activeBook = _activeBook.copyWith(chapters: updatedChapters);
    _activeChapter = newChapter;
    textEditingController.text = '';

    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();
    notifyListeners();
  }

  void createNewBook(String title, String subtitle, int targetWordCount, {String genre = 'Ficción'}) {
    final newBook = BookModel(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      genre: genre,
      targetWordCount: targetWordCount,
      status: BookStatus.outlining,
      chapters: [],
      lastEdited: DateTime.now(),
      coverEmoji: '📖',
      coverColorHex: 0xFF18181B,
      tags: [genre],
      synopsis: subtitle,
    );

    _allBooks.insert(0, newBook);
    selectBook(newBook);
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
    notifyListeners();
  }

  // --- IDEAS ACTIONS ---

  void addIdea(IdeaSnippetModel idea) {
    _ideas.insert(0, idea);
    notifyListeners();
  }

  void toggleIdeaPin(String ideaId) {
    _ideas = _ideas.map((item) {
      if (item.id == ideaId) {
        return item.copyWith(isPinned: !item.isPinned);
      }
      return item;
    }).toList();
    notifyListeners();
  }

  void insertIdeaToEditor(IdeaSnippetModel idea) {
    insertTextToEditor('\n\n/* Idea Snippet: ${idea.title} */\n${idea.content}\n\n');
  }

  void insertTextToEditor(String snippetText) {
    final text = textEditingController.text;
    final selection = textEditingController.selection;

    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, snippetText);
      textEditingController.text = newText;
      textEditingController.selection = TextSelection.collapsed(
        offset: selection.start + snippetText.length,
      );
    } else {
      textEditingController.text = text + snippetText;
      textEditingController.selection = TextSelection.collapsed(
        offset: textEditingController.text.length,
      );
    }
  }

  // --- CODEX ACTIONS ---

  void addCodexEntry(CodexEntryModel entry) {
    _codexEntries.insert(0, entry);
    notifyListeners();
  }

  void toggleCodexPin(String entryId) {
    _codexEntries = _codexEntries.map((item) {
      if (item.id == entryId) {
        return item.copyWith(isPinned: !item.isPinned);
      }
      return item;
    }).toList();
    notifyListeners();
  }

  // --- SOUNDSCAPE ACTIONS ---

  void toggleSoundscape(SoundscapeModel soundscape) {
    if (_activeSoundscape?.id == soundscape.id && _isPlayingAmbience) {
      _isPlayingAmbience = false;
    } else {
      _activeSoundscape = soundscape;
      _isPlayingAmbience = true;
    }
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

  // --- MIND MAP PLOT ACTIONS ---

  void addMindMapNode(MindMapNodeModel node) {
    _mindMapNodes.add(node);
    notifyListeners();
  }

  void updateMindMapNode(MindMapNodeModel updated) {
    _mindMapNodes = _mindMapNodes.map((n) {
      if (n.id == updated.id) {
        return updated;
      }
      return n;
    }).toList();
    notifyListeners();
  }

  void updateMindMapNodePosition(String nodeId, Offset newPos) {
    _mindMapNodes = _mindMapNodes.map((n) {
      if (n.id == nodeId) {
        n.dx = newPos.dx;
        n.dy = newPos.dy;
      }
      return n;
    }).toList();
    notifyListeners();
  }

  void connectMindMapNodes(String fromId, String toId) {
    if (fromId == toId) return;
    _mindMapNodes = _mindMapNodes.map((n) {
      if (n.id == fromId && !n.connectedToIds.contains(toId)) {
        n.connectedToIds.add(toId);
      }
      return n;
    }).toList();
    notifyListeners();
  }

  void disconnectMindMapNodes(String fromId, String toId) {
    _mindMapNodes = _mindMapNodes.map((n) {
      if (n.id == fromId) {
        n.connectedToIds.remove(toId);
      }
      return n;
    }).toList();
    notifyListeners();
  }

  void duplicateMindMapNode(String nodeId) {
    final index = _mindMapNodes.indexWhere((n) => n.id == nodeId);
    if (index != -1) {
      final original = _mindMapNodes[index];
      final clone = original.copyWith(
        id: 'node_${DateTime.now().millisecondsSinceEpoch}',
        title: '${original.title} (Copia)',
        dx: original.dx + 40,
        dy: original.dy + 40,
        connectedToIds: [],
      );
      _mindMapNodes.add(clone);
      notifyListeners();
    }
  }

  void autoArrangeMindMapNodes() {
    // Map acts to column X coordinates
    final Map<PlotAct, double> actX = {
      PlotAct.act1Exposition: 80.0,
      PlotAct.act2RisingAction: 480.0,
      PlotAct.midpoint: 880.0,
      PlotAct.act3Climax: 1280.0,
      PlotAct.resolution: 1680.0,
    };

    final Map<PlotAct, int> actCounters = {
      PlotAct.act1Exposition: 0,
      PlotAct.act2RisingAction: 0,
      PlotAct.midpoint: 0,
      PlotAct.act3Climax: 0,
      PlotAct.resolution: 0,
    };

    for (var node in _mindMapNodes) {
      final count = actCounters[node.act] ?? 0;
      node.dx = actX[node.act] ?? 100.0;
      node.dy = 120.0 + (count * 170.0);
      actCounters[node.act] = count + 1;
    }
    notifyListeners();
  }

  void deleteMindMapNode(String nodeId) {
    _mindMapNodes.removeWhere((n) => n.id == nodeId);
    for (var n in _mindMapNodes) {
      n.connectedToIds.remove(nodeId);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
