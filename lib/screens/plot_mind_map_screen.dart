import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../models/mind_map_node_model.dart';
import 'zen_editor_screen.dart';

class PlotMindMapScreen extends StatefulWidget {
  const PlotMindMapScreen({super.key});

  @override
  State<PlotMindMapScreen> createState() => _PlotMindMapScreenState();
}

class _PlotMindMapScreenState extends State<PlotMindMapScreen> {
  PlotAct? _selectedActFilter;

  void _showAddNodeDialog(BuildContext context, EditorController controller) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    PlotAct selectedAct = PlotAct.act1Exposition;
    PlotNodeType selectedType = PlotNodeType.mainPlot;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Nuevo Punto de Trama',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título del Punto de Trama',
                        hintText: 'Ej. Incidente Incitador: El Descubrimiento',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<PlotAct>(
                      initialValue: selectedAct,
                      decoration: const InputDecoration(labelText: 'Acto Narrativo'),
                      items: PlotAct.values.map((act) {
                        final dummy = MindMapNodeModel(
                          id: '',
                          bookId: '',
                          title: '',
                          description: '',
                          act: act,
                          type: PlotNodeType.mainPlot,
                          dx: 0,
                          dy: 0,
                          connectedToIds: [],
                          colorHex: 0,
                          iconEmoji: '',
                        );
                        return DropdownMenuItem(
                          value: act,
                          child: Text(dummy.actLabel),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedAct = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<PlotNodeType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Tipo de Elemento'),
                      items: PlotNodeType.values.map((type) {
                        final dummy = MindMapNodeModel(
                          id: '',
                          bookId: '',
                          title: '',
                          description: '',
                          act: PlotAct.act1Exposition,
                          type: type,
                          dx: 0,
                          dy: 0,
                          connectedToIds: [],
                          colorHex: 0,
                          iconEmoji: '',
                        );
                        return DropdownMenuItem(
                          value: type,
                          child: Text(dummy.typeLabel),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción / Notas de la Escena',
                        hintText: 'Detalles clave sobre la trama o personaje...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isNotEmpty) {
                      final newNode = MindMapNodeModel(
                        id: 'node_${DateTime.now().millisecondsSinceEpoch}',
                        bookId: controller.activeBook.id,
                        title: title,
                        description: descCtrl.text.trim(),
                        act: selectedAct,
                        type: selectedType,
                        dx: 350 + (controller.mindMapNodes.length * 40),
                        dy: 200 + (controller.mindMapNodes.length * 30),
                        connectedToIds: [],
                        colorHex: 0xFF18181B,
                        iconEmoji: '📌',
                      );
                      controller.addMindMapNode(newNode);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Crear Nodo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final isDark = controller.isDarkMode;
    final bgPrimary = isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final accentColor = isDark ? Colors.white : Colors.black;
    final cardBg = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final borderColor = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    final nodes = controller.mindMapNodes;
    final filteredNodes = _selectedActFilter == null
        ? nodes
        : nodes.where((n) => n.act == _selectedActFilter).toList();

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mapa Mental de Trama',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            Text(
              '${controller.activeBook.title} • Planificación Narrativa',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: textPrimary),
            onPressed: () => _showAddNodeDialog(context, controller),
            tooltip: 'Añadir Nodo de Trama',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Pills for Story Acts
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildActFilterChip('Todos los Actos', null, textPrimary, textSecondary, accentColor, isDark),
                _buildActFilterChip('Acto I', PlotAct.act1Exposition, textPrimary, textSecondary, accentColor, isDark),
                _buildActFilterChip('Acto II', PlotAct.act2RisingAction, textPrimary, textSecondary, accentColor, isDark),
                _buildActFilterChip('Punto Medio', PlotAct.midpoint, textPrimary, textSecondary, accentColor, isDark),
                _buildActFilterChip('Acto III', PlotAct.act3Climax, textPrimary, textSecondary, accentColor, isDark),
                _buildActFilterChip('Resolución', PlotAct.resolution, textPrimary, textSecondary, accentColor, isDark),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Interactive Canvas Area
          Expanded(
            child: ClipRect(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(1200),
                minScale: 0.3,
                maxScale: 2.2,
                child: SizedBox(
                  width: 2500,
                  height: 1800,
                  child: Stack(
                    children: [
                      // Canvas Grid lines & Custom Painter Connections
                      Positioned.fill(
                        child: CustomPaint(
                          painter: MindMapConnectionPainter(
                            nodes: nodes,
                            isDark: isDark,
                          ),
                        ),
                      ),

                      // Interactive Draggable Node Widgets
                      ...filteredNodes.map((node) {
                        return Positioned(
                          left: node.dx,
                          top: node.dy,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              controller.updateMindMapNodePosition(
                                node.id,
                                Offset(node.dx + details.delta.dx, node.dy + details.delta.dy),
                              );
                            },
                            onTap: () => _showNodeDetailBottomSheet(context, node, controller, isDark),
                            child: Container(
                              width: 230,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.5,
                                ),
                                boxShadow: AppTheme.getSoftShadow(isDark),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          node.typeLabel.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      Text(node.iconEmoji, style: const TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    node.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (node.description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      node.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    node.actLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Punto de Trama',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        onPressed: () => _showAddNodeDialog(context, controller),
      ),
    );
  }

  Widget _buildActFilterChip(
    String label,
    PlotAct? act,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
    bool isDark,
  ) {
    final isSelected = _selectedActFilter == act;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: isDark ? Colors.white : Colors.black,
        backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? (isDark ? Colors.black : Colors.white)
              : textSecondary,
        ),
        onSelected: (selected) {
          setState(() {
            _selectedActFilter = act;
          });
        },
      ),
    );
  }

  void _showNodeDetailBottomSheet(
    BuildContext context,
    MindMapNodeModel node,
    EditorController controller,
    bool isDark,
  ) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(node.iconEmoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                node.title,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                '${node.actLabel} • ${node.typeLabel}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: () {
                          controller.deleteMindMapNode(node.id);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  if (node.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      node.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('Insertar en Manuscrito', style: TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: () {
                            controller.insertTextToEditor(
                              '\n\n/* Punto de Trama: ${node.title} (${node.actLabel}) */\n${node.description}\n\n',
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
            );
          },
        );
      },
    );
  }
}

// Custom Painter for Monochrome Bezier connections between nodes
class MindMapConnectionPainter extends CustomPainter {
  final List<MindMapNodeModel> nodes;
  final bool isDark;

  MindMapConnectionPainter({
    required this.nodes,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Map<String, MindMapNodeModel> nodeMap = {for (var n in nodes) n.id: n};
    final lineColor = isDark ? Colors.white24 : Colors.black26;

    for (var sourceNode in nodes) {
      final sourceOffset = Offset(sourceNode.dx + 115, sourceNode.dy + 50);

      for (var targetId in sourceNode.connectedToIds) {
        final targetNode = nodeMap[targetId];
        if (targetNode != null) {
          final targetOffset = Offset(targetNode.dx + 115, targetNode.dy + 50);

          final path = Path();
          path.moveTo(sourceOffset.dx, sourceOffset.dy);

          final controlPoint1 = Offset(sourceOffset.dx + 80, sourceOffset.dy);
          final controlPoint2 = Offset(targetOffset.dx - 80, targetOffset.dy);

          path.cubicTo(
            controlPoint1.dx,
            controlPoint1.dy,
            controlPoint2.dx,
            controlPoint2.dy,
            targetOffset.dx,
            targetOffset.dy,
          );

          final paint = Paint()
            ..color = lineColor
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke
            ..strokeCap = ui.StrokeCap.round;

          canvas.drawPath(path, paint);

          // Connection Node Dots
          final dotPaint = Paint()
            ..color = isDark ? Colors.white : Colors.black
            ..style = PaintingStyle.fill;

          canvas.drawCircle(sourceOffset, 4, dotPaint);
          canvas.drawCircle(targetOffset, 4, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MindMapConnectionPainter oldDelegate) => true;
}
