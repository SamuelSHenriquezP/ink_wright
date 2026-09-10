import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/idea_snippet_model.dart';
import '../models/codex_entry_model.dart';
import '../widgets/keyboard_accessory_bar.dart';
import '../widgets/context_drawer_sheet.dart';
import '../widgets/chapter_history_sheet.dart';
import '../widgets/chapter_drawer.dart';
import '../widgets/editor_options_sheet.dart';
import '../widgets/export_manuscript_dialog.dart';
import '../widgets/writing_sprint_dialog.dart';
import '../widgets/chapter_metrics_view.dart';
import '../formatters/writer_text_formatter.dart';
import 'dashboard_screen.dart';
import 'plot_mind_map_screen.dart';

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

    final text = controller.textEditingController.text;
    final cursorOffset = selection.baseOffset.clamp(0, text.length);
    final lineCount = '\n'.allMatches(text.substring(0, cursorOffset)).length;
    final lineHeightPx = controller.fontSize * controller.lineHeight;
    final cursorY = lineCount * lineHeightPx;

    final viewportHeight = _scrollController.position.viewportDimension;
    final targetScroll = (cursorY - (viewportHeight / 2) + lineHeightPx)
        .clamp(0.0, _scrollController.position.maxScrollExtent);

    _scrollController.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 60),
      curve: Curves.easeOut,
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
    final newNum = controller.activeBook.chapters.length + 1;
    final titleCtrl = TextEditingController(text: 'Capítulo $newNum');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Nuevo Capítulo',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
          decoration: InputDecoration(
            labelText: 'Título del capítulo',
            labelStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final t = titleCtrl.text.trim();
              controller.addNewChapter(t.isEmpty ? 'Capítulo $newNum' : t);
              _syncTitleController(controller);
              Navigator.of(ctx).pop();
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(0);
              }
              controller.focusNode.requestFocus();
            },
            child: const Text('Crear Capítulo', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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

  Widget _buildFloatingOptionItem({
    required IconData icon,
    required String label,
    required int delayMs,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final bgPill = isDark ? const Color(0xFF222225) : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final borderSubtle = isDark ? const Color(0xFF38383C) : const Color(0xFFE2E0D8);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text Label Pill
          Material(
            color: Colors.transparent,
            elevation: 3,
            shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: bgPill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderSubtle, width: 0.9),
              ),
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Circular Floating Action Button
          Material(
            color: Colors.transparent,
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: isDark ? 0.45 : 0.2),
            shape: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgPill,
                border: Border.all(color: borderSubtle, width: 0.9),
              ),
              child: Icon(
                icon,
                size: 20,
                color: textPrimary,
              ),
            ),
          ),
          // Align with center of 56px FAB ((56 - 44) / 2 = 6px)
          const SizedBox(width: 6),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 160.ms, delay: Duration(milliseconds: delayMs))
        .slideY(begin: 0.15, end: 0, duration: 160.ms, curve: Curves.easeOut);
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
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    const fontFamilies = ['Lora', 'Merriweather', 'Playfair Display', 'JetBrains Mono'];
    const lineHeights = [1.4, 1.65, 1.9, 2.2];
    const columnWidths = [560.0, 720.0, 900.0, double.infinity];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ajustes Tipométricos y de Edición',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Modo Máquina de Escribir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                    subtitle: Text('Mantiene la línea del cursor centrada verticalmente', style: TextStyle(fontSize: 12, color: textSecondary)),
                    value: controller.isTypewriterMode,
                    activeTrackColor: isDark ? Colors.white : Colors.black,
                    onChanged: (val) {
                      controller.toggleTypewriterMode();
                      setSheetState(() {});
                      setState(() {});
                    },
                  ),
                  const Divider(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tamaño de Fuente', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                      Text('${controller.fontSize.toStringAsFixed(1)} px', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                    ],
                  ),
                  Slider(
                    value: controller.fontSize,
                    min: 13.0,
                    max: 24.0,
                    divisions: 22,
                    activeColor: isDark ? Colors.white : Colors.black,
                    inactiveColor: borderSubtle,
                    onChanged: (val) {
                      controller.setFontSize(val);
                      setSheetState(() {});
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 8),
                  Text('Interlineado', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: lineHeights.map((lh) {
                      final isSelected = (controller.lineHeight - lh).abs() < 0.05;
                      return ChoiceChip(
                        label: Text('${lh}x'),
                        selected: isSelected,
                        selectedColor: isDark ? Colors.white : Colors.black,
                        backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? (isDark ? Colors.black : Colors.white) : textSecondary,
                        ),
                        onSelected: (_) {
                          controller.setLineHeight(lh);
                          setSheetState(() {});
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),
                  Text('Ancho de Columna', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: columnWidths.map((w) {
                      final isSelected = controller.maxEditorWidth == w;
                      final label = w == double.infinity ? '100% Pantalla' : '${w.toInt()}px';
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: isDark ? Colors.white : Colors.black,
                        backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? (isDark ? Colors.black : Colors.white) : textSecondary,
                        ),
                        onSelected: (_) {
                          controller.setMaxEditorWidth(w);
                          setSheetState(() {});
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),
                  Text('Familia Tipográfica', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: fontFamilies.map((font) {
                      final isSelected = controller.selectedFontFamily == font;
                      return ChoiceChip(
                        label: Text(font),
                        selected: isSelected,
                        selectedColor: isDark ? Colors.white : Colors.black,
                        backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? (isDark ? Colors.black : Colors.white) : textSecondary,
                        ),
                        onSelected: (_) {
                          controller.setFontFamily(font);
                          setSheetState(() {});
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderSubtle),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.call_split_rounded, size: 18),
                    label: const Text('Dividir capítulo en el cursor actual', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _splitChapterAtCursor(context, controller);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _splitChapterAtCursor(BuildContext context, EditorController controller) {
    final text = controller.textEditingController.text;
    final pos = controller.textEditingController.selection.baseOffset;
    if (pos <= 0 || pos >= text.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coloca el cursor dentro del texto para dividir el capítulo.')),
      );
      return;
    }

    final titleCtrl = TextEditingController(text: '${controller.activeChapter.title} (Parte 2)');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dividir Capítulo Aquí'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se dividirá el texto en la posición del cursor (carácter $pos).'),
            const SizedBox(height: 14),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Título del nuevo capítulo'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () {
              final newChapter = controller.splitChapter(controller.activeChapter.id, pos, newChapterTitle: titleCtrl.text.trim());
              Navigator.of(ctx).pop();
              if (newChapter != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Capítulo dividido con éxito: "${newChapter.title}" creado.')),
                );
              }
            },
            child: const Text('Dividir'),
          ),
        ],
      ),
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

  Widget _buildFindReplaceBar(EditorController controller, bool isDark, Color textPrimary, Color textSecondary, Color borderSubtle, Color bgCard) {
    final matchCount = _findMatches.length;
    final currentMatchLabel = matchCount == 0
        ? 'Sin coincidencias'
        : '${_currentMatchIndex + 1} de $matchCount';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle, width: 1.2),
        boxShadow: AppTheme.getSoftShadow(isDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _findController,
                  focusNode: _findFocusNode,
                  style: TextStyle(fontSize: 13, color: textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Buscar en el capítulo...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => _onFindChanged(val, controller),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  currentMatchLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                tooltip: 'Coincidencia anterior',
                color: textPrimary,
                onPressed: () => _prevMatch(controller),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                tooltip: 'Siguiente coincidencia',
                color: textPrimary,
                onPressed: () => _nextMatch(controller),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                visualDensity: VisualDensity.compact,
                tooltip: 'Cerrar buscador (Esc)',
                color: textSecondary,
                onPressed: _toggleFindReplace,
              ),
            ],
          ),
          const Divider(height: 8),
          Row(
            children: [
              Icon(Icons.find_replace_rounded, size: 18, color: textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _replaceController,
                  style: TextStyle(fontSize: 13, color: textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Reemplazar con...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: textPrimary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () => _replaceCurrent(controller),
                child: const Text('Reemplazar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: textPrimary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () => _replaceAll(controller),
                child: const Text('Todo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 150.ms);
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bgCard = isDark ? const Color(0xFF1E1E22) : Colors.white;
        final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
        final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anotar Selección',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '«$selectedText»',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.lightbulb_outline_rounded),
                  title: Text('Guardar como Idea / Nota', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('Añade este fragmento al banco de ideas del proyecto', style: TextStyle(color: textSecondary, fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    controller.addIdea(IdeaSnippetModel(
                      id: 'idea_${DateTime.now().millisecondsSinceEpoch}',
                      title: selectedText.length > 30 ? '${selectedText.substring(0, 30)}...' : selectedText,
                      content: selectedText,
                      category: IdeaCategory.general,
                      colorHex: 0xFF18181B,
                      createdAt: DateTime.now(),
                      tags: ['Idea', 'Nota'],
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Guardado en Ideas con éxito.'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.auto_stories_outlined),
                  title: Text('Guardar en Códice del Mundo (Lore)', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('Registra este concepto en la enciclopedia de la historia', style: TextStyle(color: textSecondary, fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showAddCodexDialog(context, controller, isDark, selectedText);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.comment_outlined),
                  title: Text('Insertar como Nota de Autor', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('Envuelve el texto entre marcas Markdown <!-- [Nota]: ... -->', style: TextStyle(color: textSecondary, fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    final wrapped = '<!-- [Nota]: $selectedText -->';
                    final newText = text.replaceRange(selection.start, selection.end, wrapped);
                    controller.textEditingController.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: selection.start + wrapped.length),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCodexDialog(BuildContext context, EditorController controller, bool isDark, String initialContent) {
    final titleCtrl = TextEditingController(
      text: initialContent.length > 30 ? '${initialContent.substring(0, 30)}...' : initialContent,
    );
    String selectedCategory = 'Lore';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
          title: Text(
            'Nueva Entrada del Códice',
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
                  labelText: 'Título del concepto / entrada',
                  labelStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                dropdownColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
                style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  labelStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
                items: ['Lore', 'Ubicaciones', 'Objetos', 'Magia / Leyes', 'Facciones']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDlgState(() => selectedCategory = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancelar', style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isNotEmpty) {
                  CodexType codexType = CodexType.lore;
                  if (selectedCategory == 'Ubicaciones') codexType = CodexType.location;
                  if (selectedCategory == 'Objetos') codexType = CodexType.artifact;

                  controller.addCodexEntry(CodexEntryModel(
                    id: 'codex_${DateTime.now().millisecondsSinceEpoch}',
                    bookId: controller.activeBook.id,
                    name: title,
                    type: codexType,
                    role: selectedCategory,
                    description: initialContent,
                    traits: [selectedCategory],
                    secrets: '',
                    avatarEmoji: codexType == CodexType.location
                        ? '🏰'
                        : (codexType == CodexType.artifact ? '🗝️' : '📜'),
                    createdAt: DateTime.now(),
                  ));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Entrada añadida al Códice con éxito.'), behavior: SnackBarBehavior.floating),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
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
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
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
                                    icon: const Icon(Icons.menu_rounded, size: 24),
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
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color: textPrimary,
                                                    letterSpacing: -0.2,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textSecondary),
                                            ],
                                          ),
                                          Text(
                                            'Capítulo ${controller.activeChapterIndex + 1} de ${controller.totalChapters}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: textSecondary,
                                            ),
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
                                      margin: const EdgeInsets.only(right: 8),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(textSecondary),
                                      ),
                                    ),
                                  ],

                                  // Read-Only Indicator Badge (if active)
                                  if (_isReadOnly)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.lock_outline_rounded, size: 12, color: textSecondary),
                                          const SizedBox(width: 4),
                                          Text('Lectura', style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),

                                  // Format Badge Pill [MD] / [MD*]
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
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: controller.textEditingController.hideMarkdownSymbols
                                              ? (isDark ? Colors.white12 : Colors.black)
                                              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: controller.textEditingController.hideMarkdownSymbols
                                              ? (isDark ? Colors.white54 : Colors.black)
                                              : (isDark ? Colors.white24 : Colors.black12),
                                          ),
                                        ),
                                        child: Text(
                                          controller.textEditingController.hideMarkdownSymbols ? 'MD' : 'MD*',
                                          style: TextStyle(
                                            fontSize: 11,
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

                                  const SizedBox(width: 4),

                                  // [ ⋮ ] 2-Column Options Sheet Menu Button
                                  IconButton(
                                    icon: const Icon(Icons.more_vert_rounded, size: 22),
                                    onPressed: () => _openEditorOptionsMenu(context, controller, themeController, isDark),
                                    tooltip: 'Opciones del Editor',
                                  ),
                                ],
                              ),
                            ),
                    ),

                    if (!isZen) Divider(height: 1, color: borderSubtle),

                    // Floating Find & Replace Bar
                    if (_showFindReplace && !isZen)
                      _buildFindReplaceBar(controller, isDark, textPrimary, textSecondary, borderSubtle, bgCard),

                    // Zen Canvas Paper Text Area
                    Expanded(
                      child: Center(
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
                                  ? MediaQuery.of(context).size.height * 0.4
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(12),
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

                                const SizedBox(height: 100),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_isFabExpanded) ...[
                        // Option 4: Exportar (Top-most)
                        _buildFloatingOptionItem(
                          icon: Icons.file_download_outlined,
                          label: 'Exportar',
                          delayMs: 120,
                          isDark: isDark,
                          onTap: () {
                            setState(() => _isFabExpanded = false);
                            _openExportDialog(context, isDark);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Option 3: Mapa Mental
                        _buildFloatingOptionItem(
                          icon: Icons.hub_outlined,
                          label: 'Mapa Mental',
                          delayMs: 80,
                          isDark: isDark,
                          onTap: () {
                            setState(() => _isFabExpanded = false);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PlotMindMapScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Option 2: Nuevo Libro
                        _buildFloatingOptionItem(
                          icon: Icons.auto_stories_outlined,
                          label: 'Nuevo Libro',
                          delayMs: 40,
                          isDark: isDark,
                          onTap: () {
                            setState(() => _isFabExpanded = false);
                            _showNewBookDialog(context, controller, isDark);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Option 1: Nuevo Capítulo (Bottom-most above FAB)
                        _buildFloatingOptionItem(
                          icon: Icons.post_add_rounded,
                          label: 'Nuevo Capítulo',
                          delayMs: 0,
                          isDark: isDark,
                          onTap: () {
                            setState(() => _isFabExpanded = false);
                            _showNewChapterDialog(context, controller, isDark);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Main FAB Toggle (+ / X)
                      FloatingActionButton(
                        heroTag: 'editor_fab_options',
                        backgroundColor: _isFabExpanded
                            ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFF1E1E20))
                            : accentColor,
                        foregroundColor: _isFabExpanded
                            ? Colors.white
                            : (isDark ? Colors.black : Colors.white),
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        tooltip: _isFabExpanded ? 'Cerrar' : 'Acciones Rápidas (+)',
                        onPressed: () {
                          setState(() {
                            _isFabExpanded = !_isFabExpanded;
                          });
                        },
                        child: AnimatedRotation(
                          turns: _isFabExpanded ? 0.125 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: const Icon(Icons.add_rounded, size: 28),
                        ),
                      ),
                    ],
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
