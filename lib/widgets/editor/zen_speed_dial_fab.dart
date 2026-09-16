import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class ZenSpeedDialFab extends StatelessWidget {
  final bool isExpanded;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onNewChapter;
  final VoidCallback onNewBook;
  final VoidCallback onMindMap;
  final VoidCallback onExport;

  const ZenSpeedDialFab({
    super.key,
    required this.isExpanded,
    required this.isDark,
    required this.onToggle,
    required this.onNewChapter,
    required this.onNewBook,
    required this.onMindMap,
    required this.onExport,
  });

  Widget _buildFloatingOptionItem({
    required IconData icon,
    required String label,
    required int delayMs,
    required VoidCallback onTap,
  }) {
    final bgPill = isDark ? const Color(0xFF222225) : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final borderSubtle = isDark ? const Color(0xFF38383C) : const Color(0xFFE2E0D8);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text Label Pill
          Material(
            color: Colors.transparent,
            elevation: 3,
            shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: bgPill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderSubtle, width: 0.9),
              ),
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Circular Floating Action Button
          Material(
            color: Colors.transparent,
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: isDark ? 0.45 : 0.2),
            shape: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgPill,
                border: Border.all(color: borderSubtle, width: 0.9),
              ),
              child: Icon(
                icon,
                size: 20,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 160.ms, delay: Duration(milliseconds: delayMs))
        .slideY(begin: 0.15, end: 0, duration: 160.ms, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? Colors.white : Colors.black;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isExpanded) ...[
          _buildFloatingOptionItem(
            icon: Icons.file_download_outlined,
            label: 'Exportar',
            delayMs: 120,
            onTap: onExport,
          ),
          const SizedBox(height: 12),
          _buildFloatingOptionItem(
            icon: Icons.hub_outlined,
            label: 'Mapa Mental',
            delayMs: 80,
            onTap: onMindMap,
          ),
          const SizedBox(height: 12),
          _buildFloatingOptionItem(
            icon: Icons.auto_stories_outlined,
            label: 'Nuevo Libro',
            delayMs: 40,
            onTap: onNewBook,
          ),
          const SizedBox(height: 12),
          _buildFloatingOptionItem(
            icon: Icons.post_add_rounded,
            label: 'Nuevo Capítulo',
            delayMs: 0,
            onTap: onNewChapter,
          ),
          const SizedBox(height: 16),
        ],

        FloatingActionButton(
          heroTag: 'editor_fab_options',
          backgroundColor: isExpanded
              ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFF1E1E20))
              : accentColor,
          foregroundColor: isExpanded
              ? Colors.white
              : (isDark ? Colors.black : Colors.white),
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          tooltip: isExpanded ? 'Cerrar' : 'Acciones Rápidas (+)',
          onPressed: onToggle,
          child: AnimatedRotation(
            turns: isExpanded ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }
}

