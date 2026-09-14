import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../controllers/editor_controller.dart';
import '../../models/mind_map_node_model.dart';
import '../../screens/zen_editor_screen.dart';

/// Dialog to select a node to connect with.
void showPlotConnectDialog(
  BuildContext context,
  MindMapNodeModel node,
  EditorController controller,
  VoidCallback onUpdate,
) {
  final availableTargets = controller.mindMapNodes.where(
    (n) => n.id != node.id && !node.connectedToIds.contains(n.id),
  ).toList();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Conectar a Otro Nodo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: availableTargets.isEmpty
            ? const Text('Todos los nodos existentes ya están conectados con este.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableTargets.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final target = availableTargets[index];
                    return ListTile(
                      leading: Text(target.iconEmoji, style: const TextStyle(fontSize: 20)),
                      title: Text(target.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(target.actLabel, style: const TextStyle(fontSize: 11)),
                      onTap: () {
                        controller.connectMindMapNodes(node.id, target.id);
                        Navigator.of(context).pop();
                        onUpdate();
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}

/// Modal bottom sheet showing detailed information and connections for a selected node.
void showPlotNodeDetailModal({
  required BuildContext context,
  required MindMapNodeModel node,
  required EditorController controller,
  required void Function(MindMapNodeModel node) onEditNode,
  required void Function(MindMapNodeModel parentNode) onBranchNode,
  required void Function(String message, {IconData icon}) onNotify,
}) {
  final isDark = controller.isDarkMode;
  final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
  final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  final borderColor = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final currentNode = controller.mindMapNodes.firstWhere(
            (n) => n.id == node.id,
            orElse: () => node,
          );
          final connectedNodes = controller.mindMapNodes
              .where((n) => currentNode.connectedToIds.contains(n.id))
              .toList();

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and quick actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(currentNode.iconEmoji, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentNode.title,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${currentNode.actLabel} • ${currentNode.typeLabel}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Editar detalles',
                            color: textPrimary,
                            onPressed: () {
                              Navigator.of(context).pop();
                              onEditNode(currentNode);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 19),
                            tooltip: 'Duplicar nodo',
                            color: textPrimary,
                            onPressed: () {
                              controller.duplicateMindMapNode(currentNode.id);
                              Navigator.of(context).pop();
                              onNotify(
                                'Nodo duplicado en el lienzo.',
                                icon: Icons.copy_rounded,
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF27272A),
                              size: 20,
                            ),
                            tooltip: 'Eliminar nodo',
                            onPressed: () {
                              controller.deleteMindMapNode(currentNode.id);
                              Navigator.of(context).pop();
                              onNotify(
                                'Nodo eliminado.',
                                icon: Icons.delete_outline_rounded,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (currentNode.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        currentNode.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],

                  if (currentNode.linkedChapterId != null) ...[
                    () {
                      final linkedCh = controller.activeBook.chapters
                          .where((c) => c.id == currentNode.linkedChapterId)
                          .firstOrNull;
                      if (linkedCh == null) return const SizedBox.shrink();
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.menu_book_rounded, size: 20, color: textPrimary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CAPÍTULO VINCULADO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Capítulo ${linkedCh.chapterNumber}: ${linkedCh.title}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : Colors.black,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                              label: const Text('Ir al Capítulo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                              onPressed: () {
                                controller.selectChapter(linkedCh);
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }(),
                  ],

                  const SizedBox(height: 16),

                  // Section: Connections
                  Text(
                    'CONEXIONES E HILOS NARRATIVOS (${connectedNodes.length})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...connectedNodes.map((target) {
                        return Chip(
                          backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                          avatar: Text(target.iconEmoji, style: const TextStyle(fontSize: 13)),
                          label: Text(
                            target.title,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                          deleteIcon: const Icon(Icons.close_rounded, size: 14),
                          deleteButtonTooltipMessage: 'Desconectar',
                          onDeleted: () {
                            controller.disconnectMindMapNodes(currentNode.id, target.id);
                            setSheetState(() {});
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add_link_rounded, size: 16),
                        label: const Text('Conectar a...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          showPlotConnectDialog(context, currentNode, controller, () {
                            setSheetState(() {});
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.alt_route_rounded, size: 16),
                        label: const Text('Ramificar Subnodo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onBranchNode(currentNode);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar Datos', style: TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onEditNode(currentNode);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('Insertar en Texto', style: TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: () {
                            controller.insertTextToEditor(
                              '\n\n/* Punto de Trama: ${currentNode.title} (${currentNode.actLabel}) */\n${currentNode.description}\n\n',
                            );
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                            );
                          },
                        ),
                      ),
                    ],
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
