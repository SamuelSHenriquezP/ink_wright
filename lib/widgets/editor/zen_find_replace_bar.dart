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
  final bool isCaseSensitive;
  final ValueChanged<String> onFindChanged;
  final VoidCallback onPrevMatch;
  final VoidCallback onNextMatch;
  final VoidCallback onClose;
  final VoidCallback onReplaceCurrent;
  final VoidCallback onReplaceAll;
  final VoidCallback onToggleCaseSensitive;
  final VoidCallback? onReplaceAllInBook;

  const ZenFindReplaceBar({
    super.key,
    required this.controller,
    required this.isDark,
    required this.findController,
    required this.replaceController,
    required this.findFocusNode,
    required this.findMatches,
    required this.currentMatchIndex,
    this.isCaseSensitive = false,
    required this.onFindChanged,
    required this.onPrevMatch,
    required this.onNextMatch,
    required this.onClose,
    required this.onReplaceCurrent,
    required this.onReplaceAll,
    required this.onToggleCaseSensitive,
    this.onReplaceAllInBook,
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
        borderRadius: BorderRadius.circular(12),
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
              // Botón de Distinguir Mayúsculas/Minúsculas
              Tooltip(
                message: 'Distinguir mayúsculas / minúsculas',
                child: InkWell(
                  onTap: onToggleCaseSensitive,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCaseSensitive
                          ? (isDark ? Colors.white24 : Colors.black12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCaseSensitive ? textPrimary : borderSubtle,
                      ),
                    ),
                    child: Text(
                      'Aa',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isCaseSensitive ? textPrimary : textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentMatchLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary),
                ),
              ),
              const SizedBox(width: 2),
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
                tooltip: 'Cerrar buscador',
                color: textSecondary,
                onPressed: onClose,
              ),
            ],
          ),
          Divider(height: 10, color: borderSubtle),
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
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: BorderSide(color: borderSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onReplaceCurrent,
                child: const Text('Reemplazar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 5),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onReplaceAll,
                child: const Text('Capítulo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              if (onReplaceAllInBook != null) ...[
                const SizedBox(width: 5),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.orangeAccent : Colors.orange.shade800,
                    side: BorderSide(
                      color: isDark ? Colors.orangeAccent.withValues(alpha: 0.5) : Colors.orange.shade300,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onReplaceAllInBook,
                  child: const Text('Todo el libro', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 150.ms);
  }
}

