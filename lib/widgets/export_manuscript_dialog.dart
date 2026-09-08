import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../services/export_service.dart';

class ExportManuscriptDialog extends StatefulWidget {
  final bool isDark;

  const ExportManuscriptDialog({
    super.key,
    required this.isDark,
  });

  @override
  State<ExportManuscriptDialog> createState() => _ExportManuscriptDialogState();
}

class _ExportManuscriptDialogState extends State<ExportManuscriptDialog> {
  String _selectedFormat = 'Documento PDF (.pdf)';
  bool _includeCharacters = true;
  bool _includeCodex = false;

  final List<String> _formats = [
    'Documento PDF (.pdf)',
    'Microsoft Word (.docx)',
    'Libro Electrónico EPUB (.epub)',
    'Markdown (.md)',
    'Texto Plano (.txt)',
    'Documento HTML (.html)',
  ];
  final List<String> _fonts = ['Lora', 'Merriweather', 'Playfair Display', 'JetBrains Mono'];

  Future<void> _handleExport(BuildContext context, EditorController controller) async {
    final book = controller.activeBook;
    final baseFilename = book.title.replaceAll(' ', '_').toLowerCase();
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
      );
      Navigator.of(context).pop();
      await Printing.sharePdf(
        bytes: Uint8List.fromList(docxBytes),
        filename: '$baseFilename.docx',
      );
      return;
    }

    // 3. EPUB Ebook Export
    if (_selectedFormat == 'Libro Electrónico EPUB (.epub)') {
      final epubBytes = ExportService.generateEpub(
        book,
        characters: characters,
        codexEntries: codexEntries,
      );
      Navigator.of(context).pop();
      await Printing.sharePdf(
        bytes: Uint8List.fromList(epubBytes),
        filename: '$baseFilename.epub',
      );
      return;
    }

    // 4. Text-based exports (Markdown, TXT, HTML) -> Clipboard + Modal
    String exportedContent = '';
    String filename = baseFilename;

    switch (_selectedFormat) {
      case 'Markdown (.md)':
        exportedContent = ExportService.exportToMarkdown(
          book,
          characters: characters,
          codexEntries: codexEntries,
        );
        filename += '.md';
        break;
      case 'Texto Plano (.txt)':
        exportedContent = ExportService.exportToPlainText(
          book,
          characters: characters,
          codexEntries: codexEntries,
        );
        filename += '.txt';
        break;
      case 'Documento HTML (.html)':
        exportedContent = ExportService.exportToHtml(
          book,
          characters: characters,
          codexEntries: codexEntries,
        );
        filename += '.html';
        break;
      default:
        exportedContent = ExportService.exportToMarkdown(
          book,
          characters: characters,
          codexEntries: codexEntries,
        );
        filename += '.md';
        break;
    }

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: exportedContent));

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

    return Dialog(
      backgroundColor: bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.ios_share_rounded, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Exportar Manuscrito',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),

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
                  Text(activeBook.coverEmoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeBook.title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                        ),
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

            const SizedBox(height: 18),

            Text(
              'Seleccionar Formato de Exportación',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),

            const SizedBox(height: 8),

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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

            const SizedBox(height: 16),

            Text(
              'Tipografía Editorial',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _fonts.length,
                itemBuilder: (context, index) {
                  final font = _fonts[index];
                  final isSelected = font == controller.selectedFontFamily;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(font),
                      backgroundColor: isSelected ? accentColor : (widget.isDark ? const Color(0xFF252525) : const Color(0xFFF2F1EC)),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? (widget.isDark ? Colors.black : Colors.white)
                            : textPrimary,
                      ),
                      onPressed: () => controller.setFontFamily(font),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Contenido del Manuscrito',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Personajes (Dramatis Personae)'),
                  selected: _includeCharacters,
                  selectedColor: widget.isDark ? Colors.white : Colors.black,
                  backgroundColor: widget.isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  labelStyle: TextStyle(
                    fontSize: 11,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: _includeCodex ? FontWeight.w700 : FontWeight.w500,
                    color: _includeCodex
                        ? (widget.isDark ? Colors.black : Colors.white)
                        : textSecondary,
                  ),
                  onSelected: (val) => setState(() => _includeCodex = val),
                ),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: widget.isDark ? Colors.black : Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              icon: Icon(
                _selectedFormat.contains('PDF')
                    ? Icons.picture_as_pdf_rounded
                    : _selectedFormat.contains('Word')
                        ? Icons.description_rounded
                        : Icons.copy_rounded,
                size: 20,
              ),
              label: Text(
                _selectedFormat.contains('PDF')
                    ? 'Previsualizar / Guardar en PDF'
                    : _selectedFormat.contains('Word')
                        ? 'Exportar a Microsoft Word (.docx)'
                        : 'Copiar Manuscrito ($_selectedFormat)',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () => _handleExport(context, controller),
            ),
          ],
        ),
      ),
    );
  }
}
