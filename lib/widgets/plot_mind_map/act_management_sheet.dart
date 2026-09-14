import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../controllers/editor_controller.dart';
import '../../models/mind_map_node_model.dart';

/// Modal bottom sheet for managing additional canonical acts and custom user-defined acts.
void showActManagementSheet({
  required BuildContext context,
  required EditorController controller,
  required List<TimelineActItem> Function() getTimelineActs,
  required Set<String> extraActIds,
  required VoidCallback onActsUpdated,
  required void Function(String message, {IconData icon}) onNotify,
}) {
  final isDark = controller.isDarkMode;
  final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
  final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
  final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
  final inputBg = isDark ? const Color(0xFF1E1E22) : const Color(0xFFF6F6F8);
  final customNameCtrl = TextEditingController();

  final standardOptions = [
    (PlotAct.prologue, 'Prólogo: Introducción', '📜', 'Establece el trasfondo o la premisa inicial antes del Acto I'),
    (PlotAct.act4Fallout, 'Acto IV: Revelación y Caída', '🌪️', 'Consecuencias del clímax, caída de máscaras y giros inesperados'),
    (PlotAct.act5Resolution, 'Acto V: Desenlace Final', '🏆', 'Estructura clásica en 5 actos: resolución épica o catarsis'),
    (PlotAct.epilogue, 'Epílogo: Conclusión', '🕊️', 'Cierre emocional o vistazo al futuro de los personajes tras la historia'),
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final currentTimelineActs = getTimelineActs();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: AppTheme.getSoftShadow(isDark),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  // Drag handle
                  Center(
                    child: Container(
                      width: 38,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderSubtle),
                          ),
                          child: const Text('📑', style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gestionar Actos Narrativos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                'Personaliza la estructura y línea de tiempo de tu novela',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: textSecondary),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: borderSubtle),

                  // Scrollable content
                  Flexible(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      children: [
                        Text(
                          'ACTOS CANÓNICOS ADICIONALES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        ...standardOptions.map((opt) {
                          final act = opt.$1;
                          final title = opt.$2;
                          final emoji = opt.$3;
                          final desc = opt.$4;
                          final isEnabled = currentTimelineActs.any((a) => a.act == act);
                          final nodeCount = controller.mindMapNodes
                              .where((n) => n.bookId == controller.activeBook.id && n.act == act)
                              .length;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isEnabled
                                  ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03))
                                  : inputBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isEnabled ? (isDark ? Colors.white24 : Colors.black26) : borderSubtle,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        desc,
                                        style: TextStyle(fontSize: 11, color: textSecondary),
                                      ),
                                      if (nodeCount > 0) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '$nodeCount nodos asignados',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: isEnabled,
                                  activeThumbColor: isDark ? Colors.white : Colors.black,
                                  onChanged: (val) {
                                    if (!val && nodeCount > 0) {
                                      onNotify(
                                        'No puedes desactivar $title porque contiene $nodeCount nodos.',
                                        icon: Icons.warning_amber_rounded,
                                      );
                                      return;
                                    }
                                    setModalState(() {
                                      if (val) {
                                        extraActIds.add(act.name);
                                      } else {
                                        extraActIds.remove(act.name);
                                      }
                                    });
                                    onActsUpdated();
                                  },
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 16),
                        Text(
                          'CREAR ACTO PERSONALIZADO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: customNameCtrl,
                                style: TextStyle(color: textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Ej. Interludio, Acto II-B, Flashback...',
                                  hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5), fontSize: 12),
                                  filled: true,
                                  fillColor: inputBg,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: borderSubtle),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: borderSubtle),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : Colors.black,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Añadir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              onPressed: () {
                                final name = customNameCtrl.text.trim();
                                if (name.isEmpty) return;
                                setModalState(() {
                                  extraActIds.add('custom:$name');
                                });
                                onActsUpdated();
                                customNameCtrl.clear();
                                onNotify(
                                  'Acto «$name» añadido.',
                                  icon: Icons.check_circle_outline_rounded,
                                );
                              },
                            ),
                          ],
                        ),

                        // List of existing custom acts
                        Builder(
                          builder: (context) {
                            final customActs = currentTimelineActs.where((a) => a.act == PlotAct.custom).toList();
                            if (customActs.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                Text(
                                  'ACTOS PERSONALIZADOS ACTIVOS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...customActs.map((item) {
                                  final nodeCount = controller.mindMapNodes.where(
                                    (n) => n.bookId == controller.activeBook.id && n.act == PlotAct.custom && (n.customActName ?? '').trim() == (item.customName ?? '').trim(),
                                  ).length;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: inputBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: borderSubtle),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(item.emoji, style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.label,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '$nodeCount nodos',
                                          style: TextStyle(fontSize: 10, color: textSecondary),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline_rounded, size: 18, color: textSecondary),
                                          tooltip: 'Eliminar acto',
                                          onPressed: () {
                                            if (nodeCount > 0) {
                                              onNotify(
                                                'Mueve o elimina los $nodeCount nodos antes de quitar «${item.label}».',
                                                icon: Icons.warning_amber_rounded,
                                              );
                                              return;
                                            }
                                            setModalState(() {
                                              extraActIds.remove('custom:${item.customName}');
                                            });
                                            onActsUpdated();
                                            onNotify(
                                              'Acto «${item.label}» eliminado.',
                                              icon: Icons.delete_sweep_outlined,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
