import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../controllers/editor_controller.dart';
import '../../models/chapter_model.dart';
import '../../formatters/writer_text_formatter.dart';

class ChapterTrashSheet extends StatelessWidget {
  final EditorController controller;
  final bool isDark;

  const ChapterTrashSheet({
    super.key,
    required this.controller,
    required this.isDark,
  });

  static void show(BuildContext context, EditorController controller, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChapterTrashSheet(controller: controller, isDark: isDark),
    );
  }

  void _confirmEmptyTrash(BuildContext context) {
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgCard,
        title: Text('¿Vaciar la papelera?', style: TextStyle(fontSize: 17, color: textPrimary)),
        content: Text(
          'Se eliminarán de forma permanente todos los capítulos archivados en la papelera. Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () {
              controller.emptyTrash();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Papelera vaciada por completo.')),
              );
            },
            child: const Text('Vaciar Todo', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(BuildContext context, ChapterModel chapter) {
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgCard,
        title: Text('¿Eliminar permanentemente?', style: TextStyle(fontSize: 17, color: textPrimary)),
        content: Text(
          '¿Deseas purgar definitivamente «${chapter.title}»? El texto y sus instantáneas se perderán.',
          style: TextStyle(fontSize: 13, color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () {
              controller.permanentlyDeleteChapter(chapter.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
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
        final trashed = controller.activeBook.trashedChapters;

        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
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
                          Icon(Icons.delete_outline_rounded, size: 20, color: textPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Papelera de Capítulos',
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
                        trashed.isEmpty
                            ? 'No hay capítulos eliminados'
                            : '${trashed.length} ${trashed.length == 1 ? 'capítulo archivado' : 'capítulos archivados'}',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                if (trashed.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                    label: const Text('Vaciar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _confirmEmptyTrash(context),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
          ),

          Divider(height: 1, color: borderSubtle),

          // Trashed items list
          Expanded(
            child: trashed.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 48,
                            color: textSecondary.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'La papelera está vacía',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Cualquier capítulo que borres de la obra se moverá aquí primero para que puedas recuperarlo cuando quieras.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    itemCount: trashed.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = trashed[index];
                      final dateStr = WriterTextFormatter.formatSpanishDate(item.lastEdited);

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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.wordCount} pal.',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Editado por última vez el $dateStr',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.delete_forever_rounded, size: 14),
                                  label: const Text('Purgar', style: TextStyle(fontSize: 11)),
                                  onPressed: () => _confirmPermanentDelete(context, item),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? Colors.white : Colors.black,
                                    foregroundColor: isDark ? Colors.black : Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.restore_from_trash_rounded, size: 14),
                                  label: const Text('Restaurar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    final ok = controller.restoreChapter(item.id);
                                    if (ok) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Capítulo «${item.title}» restaurado con éxito a la obra.'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
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

