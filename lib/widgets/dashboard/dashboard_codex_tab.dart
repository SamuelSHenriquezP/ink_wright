import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../theme/app_theme.dart';
import '../codex_card.dart';
import 'dashboard_codex_modals.dart';

class DashboardCodexTab extends StatelessWidget {
  final EditorController controller;
  final bool isDark;

  const DashboardCodexTab({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Códice de Mundo',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: textPrimary),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nueva Entrada'),
                  onPressed: () => DashboardCodexModals.showAddCodexDialog(context, controller, isDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (controller.codexEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: borderSubtle),
                  boxShadow: AppTheme.getSoftShadow(isDark),
                ),
                child: Column(
                  children: [
                    Icon(Icons.auto_stories_outlined, size: 36, color: textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(height: 10),
                    Text(
                      'Sin entradas en el códice para este libro',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registra personajes, lugares, reliquias y conceptos exclusivos de "${controller.activeBook.title}".',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(color: borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Crear Primera Entrada'),
                      onPressed: () => DashboardCodexModals.showAddCodexDialog(context, controller, isDark),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 190,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: controller.codexEntries.length,
                itemBuilder: (context, index) {
                  final entry = controller.codexEntries[index];
                  return CodexCard(
                    entry: entry,
                    isDark: isDark,
                    onTap: () => DashboardCodexModals.showCodexDetailModal(context, controller, entry, isDark),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

