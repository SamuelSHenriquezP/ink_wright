import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/keyboard_accessory_bar.dart';
import '../widgets/context_drawer_sheet.dart';
import '../widgets/chapter_history_sheet.dart';
import '../widgets/chapter_drawer.dart';
import '../widgets/editor_options_sheet.dart';
import '../widgets/export_manuscript_dialog.dart';
import '../widgets/writing_sprint_dialog.dart';
import '../widgets/chapter_metrics_view.dart';
import '../widgets/revision_sidebar.dart';
import '../widgets/chapters/new_chapter_modal.dart';
import '../widgets/editor/zen_typography_sheet.dart';
import '../widgets/editor/zen_find_replace_bar.dart';
import '../widgets/editor/zen_selection_note_sheet.dart';
import '../widgets/editor/zen_speed_dial_fab.dart';
import '../widgets/editor/prose_inspector_sheet.dart';
import '../formatters/writer_text_formatter.dart';
import 'dashboard_screen.dart';
import 'plot_mind_map_screen.dart';
import 'manuscript_reader_screen.dart';
import 'corkboard_screen.dart';

class ZenEditorScreen extends StatefulWidget {
  const ZenEditorScreen({super.key});

  @override
  State<ZenEditorScreen> createState() => _ZenEditorScreenState();
}

class _ZenEditorScreenState extends State<ZenEditorScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController(initialPage: 1);
  bool _isReadOnly = false;
  bool _isFabExpanded = false;

  // Chapter title controller
  final TextEditingController _chapterTitleController = TextEditingController();
  String? _lastLoadedChapterId;

  // Find & Replace state
  bool _showFindReplace = false;
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final FocusNode _findFocusNode = FocusNode();
  List<int> _findMatches = [];
  int _currentMatchIndex = 0;

  EditorController? _observedController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _observedController?.flushPendingSave();
      _observedController?.saveCurrentSession();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = Provider.of<EditorController>(context, listen: false);
    if (_observedController != controller) {
      _observedController?.textEditingController.removeListener(_onEditorSelectionChanged);
      _observedController = controller;
      _observedController?.textEditingController.addListener(_onEditorSelectionChanged);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _observedController?.flushPendingSave();
    _observedController?.saveCurrentSession();
    _observedController?.textEditingController.removeListener(_onEditorSelectionChanged);
    _scrollController.dispose();
    _pageController.dispose();
    _chapterTitleController.dispose();
    _findController.dispose();
    _replaceController.dispose();
    _findFocusNode.dispose();
    super.dispose();
  }

  void _onEditorSelectionChanged() {
    final controller = _observedController;
    if (controller == null || !controller.isTypewriterMode || !_scrollController.hasClients) return;

    final selection = controller.textEditingController.selection;
    if (!selection.isValid) return;

    _scrollOffsetToCursor(selection.baseOffset, controller, animated: true);
  }

  void _scrollOffsetToCursor(int charOffset, EditorController controller, {bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final text = controller.textEditingController.text;
    final clamped = charOffset.clamp(0, text.length);

    final screenWidth = MediaQuery.of(context).size.width;
    final maxW = controller.maxEditorWidth == double.infinity ? screenWidth : controller.maxEditorWidth;
    final textWidth = (screenWidth - 48).clamp(100.0, maxW - 48);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: _getEditorFontTextStyle(
          controller.selectedFontFamily,
          controller.fontSize,
          controller.lineHeight,
          controller.isDarkMode,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: textWidth);
    final caretOffset = textPainter.getOffsetForCaret(
      TextPosition(offset: clamped),
      Rect.zero,
    );
    textPainter.dispose();

    // 88.0 accounts for chapter header ("CAPÍTULO X", word count, title input, margins)
    final cursorY = caretOffset.dy + 88.0;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 100;
    final accessoryBarHeight = (!controller.isZenMode && isKeyboardOpen) ? 48.0 : 0.0;
    final viewportHeight = _scrollController.position.viewportDimension;
    final visibleHeight = (viewportHeight - accessoryBarHeight).clamp(100.0, double.infinity);
    final lineHeightPx = controller.fontSize * controller.lineHeight;
    final targetScroll = (cursorY - (visibleHeight / 2) + (lineHeightPx / 2))
        .clamp(0.0, _scrollController.position.maxScrollExtent);

    if (animated) {
      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(targetScroll);
    }
  }

  void _openProseInspector(BuildContext context, EditorController controller, bool isDark) {
    ProseInspectorSheet.show(
      context: context,
      controller: controller,
      isDark: isDark,
      onJumpToIssue: (start, end) {
        final text = controller.textEditingController.text;
        final safeStart = start.clamp(0, text.length);
        final safeEnd = end.clamp(0, text.length);
        controller.textEditingController.selection = TextSelection(
          baseOffset: safeStart,
          extentOffset: safeEnd,
        );
        controller.focusNode.requestFocus();
        _scrollOffsetToCursor(safeStart, controller, animated: true);
      },
    );
  }

  void _openContextDrawer(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContextDrawerSheet(isDark: isDark),
    );
  }

  void _openExportDialog(BuildContext context, bool isDark) {
    ExportManuscriptDialog.show(context, isDark: isDark);
  }

  void _openSprintDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => WritingSprintDialog(isDark: isDark),
    );
  }

  void _syncTitleController(EditorController controller) {
    if (_lastLoadedChapterId != controller.activeChapter.id) {
      _lastLoadedChapterId = controller.activeChapter.id;
      _chapterTitleController.text = controller.activeChapter.title;
    }
  }

  void _showNewChapterDialog(BuildContext context, EditorController controller, bool isDark) {
    NewChapterModal.show(
      context,
      isDark: isDark,
      onChapterCreated: () {
        _syncTitleController(controller);
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        controller.focusNode.requestFocus();
      },
    );
  }

  void _showNewBookDialog(BuildContext context, EditorController controller, bool isDark) {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Nuevo Libro',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
              decoration: InputDecoration(
                labelText: 'Título del libro / proyecto',
                labelStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subtitleCtrl,
              style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
              decoration: InputDecoration(
                labelText: 'Subtítulo o premisa (opcional)',
                labelStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isNotEmpty) {
                controller.createNewBook(
                  title,
                  subtitleCtrl.text.trim(),
                  50000,
                );
                _syncTitleController(controller);
                Navigator.of(ctx).pop();
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Libro "$title" creado con éxito.'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Crear Libro', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _toggleFindReplace() {
    setState(() {
      _showFindReplace = !_showFindReplace;
      if (_showFindReplace) {
        _findFocusNode.requestFocus();
        final controller = Provider.of<EditorController>(context, listen: false);
        _onFindChanged(_findController.text, controller);
      } else {
        _findMatches.clear();
        _currentMatchIndex = 0;
      }
    });
  }

  void _onFindChanged(String query, EditorController controller) {
    if (query.isEmpty) {
      setState(() {
        _findMatches = [];
        _currentMatchIndex = 0;
      });
      return;
    }

    final text = controller.textEditingController.text;
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = <int>[];
    int start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) break;
      matches.add(index);
      start = index + lowerQuery.length;
    }

    setState(() {
      _findMatches = matches;
      if (_currentMatchIndex >= matches.length) {
        _currentMatchIndex = 0;
      }
    });

    if (matches.isNotEmpty) {
      _highlightCurrentMatch(controller);
    }
  }

  void _highlightCurrentMatch(EditorController controller) {
    if (_findMatches.isEmpty) return;
    final start = _findMatches[_currentMatchIndex];
    final end = (start + _findController.text.length).clamp(0, controller.textEditingController.text.length);
    controller.textEditingController.selection = TextSelection(baseOffset: start, extentOffset: end);

    final text = controller.textEditingController.text;
    final lineIndex = '\n'.allMatches(text.substring(0, start)).length;
    final targetY = (lineIndex * (controller.fontSize * controller.lineHeight)) - 100;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetY.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }
  }

  void _nextMatch(EditorController controller) {
    if (_findMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _findMatches.length;
    });
    _highlightCurrentMatch(controller);
  }

  void _prevMatch(EditorController controller) {
    if (_findMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _findMatches.length) % _findMatches.length;
    });
    _highlightCurrentMatch(controller);
  }

  void _replaceCurrent(EditorController controller) {
    if (_findMatches.isEmpty) return;
    final query = _findController.text;
    final replacement = _replaceController.text;
    final start = _findMatches[_currentMatchIndex];
    final text = controller.textEditingController.text;
    final newText = text.replaceRange(start, start + query.length, replacement);
    controller.textEditingController.text = newText;
    _onFindChanged(query, controller);
  }

  void _replaceAll(EditorController controller) {
    if (_findMatches.isEmpty) return;
    final query = _findController.text;
    final replacement = _replaceController.text;
    final text = controller.textEditingController.text;
    final newText = text.replaceAll(RegExp(RegExp.escape(query), caseSensitive: false), replacement);
    controller.textEditingController.text = newText;
    _onFindChanged(query, controller);
  }

  void _openTypographySheet(BuildContext context, EditorController controller, bool isDark) {
    ZenTypographySheet.show(
      context: context,
      controller: controller,
      isDark: isDark,
      onSettingsChanged: () => setState(() {}),
    );
  }

  TextStyle _getEditorFontTextStyle(String fontName, double fontSize, double lineHeight, bool isDark) {
    final color = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    switch (fontName) {
      case 'Merriweather':
        return GoogleFonts.merriweather(fontSize: fontSize, height: lineHeight, color: color);
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(fontSize: fontSize * 1.05, height: lineHeight, color: color);
      case 'JetBrains Mono':
        return GoogleFonts.jetBrainsMono(fontSize: fontSize * 0.92, height: lineHeight, color: color);
      case 'Lora':
      default:
        return GoogleFonts.lora(fontSize: fontSize, height: lineHeight, color: color);
    }
  }

  void _annotateSelection(BuildContext context, EditorController controller, bool isDark) {
    final selection = controller.textEditingController.selection;
    final text = controller.textEditingController.text;
    if (!selection.isValid || selection.isCollapsed || selection.start < 0 || selection.end > text.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona primero una frase o fragmento en el editor para anotarlo.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedText = text.substring(selection.start, selection.end).trim();
    if (selectedText.isEmpty) return;

    ZenSelectionNoteSheet.show(
      context: context,
      controller: controller,
      isDark: isDark,
      selectedText: selectedText,
      selection: selection,
      fullText: text,
    );
  }

  void _openEditorOptionsMenu(
    BuildContext context,
    EditorController controller,
    ThemeController themeController,
    bool isDark,
  ) {
    EditorOptionsMenuSheet.show(
      context: context,
      isDark: isDark,
      chapterTitle: controller.activeChapter.title,
      chapterContent: controller.textEditingController.text,
      isReadOnly: _isReadOnly,
      isTypewriter: controller.isTypewriterMode,
      hideMarkdownSymbols: controller.textEditingController.hideMarkdownSymbols,
      hasNextChapter: controller.hasNextChapter,
      hasPreviousChapter: controller.hasPreviousChapter,
      onNextChapter: () {
        controller.goToNextChapter();
        _syncTitleController(controller);
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
      },
      onPreviousChapter: () {
        controller.goToPreviousChapter();
        _syncTitleController(controller);
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
      },
      onNewChapter: () => _showNewChapterDialog(context, controller, isDark),
      onWritingSprint: () => _openSprintDialog(context, isDark),
      onMuseAssistant: () => _openContextDrawer(context, isDark),
      onToggleReadOnly: () {
        setState(() {
          _isReadOnly = !_isReadOnly;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isReadOnly ? 'Modo Solo Lectura activado' : 'Modo Edición activado'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onToggleTypewriter: () {
        controller.toggleTypewriterMode();
      },
      onToggleHideMarkdown: () {
        controller.textEditingController.toggleHideMarkdownSymbols();
        setState(() {});
      },
      onFindReplace: () {
        if (!_showFindReplace) _toggleFindReplace();
      },
      onExport: () {
        _openExportDialog(context, isDark);
      },
      onHistory: () {
        ChapterHistorySheet.show(context, controller.activeChapter, isDark);
      },
      onTypography: () {
        _openTypographySheet(context, controller, isDark);
      },
      onStats: () {
        _openStatsDialog(context, controller, isDark);
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            2,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          );
        }
      },
      onContinuousReader: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ManuscriptReaderScreen(
              initialChapterIndex: controller.activeChapterIndex,
            ),
          ),
        );
      },
      onProseInspector: () {
        _openProseInspector(context, controller, isDark);
      },
      onCorkboard: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CorkboardScreen()),
        );
      },
      onGoToDashboard: () {
        controller.saveCurrentSession();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      },
    );
  }

  void _openStatsDialog(BuildContext context, EditorController controller, bool isDark) {
    final text = controller.textEditingController.text;
    final words = WriterTextFormatter.countWords(text);
    final chars = text.length;
    final charsNoSpaces = text.replaceAll(RegExp(r'\s+'), '').length;
    final paragraphs = WriterTextFormatter.countParagraphs(text);
    final readingTimeMinutes = (words / 200).ceil();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
        title: Text(
          'Métricas del Capítulo',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Palabras', '$words', isDark),
            const Divider(height: 16),
            _buildStatRow('Caracteres (con espacios)', '$chars', isDark),
            const Divider(height: 16),
            _buildStatRow('Caracteres (sin espacios)', '$charsNoSpaces', isDark),
            const Divider(height: 16),
            _buildStatRow('Párrafos', '$paragraphs', isDark),
            const Divider(height: 16),
            _buildStatRow('Tiempo de lectura aprox.', '$readingTimeMinutes min', isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cerrar', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String val, bool isDark) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: textSecondary, fontSize: 13)),
        Text(val, style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final themeController = Provider.of<ThemeController>(context);
    final isDark = themeController.isDarkMode;
    final isZen = themeController.isZenMode;

    final bgPrimary = isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentColor = isDark ? Colors.white : Colors.black;

    final activeBook = controller.activeBook;
    final content = controller.textEditingController.text;
    final wordCount = WriterTextFormatter.countWords(content);
    _syncTitleController(controller);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _toggleFindReplace,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): _toggleFindReplace,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_showFindReplace) _toggleFindReplace();
        },
      },
      child: PopScope(
        canPop: !_isFabExpanded,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_isFabExpanded) {
            setState(() {
              _isFabExpanded = false;
            });
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          drawer: ChapterDrawer(controller: controller, isDark: isDark),
          drawerEnableOpenDragGesture: false,
          backgroundColor: bgPrimary,
          body: SafeArea(
            child: PageView(
              controller: _pageController,
              onPageChanged: (idx) {
                if (_isFabExpanded) {
                  setState(() => _isFabExpanded = false);
                }
              },
              physics: isKeyboardOpen
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
            children: [
              // Page 0: Chapter Drawer (Revealed when swiping to the right — matches top-left menu)
              ChapterDrawer(
                controller: controller,
                isDark: isDark,
                width: double.infinity,
                onSelectChapter: () {
                  if (_pageController.hasClients) {
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),

              // Page 1: Main Text Editor Canvas
              Stack(
            children: [
              // Main Text Editor Canvas
              Positioned.fill(
                bottom: (!isZen && isKeyboardOpen) ? 48.0 : 0.0,
                child: Column(
                  children: [
                    // Minimalist App Bar matching Screenshot 2 (Animated out when Zen mode active)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: isZen ? 0 : 58,
                      curve: Curves.easeInOut,
                      child: isZen
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  // [ = ] Hamburger Menu Button (Opens Chapter Drawer)
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    icon: const Icon(Icons.menu_rounded, size: 22),
                                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                                    tooltip: 'Capítulos',
                                  ),
                                  const SizedBox(width: 4),

                                  // Chapter & Book Title (Tap opens chapter drawer too)
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  activeBook.title,
                                                  style: TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: textPrimary,
                                                    letterSpacing: -0.2,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: textSecondary),
                                            ],
                                          ),
                                          Text(
                                            'Cap. ${controller.activeChapterIndex + 1} de ${controller.totalChapters} • ${controller.activeChapter.title}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // AutoSave Status Indicator
                                  if (controller.isSaving) ...[
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 6),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(textSecondary),
                                      ),
                                    ),
                                  ],

                                   // Read-Only Indicator Badge (compact icon with tooltip)
                                   if (_isReadOnly)
                                     Tooltip(
                                       message: 'Modo Lectura Activo (${controller.activeChapter.readingTimeMinutes} min)',
                                       child: Container(
                                         margin: const EdgeInsets.only(right: 4),
                                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                         decoration: BoxDecoration(
                                           color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                                           borderRadius: BorderRadius.circular(8),
                                         ),
                                         child: Icon(Icons.menu_book_rounded, size: 15, color: textSecondary),
                                       ),
                                     ),

                                   // Format Badge Pill [MD] / [MD*] (Square aesthetic)
                                   GestureDetector(
                                     onTap: () {
                                       controller.textEditingController.toggleHideMarkdownSymbols();
                                       setState(() {});
                                     },
                                     child: Tooltip(
                                       message: controller.textEditingController.hideMarkdownSymbols
                                           ? 'Símbolos Markdown ocultos (pulsa para mostrar)'
                                           : 'Símbolos Markdown visibles (pulsa para ocultar)',
                                       child: Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                         decoration: BoxDecoration(
                                           color: controller.textEditingController.hideMarkdownSymbols
                                               ? (isDark ? Colors.white12 : Colors.black)
                                               : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                                           borderRadius: BorderRadius.circular(8),
                                           border: Border.all(
                                             color: controller.textEditingController.hideMarkdownSymbols
                                               ? (isDark ? Colors.white54 : Colors.black)
                                               : (isDark ? Colors.white24 : Colors.black12),
                                           ),
                                         ),
                                         child: Text(
                                           controller.textEditingController.hideMarkdownSymbols ? 'MD' : 'MD*',
                                           style: TextStyle(
                                             fontSize: 10.5,
                                             fontWeight: FontWeight.w800,
                                             letterSpacing: 0.5,
                                             color: controller.textEditingController.hideMarkdownSymbols
                                                 ? Colors.white
                                                 : textSecondary,
                                           ),
                                         ),
                                       ),
                                     ),
                                   ),

                                   const SizedBox(width: 2),

                                   // Revision Mode Button
                                   Builder(
                                     builder: (ctx) {
                                       final openComments = controller.activeChapterComments.where((c) => !c.isResolved).length;
                                       return IconButton(
                                         visualDensity: VisualDensity.compact,
                                         padding: EdgeInsets.zero,
                                         constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                         icon: Badge(
                                           isLabelVisible: openComments > 0,
                                           label: Text('$openComments'),
                                           backgroundColor: isDark ? Colors.amberAccent : Colors.amber.shade800,
                                           textColor: isDark ? Colors.black : Colors.white,
                                           child: Icon(
                                             controller.isRevisionMode ? Icons.rate_review_rounded : Icons.rate_review_outlined,
                                             size: 20,
                                             color: controller.isRevisionMode
                                                 ? (isDark ? Colors.amberAccent : Colors.amber.shade800)
                                                 : textSecondary,
                                           ),
                                         ),
                                         tooltip: 'Panel de Revisión & Notas',
                                         onPressed: () {
                                           controller.toggleRevisionMode();
                                           RevisionSidebar.show(context);
                                         },
                                       );
                                     },
                                   ),

                                   // Manuscript Reader Mode Button
                                   IconButton(
                                     visualDensity: VisualDensity.compact,
                                     padding: EdgeInsets.zero,
                                     constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                     icon: const Icon(Icons.auto_stories_outlined, size: 20),
                                     tooltip: 'Lector del Manuscrito Completo',
                                     onPressed: () {
                                       Navigator.of(context).push(
                                         MaterialPageRoute(
                                           builder: (_) => ManuscriptReaderScreen(
                                             initialChapterIndex: controller.activeChapterIndex,
                                           ),
                                         ),
                                       );
                                     },
                                   ),

                                   // [ ⋮ ] 2-Column Options Sheet Menu Button
                                   IconButton(
                                     visualDensity: VisualDensity.compact,
                                     padding: EdgeInsets.zero,
                                     constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                     icon: const Icon(Icons.more_vert_rounded, size: 21),
                                     onPressed: () => _openEditorOptionsMenu(context, controller, themeController, isDark),
                                     tooltip: 'Opciones del Editor',
                                   ),
                                   const SizedBox(width: 4),
                                 ],
                               ),
                             ),
                     ),

                     if (!isZen) Divider(height: 1, color: borderSubtle),

                     if (_isReadOnly)
                       LinearProgressIndicator(
                         minHeight: 2.5,
                         backgroundColor: Colors.transparent,
                         valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white70 : Colors.black87),
                       ),

                    // Floating Find & Replace Bar
                    if (_showFindReplace && !isZen)
                      ZenFindReplaceBar(
                        controller: controller,
                        isDark: isDark,
                        findController: _findController,
                        replaceController: _replaceController,
                        findFocusNode: _findFocusNode,
                        findMatches: _findMatches,
                        currentMatchIndex: _currentMatchIndex,
                        onFindChanged: (val) => _onFindChanged(val, controller),
                        onPrevMatch: () => _prevMatch(controller),
                        onNextMatch: () => _nextMatch(controller),
                        onClose: _toggleFindReplace,
                        onReplaceCurrent: () => _replaceCurrent(controller),
                        onReplaceAll: () => _replaceAll(controller),
                      ),

                    // Zen Canvas Paper Text Area
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: controller.maxEditorWidth == double.infinity
                                ? double.infinity
                                : controller.maxEditorWidth,
                          ),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              24,
                              20,
                              24,
                              controller.isTypewriterMode
                                  ? MediaQuery.of(context).size.height * 0.55
                                  : 140,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Editorial Chapter Header Block
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'CAPÍTULO ${controller.activeChapterIndex + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                        color: textSecondary,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                                            ),
                                          ),
                                          child: Text(
                                            '$wordCount pal. • ${WriterTextFormatter.estimateReadingTime(content)} min',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _openProseInspector(context, controller, isDark),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isDark ? Colors.white24 : Colors.black12,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.auto_awesome_rounded, size: 12, color: textPrimary),
                                                const SizedBox(width: 5),
                                                Text(
                                                  'Inspector',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Editable Chapter Title Field
                                TextField(
                                  controller: _chapterTitleController,
                                  clipBehavior: Clip.none,
                                  readOnly: _isReadOnly,
                                  style: GoogleFonts.getFont(
                                    controller.selectedFontFamily,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Título del capítulo...',
                                    hintStyle: TextStyle(
                                      color: textSecondary.withValues(alpha: 0.4),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                  onChanged: (val) {
                                    controller.updateActiveChapterTitle(val);
                                  },
                                ),
                                const SizedBox(height: 8),
                                Divider(height: 1, color: borderSubtle),
                                const SizedBox(height: 16),

                                // Chapter Manuscript Body
                                TextField(
                                  readOnly: _isReadOnly,
                                  controller: controller.textEditingController,
                                  focusNode: controller.focusNode,
                                  clipBehavior: Clip.none,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  cursorColor: accentColor,
                                  cursorWidth: 2.5,
                                  cursorRadius: const Radius.circular(2),
                                  style: _getEditorFontTextStyle(
                                    controller.selectedFontFamily,
                                    controller.fontSize,
                                    controller.lineHeight,
                                    isDark,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Empieza a escribir tu historia aquí...',
                                    hintStyle: _getEditorFontTextStyle(
                                      controller.selectedFontFamily,
                                      controller.fontSize,
                                      controller.lineHeight,
                                      isDark,
                                    ).copyWith(
                                      color: textSecondary.withValues(alpha: 0.4),
                                      fontStyle: FontStyle.italic,
                                    ),
                                   border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),

                                 SizedBox(
                                   height: controller.isTypewriterMode
                                       ? (MediaQuery.of(context).size.height * 0.55)
                                       : (isKeyboardOpen ? 60 : 100),
                                 ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Zen Mode Float Restorer
              if (isZen)
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    backgroundColor: accentColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    child: const Icon(Icons.close_fullscreen_rounded, size: 18),
                    onPressed: () {
                      themeController.toggleZenMode();
                      controller.toggleZenMode();
                    },
                  ),
                ).animate().fadeIn(duration: 200.ms),

              // Keyboard Accessory Toolbar (Only shown when virtual keyboard is active)
              if (!isZen && isKeyboardOpen)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: KeyboardAccessoryBar(
                    textController: controller.textEditingController,
                    isDark: isDark,
                    canUndo: controller.canUndo,
                    canRedo: controller.canRedo,
                    onUndo: () => controller.undo(),
                    onRedo: () => controller.redo(),
                    onAnnotateSelection: () => _annotateSelection(context, controller, isDark),
                  ),
                ),

              // Scrim / Backdrop overlay when FAB is expanded
              if (_isFabExpanded && !isZen && !isKeyboardOpen)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _isFabExpanded = false),
                    child: Container(
                      color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.35),
                    ),
                  ).animate().fadeIn(duration: 150.ms),
                ),

              // Floating Speed Dial Options + Main FAB (Only shown when keyboard is closed)
              if (!isZen && !isKeyboardOpen)
                Positioned(
                  bottom: 24,
                  right: 20,
                  child: ZenSpeedDialFab(
                    isExpanded: _isFabExpanded,
                    isDark: isDark,
                    onToggle: () {
                      setState(() {
                        _isFabExpanded = !_isFabExpanded;
                      });
                    },
                    onNewChapter: () {
                      setState(() => _isFabExpanded = false);
                      _showNewChapterDialog(context, controller, isDark);
                    },
                    onNewBook: () {
                      setState(() => _isFabExpanded = false);
                      _showNewBookDialog(context, controller, isDark);
                    },
                    onMindMap: () {
                      setState(() => _isFabExpanded = false);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PlotMindMapScreen()),
                      );
                    },
                    onExport: () {
                      setState(() => _isFabExpanded = false);
                      _openExportDialog(context, isDark);
                    },
                  ),
                ),
              ],
            ),

            // Page 2: Chapter Metrics View (Revealed when swiping to the left)
            ChapterMetricsView(
              controller: controller,
              isDark: isDark,
              onBackToEditor: () {
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ],
        ),
      ),
    ),
  ),
  );
  }
}
