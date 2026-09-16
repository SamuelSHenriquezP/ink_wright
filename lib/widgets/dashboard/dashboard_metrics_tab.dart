import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/editor_controller.dart';
import '../../models/sprint_history_model.dart';
import '../../theme/app_theme.dart';
import '../progress_ring_card.dart';

class DashboardMetricsTab extends StatelessWidget {
  final EditorController controller;
  final bool isDark;

  const DashboardMetricsTab({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métricas y Estadísticas de Escritura',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Progreso diario, velocidad y constancia semanal',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            const SizedBox(height: 16),
            ProgressRingCard(
              stats: controller.writerStats,
              isDark: isDark,
            ),

            // ─── Historial de Sprints ───────────────────────────
            const SizedBox(height: 28),

            Builder(builder: (ctx) {
              final allEntries = controller.sprintHistory;
              final displayEntries = allEntries.take(10).toList();
              final hasMore = allEntries.length > 10;
              final dateFormatter = DateFormat('dd MMM yyyy, HH:mm', 'es');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Historial de Sprints',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      if (allEntries.isNotEmpty)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.delete_sweep_rounded, size: 15),
                          label: const Text(
                            'Limpiar',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                                  side: BorderSide(color: isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle),
                                ),
                                title: Text(
                                  'Limpiar historial',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                                ),
                                content: Text(
                                  '¿Eliminar todos los sprints registrados de este libro?',
                                  style: TextStyle(fontSize: 13, color: textSecondary),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogCtx).pop(),
                                    child: Text('Cancelar', style: TextStyle(color: textSecondary)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? Colors.white : Colors.black,
                                      foregroundColor: isDark ? Colors.black : Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      controller.clearSprintHistory();
                                      Navigator.of(dialogCtx).pop();
                                    },
                                    child: const Text('Limpiar'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Empty state
                  if (allEntries.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1F) : const Color(0xFFF7F6F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.timer_outlined, size: 36, color: textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 10),
                          Text(
                            'Aún no hay sprints registrados.',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Inicia un sprint para comenzar.',
                            style: TextStyle(fontSize: 12, color: textSecondary.withValues(alpha: 0.7)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    // Sprint entry list
                    Column(
                      children: [
                        ...displayEntries.map((SprintHistoryModel entry) {
                          final dateStr = dateFormatter.format(entry.startTime);
                          final completionRate = entry.completionRate.clamp(0.0, 1.0);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      entry.goalReached
                                          ? Icons.check_circle_rounded
                                          : Icons.access_time_rounded,
                                      size: 16,
                                      color: entry.goalReached
                                          ? const Color(0xFF38C793)
                                          : textSecondary.withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        entry.chapterTitle.isNotEmpty
                                            ? entry.chapterTitle
                                            : 'Sin capítulo',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _sprintStatChip(
                                      '${entry.durationMinutes} min',
                                      Icons.timer_rounded,
                                      textSecondary,
                                      isDark,
                                    ),
                                    const SizedBox(width: 6),
                                    _sprintStatChip(
                                      '${entry.wordsWritten} palabras',
                                      Icons.edit_rounded,
                                      textSecondary,
                                      isDark,
                                    ),
                                    const SizedBox(width: 6),
                                    _sprintStatChip(
                                      '${entry.wordsWritten}/${entry.targetWords}',
                                      Icons.flag_rounded,
                                      textSecondary,
                                      isDark,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: completionRate,
                                    minHeight: 4,
                                    backgroundColor: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      entry.goalReached
                                          ? const Color(0xFF38C793)
                                          : (isDark ? Colors.white54 : Colors.black38),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        // "Ver todos" button if more than 10
                        if (hasMore)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: textSecondary,
                                minimumSize: const Size(double.infinity, 40),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Total de sprints: ${allEntries.length}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                              child: Text(
                                'Ver todos (${allEntries.length})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              );
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sprintStatChip(
    String label,
    IconData icon,
    Color textColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

