import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../controllers/theme_controller.dart';
import '../formatters/writer_text_formatter.dart';
import '../widgets/editor/zen_typography_sheet.dart';

/// Pantalla de "Editor de Texto Simple":
/// Un espacio despejado y sin fricción dedicado exclusivamente a escribir.
/// Conserva las calidades de vida esenciales (autoguardado, deshacer/rehacer,
/// tipografía cómoda, métricas discretas) sin ninguna herramienta compleja.
class SimpleTextEditorScreen extends StatefulWidget {
  const SimpleTextEditorScreen({super.key});

  @override
  State<SimpleTextEditorScreen> createState() => _SimpleTextEditorScreenState();
}

class _SimpleTextEditorScreenState extends State<SimpleTextEditorScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();

  EditorController? _observedController;
  String? _lastLoadedChapterId;
  bool _showMetricsBar = true;

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
      _observedController = controller;
    }
    _syncTitle(controller);
  }

  void _syncTitle(EditorController controller) {
    if (_lastLoadedChapterId != controller.activeChapter.id) {
      _lastLoadedChapterId = controller.activeChapter.id;
      _titleController.text = controller.activeChapter.title;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _observedController?.flushPendingSave();
    _observedController?.saveCurrentSession();
    _scrollController.dispose();
    _titleController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  TextStyle _getEditorFontTextStyle(
    String fontName,
    double fontSize,
    double lineHeight,
    bool isDark,
  ) {
    final color = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    switch (fontName) {
      case 'Merriweather':
        return GoogleFonts.merriweather(
          fontSize: fontSize,
          height: lineHeight,
          color: color,
        );
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(
          fontSize: fontSize * 1.05,
          height: lineHeight,
          color: color,
        );
      case 'JetBrains Mono':
        return GoogleFonts.jetBrainsMono(
          fontSize: fontSize * 0.92,
          height: lineHeight,
          color: color,
        );
      case 'Lora':
      default:
        return GoogleFonts.lora(
          fontSize: fontSize,
          height: lineHeight,
          color: color,
        );
    }
  }

  void _openTypographySheet(
    BuildContext context,
    EditorController controller,
    bool isDark,
  ) {
    ZenTypographySheet.show(
      context: context,
      controller: controller,
      isDark: isDark,
      onSettingsChanged: () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final themeController = Provider.of<ThemeController>(context);
    final isDark = themeController.isDarkMode;

    final bgPrimary = isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentColor = isDark ? Colors.white : Colors.black;

    _syncTitle(controller);

    final content = controller.textEditingController.text;
    final wordCount = WriterTextFormatter.countWords(content);
    final readingTime = WriterTextFormatter.estimateReadingTime(content);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior limpia y minimalista
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderSubtle, width: 0.8)),
              ),
              child: Row(
                children: [
                  // Botón Volver
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 21),
                    tooltip: 'Volver al editor principal',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      controller.flushPendingSave();
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 4),

                  // Navegación entre capítulos
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    tooltip: 'Capítulo anterior',
                    visualDensity: VisualDensity.compact,
                    onPressed: controller.hasPreviousChapter
                        ? () {
                            controller.goToPreviousChapter();
                            _syncTitle(controller);
                            if (_scrollController.hasClients) _scrollController.jumpTo(0);
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    tooltip: 'Capítulo siguiente',
                    visualDensity: VisualDensity.compact,
                    onPressed: controller.hasNextChapter
                        ? () {
                            controller.goToNextChapter();
                            _syncTitle(controller);
                            if (_scrollController.hasClients) _scrollController.jumpTo(0);
                          }
                        : null,
                  ),

                  const SizedBox(width: 6),

                  // Indicador del capítulo y libro
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.activeBook.title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Capítulo ${controller.activeChapterIndex + 1} de ${controller.totalChapters}',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Estado de guardado
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

                  // Deshacer / Rehacer
                  IconButton(
                    icon: const Icon(Icons.undo_rounded, size: 19),
                    tooltip: 'Deshacer (Ctrl+Z)',
                    visualDensity: VisualDensity.compact,
                    onPressed: controller.canUndo ? () => controller.undo() : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo_rounded, size: 19),
                    tooltip: 'Rehacer (Ctrl+Y)',
                    visualDensity: VisualDensity.compact,
                    onPressed: controller.canRedo ? () => controller.redo() : null,
                  ),

                  // Selector de tipografía / fuente
                  IconButton(
                    icon: const Icon(Icons.format_size_rounded, size: 20),
                    tooltip: 'Tipografía y tamaño de texto',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _openTypographySheet(context, controller, isDark),
                  ),

                  // Alternar Tema Claro / Oscuro
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 20,
                    ),
                    tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => themeController.toggleThemeMode(),
                  ),
                ],
              ),
            ),

            // Lienzo de texto amplio y limpio
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: controller.maxEditorWidth == double.infinity
                              ? 760
                              : controller.maxEditorWidth,
                        ),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            28,
                            24,
                            28,
                            MediaQuery.of(context).size.height * 0.40,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Título del capítulo
                              TextField(
                                controller: _titleController,
                                style: GoogleFonts.getFont(
                                  controller.selectedFontFamily,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                  color: textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Título del capítulo...',
                                  hintStyle: TextStyle(
                                    color: textSecondary.withValues(alpha: 0.35),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                ),
                                onChanged: (val) {
                                  controller.updateActiveChapterTitle(val);
                                },
                              ),
                              const SizedBox(height: 12),
                              Divider(height: 1, color: borderSubtle),
                              const SizedBox(height: 20),

                              // Cuerpo del texto sin distracciones
                              TextField(
                                controller: controller.textEditingController,
                                focusNode: _editorFocusNode,
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
                                  hintText: 'Escribe libremente aquí...',
                                  hintStyle: _getEditorFontTextStyle(
                                    controller.selectedFontFamily,
                                    controller.fontSize,
                                    controller.lineHeight,
                                    isDark,
                                  ).copyWith(
                                    color: textSecondary.withValues(alpha: 0.35),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Píldora discreta de métricas en la esquina inferior (solo si el teclado está cerrado)
                  if (!isKeyboardOpen && _showMetricsBar)
                    Positioned(
                      bottom: 18,
                      right: 18,
                      child: GestureDetector(
                        onTap: () => setState(() => _showMetricsBar = !_showMetricsBar),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E22).withValues(alpha: 0.92)
                                : Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderSubtle),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_note_rounded, size: 14, color: textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                '$wordCount palabras • $readingTime min',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

