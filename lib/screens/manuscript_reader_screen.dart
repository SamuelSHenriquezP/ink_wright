import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/editor_controller.dart';
import '../models/book_model.dart';
import '../models/chapter_model.dart';
import '../theme/app_theme.dart';
import 'zen_editor_screen.dart';

enum ReaderTheme {
  light,
  dark,
  sepia,
}

class ManuscriptReaderScreen extends StatefulWidget {
  final int? initialChapterIndex;

  const ManuscriptReaderScreen({
    super.key,
    this.initialChapterIndex,
  });

  @override
  State<ManuscriptReaderScreen> createState() => _ManuscriptReaderScreenState();
}

class _ManuscriptReaderScreenState extends State<ManuscriptReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _chapterKeys = {};

  bool _showControls = true;
  final ValueNotifier<double> _scrollProgressNotifier = ValueNotifier<double>(0.0);
  ReaderTheme _readerTheme = ReaderTheme.dark;
  String _fontFamily = 'Lora';
  double _fontSize = 17.5;
  final double _lineHeight = 1.75;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<EditorController>(context, listen: false);
      setState(() {
        _readerTheme = controller.isDarkMode ? ReaderTheme.dark : ReaderTheme.light;
        _fontFamily = controller.selectedFontFamily;
      });

      if (widget.initialChapterIndex != null && widget.initialChapterIndex! > 0) {
        _scrollToChapter(widget.initialChapterIndex!);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollProgressNotifier.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0) {
      final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      if ((progress - _scrollProgressNotifier.value).abs() > 0.005) {
        _scrollProgressNotifier.value = progress;
      }
    }
  }

  void _scrollToChapter(int index) {
    final key = _chapterKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  TextStyle _getBodyTextStyle(Color textColor) {
    TextStyle baseStyle = TextStyle(
      fontSize: _fontSize,
      height: _lineHeight,
      color: textColor,
      letterSpacing: 0.15,
    );

    try {
      switch (_fontFamily) {
        case 'Merriweather':
          return GoogleFonts.merriweather(textStyle: baseStyle);
        case 'Cinzel':
          return GoogleFonts.cinzel(textStyle: baseStyle);
        case 'Inter':
          return GoogleFonts.inter(textStyle: baseStyle);
        case 'Fira Code':
          return GoogleFonts.firaCode(textStyle: baseStyle);
        case 'EB Garamond':
          return GoogleFonts.ebGaramond(textStyle: baseStyle);
        case 'Lora':
        default:
          return GoogleFonts.lora(textStyle: baseStyle);
      }
    } catch (_) {
      return baseStyle.copyWith(fontFamily: _fontFamily);
    }
  }

  void _showAppearanceSheet(BuildContext context) {
    final themeColors = _resolveColors();
    showModalBottomSheet(
      context: context,
      backgroundColor: themeColors.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: themeColors.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Ajustes de Lectura',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: themeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Selector de Tema (Luz, Sepia, Noche)
                    Row(
                      children: [
                        _buildThemeOption(
                          label: 'Claro',
                          icon: Icons.light_mode_outlined,
                          theme: ReaderTheme.light,
                          bgColor: const Color(0xFFFAFAFA),
                          fgColor: Colors.black,
                          isSelected: _readerTheme == ReaderTheme.light,
                          onTap: () {
                            setState(() => _readerTheme = ReaderTheme.light);
                            setSheetState(() {});
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildThemeOption(
                          label: 'Sepia',
                          icon: Icons.auto_stories_outlined,
                          theme: ReaderTheme.sepia,
                          bgColor: const Color(0xFFF7EED9),
                          fgColor: const Color(0xFF382C1E),
                          isSelected: _readerTheme == ReaderTheme.sepia,
                          onTap: () {
                            setState(() => _readerTheme = ReaderTheme.sepia);
                            setSheetState(() {});
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildThemeOption(
                          label: 'Oscuro',
                          icon: Icons.dark_mode_outlined,
                          theme: ReaderTheme.dark,
                          bgColor: const Color(0xFF141416),
                          fgColor: Colors.white,
                          isSelected: _readerTheme == ReaderTheme.dark,
                          onTap: () {
                            setState(() => _readerTheme = ReaderTheme.dark);
                            setSheetState(() {});
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Tamaño de Fuente
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tamaño de Letra',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: themeColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _fontSize > 13.0
                                  ? () {
                                      setState(() => _fontSize = (_fontSize - 1.0).clamp(13.0, 26.0));
                                      setSheetState(() {});
                                    }
                                  : null,
                              icon: const Icon(Icons.text_decrease_rounded, size: 20),
                              color: themeColors.textPrimary,
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 44),
                              alignment: Alignment.center,
                              child: Text(
                                '${_fontSize.toInt()} pt',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: themeColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _fontSize < 26.0
                                  ? () {
                                      setState(() => _fontSize = (_fontSize + 1.0).clamp(13.0, 26.0));
                                      setSheetState(() {});
                                    }
                                  : null,
                              icon: const Icon(Icons.text_increase_rounded, size: 20),
                              color: themeColors.textPrimary,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Tipografía
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tipografía',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: themeColors.textPrimary,
                          ),
                        ),
                        DropdownButton<String>(
                          value: _fontFamily,
                          underline: const SizedBox(),
                          dropdownColor: themeColors.sheetBg,
                          style: TextStyle(color: themeColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                          items: const [
                            DropdownMenuItem(value: 'Lora', child: Text('Lora (Serif)')),
                            DropdownMenuItem(value: 'Merriweather', child: Text('Merriweather')),
                            DropdownMenuItem(value: 'EB Garamond', child: Text('Garamond')),
                            DropdownMenuItem(value: 'Inter', child: Text('Inter (Sans)')),
                            DropdownMenuItem(value: 'Cinzel', child: Text('Cinzel')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _fontFamily = val);
                              setSheetState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required ReaderTheme theme,
    required Color bgColor,
    required Color fgColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? fgColor : fgColor.withValues(alpha: 0.15),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: fgColor),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTableOfContents(BuildContext context, List<ChapterModel> chapters) {
    final themeColors = _resolveColors();
    showModalBottomSheet(
      context: context,
      backgroundColor: themeColors.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: themeColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Índice del Manuscrito',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: themeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${chapters.length} capítulos en secuencia',
                  style: TextStyle(fontSize: 12, color: themeColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: chapters.length,
                    separatorBuilder: (_, _) => Divider(color: themeColors.divider, height: 1),
                    itemBuilder: (context, idx) {
                      final ch = chapters[idx];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        leading: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: themeColors.accentBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${ch.chapterNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: themeColors.textPrimary,
                            ),
                          ),
                        ),
                        title: Text(
                          ch.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: themeColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${ch.wordCount} palabras • ${ch.readingTimeMinutes} min',
                          style: TextStyle(fontSize: 11.5, color: themeColors.textSecondary),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: themeColors.textSecondary),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _scrollToChapter(idx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _ReaderColors _resolveColors() {
    switch (_readerTheme) {
      case ReaderTheme.light:
        return _ReaderColors(
          bg: const Color(0xFFFAFAFA),
          sheetBg: Colors.white,
          textPrimary: const Color(0xFF18181B),
          textSecondary: const Color(0xFF71717A),
          borderSubtle: const Color(0xFFE4E4E7),
          divider: const Color(0xFFEEEEEE),
          accentBg: Colors.black.withValues(alpha: 0.05),
        );
      case ReaderTheme.sepia:
        return _ReaderColors(
          bg: const Color(0xFFFBF0D9),
          sheetBg: const Color(0xFFF4E5C7),
          textPrimary: const Color(0xFF382C1E),
          textSecondary: const Color(0xFF7A6854),
          borderSubtle: const Color(0xFFDECDB1),
          divider: const Color(0xFFE5D7BE),
          accentBg: const Color(0xFF382C1E).withValues(alpha: 0.08),
        );
      case ReaderTheme.dark:
        return _ReaderColors(
          bg: const Color(0xFF131315),
          sheetBg: const Color(0xFF1C1C1F),
          textPrimary: const Color(0xFFF4F4F5),
          textSecondary: const Color(0xFFA1A1AA),
          borderSubtle: const Color(0xFF27272A),
          divider: const Color(0xFF27272A),
          accentBg: Colors.white.withValues(alpha: 0.08),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final BookModel book = controller.activeBook;
    final chapters = book.chapters;
    final colors = _resolveColors();
    final bodyStyle = _getBodyTextStyle(colors.textPrimary);

    return Scaffold(
      backgroundColor: colors.bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Contenido continuo del Manuscrito
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: _showControls ? 80 : 40),
                ),

                // Portada / Cabecera del libro en modo lectura
                SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 720),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: colors.accentBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(book.coverEmoji, style: const TextStyle(fontSize: 34)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            book.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (book.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              book.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            '${chapters.length} capítulos • ${book.currentWordCount} palabras • ~${(book.currentWordCount / 200).ceil()} min de lectura',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: 80,
                            height: 1.5,
                            color: colors.textSecondary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ),
                ),

                // Lista de capítulos en cascada
                if (chapters.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'El manuscrito no tiene capítulos aún.',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final chapter = chapters[index];
                        final isLast = index == chapters.length - 1;
                        final chapterKey = _chapterKeys.putIfAbsent(index, () => GlobalKey());

                        return Center(
                          key: chapterKey,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 720),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cabecera de Capítulo
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'CAPÍTULO ${chapter.chapterNumber}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.5,
                                              color: colors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            chapter.title,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.4,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Editar capítulo',
                                      icon: Icon(Icons.edit_note_rounded, size: 20, color: colors.textSecondary),
                                      onPressed: () {
                                        controller.selectChapter(chapter);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Texto del capítulo
                                _buildFormattedContent(chapter.content, bodyStyle, colors),

                                const SizedBox(height: 40),

                                // Separador entre capítulos o fin
                                if (!isLast)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(width: 40, height: 1, color: colors.borderSubtle),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14),
                                            child: Text(
                                              '❦',
                                              style: TextStyle(color: colors.textSecondary, fontSize: 14),
                                            ),
                                          ),
                                          Container(width: 40, height: 1, color: colors.borderSubtle),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 50),
                                      child: Column(
                                        children: [
                                          Icon(Icons.check_circle_outline_rounded, size: 32, color: colors.textSecondary),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Fin del Manuscrito',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: colors.textPrimary,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${book.currentWordCount} palabras en total',
                                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: chapters.length,
                      addAutomaticKeepAlives: true,
                      addRepaintBoundaries: true,
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 90),
                ),
              ],
            ),

            // Barra Superior de Controles (con fade in/out)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              top: _showControls ? 0 : -85,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 6,
                  bottom: 8,
                  left: 12,
                  right: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.sheetBg.withValues(alpha: 0.94),
                  border: Border(bottom: BorderSide(color: colors.borderSubtle)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            book.title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          ValueListenableBuilder<double>(
                            valueListenable: _scrollProgressNotifier,
                            builder: (_, progress, _) => Text(
                              'Modo Lectura • ${(progress * 100).toInt()}% leído',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Índice de Capítulos',
                      icon: Icon(Icons.format_list_bulleted_rounded, color: colors.textPrimary),
                      onPressed: () => _showTableOfContents(context, chapters),
                    ),
                    IconButton(
                      tooltip: 'Ajustes de Lectura',
                      icon: Icon(Icons.tune_rounded, color: colors.textPrimary),
                      onPressed: () => _showAppearanceSheet(context),
                    ),
                  ],
                ),
              ),
            ),

            // Barra delgada de progreso de lectura (siempre visible arriba)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _scrollProgressNotifier,
                builder: (_, progress, _) => LinearProgressIndicator(
                  value: progress,
                  minHeight: 2.5,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colors.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),

            // Barra Inferior de Estado (ocultable)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              bottom: _showControls ? 0 : -60,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                  top: 8,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  color: colors.sheetBg.withValues(alpha: 0.94),
                  border: Border(top: BorderSide(color: colors.borderSubtle)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ValueListenableBuilder<double>(
                      valueListenable: _scrollProgressNotifier,
                      builder: (_, progress, _) => Text(
                        'Progreso general: ${(progress * 100).toInt()}%',
                        style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${book.currentWordCount} palabras',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedContent(String content, TextStyle bodyStyle, _ReaderColors colors) {
    if (content.trim().isEmpty) {
      return Text(
        'Este capítulo está vacío por ahora...',
        style: bodyStyle.copyWith(fontStyle: FontStyle.italic, color: colors.textSecondary),
      );
    }

    final paragraphs = content.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((p) {
        final text = p.trim();
        if (text.isEmpty) return const SizedBox.shrink();

        // Encabezados Markdown
        if (text.startsWith('# ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Text(
              text.substring(2).trim(),
              style: bodyStyle.copyWith(fontSize: _fontSize * 1.35, fontWeight: FontWeight.w800),
            ),
          );
        } else if (text.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 6),
            child: Text(
              text.substring(3).trim(),
              style: bodyStyle.copyWith(fontSize: _fontSize * 1.2, fontWeight: FontWeight.w700),
            ),
          );
        } else if (text.startsWith('### ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              text.substring(4).trim(),
              style: bodyStyle.copyWith(fontSize: _fontSize * 1.08, fontWeight: FontWeight.w700),
            ),
          );
        } else if (text.startsWith('> ')) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: colors.textPrimary.withValues(alpha: 0.4), width: 3)),
            ),
            child: Text(
              text.substring(2).trim(),
              style: bodyStyle.copyWith(fontStyle: FontStyle.italic, color: colors.textPrimary.withValues(alpha: 0.9)),
            ),
          );
        }

        // Párrafo normal
        final cleanText = text.replaceAll(RegExp(r'[*_~`]+'), '');
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            cleanText,
            style: bodyStyle,
          ),
        );
      }).toList(),
    );
  }
}

class _ReaderColors {
  final Color bg;
  final Color sheetBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderSubtle;
  final Color divider;
  final Color accentBg;

  _ReaderColors({
    required this.bg,
    required this.sheetBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderSubtle,
    required this.divider,
    required this.accentBg,
  });
}
