import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controllers/editor_controller.dart';
import '../../theme/app_theme.dart';

class ZenFindReplaceBar extends StatelessWidget {
  final EditorController controller;
  final bool isDark;
  final TextEditingController findController;
  final TextEditingController replaceController;
  final FocusNode findFocusNode;
  final List<int> findMatches;
  final int currentMatchIndex;
  final ValueChanged<String> onFindChanged;
  final VoidCallback onPrevMatch;
  final VoidCallback onNextMatch;
  final VoidCallback onClose;
  final VoidCallback onReplaceCurrent;
  final VoidCallback onReplaceAll;

  const ZenFindReplaceBar({
    super.key,
    required this.controller,
    required this.isDark,
    required this.findController,
    required this.replaceController,
    required this.findFocusNode,
    required this.findMatches,
    required this.currentMatchIndex,
    required this.onFindChanged,
    required this.onPrevMatch,
    required this.onNextMatch,
    required this.onClose,
    required this.onReplaceCurrent,
    required this.onReplaceAll,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;

    final matchCount = findMatches.length;
    final currentMatchLabel = matchCount == 0
        ? 'Sin coincidencias'
        : '${currentMatchIndex + 1} de $matchCount';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle, width: 1.2),
        boxShadow: AppTheme.getSoftShadow(isDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: findController,
                  focusNode: findFocusNode,
                  style: TextStyle(fontSize: 13, color: textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Buscar en el capítulo...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                  onChanged: onFindChanged,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  currentMatchLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                tooltip: 'Coincidencia anterior',
                color: textPrimary,
                onPressed: onPrevMatch,
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                tooltip: 'Siguiente coincidencia',
                color: textPrimary,
                onPressed: onNextMatch,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                visualDensity: VisualDensity.compact,
                tooltip: 'Cerrar buscador (Esc)',
                color: textSecondary,
                onPressed: onClose,
              ),
            ],
          ),
          const Divider(height: 8),
          Row(
            children: [
              Icon(Icons.find_replace_rounded, size: 18, color: textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: replaceController,
                  style: TextStyle(fontSize: 13, color: textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Reemplazar con...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: textPrimary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: onReplaceCurrent,
                child: const Text('Reemplazar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: textPrimary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: onReplaceAll,
                child: const Text('Todo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 150.ms);
  }
}

