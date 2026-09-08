import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../models/chapter_model.dart';
import '../models/chapter_snapshot_model.dart';
import '../formatters/writer_text_formatter.dart';

class ChapterHistorySheet extends StatelessWidget {
  final ChapterModel chapter;
  final bool isDark;

  const ChapterHistorySheet({
    super.key,
    required this.chapter,
    required this.isDark,
  });

  static void show(BuildContext context, ChapterModel chapter, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChapterHistorySheet(chapter: chapter, isDark: isDark),
    );
  }

  void _showCreateSnapshotDialog(BuildContext context, EditorController controller) {
    final textController = TextEditingController();
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
            Icon(Icons.camera_alt_outlined, color: textPrimary, size: 22),
            const SizedBox(width: 10),
            Text(
              'Nueva Instantánea',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guarda el estado actual del texto para poder volver a él en cualquier momento.',
              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              autofocus: true,
              style: TextStyle(fontSize: 14, color: textPrimary),
              decoration: InputDecoration(
                labelText: 'Etiqueta o nota (opcional)',
                hintText: 'ej. Antes de reescribir clímax',
                labelStyle: TextStyle(fontSize: 13, color: textSecondary),
                hintStyle: TextStyle(fontSize: 12, color: textSecondary.withValues(alpha: 0.5)),
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
              controller.createChapterSnapshot(chapter.id, label: label.isEmpty ? null : label);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Instantánea guardada correctamente.'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showPreviewDialog(BuildContext context, ChapterSnapshotModel snapshot) {
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
            Icon(Icons.history_edu_rounded, color: textPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    snapshot.label,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${snapshot.wordCount} palabras • ${WriterTextFormatter.formatSpanishDate(snapshot.createdAt)}',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderSubtle),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                snapshot.content.isEmpty ? '(Versión vacía)' : snapshot.content,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: textPrimary,
                ),
              ),
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: textPrimary,
              side: BorderSide(color: borderSubtle),
            ),
            icon: const Icon(Icons.copy_rounded, size: 15),
            label: const Text('Copiar Texto', style: TextStyle(fontSize: 12)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: snapshot.content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Texto de la versión copiado al portapapeles.')),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(BuildContext context, EditorController controller, ChapterSnapshotModel snapshot) {
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
            const Icon(Icons.settings_backup_restore_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 10),
            Text(
              '¿Restaurar Versión?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción reemplazará el texto del capítulo con los contenidos de «${snapshot.label}».',
              style: TextStyle(fontSize: 13, color: textPrimary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Se creará automáticamente una instantánea de seguridad de tu texto actual antes de restaurar.',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ),
                ],
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
            ),
            onPressed: () {
              final ok = controller.restoreChapterSnapshot(chapter.id, snapshot.id);
              Navigator.of(ctx).pop();
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Capítulo restaurado a «${snapshot.label}». Respaldo preventivo guardado.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Restaurar Ahora'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, EditorController controller, ChapterSnapshotModel snapshot) {
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgCard,
        title: Text('¿Eliminar Instantánea?', style: TextStyle(fontSize: 17, color: textPrimary)),
        content: Text(
          '¿Deseas eliminar permanentemente «${snapshot.label}»?',
          style: TextStyle(fontSize: 13, color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () {
              controller.deleteChapterSnapshot(chapter.id, snapshot.id);
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
    final controller = Provider.of<EditorController>(context);
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    // Get live updated chapter from controller
    final liveChapter = controller.activeBook.chapters.firstWhere(
      (c) => c.id == chapter.id,
      orElse: () => chapter,
    );

    final currentWordCount = liveChapter.id == controller.activeChapter.id
        ? WriterTextFormatter.countWords(controller.textEditingController.text)
        : liveChapter.wordCount;

    final snapshots = liveChapter.snapshots;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
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
                          Icon(Icons.history_rounded, size: 20, color: textPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Historial de Versiones',
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
                        'Capítulo ${liveChapter.chapterNumber}: ${liveChapter.title} • $currentWordCount palabras actuales',
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

          // Action Button: Save new snapshot
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 17),
                    label: const Text(
                      'Crear Instantánea del Estado Actual',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _showCreateSnapshotDialog(context, controller),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: borderSubtle),

          // Snapshots List
          Expanded(
            child: snapshots.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 48,
                            color: textSecondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Sin versiones guardadas todavía',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Crea una instantánea en cualquier momento para congelar una versión de tu borrador y experimentar reescribiendo sin temor a perder nada.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: textSecondary, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    itemCount: snapshots.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final snapshot = snapshots[index];
                      final deltaWords = snapshot.wordCount - currentWordCount;
                      final deltaText = deltaWords == 0
                          ? 'Misma longitud'
                          : (deltaWords > 0 ? '+$deltaWords palabras' : '$deltaWords palabras');

                      final timeStr = '${snapshot.createdAt.hour.toString().padLeft(2, '0')}:${snapshot.createdAt.minute.toString().padLeft(2, '0')}';
                      final dateStr = WriterTextFormatter.formatSpanishDate(snapshot.createdAt);

                      return Container(
                        padding: const EdgeInsets.all(16),
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
                                    snapshot.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${snapshot.wordCount} palabras',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '$dateStr a las $timeStr',
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                                const SizedBox(width: 8),
                                Text('•', style: TextStyle(fontSize: 11, color: textSecondary)),
                                const SizedBox(width: 8),
                                Text(
                                  deltaText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: deltaWords > 0
                                        ? (isDark ? Colors.lightBlueAccent : Colors.blue.shade700)
                                        : (deltaWords < 0
                                            ? (isDark ? Colors.orangeAccent : Colors.orange.shade800)
                                            : textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textPrimary,
                                    side: BorderSide(color: borderSubtle),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.visibility_outlined, size: 14),
                                  label: const Text('Ver', style: TextStyle(fontSize: 11)),
                                  onPressed: () => _showPreviewDialog(context, snapshot),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? Colors.white : Colors.black,
                                    foregroundColor: isDark ? Colors.black : Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.settings_backup_restore_rounded, size: 14),
                                  label: const Text('Restaurar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                  onPressed: () => _confirmRestore(context, controller, snapshot),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, size: 16, color: textSecondary),
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Eliminar instantánea',
                                  onPressed: () => _confirmDelete(context, controller, snapshot),
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
  }
}
