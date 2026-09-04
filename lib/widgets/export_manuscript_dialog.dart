import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';

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
  String _selectedFormat = 'Manuscrito PDF';
  final List<String> _formats = ['Manuscrito PDF', 'E-Book (EPUB)', 'Markdown (.md)', 'Texto Plano (.txt)'];

  final List<String> _fonts = ['Lora', 'Merriweather', 'Playfair Display', 'JetBrains Mono'];

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
              'Seleccionar Formato',
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

            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: widget.isDark ? Colors.black : Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              icon: const Icon(Icons.download_done_rounded, size: 20),
              label: Text('Exportar como $_selectedFormat', style: const TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('¡"${activeBook.title}" exportado como $_selectedFormat exitosamente!'),
                    backgroundColor: widget.isDark ? Colors.white : Colors.black,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
