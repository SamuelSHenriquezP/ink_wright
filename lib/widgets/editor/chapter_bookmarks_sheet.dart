import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../controllers/editor_controller.dart';
import '../../models/chapter_model.dart';
import '../../models/chapter_bookmark_model.dart';
import '../../formatters/writer_text_formatter.dart';

class ChapterBookmarksSheet extends StatelessWidget {
  final ChapterModel chapter;
  final EditorController controller;
  final bool isDark;
  final int currentCursorOffset;
  final void Function(int offset) onJumpToBookmark;

  const ChapterBookmarksSheet({
    super.key,
    required this.chapter,
    required this.controller,
    required this.isDark,
    required this.currentCursorOffset,
    required this.onJumpToBookmark,
  });

  static void show({
    required BuildContext context,
    required ChapterModel chapter,
    required EditorController controller,
    required bool isDark,
    required int currentCursorOffset,
    required void Function(int offset) onJumpToBookmark,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChapterBookmarksSheet(
        chapter: chapter,
        controller: controller,
        isDark: isDark,
        currentCursorOffset: currentCursorOffset,
        onJumpToBookmark: onJumpToBookmark,
      ),
    );
  }

  void _showAddBookmarkDialog(BuildContext context) {
    final textController = TextEditingController();
    final text = controller.textEditingController.text;
    final safeOffset = currentCursorOffset.clamp(0, text.length);

    // Extract surrounding snippet
    int start = (safeOffset - 25).clamp(0, text.length);
    int end = (safeOffset + 25).clamp(0, text.length);
    final snippet = text.isEmpty ? '' : text.substring(start, end).trim();

    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(color: borderSubtle),
        ),
        title: Row(
          children: [
            Icon(Icons.bookmark_add_rounded, color: textPrimary, size: 22),
            const SizedBox(width: 10),
            Text(
              'Nuevo Marcapáginas',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (snippet.isNotEmpty) ...[
              Text(
                'Posición actual:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '«$snippet»',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: textController,
              autofocus: true,
              style: TextStyle(fontSize: 14, color: textPrimary),
              decoration: InputDecoration(
                labelText: 'Etiqueta o nota (opcional)',
                hintText: 'ej. Revisar diálogo, Clímax...',
                labelStyle: TextStyle(fontSize: 13, color: textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderSubtle),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final label = textController.text.trim();
              controller.addBookmark(
                chapter.id,
                charOffset: safeOffset,
                previewText: snippet.isEmpty ? 'Posición $safeOffset' : snippet,
                label: label.isEmpty ? null : label,
              );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Marcapáginas guardado en el capítulo.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        // Get live updated chapter
        final liveChapter = controller.activeBook.chapters.firstWhere(
          (c) => c.id == chapter.id,
          orElse: () => chapter,
        );

        final bookmarks = liveChapter.bookmarks;

        return Container(
          height: MediaQuery.of(context).size.height * 0.70,
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
            border: Border.all(color: borderSubtle),
          ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bookmark_rounded, size: 20, color: textPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Marcadores del Capítulo',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Puntos de retorno rápido en «${liveChapter.title}» (${bookmarks.length} guardados)',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
          ),

          // Add bookmark button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.bookmark_add_rounded, size: 17),
                    label: const Text(
                      'Añadir Marcador en Cursor Actual',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _showAddBookmarkDialog(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: borderSubtle),

          // Bookmarks List
          Expanded(
            child: bookmarks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border_rounded,
                            size: 46,
                            color: textSecondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No hay marcadores en este capítulo',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Coloca marcas en frases clave para volver a ellas al instante con un solo toque.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                    itemCount: bookmarks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final bm = bookmarks[index];
                      final dateStr = WriterTextFormatter.formatSpanishDate(bm.createdAt);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.bookmark_rounded,
                                  size: 16,
                                  color: isDark ? Colors.amberAccent : Colors.amber.shade800,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    bm.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '«${bm.previewText}»',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textPrimary,
                                    side: BorderSide(color: borderSubtle),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 13),
                                  label: const Text('Ir al punto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    onJumpToBookmark(bm.charOffset);
                                  },
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, size: 16, color: textSecondary),
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Eliminar marcador',
                                  onPressed: () {
                                    controller.removeBookmark(chapter.id, bm.id);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  },
);
  }
}

