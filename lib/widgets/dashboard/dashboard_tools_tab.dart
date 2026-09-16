import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../theme/app_theme.dart';
import 'dashboard_goal_modal.dart';
import 'dashboard_restore_dialog.dart';
import 'dashboard_tutorial_sheet.dart';

class DashboardToolsTab extends StatelessWidget {
  final EditorController controller;
  final bool isDark;
  final VoidCallback onOpenMuse;
  final VoidCallback onOpenSprint;
  final VoidCallback onOpenExport;
  final VoidCallback onExportBackup;

  const DashboardToolsTab({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onOpenMuse,
    required this.onOpenSprint,
    required this.onOpenExport,
    required this.onExportBackup,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de Meta Diaria de Escritura
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: borderSubtle, width: 1.0),
                boxShadow: AppTheme.getSoftShadow(isDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.flag_rounded, size: 20, color: textPrimary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Meta Diaria de Escritura',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${controller.writerStats.wordsToday} de ${controller.writerStats.dailyGoalWords} palabras hoy',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${controller.writerStats.dailyPercentage}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: controller.writerStats.dailyGoalRatio,
                      minHeight: 6,
                      backgroundColor: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(color: borderSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 17),
                      label: const Text(
                        'Ajustar Meta Diaria',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => DashboardGoalModal.show(context, controller, isDark),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Text(
              'Herramientas y Productividad',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Utilidades para inspirarte, estructurar y gestionar tu obra',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    icon: const Icon(Icons.auto_awesome_outlined, size: 17),
                    label: const Text('Asistente Muse', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    onPressed: onOpenMuse,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    icon: const Icon(Icons.menu_book_rounded, size: 17),
                    label: const Text('Guía y Tutorial', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    onPressed: () => DashboardTutorialSheet.show(context, isDark, controller),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    icon: const Icon(Icons.timer_outlined, size: 17),
                    label: const Text('Sprint de Escritura', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    onPressed: onOpenSprint,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    icon: const Icon(Icons.ios_share_rounded, size: 17),
                    label: const Text('Exportar Libro', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    onPressed: onOpenExport,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card de Copia de Seguridad Integral (.inkwright)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: borderSubtle, width: 1.0),
                boxShadow: AppTheme.getSoftShadow(isDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          size: 20,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Copia de Seguridad Integral',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Exporta o restaura toda tu biblioteca (.inkwright)',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Guarda una copia completa en archivo local de tus novelas, capítulos, personajes, códice, notas y mapas de trama para no perder nunca tu trabajo o transferirlo a otro dispositivo.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.download_rounded, size: 17),
                          label: const Text('Exportar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          onPressed: onExportBackup,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderSubtle),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          ),
                          icon: const Icon(Icons.settings_backup_restore_rounded, size: 17),
                          label: const Text('Restaurar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          onPressed: () => DashboardRestoreDialog.show(context, controller, isDark),
                        ),
                      ),
                    ],
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

