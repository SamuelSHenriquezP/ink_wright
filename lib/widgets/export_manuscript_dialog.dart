import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../services/export_service.dart';
import '../services/cloud_backup_service.dart';
import 'import_manuscript_dialog.dart';
import 'compiler/book_compiler_modal.dart';

class ExportManuscriptDialog extends StatefulWidget {
  final bool isDark;

  const ExportManuscriptDialog({
    super.key,
    required this.isDark,
  });

  static Future<void> show(BuildContext context, {required bool isDark}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportManuscriptDialog(isDark: isDark),
    );
  }

  @override
  State<ExportManuscriptDialog> createState() => _ExportManuscriptDialogState();
}

class _ExportManuscriptDialogState extends State<ExportManuscriptDialog> {
  String _selectedFormat = 'Documento PDF (.pdf)';
  bool _exportOnlyActiveChapter = false;
  bool _includeEditorialElements = false;
  bool _includeCharacters = false;
  bool _includeCodex = false;

  final List<String> _formats = [
    'Documento PDF (.pdf)',
    'Microsoft Word (.docx)',
    'Libro Electrónico EPUB (.epub)',
    'Markdown (.md)',
    'Documento HTML (.html)',
    'Solo Texto (.txt)',
  ];
  final List<String> _fonts = ['Lora', 'Merriweather', 'Playfair Display', 'JetBrains Mono'];

  Future<void> _handleExport(BuildContext context, EditorController controller) async {
    try {
      final activeChapter = controller.activeChapter;
      final book = _exportOnlyActiveChapter
          ? controller.activeBook.copyWith(chapters: [activeChapter])
          : controller.activeBook;
      final baseFilename = _exportOnlyActiveChapter
          ? '${controller.activeBook.title}_cap_${activeChapter.chapterNumber}'.replaceAll(' ', '_').toLowerCase()
          : controller.activeBook.title.replaceAll(' ', '_').toLowerCase();
      final characters = _includeCharacters ? controller.characters : null;
      final codexEntries = _includeCodex ? controller.codexEntries : null;

      // 1. PDF Export (Native preview, print, save)
      if (_selectedFormat == 'Documento PDF (.pdf)') {
        Navigator.of(context).pop();
        await Printing.layoutPdf(
          name: baseFilename,
          onLayout: (format) async => ExportService.generatePdf(
            book,
            characters: characters,
            codexEntries: codexEntries,
            includeEditorialElements: _includeEditorialElements,
          ),
        );
        return;
      }

      // 2. Microsoft Word (.docx) Export
      if (_selectedFormat == 'Microsoft Word (.docx)') {
        final docxBytes = ExportService.generateDocx(
          book,
          characters: characters,
          codexEntries: codexEntries,
          includeEditorialElements: _includeEditorialElements,
        );
        Navigator.of(context).pop();
        final xFile = XFile.fromData(
          Uint8List.fromList(docxBytes),
          name: '$baseFilename.docx',
          mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            fileNameOverrides: ['$baseFilename.docx'],
            subject: book.title,
          ),
        );
        return;
      }

      // 3. EPUB Ebook Export
      if (_selectedFormat == 'Libro Electrónico EPUB (.epub)') {
        final epubBytes = ExportService.generateEpub(
          book,
          characters: characters,
          codexEntries: codexEntries,
          includeEditorialElements: _includeEditorialElements,
        );
        Navigator.of(context).pop();
        final xFile = XFile.fromData(
          Uint8List.fromList(epubBytes),
          name: '$baseFilename.epub',
          mimeType: 'application/epub+zip',
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            fileNameOverrides: ['$baseFilename.epub'],
            subject: book.title,
          ),
        );
        return;
      }

      // 4. Text-based exports (Solo Texto, Markdown, TXT, HTML) -> Clipboard + Modal
      String exportedContent = '';
      String filename = baseFilename;

      switch (_selectedFormat) {
        case 'Markdown (.md)':
          exportedContent = ExportService.exportToMarkdown(
            book,
            characters: characters,
            codexEntries: codexEntries,
            includeEditorialElements: _includeEditorialElements,
          );
          filename += '.md';
          break;
        case 'Documento HTML (.html)':
          exportedContent = ExportService.exportToHtml(
            book,
            characters: characters,
            codexEntries: codexEntries,
            includeEditorialElements: _includeEditorialElements,
          );
          filename += '.html';
          break;
        case 'Solo Texto (.txt)':
        case 'Texto Plano con Portada (.txt)':
        case 'Texto Plano (.txt)':
        default:
          exportedContent = ExportService.exportToPlainText(
            book,
            characters: characters,
            codexEntries: codexEntries,
            rawTextOnly: !_includeEditorialElements,
            includeEditorialElements: _includeEditorialElements,
          );
          filename += '.txt';
          break;
      }

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: exportedContent));

      if (!context.mounted) return;
      Navigator.of(context).pop();

      showModalBottomSheet(
        context: context,
        backgroundColor: widget.isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '¡"$filename" generado con éxito!',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'El contenido completo del manuscrito (${book.currentWordCount} palabras, ${book.chapters.length} capítulos) se ha copiado al portapapeles en formato $_selectedFormat.',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isDark ? Colors.white : Colors.black,
                    foregroundColor: widget.isDark ? Colors.black : Colors.white,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: const Icon(Icons.done_rounded, size: 18),
                  label: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final bgCard = widget.isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = widget.isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentColor = widget.isDark ? Colors.white : Colors.black;

    final activeBook = controller.activeBook;
    final totalWords = activeBook.currentWordCount;
    final totalChapters = activeBook.chapters.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.ios_share_rounded, size: 22, color: textPrimary),
                      const SizedBox(width: 10),
                      Text(
                        'Exportar Manuscrito',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderSubtle),

            // Scrollable Options and Actions
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Details Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: widget.isDark ? const Color(0xFF222222) : const Color(0xFFFAFAF8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_stories_rounded, size: 28, color: textPrimary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeBook.title,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$totalChapters capítulos • $totalWords palabras totales',
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Compilador Editorial Banner
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        BookCompilerModal.show(context, controller, widget.isDark);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isDark
                                ? [const Color(0xFF27272A), const Color(0xFF18181B)]
                                : [const Color(0xFFF4F4F5), const Color(0xFFE4E4E7)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: widget.isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.auto_stories_rounded,
                                size: 20,
                                color: widget.isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Compilador Profesional',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Composición, maquetación y portada',
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Alcance de Exportación',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text('Obra completa ($totalChapters caps)'),
                          selected: !_exportOnlyActiveChapter,
                          selectedColor: widget.isDark ? Colors.white : Colors.black,
                          backgroundColor: widget.isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: !_exportOnlyActiveChapter ? FontWeight.w700 : FontWeight.w500,
                            color: !_exportOnlyActiveChapter
                                ? (widget.isDark ? Colors.black : Colors.white)
                                : textSecondary,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _exportOnlyActiveChapter = false);
                          },
                        ),
                        ChoiceChip(
                          label: Text('Solo capítulo actual (Cap. ${controller.activeChapter.chapterNumber})'),
                          selected: _exportOnlyActiveChapter,
                          selectedColor: widget.isDark ? Colors.white : Colors.black,
                          backgroundColor: widget.isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: _exportOnlyActiveChapter ? FontWeight.w700 : FontWeight.w500,
                            color: _exportOnlyActiveChapter
                                ? (widget.isDark ? Colors.black : Colors.white)
                                : textSecondary,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _exportOnlyActiveChapter = true);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Seleccionar Formato de Exportación',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _formats.map((fmt) {
                        final isSelected = fmt == _selectedFormat;
                        return ChoiceChip(
                          label: Text(fmt),
                          selected: isSelected,
                          selectedColor: widget.isDark ? Colors.white : Colors.black,
                          backgroundColor: widget.isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (widget.isDark ? Colors.black : Colors.white)
                                : textSecondary,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedFormat = fmt;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Tipografía Editorial',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _fonts.map((font) {
                        final isSelected = font == controller.selectedFontFamily;
                        return ChoiceChip(
                          label: Text(font),
                          selected: isSelected,
                          selectedColor: widget.isDark ? Colors.white : Colors.black,
                          backgroundColor: widget.isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (widget.isDark ? Colors.black : Colors.white)
                                : textSecondary,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              controller.setFontFamily(font);
                            }
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Modo de Exportación (Añadidos Editoriales)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          avatar: const Icon(Icons.notes_rounded, size: 16),
                          label: const Text('Solo Texto (Sin añadidos editoriales)'),
                          selected: !_includeEditorialElements,
                          selectedColor: widget.isDark ? Colors.white : Colors.black,
                          backgroundColor: widget.isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: !_includeEditorialElements ? FontWeight.w700 : FontWeight.w500,
                            color: !_includeEditorialElements
                                ? (widget.isDark ? Colors.black : Colors.white)
                                : textSecondary,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _includeEditorialElements = false);
                          },
                        ),
                        ChoiceChip(
                          avatar: const Icon(Icons.auto_stories_rounded, size: 16),
                          label: const Text('Edición Completa (Con portada, dedicatoria e índice)'),
                          selected: _includeEditorialElements,
                          selectedColor: widget.isDark ? Colors.white : Colors.black,
                          backgroundColor: widget.isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: _includeEditorialElements ? FontWeight.w700 : FontWeight.w500,
                            color: _includeEditorialElements
                                ? (widget.isDark ? Colors.black : Colors.white)
                                : textSecondary,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _includeEditorialElements = true);
                          },
                        ),
                      ],
                    ),

                    if (_includeEditorialElements) ...[
                      const SizedBox(height: 14),

                      Text(
                        'Contenido Adicional',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Personajes (Dramatis Personae)'),
                            selected: _includeCharacters,
                            selectedColor: widget.isDark ? Colors.white : Colors.black,
                            backgroundColor: widget.isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _includeCharacters ? FontWeight.w700 : FontWeight.w500,
                              color: _includeCharacters
                                  ? (widget.isDark ? Colors.black : Colors.white)
                                  : textSecondary,
                            ),
                            onSelected: (val) => setState(() => _includeCharacters = val),
                          ),
                          FilterChip(
                            label: const Text('Códice de Mundo'),
                            selected: _includeCodex,
                            selectedColor: widget.isDark ? Colors.white : Colors.black,
                            backgroundColor: widget.isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _includeCodex ? FontWeight.w700 : FontWeight.w500,
                              color: _includeCodex
                                  ? (widget.isDark ? Colors.black : Colors.white)
                                  : textSecondary,
                            ),
                            onSelected: (val) => setState(() => _includeCodex = val),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Export Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: widget.isDark ? Colors.black : Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: Icon(
                        _selectedFormat.contains('PDF')
                            ? Icons.picture_as_pdf_rounded
                            : _selectedFormat.contains('Word')
                                ? Icons.description_rounded
                                : _selectedFormat.contains('EPUB')
                                    ? Icons.menu_book_rounded
                                    : Icons.copy_rounded,
                        size: 20,
                      ),
                      label: Text(
                        _selectedFormat.contains('PDF')
                            ? (!_includeEditorialElements ? 'Exportar Solo Texto en PDF' : 'Previsualizar / Guardar en PDF')
                            : _selectedFormat.contains('Word')
                                ? 'Exportar a Microsoft Word (.docx)'
                                : _selectedFormat.contains('EPUB')
                                    ? (!_includeEditorialElements ? 'Exportar Solo Texto en EPUB' : 'Exportar a Libro EPUB (.epub)')
                                    : (!_includeEditorialElements ? 'Copiar Solo Texto ($_selectedFormat)' : 'Copiar Manuscrito ($_selectedFormat)'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _handleExport(context, controller),
                    ),

                    const SizedBox(height: 10),

                    // Quick Button: Copiar Solo Texto Directamente
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: borderSubtle),
                      ),
                      icon: const Icon(Icons.copy_all_rounded, size: 18),
                      label: const Text(
                        'Copiar Solo Texto (Sin más ni menos)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: () async {
                        final targetBook = _exportOnlyActiveChapter
                            ? controller.activeBook.copyWith(chapters: [controller.activeChapter])
                            : controller.activeBook;
                        final text = ExportService.exportRawText(
                          targetBook,
                          includeChapterHeaders: !_exportOnlyActiveChapter,
                        );
                        await Clipboard.setData(ClipboardData(text: text));
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_exportOnlyActiveChapter
                                ? 'Texto puro del capítulo copiado al portapapeles.'
                                : 'Texto puro de la obra copiado al portapapeles (sin metadatos ni portadas).'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // ─── Importar / Restaurar Section ──────────────────────
                    Divider(height: 1, color: borderSubtle),
                    const SizedBox(height: 20),

                    Text(
                      'Importar / Restaurar',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    const SizedBox(height: 8),

                    // Warning text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.isDark ? const Color(0xFF222226) : const Color(0xFFF4F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderSubtle),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Esta acción reemplazará todos tus datos actuales. Se recomienda exportar un respaldo antes de importar.',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Botón Subir a Google Drive
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isDark ? Colors.white : Colors.black,
                        foregroundColor: widget.isDark ? Colors.black : Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                      label: const Text(
                        'Subir Respaldo a Google Drive / Nube',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => CloudBackupService.uploadToCloudDrive(context, controller),
                    ),

                    const SizedBox(height: 10),

                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.isDark ? const Color(0xFF2A2A2E) : const Color(0xFFF0EFE9),
                        foregroundColor: textPrimary,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(color: borderSubtle),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.cloud_download_outlined, size: 20),
                      label: const Text(
                        'Restaurar de Google Drive / Archivo',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => CloudBackupService.restoreFromCloudDrive(
                        context,
                        controller,
                        isDark: widget.isDark,
                      ),
                    ),

                    const SizedBox(height: 10),

                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        minimumSize: const Size(double.infinity, 48),
                        side: BorderSide(color: borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.file_download_outlined, size: 20),
                      label: const Text(
                        'Importar Manuscrito (.docx, .epub, .md, .txt)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        ImportManuscriptDialog.show(context, isDark: widget.isDark);
                      },
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
}
