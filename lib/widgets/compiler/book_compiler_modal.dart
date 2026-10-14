import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../controllers/editor_controller.dart';
import '../../models/book_model.dart';
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

  static void show(BuildContext context, EditorController controller, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookCompilerModal(controller: controller, isDark: isDark),
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
    setState(() => _isExporting = true);

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
            content: Text('Compilación $format generada con éxito.'),
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
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgCard = isDark ? const Color(0xFF18181B) : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 6),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.auto_stories_rounded, size: 20, color: textPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compilador Editorial y Portadas',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Maquetación integral de obra para publicación',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    _saveConfig();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),

          // Physical Format & Reading Stats Banner
          Builder(builder: (context) {
            final totalWords = widget.controller.activeBook.currentWordCount;
            final estPages = (totalWords / 260).ceil() + 4;
            final readMinutes = (totalWords / 220).ceil();
            final readHours = readMinutes ~/ 60;
            final readMinsRemainder = readMinutes % 60;
            final readTimeString = readHours > 0 ? '${readHours}h ${readMinsRemainder}m' : '${readMinutes}m';

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? Colors.amber.withValues(alpha: 0.08) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? Colors.amber.withValues(alpha: 0.25) : const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_stories_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estimación física: ~$estPages págs. (formato 6"×9")  •  ⏱️ ~$readTimeString de lectura  •  $totalWords palabras',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDark ? Colors.white24 : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: textPrimary,
                unselectedLabelColor: textSecondary,
                labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: '1. Portada'),
                  Tab(text: '2. Maquetación'),
                  Tab(text: '3. Textos & Autor'),
                  Tab(text: '4. Índice (TOC)'),
                ],
              ),
            ),
          ),

          Divider(height: 1, color: borderSubtle),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCoverTab(isDark, textPrimary, textSecondary, borderSubtle),
                _buildLayoutTab(isDark, textPrimary, textSecondary, borderSubtle),
                _buildEditorialTextsTab(isDark, textPrimary, textSecondary, borderSubtle),
                _buildTocTab(isDark, textPrimary, textSecondary, borderSubtle),
              ],
            ),
          ),

          Divider(height: 1, color: borderSubtle),

          // Bottom Compile Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: _isExporting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text('Compilar PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _isExporting ? null : () => _exportCompiled('pdf'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.description_rounded, size: 16),
                    label: const Text('Word DOCX', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _isExporting ? null : () => _exportCompiled('docx'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.book_rounded, size: 16),
                    label: const Text('EPUB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _isExporting ? null : () => _exportCompiled('epub'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF3F3F46) : const Color(0xFF52525B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.notes_rounded, size: 16),
                    label: const Text('Solo Texto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: _isExporting ? null : () => _exportCompiled('txt'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: COVER DESIGNER ---
  Widget _buildCoverTab(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderSubtle,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Cover Preview Box (Capturable for PNG HD export)
          Center(
            child: RepaintBoundary(
              key: _coverKey,
              child: Container(
                width: 180,
                height: 260,
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
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(4, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: _getAlignmentFromPosition(_textPosition),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _titleCtrl.text.isEmpty ? 'TÍTULO DE LA OBRA' : _titleCtrl.text.toUpperCase(),
                      style: TextStyle(
                        color: Color(_textColorHex),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        fontFamily: _fontFamily,
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
                          color: Color(_textColorHex).withValues(alpha: 0.8),
                          fontSize: 9.5,
                          fontStyle: FontStyle.italic,
                          fontFamily: _fontFamily,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      width: 32,
                      height: 1,
                      color: Color(_textColorHex).withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _authorCtrl.text.isEmpty ? 'NOMBRE DEL AUTOR' : _authorCtrl.text,
                      style: TextStyle(
                        color: Color(_textColorHex),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
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

          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                side: BorderSide(color: borderSubtle),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isExportingCover
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded, size: 16),
              label: const Text(
                'Descargar Portada HD (.png)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: _isExportingCover ? null : _exportCoverAsPng,
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Datos de Portada',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 10),

          // Title input
          TextField(
            controller: _titleCtrl,
            style: TextStyle(fontSize: 13, color: textPrimary),
            decoration: InputDecoration(
              labelText: 'Título en Portada',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),

          // Subtitle input
          TextField(
            controller: _subtitleCtrl,
            style: TextStyle(fontSize: 13, color: textPrimary),
            decoration: InputDecoration(
              labelText: 'Subtítulo (opcional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),

          // Author input
          TextField(
            controller: _authorCtrl,
            style: TextStyle(fontSize: 13, color: textPrimary),
            decoration: InputDecoration(
              labelText: 'Nombre del Autor',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 16),
          Text(
            'Imagen de Fondo / Ilustración',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 8),
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
                    _imagePath != null ? 'Cambiar Imagen' : 'Seleccionar Imagen',
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
                IconButton(
                  tooltip: 'Quitar imagen de portada',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    setState(() {
                      _imagePath = null;
                    });
                  },
                ),
              ],
            ],
          ),
          if (_imagePath != null) ...[
            const SizedBox(height: 6),
            Text(
              'Archivo: ${_imagePath!.split(Platform.pathSeparator).last}',
              style: TextStyle(fontSize: 11, color: textSecondary, fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 20),
          Text(
            'Tipografía y Posición',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 10),

          // Font and Position Row
          Row(
            children: [
              // Font dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _fontFamily,
                  decoration: InputDecoration(
                    labelText: 'Fuente',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _fonts.map((f) => DropdownMenuItem(value: f, child: Text(f, style: TextStyle(fontSize: 12, color: textPrimary)))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _fontFamily = val);
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Position toggle
              Expanded(
                child: DropdownButtonFormField<CoverTextPosition>(
                  value: _textPosition,
                  decoration: InputDecoration(
                    labelText: 'Posición Texto',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: CoverTextPosition.top, child: Text('Arriba', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: CoverTextPosition.center, child: Text('Centro', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: CoverTextPosition.bottom, child: Text('Abajo', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _textPosition = val);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            'Paleta y Colores RGB',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 8),

          // Preset Swatches
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(p['bg']),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSel ? Colors.amberAccent : Colors.white24,
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

          const SizedBox(height: 14),

          // RGB Sliders for Custom Background
          _buildRgbSlider(
            label: 'Rojo',
            value: ((_bgColorHex >> 16) & 0xFF).toDouble(),
            color: Colors.redAccent,
            onChanged: (v) {
              final g = (_bgColorHex >> 8) & 0xFF;
              final b = _bgColorHex & 0xFF;
              setState(() => _bgColorHex = (0xFF << 24) | (v.toInt() << 16) | (g << 8) | b);
            },
          ),
          _buildRgbSlider(
            label: 'Verde',
            value: ((_bgColorHex >> 8) & 0xFF).toDouble(),
            color: Colors.greenAccent,
            onChanged: (v) {
              final r = (_bgColorHex >> 16) & 0xFF;
              final b = _bgColorHex & 0xFF;
              setState(() => _bgColorHex = (0xFF << 24) | (r << 16) | (v.toInt() << 8) | b);
            },
          ),
          _buildRgbSlider(
            label: 'Azul',
            value: (_bgColorHex & 0xFF).toDouble(),
            color: Colors.lightBlueAccent,
            onChanged: (v) {
              final r = (_bgColorHex >> 16) & 0xFF;
              final g = (_bgColorHex >> 8) & 0xFF;
              setState(() => _bgColorHex = (0xFF << 24) | (r << 16) | (g << 8) | v.toInt());
            },
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Color de Texto: ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(width: 8),
              _buildTextColorCircle(0xFFF4F4F5, 'Blanco'),
              const SizedBox(width: 8),
              _buildTextColorCircle(0xFFFEF08A, 'Dorado'),
              const SizedBox(width: 8),
              _buildTextColorCircle(0xFF09090B, 'Negro'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRgbSlider({
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            activeColor: color,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            '${value.toInt()}',
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildTextColorCircle(int hex, String label) {
    final isSel = _textColorHex == hex;
    return GestureDetector(
      onTap: () => setState(() => _textColorHex = hex),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Color(hex),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSel ? Colors.amberAccent : Colors.grey.shade600,
            width: isSel ? 2.5 : 1,
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

  // --- TAB 2: LAYOUT & EDITORIAL PRESETS ---
  Widget _buildLayoutTab(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderSubtle,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Presets de Maquetación Editorial',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Aplica un estilo tipográfico y de composición integral para tu obra.',
            style: TextStyle(fontSize: 11.5, color: textSecondary),
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
            subtitle: 'Tipografía limpia sin serifa (Sans-Serif), espaciado de bloque entre párrafos sin sangría. Ideal para no-ficción, ensayo, sci-fi y publicación en Wattpad.',
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

          const SizedBox(height: 24),
          Divider(height: 1, color: borderSubtle),
          const SizedBox(height: 20),

          Text(
            'Separador de Escenas en Capítulos',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Símbolo impreso para indicar el paso del tiempo o cambios de punto de vista dentro de un mismo capítulo.',
            style: TextStyle(fontSize: 11.5, color: textSecondary),
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
                    color: isSel ? Colors.white : textPrimary,
                  ),
                ),
                selected: isSel,
                selectedColor: isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5),
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
              labelText: 'Separador Personalizado (o símbolo decorativo)',
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
    );
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
    final activeColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _preset = preset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF312E81).withValues(alpha: 0.35) : const Color(0xFFEEF2FF))
              : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.2)
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
                            color: isSelected ? (isDark ? Colors.white : const Color(0xFF312E81)) : textPrimary,
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

  // --- TAB 3: TEXTOS Y AUTOR ---
  Widget _buildEditorialTextsTab(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderSubtle,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dedicatoria de la Obra',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Aparecerá en una página preliminar exclusiva, centrada y en cursiva.',
            style: TextStyle(fontSize: 11.5, color: textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _dedicationCtrl,
            maxLines: 3,
            style: TextStyle(fontSize: 13, color: textPrimary, fontStyle: FontStyle.italic),
            decoration: InputDecoration(
              hintText: 'ej. Para aquellos que buscan la luz en la oscuridad...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'Página de Derechos y Créditos (Copyright)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Aviso legal formal al reverso de la portada o página final.',
            style: TextStyle(fontSize: 11.5, color: textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _copyrightCtrl,
            maxLines: 2,
            style: TextStyle(fontSize: 12, color: textPrimary),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 20),
          Divider(height: 1, color: borderSubtle),
          const SizedBox(height: 20),

          Text(
            'Biografía del Autor',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Semblanza y trayectoria del autor que aparecerá en la sección final del libro.',
            style: TextStyle(fontSize: 11.5, color: textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _authorBioCtrl,
            maxLines: 4,
            style: TextStyle(fontSize: 12.5, color: textPrimary),
            decoration: InputDecoration(
              hintText: 'ej. Nació en una noche de tormenta y desde entonces escribe historias sobre mundos olvidados...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'Redes y Enlaces de Contacto',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Enlaces a tus perfiles públicos, Instagram, Wattpad, Goodreads o página web.',
            style: TextStyle(fontSize: 11.5, color: textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _authorSocialsCtrl,
            style: TextStyle(fontSize: 12.5, color: textPrimary),
            decoration: InputDecoration(
              hintText: 'ej. @autor_fantasia • www.autor.com • wattpad.com/user/autor',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'Página de Agradecimientos',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Reconocimiento a lectores beta, correctores, familia y mecenas.',
            style: TextStyle(fontSize: 11.5, color: textSecondary),
          ),
          const SizedBox(height: 8),
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
    );
  }

  // --- TAB 3: TABLE OF CONTENTS (TOC) ---
  Widget _buildTocTab(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderSubtle,
  ) {
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tabla de Contenidos',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  Text(
                    'Reordena, excluye o edita títulos para la compilación',
                    style: TextStyle(fontSize: 11.5, color: textSecondary),
                  ),
                ],
              ),
              Switch(
                value: _includeToc,
                onChanged: (val) => setState(() => _includeToc = val),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: borderSubtle),
          const SizedBox(height: 10),

          ...orderedChapters.asMap().entries.map((entry) {
            final index = entry.key;
            final ch = entry.value;
            final isExcluded = _excludedChapterIds.contains(ch.id);
            final customTitle = _customChapterTitles[ch.id] ?? ch.title;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Reorder buttons (Up/Down)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: index > 0 ? () => _moveChapter(index, -1) : null,
                            child: Padding(
                              padding: const EdgeInsets.all(2),
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
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: index < orderedChapters.length - 1 ? textPrimary : textSecondary.withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
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
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              customTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isExcluded ? textSecondary.withValues(alpha: 0.5) : textPrimary,
                                decoration: isExcluded ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_note_rounded, size: 20, color: textSecondary),
                        tooltip: 'Editar título en el índice',
                        onPressed: () {
                          final editCtrl = TextEditingController(text: customTitle);
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
                              title: Text('Editar Título en Índice', style: TextStyle(fontSize: 16, color: textPrimary)),
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
                      // ChapterType picker popup
                      PopupMenuButton<ChapterType>(
                        initialValue: ch.chapterType,
                        tooltip: 'Tipo de capítulo',
                        icon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ch.chapterType == ChapterType.prologue
                                ? 'Prólogo'
                                : (ch.chapterType == ChapterType.epilogue ? 'Epílogo' : 'Normal'),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                        ),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: ChapterType.prologue, child: Text('Marcar como Prólogo')),
                          const PopupMenuItem(value: ChapterType.chapter, child: Text('Capítulo Regular')),
                          const PopupMenuItem(value: ChapterType.epilogue, child: Text('Marcar como Epílogo')),
                        ],
                        onSelected: (type) {
                          widget.controller.setChapterType(ch.id, type);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
