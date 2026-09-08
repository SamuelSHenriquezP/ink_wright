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
import '../widgets/export_manuscript_dialog.dart';
import '../formatters/writer_text_formatter.dart';
import 'dashboard_screen.dart';

class ZenEditorScreen extends StatefulWidget {
  const ZenEditorScreen({super.key});

  @override
  State<ZenEditorScreen> createState() => _ZenEditorScreenState();
}

class _ZenEditorScreenState extends State<ZenEditorScreen> {
  final ScrollController _scrollController = ScrollController();

  // Find & Replace state
  bool _showFindReplace = false;
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final FocusNode _findFocusNode = FocusNode();
  List<int> _findMatches = [];
  int _currentMatchIndex = 0;

  EditorController? _observedController;

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
    _observedController?.textEditingController.removeListener(_onEditorSelectionChanged);
    _scrollController.dispose();
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
    showDialog(
      context: context,
      builder: (_) => ExportManuscriptDialog(isDark: isDark),
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

    final activeChapter = controller.activeChapter;
    final activeBook = controller.activeBook;
    final content = controller.textEditingController.text;
    final wordCount = WriterTextFormatter.countWords(content);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _toggleFindReplace,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): _toggleFindReplace,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_showFindReplace) _toggleFindReplace();
        },
      },
      child: Scaffold(
        backgroundColor: bgPrimary,
        body: SafeArea(
          child: Stack(
            children: [
              // Main Text Editor Canvas
              Positioned.fill(
                child: Column(
                  children: [
                    // App Bar (Animated out when Zen mode active)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: isZen ? 0 : 64,
                      curve: Curves.easeInOut,
                      child: isZen
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  // Back to Dashboard Button
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                                    onPressed: () {
                                      controller.saveCurrentSession();
                                      if (Navigator.of(context).canPop()) {
                                        Navigator.of(context).pop();
                                      } else {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(builder: (_) => const DashboardScreen()),
                                        );
                                      }
                                    },
                                    tooltip: 'Volver al Inicio',
                                  ),
                                  const SizedBox(width: 8),

                                  // Book & Chapter Title Button (Opens Context Drawer)
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _openContextDrawer(context, isDark),
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
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: textSecondary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: textSecondary),
                                            ],
                                          ),
                                          Text(
                                            activeChapter.title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: textPrimary,
                                              letterSpacing: -0.2,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Live Word Counter Badge Pill + AutoSave Status
                                  GestureDetector(
                                    onTap: () => _openContextDrawer(context, isDark),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$wordCount palabras',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: textPrimary,
                                            ),
                                          ),
                                          if (controller.isSaving) ...[
                                            const SizedBox(width: 6),
                                            SizedBox(
                                              width: 10,
                                              height: 10,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(textSecondary),
                                              ),
                                            ),
                                          ] else ...[
                                            const SizedBox(width: 5),
                                            Icon(Icons.check_circle_outline_rounded, size: 12, color: textSecondary.withValues(alpha: 0.6)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 6),

                                  // Markdown Live Toggle Pill
                                  GestureDetector(
                                    onTap: () => controller.toggleLiveMarkdown(),
                                    child: Tooltip(
                                      message: controller.isLiveMarkdownEnabled
                                          ? 'Markdown en vivo activo (pulsa para desactivar)'
                                          : 'Markdown en vivo desactivado (pulsa para activar)',
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: controller.isLiveMarkdownEnabled
                                              ? (isDark ? Colors.white12 : Colors.black)
                                              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: controller.isLiveMarkdownEnabled
                                                ? (isDark ? Colors.white54 : Colors.black)
                                                : (isDark ? Colors.white24 : Colors.black12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.auto_stories_outlined,
                                              size: 13,
                                              color: controller.isLiveMarkdownEnabled
                                                  ? Colors.white
                                                  : textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'MD',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                                color: controller.isLiveMarkdownEnabled
                                                    ? Colors.white
                                                    : textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 4),

                                  // Find & Replace Toggle Button
                                  IconButton(
                                    icon: Icon(
                                      Icons.search_rounded,
                                      size: 20,
                                      color: _showFindReplace ? accentColor : textSecondary,
                                    ),
                                    onPressed: _toggleFindReplace,
                                    tooltip: 'Buscar y reemplazar (Ctrl+F)',
                                  ),

                                  // Typography & Typewriter Settings Button
                                  IconButton(
                                    icon: Icon(
                                      Icons.format_size_rounded,
                                      size: 20,
                                      color: controller.isTypewriterMode ? accentColor : textSecondary,
                                    ),
                                    onPressed: () => _openTypographySheet(context, controller, isDark),
                                    tooltip: 'Tipografía y Máquina de escribir',
                                  ),

                                  // Chapter History & Snapshots Button
                                  IconButton(
                                    icon: Icon(Icons.history_rounded, size: 20, color: textSecondary),
                                    onPressed: () => ChapterHistorySheet.show(context, controller.activeChapter, isDark),
                                    tooltip: 'Historial de Versiones e Instantáneas',
                                  ),

                                  // Export Manuscript Button
                                  IconButton(
                                    icon: Icon(Icons.ios_share_rounded, size: 20, color: textSecondary),
                                    onPressed: () => _openExportDialog(context, isDark),
                                    tooltip: 'Exportar Manuscrito',
                                  ),

                                  // Botón Pantalla Completa
                                  IconButton(
                                    icon: Icon(
                                      Icons.fullscreen_rounded,
                                      size: 22,
                                      color: isZen ? accentColor : textSecondary,
                                    ),
                                    onPressed: () {
                                      themeController.toggleZenMode();
                                      controller.toggleZenMode();
                                    },
                                    tooltip: 'Pantalla Completa',
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: TextField(
                            controller: controller.textEditingController,
                            focusNode: controller.focusNode,
                            scrollController: _scrollController,
                            maxLines: null,
                            expands: true,
                            keyboardType: TextInputType.multiline,
                            cursorColor: accentColor,
                            cursorWidth: 2.5,
                            cursorRadius: const Radius.circular(2),
                            scrollPadding: controller.isTypewriterMode
                                ? EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.4)
                                : const EdgeInsets.all(20),
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

              // Keyboard Accessory Toolbar (Bottom)
              if (!isZen)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  child: KeyboardAccessoryBar(
                    textController: controller.textEditingController,
                    isDark: isDark,
                    onToggleZenMode: () {
                      themeController.toggleZenMode();
                      controller.toggleZenMode();
                    },
                    onOpenIdeas: () => _openContextDrawer(context, isDark),
                    onOpenContextDrawer: () => _openContextDrawer(context, isDark),
                    wordCount: wordCount,
                    canUndo: controller.canUndo,
                    canRedo: controller.canRedo,
                    onUndo: () => controller.undo(),
                    onRedo: () => controller.redo(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
