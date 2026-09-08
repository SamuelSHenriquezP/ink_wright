import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_model.dart';
import '../models/chapter_model.dart';
import '../models/idea_snippet_model.dart';
import '../models/writer_stats_model.dart';
import '../models/codex_entry_model.dart';
import '../models/soundscape_model.dart';
import '../models/writing_sprint_model.dart';
import '../models/mind_map_node_model.dart';
import '../models/character_model.dart';
import '../formatters/writer_text_formatter.dart';
import 'markdown_editing_controller.dart';
import '../services/persistence_service.dart';

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
  List<SoundscapeModel> _soundscapes = [];
  List<MindMapNodeModel> _mindMapNodes = [];
  List<CharacterModel> _characters = [];

  SoundscapeModel? _activeSoundscape;
  bool _isPlayingAmbience = false;

  WritingSprintModel? _activeSprint;
  String _selectedFontFamily = 'Lora';
  double _fontSize = 16.5;
  double _lineHeight = 1.65;
  double _maxEditorWidth = 720.0;
  bool _isTypewriterMode = false;

  final MarkdownEditingController textEditingController = MarkdownEditingController();
  final FocusNode focusNode = FocusNode();

  // Undo / Redo history
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  bool _isPerformingUndoRedo = false;
  String _lastRecordedText = '';

  // Debounce for text change auto-save
  Timer? _textChangeDebounceTimer;
  DateTime? _lastSavedTime;
  bool _isSaving = false;

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get isZenMode => _isZenMode;
  bool get isAutoSaveEnabled => _isAutoSaveEnabled;
  bool get isLiveMarkdownEnabled => textEditingController.isLiveMarkdownEnabled;
  bool get isSaving => _isSaving;
  DateTime? get lastSavedTime => _lastSavedTime;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  BookModel get activeBook => _activeBook;
  ChapterModel get activeChapter => _activeChapter;
  WriterStatsModel get writerStats => _writerStats;
  List<BookModel> get allBooks => List.unmodifiable(_allBooks);
  List<IdeaSnippetModel> get ideas => List.unmodifiable(_ideas);
  List<CodexEntryModel> get codexEntries => List.unmodifiable(_codexEntries);
  List<SoundscapeModel> get soundscapes => List.unmodifiable(_soundscapes);

  // Each mind map is strictly individual per book
  List<MindMapNodeModel> get mindMapNodes =>
      _mindMapNodes.where((n) => n.bookId == _activeBook.id).toList();

  // Characters are strictly individual per book
  List<CharacterModel> get characters =>
      _characters.where((c) => c.bookId == _activeBook.id).toList();
  List<CharacterModel> get allCharacters => List.unmodifiable(_characters);

  SoundscapeModel? get activeSoundscape => _activeSoundscape;
  bool get isPlayingAmbience => _isPlayingAmbience;
  WritingSprintModel? get activeSprint => _activeSprint;
  String get selectedFontFamily => _selectedFontFamily;
  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  double get maxEditorWidth => _maxEditorWidth;
  bool get isTypewriterMode => _isTypewriterMode;

  EditorController() {
    _initializeInitialState();
    _loadPersistedData();
  }

  void _initializeInitialState() {
    // 1. Starter Tutorial Manuscript (Unico libro inicial de bienvenida)
    final ch1 = ChapterModel(
      id: 'ch_tut_1',
      bookId: 'b_tutorial',
      chapterNumber: 1,
      title: 'Capítulo 1: Bienvenido a tu Estudio & Markdown en Vivo',
      content: '''# Bienvenido a Ink & Wright

Este es tu nuevo santuario de escritura: un espacio minimalista en blanco y negro pensado para que las distracciones desaparezcan y tus palabras cobren vida.

## Escribir con Markdown en Vivo

Mientras escribes en este lienzo, el formato se renderiza en tiempo real:

- Las palabras entre asteriscos dobles se convierten en **negrita editorial**.
- Las palabras entre asteriscos simples adquieren un *tono íntimo en cursiva*.
- Puedes tachar ideas descartadas usando ~~texto tachado~~.
- Escribe fragmentos técnicos o notas de estilo entre comillas invertidas: `escena_climax_01`.

> "Escribir no es añadir adornos, sino retirar la niebla hasta que la historia respire por sí sola."

### Diálogos y Narrativa

Para los diálogos en español, utiliza la raya literaria:

— La tinta guarda secretos que la memoria prefiere olvidar —susurró el archivista mientras cerraba el tomo de cuero.

— Entonces no abras el candado de la biblioteca —respondió ella con calma.

### Tu Lista de Tareas Creativas

- [x] Conocer el editor y probar el Markdown dinámico.
- [ ] Explorar la sección de Personajes en el menú principal.
- [ ] Abrir el Mapa Mental para trazar el arco de tu historia.
- [ ] Probar el modo Pantalla Completa para máxima concentración.

***

Pulsa el icono superior para abrir el panel lateral o vuelve al panel de inicio para comenzar a forjar tu propio manuscrito.''',
      lastEdited: DateTime.now(),
      isCompleted: true,
      notes: 'Capítulo introductorio que enseña las funciones básicas del editor.',
      povCharacter: 'Evelyn Vance',
    );

    final ch2 = ChapterModel(
      id: 'ch_tut_2',
      bookId: 'b_tutorial',
      chapterNumber: 2,
      title: 'Capítulo 2: El Arte de Crear Personajes',
      content: '''# Diseñar Personajes con Alma

En la sección de **Personajes**, cada criatura de tu historia tiene su propia ficha narrativa con psicología, deseos y su biografía escrita.

## Los Tres Pilares de un Buen Personaje

1. **El Deseo Consciente:** Lo que el personaje cree que quiere (el objetivo externo).
2. **La Necesidad Inconsciente:** La lección o maduración que debe experimentar para sanar.
3. **El Fantasma o Herida:** Aquello que le ocurrió en el pasado y condiciona sus miedos.

> "Un personaje sin conflicto interno es solo una marioneta con buen vestuario."

### Cómo Usar las Fichas

Puedes consultar tus personajes en cualquier momento, editar su biografía escrita e incluso insertarlos directamente en tu capítulo pulsando "Insertar en Manuscrito".''',
      lastEdited: DateTime.now(),
      isCompleted: false,
      notes: 'Capítulo tutorial sobre la creación y gestión de personajes.',
      povCharacter: 'Evelyn Vance',
    );

    final ch3 = ChapterModel(
      id: 'ch_tut_3',
      bookId: 'b_tutorial',
      chapterNumber: 3,
      title: 'Capítulo 3: Estructuración y Mapa Mental de la Trama',
      content: '''# El Mapa Mental de la Trama

Cada libro en Ink & Wright tiene su propio **Mapa Mental independiente**. Lo que traces para una novela nunca se mezclará con tus otros proyectos.

## Los Actos Narrativos

- **Acto I (Planteamiento):** Presenta el mundo ordinario y el incidente incitador que rompe el equilibrio.
- **Acto II (Nudo y Complicaciones):** El punto medio donde las consecuencias se vuelven irreversibles.
- **Acto III (Clímax y Resolución):** El enfrentamiento decisivo donde el protagonista cambia para siempre.

### Modos del Lienzo

- **Mover y Explorar:** Arrastra el lienzo en cualquier dirección con libertad total.
- **Conectar Nodos:** Toca el botón de conectar en cualquier tarjeta y selecciona el nodo destino para enlazar causas y consecuencias.
- **Auto-Organizar:** Usa el botón de organización automática para ordenar tus ideas en columnas por actos narrativos.''',
      lastEdited: DateTime.now(),
      isCompleted: false,
      notes: 'Capítulo tutorial sobre el mapa mental.',
      povCharacter: 'Evelyn Vance',
    );

    final tutorialBook = BookModel(
      id: 'b_tutorial',
      title: 'Manual del Escritor — Guía de Ink & Wright',
      subtitle: 'Tu espacio de escritura, personajes y mapas de trama',
      genre: 'Guía / Tutorial',
      targetWordCount: 25000,
      status: BookStatus.drafting,
      chapters: [ch1, ch2, ch3],
      lastEdited: DateTime.now(),
      coverEmoji: '🖋️',
      coverColorHex: 0xFF18181B,
      tags: ['Tutorial', 'Guía', 'Escritura Creativa'],
      synopsis:
          'Una guía viva diseñada para mostrarte cómo escribir con Markdown en tiempo real, dar vida a personajes inolvidables y estructurar tramas visuales.',
    );

    _allBooks = [tutorialBook];
    _activeBook = tutorialBook;
    _activeChapter = ch1;

    textEditingController.text = _activeChapter.content;
    _lastRecordedText = _activeChapter.content;
    textEditingController.addListener(_onTextChanged);

    // Initial Sample Ideas (relacionadas al tutorial y narrativa)
    _ideas = [
      IdeaSnippetModel(
        id: 'i_1',
        title: 'Consejo: El Gancho Inicial',
        content: 'Empieza siempre in media res o con una imagen que revele el tono antes que la trama.',
        category: IdeaCategory.general,
        colorHex: 0xFF18181B,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        tags: ['Técnica', 'Inicio'],
        isPinned: true,
      ),
      IdeaSnippetModel(
        id: 'i_2',
        title: 'Atmósfera y Sentidos',
        content: 'Describe al menos dos sentidos que no sean la vista en cada cambio de escena importante.',
        category: IdeaCategory.character,
        colorHex: 0xFF27272A,
        createdAt: DateTime.now(),
        tags: ['Inmersión', 'Estilo'],
        isPinned: true,
      ),
    ];

    // Initial Codex Entries
    _codexEntries = [
      CodexEntryModel(
        id: 'codex_tut_1',
        bookId: 'b_tutorial',
        name: 'El Estudio de Ink & Wright',
        type: CodexType.location,
        role: 'Santuario Creativo',
        description: 'Un refugio atemporal donde el autor puede concentrarse exclusivamente en su manuscrito.',
        traits: ['Silencioso', 'Minimalista', 'Monocromático'],
        secrets: 'Diseñado para escritores que buscan la pureza de la palabra.',
        avatarEmoji: '🏛️',
        createdAt: DateTime.now(),
        isPinned: true,
      ),
    ];

    _soundscapes = [
      const SoundscapeModel(
        id: 'snd_1',
        title: 'Lluvia sobre Ventanal',
        category: 'Naturaleza',
        iconEmoji: '🌧️',
        description: 'Suaves gotas de lluvia sobre cristales antiguos',
        colorHex: 0xFF18181B,
      ),
      const SoundscapeModel(
        id: 'snd_2',
        title: 'Chimenea de Biblioteca',
        category: 'Ambiente',
        iconEmoji: '🔥',
        description: 'Leña crujiendo suavemente y pasar de páginas',
        colorHex: 0xFF27272A,
      ),
      const SoundscapeModel(
        id: 'snd_3',
        title: 'Café de Escritores',
        category: 'Urbano',
        iconEmoji: '☕',
        description: 'Murmullo lejano y lluvia tenue de fondo',
        colorHex: 0xFF3F3F46,
      ),
      const SoundscapeModel(
        id: 'snd_4',
        title: 'Brisa en el Bosque',
        category: 'Naturaleza',
        iconEmoji: '🌲',
        description: 'Viento susurrando entre las copas de los árboles',
        colorHex: 0xFF52525B,
      ),
    ];
    _activeSoundscape = _soundscapes[0];

    // Initial Mind Map Nodes (Individual para el libro tutorial 'b_tutorial')
    _mindMapNodes = [
      MindMapNodeModel(
        id: 'node_tut_1',
        bookId: 'b_tutorial',
        title: 'Acto I: Conoce tu Espacio de Escritura',
        description: 'Aprende a usar el editor con Markdown en vivo, las tipografías y el modo de pantalla completa.',
        act: PlotAct.act1Exposition,
        type: PlotNodeType.turningPoint,
        dx: 80,
        dy: 120,
        connectedToIds: ['node_tut_2'],
        colorHex: 0xFF18181B,
        iconEmoji: '🖋️',
      ),
      MindMapNodeModel(
        id: 'node_tut_2',
        bookId: 'b_tutorial',
        title: 'Acto II: Diseña tus Personajes y Fichas',
        description: 'Crea personajes con psicología, deseos y su biografía narrativa completa.',
        act: PlotAct.midpoint,
        type: PlotNodeType.characterArc,
        dx: 480,
        dy: 120,
        connectedToIds: ['node_tut_3'],
        colorHex: 0xFF27272A,
        iconEmoji: '👤',
      ),
      MindMapNodeModel(
        id: 'node_tut_3',
        bookId: 'b_tutorial',
        title: 'Acto III: Escribe y Estructura tu Trama',
        description: 'Traza causas y consecuencias en el lienzo infinito y exporta tu manuscrito.',
        act: PlotAct.act3Climax,
        type: PlotNodeType.mainPlot,
        dx: 880,
        dy: 120,
        connectedToIds: [],
        colorHex: 0xFF18181B,
        iconEmoji: '📖',
      ),
    ];

    // Initial Characters (Individual para el libro tutorial 'b_tutorial')
    _characters = [
      CharacterModel(
        id: 'char_tut_1',
        bookId: 'b_tutorial',
        name: 'Evelyn Vance',
        role: 'Protagonista',
        archetype: 'La Investigadora Renuente',
        traits: ['Observadora', 'Metódica', 'Intuitiva'],
        physicalAppearance: 'Mirada atenta de ojos grises, gabardina oscura con marcas de tinta en los puños y un reloj de bolsillo antiguo.',
        motivation: 'Descifrar los manuscritos olvidados de la antigua biblioteca de Blackwood.',
        flawOrGhost: 'Teme equivocarse y repetir el error que le costó el puesto a su mentor.',
        characterArc: 'Pasa de dudar de sus instintos a liderar la investigación con determinación inquebrantable.',
        writtenBiography: '''Evelyn nació en una familia de encuadernadores y archivistas. Creció entre olor a cuero viejo, papel secante y tinta ferrogálica. Posee una memoria prodigiosa para las palabras no dichas y los márgenes de los textos antiguos, donde los escritores solían anotar sus verdades más peligrosas.

A los veintiocho años, heredó el taller de su abuelo junto con un baúl de notas que nadie había logrado descifrar. Su vida cambió el día que encontró un pliego con el sello intacto del Gremio.''',
        quote: '«Los márgenes de los libros siempre revelan más que los textos impresos.»',
        avatarEmoji: '🕵️‍♀️',
        createdAt: DateTime.now(),
      ),
    ];

    _writerStats = WriterStatsModel(
      wordsToday: 850,
      dailyGoalWords: 2000,
      streakDays: 3,
      totalWordsWritten: 12500,
      writingTimeTodayMinutes: 35,
      wordsPerMinuteAvg: 30,
      focusScore: 95,
      weeklyProgress: {
        'Lun': 1200,
        'Mar': 1500,
        'Mié': 850,
        'Jue': 1100,
        'Vie': 1400,
        'Sáb': 900,
        'Dom': 850,
      },
    );
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

      if (savedIdeas != null) _ideas = savedIdeas;
      if (savedCodex != null) _codexEntries = savedCodex;
      if (savedNodes != null) _mindMapNodes = savedNodes;
      if (savedCharacters != null) _characters = savedCharacters;
      if (savedStats != null) _writerStats = savedStats;

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

    _allBooks = books;
    _ideas = (data['ideas'] as List<IdeaSnippetModel>?) ?? _ideas;
    _codexEntries = (data['codex'] as List<CodexEntryModel>?) ?? _codexEntries;
    _mindMapNodes = (data['mindMap'] as List<MindMapNodeModel>?) ?? _mindMapNodes;
    _characters = (data['characters'] as List<CharacterModel>?) ?? _characters;
    if (data['writerStats'] != null) {
      _writerStats = data['writerStats'] as WriterStatsModel;
    }

    final prefs = (data['preferences'] as Map<String, dynamic>?) ?? {};
    final savedBookId = prefs['activeBookId'] as String?;
    _activeBook = _allBooks.firstWhere(
      (b) => b.id == savedBookId,
      orElse: () => _allBooks.first,
    );

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

  void addNewChapter(String title) {
    final newChapterNum = _activeBook.chapters.length + 1;
    final newChapter = ChapterModel(
      id: 'ch_${DateTime.now().millisecondsSinceEpoch}',
      bookId: _activeBook.id,
      chapterNumber: newChapterNum,
      title: title.trim().isEmpty ? 'Capítulo $newChapterNum' : title.trim(),
      content: '',
      lastEdited: DateTime.now(),
      notes: '',
      povCharacter: '',
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

  void reorderChapters(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final List<ChapterModel> reordered = List.from(_activeBook.chapters);
    final ChapterModel moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    // Re-assign chapter numbers sequentially
    final updatedList = <ChapterModel>[];
    for (int i = 0; i < reordered.length; i++) {
      updatedList.add(reordered[i].copyWith(chapterNumber: i + 1));
    }

    _activeBook = _activeBook.copyWith(chapters: updatedList);
    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();
    _saveCurrentData(debounced: false);
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

    final updatedChapters = _activeBook.chapters
        .where((ch) => ch.id != chapterId)
        .toList();

    final reindexed = <ChapterModel>[];
    for (int i = 0; i < updatedChapters.length; i++) {
      reindexed.add(updatedChapters[i].copyWith(chapterNumber: i + 1));
    }

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
    final chapterIndex = _activeBook.chapters.indexWhere((ch) => ch.id == chapterId);
    if (chapterIndex == -1) return null;

    final targetChapter = _activeBook.chapters[chapterIndex];
    final fullText = targetChapter.id == _activeChapter.id
        ? textEditingController.text
        : targetChapter.content;

    final clampedPos = splitPosition.clamp(0, fullText.length);
    final part1 = fullText.substring(0, clampedPos).trimRight();
    final part2 = fullText.substring(clampedPos).trimLeft();

    final updatedOriginal = targetChapter.copyWith(
      content: part1,
      lastEdited: DateTime.now(),
    );

    final newChapterNum = chapterIndex + 2;
    final fallbackTitle = '${targetChapter.title} (Parte 2)';
    final newChapter = ChapterModel(
      id: 'ch_${DateTime.now().millisecondsSinceEpoch}',
      bookId: _activeBook.id,
      chapterNumber: newChapterNum,
      title: (newChapterTitle != null && newChapterTitle.trim().isNotEmpty)
          ? newChapterTitle.trim()
          : fallbackTitle,
      content: part2,
      lastEdited: DateTime.now(),
      notes: '',
      povCharacter: targetChapter.povCharacter,
    );

    final updatedChapters = List<ChapterModel>.from(_activeBook.chapters);
    updatedChapters[chapterIndex] = updatedOriginal;
    updatedChapters.insert(chapterIndex + 1, newChapter);

    final reindexed = <ChapterModel>[];
    for (int i = 0; i < updatedChapters.length; i++) {
      reindexed.add(updatedChapters[i].copyWith(chapterNumber: i + 1));
    }

    _activeBook = _activeBook.copyWith(chapters: reindexed);
    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();

    if (_activeChapter.id == chapterId) {
      _activeChapter = reindexed[chapterIndex];
      textEditingController.removeListener(_onTextChanged);
      textEditingController.text = part1;
      _lastRecordedText = part1;
      _undoStack.clear();
      _redoStack.clear();
      textEditingController.addListener(_onTextChanged);
    }

    _saveCurrentData(debounced: false);
    notifyListeners();
    return reindexed[chapterIndex + 1];
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

    final separator = (currentContent.isEmpty || nextContent.isEmpty) ? '' : '\n\n';
    final mergedContent = '$currentContent$separator$nextContent';

    final mergedChapter = current.copyWith(
      content: mergedContent,
      lastEdited: DateTime.now(),
    );

    final updatedChapters = List<ChapterModel>.from(_activeBook.chapters);
    updatedChapters[chapterIndex] = mergedChapter;
    updatedChapters.removeAt(chapterIndex + 1);

    final reindexed = <ChapterModel>[];
    for (int i = 0; i < updatedChapters.length; i++) {
      reindexed.add(updatedChapters[i].copyWith(chapterNumber: i + 1));
    }

    _activeBook = _activeBook.copyWith(chapters: reindexed);
    _allBooks = _allBooks.map((b) => b.id == _activeBook.id ? _activeBook : b).toList();

    _mindMapNodes = _mindMapNodes.map((node) {
      if (node.linkedChapterId == next.id) {
        return node.copyWith(linkedChapterId: current.id);
      }
      return node;
    }).toList();

    if (_activeChapter.id == current.id || _activeChapter.id == next.id) {
      _activeChapter = reindexed[chapterIndex];
      textEditingController.removeListener(_onTextChanged);
      textEditingController.text = mergedContent;
      _lastRecordedText = mergedContent;
      _undoStack.clear();
      _redoStack.clear();
      textEditingController.addListener(_onTextChanged);
    }

    _saveCurrentData(debounced: false);
    notifyListeners();
    return true;
  }

  bool deleteBook(String bookId) {
    if (_allBooks.length <= 1) {
      return false;
    }

    _allBooks = _allBooks.where((b) => b.id != bookId).toList();
    _mindMapNodes.removeWhere((n) => n.bookId == bookId);
    _characters.removeWhere((c) => c.bookId == bookId);

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
    _ideas.insert(0, idea);
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
    _codexEntries.insert(0, entry);
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
    if (fromId == toId) return;
    _mindMapNodes = _mindMapNodes.map((n) {
      if (n.id == fromId && !n.connectedToIds.contains(toId)) {
        final updated = List<String>.from(n.connectedToIds)..add(toId);
        return n.copyWith(connectedToIds: updated);
      }
      return n;
    }).toList();
    _saveCurrentData(debounced: false);
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
        bookId: original.bookId,
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

    // Auto-arrange only the nodes belonging to the active book
    _mindMapNodes = _mindMapNodes.map((node) {
      if (node.bookId == _activeBook.id) {
        final count = actCounters[node.act] ?? 0;
        actCounters[node.act] = count + 1;
        final newX = actX[node.act] ?? 100.0;
        final newY = 120.0 + (count * 170.0);
        return node.copyWith(dx: newX, dy: newY);
      }
      return node;
    }).toList();
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  void deleteMindMapNode(String nodeId) {
    _mindMapNodes.removeWhere((n) => n.id == nodeId);
    _mindMapNodes = _mindMapNodes.map((n) {
      if (n.connectedToIds.contains(nodeId)) {
        final updated = List<String>.from(n.connectedToIds)..remove(nodeId);
        return n.copyWith(connectedToIds: updated);
      }
      return n;
    }).toList();
    _saveCurrentData(debounced: false);
    notifyListeners();
  }

  @override
  void dispose() {
    _textChangeDebounceTimer?.cancel();
    _persistenceService.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
