import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../controllers/editor_controller.dart';
import '../../models/chapter_model.dart';
import '../../models/book_compilation_config_model.dart';
import '../../services/export_service.dart';

class BookCompilerModal extends StatefulWidget {
  final EditorController controller;
  final bool isDark;

  const BookCompilerModal({
    super.key,
    required this.controller,
    required this.isDark,
  });

  /// Abre el compilador como una pantalla completa dedicada
  static Future<void> show(BuildContext context, EditorController controller, bool isDark) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookCompilerModal(controller: controller, isDark: isDark),
      ),
    );
  }

  @override
  State<BookCompilerModal> createState() => _BookCompilerModalState();
}

class _BookCompilerModalState extends State<BookCompilerModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey _coverKey = GlobalKey();

  // Controllers
  late TextEditingController _titleCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _dedicationCtrl;
  late TextEditingController _copyrightCtrl;
  late TextEditingController _authorBioCtrl;
  late TextEditingController _authorSocialsCtrl;
  late TextEditingController _acknowledgmentsCtrl;
  late TextEditingController _customSceneSepCtrl;

  // Cover settings
  late int _bgColorHex;
  late int _textColorHex;
  late String _fontFamily;
  late CoverTextPosition _textPosition;
  String? _imagePath;
  int _coverSectionIndex = 0; // 0: Textos & Títulos, 1: Fondo & Imagen, 2: Tipografía & Posición

  // Editorial settings
  late EditorialPreset _preset;
  late String _sceneSeparator;

  // Compilation settings
  late bool _includeToc;
  late Map<String, String> _customChapterTitles;
  late Set<String> _excludedChapterIds;
  late List<String> _orderedChapterIds;

  bool _isExporting = false;
  bool _isExportingCover = false;
  String? _currentlyExportingFormat;

  final List<String> _fonts = [
    'Playfair Display',
    'Cinzel',
    'Merriweather',
    'Lora',
    'Oswald',
    'Roboto',
  ];

  final List<Map<String, dynamic>> _presetPalettes = [
    {'name': 'Carbón', 'bg': 0xFF18181B, 'text': 0xFFF4F4F5},
    {'name': 'Borgoña', 'bg': 0xFF4A0E17, 'text': 0xFFFEF08A},
    {'name': 'Medianoche', 'bg': 0xFF0F172A, 'text': 0xFFE2E8F0},
    {'name': 'Bosque', 'bg': 0xFF14342B, 'text': 0xFFFEF9C3},
    {'name': 'Imperial', 'bg': 0xFF2E1065, 'text': 0xFFF5D0FE},
    {'name': 'Papiro', 'bg': 0xFFF5EBE1, 'text': 0xFF292524},
    {'name': 'Dorado', 'bg': 0xFF422006, 'text': 0xFFFEF08A},
  ];

  final List<String> _quickSceneSeparators = [
    '* * *',
    '# # #',
    '~ * ~',
    '— · —',
    '***',
    '---',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    final book = widget.controller.activeBook;
    final config = book.compilationConfig ??
        BookCompilationConfig(
          cover: BookCoverConfig(
            title: book.title,
            author: 'Autor de la Obra',
            subtitle: book.subtitle,
          ),
          copyrightNotice: '© ${DateTime.now().year} ${book.title}. Todos los derechos reservados.',
        );

    _titleCtrl = TextEditingController(text: config.cover.title.isNotEmpty ? config.cover.title : book.title);
    _subtitleCtrl = TextEditingController(text: config.cover.subtitle.isNotEmpty ? config.cover.subtitle : book.subtitle);
    _authorCtrl = TextEditingController(text: config.cover.author.isNotEmpty ? config.cover.author : 'Autor de la Obra');
    _dedicationCtrl = TextEditingController(text: config.dedication);
    _copyrightCtrl = TextEditingController(
      text: config.copyrightNotice.isNotEmpty
          ? config.copyrightNotice
          : '© ${DateTime.now().year} ${book.title}. Todos los derechos reservados.',
    );
    _authorBioCtrl = TextEditingController(text: config.authorBio);
    _authorSocialsCtrl = TextEditingController(text: config.authorSocials);
    _acknowledgmentsCtrl = TextEditingController(text: config.acknowledgments);
    _customSceneSepCtrl = TextEditingController(text: config.sceneSeparator);

    _bgColorHex = config.cover.backgroundColorHex;
    _textColorHex = config.cover.textColorHex;
    _fontFamily = config.cover.fontFamily;
    _textPosition = config.cover.textPosition;
    _imagePath = config.cover.imagePath;

    _preset = config.preset;
    _sceneSeparator = config.sceneSeparator.isNotEmpty ? config.sceneSeparator : '* * *';

    _includeToc = config.includeTableOfContents;
    _customChapterTitles = Map<String, String>.from(config.customChapterTitles);
    _excludedChapterIds = Set<String>.from(config.excludedChapterIds);

    // Initialize ordered chapter IDs
    final existingOrder = config.orderedChapterIds;
    final bookChapterIds = book.chapters.map((c) => c.id).toList();
    final initialOrdered = existingOrder.where((id) => bookChapterIds.contains(id)).toList();
    for (final id in bookChapterIds) {
      if (!initialOrdered.contains(id)) {
        initialOrdered.add(id);
      }
    }
    _orderedChapterIds = initialOrdered;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _authorCtrl.dispose();
    _dedicationCtrl.dispose();
    _copyrightCtrl.dispose();
    _authorBioCtrl.dispose();
    _authorSocialsCtrl.dispose();
    _acknowledgmentsCtrl.dispose();
    _customSceneSepCtrl.dispose();
    super.dispose();
  }

  void _moveChapter(int fromIndex, int delta) {
    final toIndex = fromIndex + delta;
    if (toIndex < 0 || toIndex >= _orderedChapterIds.length) return;
    setState(() {
      final item = _orderedChapterIds.removeAt(fromIndex);
      _orderedChapterIds.insert(toIndex, item);
    });
  }

  void _saveConfig() {
    final updated = BookCompilationConfig(
      cover: BookCoverConfig(
        title: _titleCtrl.text.trim(),
        author: _authorCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim(),
        imagePath: _imagePath,
        backgroundColorHex: _bgColorHex,
        textColorHex: _textColorHex,
        fontFamily: _fontFamily,
        textPosition: _textPosition,
      ),
      dedication: _dedicationCtrl.text.trim(),
      copyrightNotice: _copyrightCtrl.text.trim(),
      includeTableOfContents: _includeToc,
      customChapterTitles: _customChapterTitles,
      excludedChapterIds: _excludedChapterIds.toList(),
      orderedChapterIds: _orderedChapterIds,
      preset: _preset,
      sceneSeparator: _sceneSeparator.trim().isNotEmpty ? _sceneSeparator.trim() : '* * *',
      authorBio: _authorBioCtrl.text.trim(),
      acknowledgments: _acknowledgmentsCtrl.text.trim(),
      authorSocials: _authorSocialsCtrl.text.trim(),
    );
    widget.controller.updateCompilationConfig(updated);
  }

  Future<void> _exportCoverAsPng() async {
    _saveConfig();
    setState(() => _isExportingCover = true);
    try {
      final boundary = _coverKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('El contenedor de vista previa no está listo');
      }
      final image = await boundary.toImage(pixelRatio: 3.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('No se pudo procesar la imagen PNG');
      }
      final pngBytes = byteData.buffer.asUint8List();
      final baseFilename = widget.controller.activeBook.title.replaceAll(' ', '_').toLowerCase();
      final filename = '${baseFilename}_portada_hd.png';

      final xFile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: filename,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          fileNameOverrides: [filename],
          subject: 'Portada HD - ${widget.controller.activeBook.title}',
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portada PNG HD lista para compartir o descargar.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar portada: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingCover = false);
    }
  }

  Future<void> _exportCompiled(String format) async {
    _saveConfig();
    setState(() {
      _isExporting = true;
      _currentlyExportingFormat = format;
    });

    try {
      final book = widget.controller.activeBook;
      final config = book.compilationConfig!;
      final baseFilename = book.title.replaceAll(' ', '_').toLowerCase();

      if (format == 'pdf') {
        final pdfBytes = await ExportService.generatePdf(
          book,
          characters: widget.controller.characters,
          codexEntries: widget.controller.codexEntries,
          compilationConfig: config,
        );
        if (mounted) {
          await Printing.layoutPdf(name: baseFilename, onLayout: (_) async => pdfBytes);
        }
      } else if (format == 'docx') {
        final docxBytes = ExportService.generateDocx(
          book,
          characters: widget.controller.characters,
          codexEntries: widget.controller.codexEntries,
          compilationConfig: config,
        );
        final xFile = XFile.fromData(
          Uint8List.fromList(docxBytes),
          mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          name: '$baseFilename.docx',
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            fileNameOverrides: ['$baseFilename.docx'],
            subject: book.title,
          ),
        );
      } else if (format == 'epub') {
        final epubBytes = ExportService.generateEpub(
          book,
          characters: widget.controller.characters,
          codexEntries: widget.controller.codexEntries,
          compilationConfig: config,
        );
        final xFile = XFile.fromData(
          Uint8List.fromList(epubBytes),
          mimeType: 'application/epub+zip',
          name: '$baseFilename.epub',
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            fileNameOverrides: ['$baseFilename.epub'],
            subject: book.title,
          ),
        );
      } else if (format == 'txt') {
        final rawText = ExportService.exportRawText(
          book,
          includeChapterHeaders: true,
          compilationConfig: config,
        );
        await Clipboard.setData(ClipboardData(text: rawText));
        final xFile = XFile.fromData(
          Uint8List.fromList(utf8.encode(rawText)),
          mimeType: 'text/plain',
          name: '$baseFilename.txt',
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            fileNameOverrides: ['$baseFilename.txt'],
            subject: book.title,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Compilación ${format.toUpperCase()} generada con éxito.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compilar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _currentlyExportingFormat = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgScaffold = isDark ? const Color(0xFF101012) : const Color(0xFFF8F9FA);
    final bgCard = isDark ? const Color(0xFF18181B) : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _saveConfig();
      },
      child: Scaffold(
        backgroundColor: bgScaffold,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: bgCard,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
            tooltip: 'Volver al editor',
            onPressed: () {
              _saveConfig();
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            'Compilador Profesional',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Guardar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                onPressed: () {
                  _saveConfig();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Configuración guardada.'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderSubtle)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: textPrimary,
                indicatorWeight: 2.5,
                labelColor: textPrimary,
                unselectedLabelColor: textSecondary,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(icon: Icon(Icons.palette_outlined, size: 17), text: 'Portada'),
                  Tab(icon: Icon(Icons.format_list_numbered_rounded, size: 17), text: 'Capítulos'),
                  Tab(icon: Icon(Icons.bookmark_border_rounded, size: 17), text: 'Amenidades'),
                  Tab(icon: Icon(Icons.tune_rounded, size: 17), text: 'Maquetación'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCoverTab(isDark, textPrimary, textSecondary, borderSubtle, bgCard),
            _buildChaptersTab(isDark, textPrimary, textSecondary, borderSubtle, bgCard),
            _buildAmenitiesTab(isDark, textPrimary, textSecondary, borderSubtle, bgCard),
            _buildLayoutTab(isDark, textPrimary, textSecondary, borderSubtle, bgCard),
          ],
        ),
        bottomNavigationBar: _buildExportBottomBar(isDark, textPrimary, textSecondary, borderSubtle, bgCard),
      ),
    );
  }

  // =========================================================================
  // --- SECCIÓN 1: PORTADA EXCLUSIVA (DISEÑO VISUAL Y ASSETS) ---
  // =========================================================================
  Widget _buildCoverTab(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderSubtle,
    Color bgCard,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Cover Preview Box (Capturable para exportar PNG HD)
          Center(
            child: RepaintBoundary(
              key: _coverKey,
              child: Container(
                width: 195,
                height: 285,
                decoration: BoxDecoration(
                  color: Color(_bgColorHex),
                  image: _imagePath != null && File(_imagePath!).existsSync()
                      ? DecorationImage(
                          image: FileImage(File(_imagePath!)),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.4),
                            BlendMode.darken,
                          ),
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(4, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: Column(
                  mainAxisAlignment: _getAlignmentFromPosition(_textPosition),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _titleCtrl.text.isEmpty ? 'TÍTULO DE LA OBRA' : _titleCtrl.text.toUpperCase(),
                      style: TextStyle(
                        color: Color(_textColorHex),
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontFamily: _fontFamily,
                        height: 1.25,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_subtitleCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _subtitleCtrl.text,
                        style: TextStyle(
                          color: Color(_textColorHex).withValues(alpha: 0.85),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          fontFamily: _fontFamily,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      width: 36,
                      height: 1.2,
                      color: Color(_textColorHex).withValues(alpha: 0.55),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _authorCtrl.text.isEmpty ? 'NOMBRE DEL AUTOR' : _authorCtrl.text,
                      style: TextStyle(
                        color: Color(_textColorHex),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.9,
                        fontFamily: _fontFamily,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Botón Descargar Portada HD
          Center(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                side: BorderSide(color: borderSubtle),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isExportingCover
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded, size: 17),
              label: const Text(
                'Descargar Portada HD (.png)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              onPressed: _isExportingCover ? null : _exportCoverAsPng,
            ),
          ),

          const SizedBox(height: 18),

          // Selector de espacio estilo editor de fotos
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFEFEFF2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderSubtle),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildSegmentButton(0, Icons.edit_note_rounded, 'Textos', textPrimary, isDark),
                _buildSegmentButton(1, Icons.palette_outlined, 'Fondo', textPrimary, isDark),
                _buildSegmentButton(2, Icons.format_paint_outlined, 'Estilo', textPrimary, isDark),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Espacio seleccionado
          if (_coverSectionIndex == 0)
            _buildCardContainer(
              bgCard: bgCard,
              borderSubtle: borderSubtle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleCtrl,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Título de la Obra',
                      prefixIcon: const Icon(Icons.book_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subtitleCtrl,
                    style: TextStyle(fontSize: 13, color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Subtítulo (opcional)',
                      prefixIcon: const Icon(Icons.short_text_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _authorCtrl,
                    style: TextStyle(fontSize: 13, color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Nombre del Autor o Seudónimo',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            )
          else if (_coverSectionIndex == 1)
            _buildCardContainer(
              bgCard: bgCard,
              borderSubtle: borderSubtle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderSubtle),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: Text(
                            _imagePath != null ? 'Cambiar Imagen de Fondo' : 'Cargar Imagen de Fondo',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () async {
                            final res = await FilePicker.platform.pickFiles(type: FileType.image);
                            if (res != null && res.files.single.path != null) {
                              setState(() {
                                _imagePath = res.files.single.path;
                              });
                            }
                          },
                        ),
                      ),
                      if (_imagePath != null) ...[
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          tooltip: 'Quitar imagen de portada',
                          style: IconButton.styleFrom(
                            side: BorderSide(color: borderSubtle),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 19),
                          onPressed: () => setState(() => _imagePath = null),
                        ),
                      ],
                    ],
                  ),
                  if (_imagePath != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _imagePath!.split(Platform.pathSeparator).last,
                      style: TextStyle(fontSize: 11, color: textSecondary, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Color de Fondo',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetPalettes.map((p) {
                      final isSel = _bgColorHex == p['bg'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _bgColorHex = p['bg'];
                            _textColorHex = p['text'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Color(p['bg']),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? (isDark ? Colors.white : Colors.black) : Colors.white24,
                              width: isSel ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            p['name'],
                            style: TextStyle(
                              color: Color(p['text']),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Tono del Texto:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(width: 10),
                      _buildTextColorCircle(0xFFF4F4F5, 'Blanco Marfil'),
                      const SizedBox(width: 8),
                      _buildTextColorCircle(0xFFFEF08A, 'Dorado Editorial'),
                      const SizedBox(width: 8),
                      _buildTextColorCircle(0xFF09090B, 'Negro Carbón'),
                    ],
                  ),
                ],
              ),
            )
          else
            _buildCardContainer(
              bgCard: bgCard,
              borderSubtle: borderSubtle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _fontFamily,
                    decoration: InputDecoration(
                      labelText: 'Tipografía',
                      prefixIcon: const Icon(Icons.text_fields_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: _fonts
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f, style: TextStyle(fontSize: 12.5, color: textPrimary)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _fontFamily = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Posición del Texto',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPositionChip(CoverTextPosition.top, 'Superior', Icons.vertical_align_top_rounded, textPrimary, borderSubtle, isDark),
                      const SizedBox(width: 8),
                      _buildPositionChip(CoverTextPosition.center, 'Centro', Icons.vertical_align_center_rounded, textPrimary, borderSubtle, isDark),
                      const SizedBox(width: 8),
                      _buildPositionChip(CoverTextPosition.bottom, 'Inferior', Icons.vertical_align_bottom_rounded, textPrimary, borderSubtle, isDark),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =========================================================================
  // --- SECCIÓN 2: CAPÍTULOS DE LA OBRA ---
  // =========================================================================
  Widget _buildChaptersTab(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderSubtle,
    Color bgCard,
  ) {
    final book = widget.controller.activeBook;
    final chaptersMap = {for (final ch in book.chapters) ch.id: ch};
    final orderedChapters = _orderedChapterIds
        .map((id) => chaptersMap[id])
        .whereType<ChapterModel>()
        .toList();
    for (final ch in book.chapters) {
      if (!orderedChapters.contains(ch)) {
        orderedChapters.add(ch);
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardContainer(
            bgCard: bgCard,
            borderSubtle: borderSubtle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Capítulos',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    Text(
                      '${orderedChapters.length} capítulos',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ...orderedChapters.asMap().entries.map((entry) {
                  final ch = entry.value;
                  final isExcluded = _excludedChapterIds.contains(ch.id);
                  final customTitle = _customChapterTitles[ch.id] ?? ch.title;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Row(
                      children: [
                        // Checkbox para incluir o excluir
                        Checkbox(
                          value: !isExcluded,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _excludedChapterIds.remove(ch.id);
                              } else {
                                _excludedChapterIds.add(ch.id);
                              }
                            });
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ch.chapterType == ChapterType.prologue
                                    ? 'Prólogo'
                                    : (ch.chapterType == ChapterType.epilogue
                                        ? 'Epílogo'
                                        : 'Capítulo ${ch.chapterNumber}'),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: textSecondary,
                                ),
                              ),
                              Text(
                                customTitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isExcluded ? textSecondary.withValues(alpha: 0.4) : textPrimary,
                                  decoration: isExcluded ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_note_rounded, size: 20, color: textSecondary),
                          tooltip: 'Editar título para publicación',
                          onPressed: () {
                            final editCtrl = TextEditingController(text: customTitle);
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
                                title: Text('Editar Título Compilado', style: TextStyle(fontSize: 15, color: textPrimary)),
                                content: TextField(
                                  controller: editCtrl,
                                  autofocus: true,
                                  style: TextStyle(color: textPrimary),
                                  decoration: const InputDecoration(
                                    labelText: 'Título para el libro compilado',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: Text('Cancelar', style: TextStyle(color: textSecondary)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _customChapterTitles[ch.id] = editCtrl.text.trim();
                                      });
                                      Navigator.of(ctx).pop();
                                    },
                                    child: const Text('Guardar'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =========================================================================
  // --- SECCIÓN 3: RESTO DE AMENIDADES (CONTENIDO EDITORIAL) ---
  // =========================================================================
  Widget _buildAmenitiesTab(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderSubtle,
    Color bgCard,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta: Dedicatoria
          _buildCardContainer(
            bgCard: bgCard,
            borderSubtle: borderSubtle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_border_rounded, size: 18, color: textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Dedicatoria de la Obra',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _dedicationCtrl,
                  maxLines: 3,
                  style: TextStyle(fontSize: 13, color: textPrimary, fontStyle: FontStyle.italic),
                  decoration: InputDecoration(
                    hintText: 'ej. Para aquellos que buscan la luz en la oscuridad...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tarjeta: Copyright
          _buildCardContainer(
            bgCard: bgCard,
            borderSubtle: borderSubtle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.copyright_rounded, size: 18, color: textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Página de Derechos y Créditos (Copyright)',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _copyrightCtrl,
                  maxLines: 2,
                  style: TextStyle(fontSize: 12, color: textPrimary),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tarjeta: Biografía del Autor
          _buildCardContainer(
            bgCard: bgCard,
            borderSubtle: borderSubtle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history_edu_rounded, size: 18, color: textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Biografía del Autor',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _authorBioCtrl,
                  maxLines: 4,
                  style: TextStyle(fontSize: 12.5, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'ej. Nació en una noche de tormenta y desde entonces escribe historias sobre mundos olvidados...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tarjeta: Redes y Enlaces
          _buildCardContainer(
            bgCard: bgCard,
            borderSubtle: borderSubtle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.link_rounded, size: 18, color: textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Redes y Enlaces de Contacto',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _authorSocialsCtrl,
                  style: TextStyle(fontSize: 12.5, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'ej. @autor_fantasia • www.autor.com • wattpad.com/user/autor',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tarjeta: Agradecimientos
          _buildCardContainer(
            bgCard: bgCard,
            borderSubtle: borderSubtle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.handshake_outlined, size: 18, color: textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Página de Agradecimientos',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _acknowledgmentsCtrl,
                  maxLines: 4,
                  style: TextStyle(fontSize: 12.5, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'ej. Gracias a mis primeros lectores por no dejarme rendir en el camino...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =========================================================================
  // --- SECCIÓN 4: MAQUETACIÓN Y FORMATO ---
  // =========================================================================
  Widget _buildLayoutTab(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderSubtle,
    Color bgCard,
  ) {
    final totalWords = widget.controller.activeBook.currentWordCount;
    final estPages = (totalWords / 260).ceil() + 4;
    final readMinutes = (totalWords / 220).ceil();
    final readHours = readMinutes ~/ 60;
    final readMinsRemainder = readMinutes % 60;
    final readTimeString = readHours > 0 ? '${readHours}h ${readMinsRemainder}m' : '${readMinutes}m';

    final chaptersMap = {for (final ch in widget.controller.activeBook.chapters) ch.id: ch};
    final orderedChapters = _orderedChapterIds
        .map((id) => chaptersMap[id])
        .whereType<ChapterModel>()
        .toList();
    for (final ch in widget.controller.activeBook.chapters) {
      if (!orderedChapters.contains(ch)) {
        orderedChapters.add(ch);
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de Estimación Física
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderSubtle),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_stories_rounded, size: 22, color: textPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimación física: ~$estPages págs. (formato 6"×9")',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '⏱️ ~$readTimeString de lectura estimada  •  $totalWords palabras totales',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Presets de Maquetación
          Text(
            'Presets de Maquetación Editorial',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 12),

          _buildPresetCard(
            preset: EditorialPreset.classic,
            title: 'Clásica / Novela Tradicional',
            subtitle: 'Tipografía serif clásica (Lora/Georgia), sangría francesa (1.5em) y saltos florales centrados. Estilo estándar en editoriales de narrativa y ficción.',
            icon: Icons.history_edu_rounded,
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            borderSubtle: borderSubtle,
          ),
          const SizedBox(height: 10),

          _buildPresetCard(
            preset: EditorialPreset.modern,
            title: 'Moderna / Minimalista',
            subtitle: 'Tipografía limpia sin serifa (Sans-Serif), espaciado de bloque entre párrafos sin sangría. Ideal para no-ficción, ensayo, sci-fi y publicación web.',
            icon: Icons.auto_awesome_rounded,
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            borderSubtle: borderSubtle,
          ),
          const SizedBox(height: 10),

          _buildPresetCard(
            preset: EditorialPreset.manuscriptSubmission,
            title: 'Envío Editorial / Concurso',
            subtitle: 'Formato estándar de manuscrito (Courier/monoespaciada, interlineado doble amplio, márgenes uniformes) para certámenes literarios y agencias.',
            icon: Icons.article_rounded,
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            borderSubtle: borderSubtle,
          ),

          const SizedBox(height: 20),

          // Separador de Escenas
          _buildCardContainer(
            bgCard: bgCard,
            borderSubtle: borderSubtle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Separador de Escenas en Capítulos',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickSceneSeparators.map((sep) {
                    final isSel = _sceneSeparator == sep;
                    return ChoiceChip(
                      label: Text(
                        sep,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSel ? (isDark ? Colors.black : Colors.white) : textPrimary,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: isDark ? Colors.white : Colors.black,
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _sceneSeparator = sep;
                            _customSceneSepCtrl.text = sep;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customSceneSepCtrl,
                  style: TextStyle(fontSize: 13, color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Separador Personalizado',
                    hintText: 'ej. ~ * ~ o * * *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_rounded, size: 18),
                      onPressed: () {
                        final text = _customSceneSepCtrl.text.trim();
                        if (text.isNotEmpty) {
                          setState(() => _sceneSeparator = text);
                        }
                      },
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _sceneSeparator = val.trim());
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tabla de Contenidos (Índice / TOC)
          _buildCardContainer(
            bgCard: bgCard,
            borderSubtle: borderSubtle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tabla de Contenidos (Índice)',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    Switch(
                      value: _includeToc,
                      onChanged: (val) => setState(() => _includeToc = val),
                    ),
                  ],
                ),
                if (_includeToc) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Orden de lectura:',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ...orderedChapters.asMap().entries.map((entry) {
                    final index = entry.key;
                    final ch = entry.value;
                    final customTitle = _customChapterTitles[ch.id] ?? ch.title;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${index + 1}.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              customTitle,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: index > 0 ? () => _moveChapter(index, -1) : null,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.keyboard_arrow_up_rounded,
                                size: 18,
                                color: index > 0 ? textPrimary : textSecondary.withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: index < orderedChapters.length - 1 ? () => _moveChapter(index, 1) : null,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: index < orderedChapters.length - 1 ? textPrimary : textSecondary.withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =========================================================================
  // --- BOTTOM BAR: BOTONES DE EXPORTACIÓN CONSISTENTES Y ARMONIOSOS ---
  // =========================================================================
  Widget _buildExportBottomBar(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderSubtle,
    Color bgCard,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        border: Border(top: BorderSide(color: borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila de encabezado de exportación
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.ios_share_rounded, size: 15, color: textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Formatos de Publicación',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  if (_isExporting)
                    Row(
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Compilando ${_currentlyExportingFormat?.toUpperCase()}...',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // Botones de Exportación: Uniformes en tamaño, proporciones y estilo armónico
              Row(
                children: [
                  // 1. PDF
                  Expanded(
                    child: _buildExportButton(
                      label: 'PDF',
                      format: 'pdf',
                      icon: Icons.picture_as_pdf_rounded,
                      accentColor: textPrimary,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      borderSubtle: borderSubtle,
                      onTap: () => _exportCompiled('pdf'),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Word DOCX
                  Expanded(
                    child: _buildExportButton(
                      label: 'DOCX',
                      format: 'docx',
                      icon: Icons.description_rounded,
                      accentColor: textPrimary,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      borderSubtle: borderSubtle,
                      onTap: () => _exportCompiled('docx'),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. EPUB
                  Expanded(
                    child: _buildExportButton(
                      label: 'EPUB',
                      format: 'epub',
                      icon: Icons.menu_book_rounded,
                      accentColor: textPrimary,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      borderSubtle: borderSubtle,
                      onTap: () => _exportCompiled('epub'),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 4. Texto Plano
                  Expanded(
                    child: _buildExportButton(
                      label: 'TXT',
                      format: 'txt',
                      icon: Icons.text_snippet_rounded,
                      accentColor: textPrimary,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      borderSubtle: borderSubtle,
                      onTap: () => _exportCompiled('txt'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required String label,
    required String format,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required Color textPrimary,
    required Color borderSubtle,
    required VoidCallback onTap,
  }) {
    final isCurrent = _isExporting && _currentlyExportingFormat == format;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isExporting ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF202024) : const Color(0xFFF4F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent ? accentColor : borderSubtle,
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isCurrent)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accentColor,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 17,
                  color: accentColor,
                ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildCardContainer({
    required Widget child,
    required Color bgCard,
    required Color borderSubtle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderSubtle),
      ),
      child: child,
    );
  }

  Widget _buildSegmentButton(int index, IconData icon, String label, Color textPrimary, bool isDark) {
    final isSelected = _coverSectionIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _coverSectionIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? Colors.white12 : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? textPrimary : textPrimary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? textPrimary : textPrimary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPositionChip(
    CoverTextPosition pos,
    String label,
    IconData icon,
    Color textPrimary,
    Color borderSubtle,
    bool isDark,
  ) {
    final isSel = _textPosition == pos;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _textPosition = pos),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel
                ? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? textPrimary : borderSubtle,
              width: isSel ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSel ? textPrimary : textPrimary.withValues(alpha: 0.6)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? textPrimary : textPrimary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextColorCircle(int hex, String label) {
    final isSel = _textColorHex == hex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _textColorHex = hex),
      child: Tooltip(
        message: label,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Color(hex),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSel ? (isDark ? Colors.white : Colors.black) : Colors.grey.shade600,
              width: isSel ? 2.5 : 1,
            ),
          ),
        ),
      ),
    );
  }

  MainAxisAlignment _getAlignmentFromPosition(CoverTextPosition pos) {
    switch (pos) {
      case CoverTextPosition.top:
        return MainAxisAlignment.start;
      case CoverTextPosition.center:
        return MainAxisAlignment.center;
      case CoverTextPosition.bottom:
        return MainAxisAlignment.end;
    }
  }

  Widget _buildPresetCard({
    required EditorialPreset preset,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderSubtle,
  }) {
    final isSelected = _preset == preset;
    final activeColor = textPrimary;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _preset = preset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05))
              : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white12 : Colors.black12)
                    : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: isSelected ? activeColor : textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, size: 18, color: activeColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.35),
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
