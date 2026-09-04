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
    String selectedEmoji = '📌';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Story Plot Node'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Plot Node Title',
                        hintText: 'e.g. Inciting Incident: The Secret Cipher',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PlotAct>(
                      initialValue: selectedAct,
                      decoration: const InputDecoration(labelText: 'Story Act'),
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PlotNodeType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Plot Element Type'),
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description / Event Notes',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
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
                        dx: 400 + (controller.mindMapNodes.length * 30),
                        dy: 200 + (controller.mindMapNodes.length * 20),
                        connectedToIds: [],
                        colorHex: _getColorForType(selectedType),
                        iconEmoji: selectedEmoji,
                      );
                      controller.addMindMapNode(newNode);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Create Node'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  int _getColorForType(PlotNodeType type) {
    switch (type) {
      case PlotNodeType.mainPlot:
        return 0xFF4A90E2;
      case PlotNodeType.subplot:
        return 0xFFF5A623;
      case PlotNodeType.characterArc:
        return 0xFF38C793;
      case PlotNodeType.worldLore:
        return 0xFF9013FE;
      case PlotNodeType.turningPoint:
        return 0xFFE74C3C;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final isDark = controller.isDarkMode;
    final bgPrimary = isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final accentMint = isDark ? AppTheme.darkAccentMint : AppTheme.lightAccentMint;

    final nodes = controller.mindMapNodes;
    final filteredNodes = _selectedActFilter == null
        ? nodes
        : nodes.where((n) => n.act == _selectedActFilter).toList();

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Story Arc & Plot Mind Map',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            Text(
              '${controller.activeBook.title} • Visual Narrative Canvas',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_location_alt_outlined, color: accentMint),
            onPressed: () => _showAddNodeDialog(context, controller),
            tooltip: 'Add Plot Node',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Pills for Story Acts
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildActFilterChip('All Acts', null, textPrimary, textSecondary, accentMint, isDark),
                _buildActFilterChip('Act I: Setup', PlotAct.act1Exposition, textPrimary, textSecondary, accentMint, isDark),
                _buildActFilterChip('Act II: Complications', PlotAct.act2RisingAction, textPrimary, textSecondary, accentMint, isDark),
                _buildActFilterChip('Midpoint', PlotAct.midpoint, textPrimary, textSecondary, accentMint, isDark),
                _buildActFilterChip('Act III: Climax', PlotAct.act3Climax, textPrimary, textSecondary, accentMint, isDark),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Interactive Canvas Area
          Expanded(
            child: ClipRect(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(1000),
                minScale: 0.4,
                maxScale: 2.5,
                child: SizedBox(
                  width: 2400,
                  height: 1600,
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
                              width: 220,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Color(node.colorHex),
                                  width: 2,
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
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Color(node.colorHex).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          node.typeLabel.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Color(node.colorHex),
                                          ),
                                        ),
                                      ),
                                      Text(node.iconEmoji, style: const TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    node.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    node.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
        backgroundColor: accentMint,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Plot Point', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _showAddNodeDialog(context, controller),
      ),
    );
  }

  Widget _buildActFilterChip(
    String label,
    PlotAct? act,
    Color textPrimary,
    Color textSecondary,
    Color accentMint,
    bool isDark,
  ) {
    final isSelected = _selectedActFilter == act;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: accentMint.withValues(alpha: 0.2),
        backgroundColor: isDark ? const Color(0xFF252525) : const Color(0xFFF2F1EC),
        side: BorderSide(color: isSelected ? accentMint : Colors.transparent),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? accentMint : textSecondary,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
      ),
      builder: (context) {
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
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          Text(
                            node.actLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(node.colorHex),
                              fontWeight: FontWeight.w700,
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
              const SizedBox(height: 12),
              Text(
                node.description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      icon: const Icon(Icons.input_rounded, size: 18),
                      label: const Text('Insert Node to Editor'),
                      onPressed: () {
                        controller.insertTextToEditor(
                          '\n\n/* Story Plot Point: ${node.title} (${node.actLabel}) */\n${node.description}\n\n',
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
  }
}

// Custom Painter for Bezier connections between nodes
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

    for (var sourceNode in nodes) {
      final sourceOffset = Offset(sourceNode.dx + 110, sourceNode.dy + 50);

      for (var targetId in sourceNode.connectedToIds) {
        final targetNode = nodeMap[targetId];
        if (targetNode != null) {
          final targetOffset = Offset(targetNode.dx + 110, targetNode.dy + 50);

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
            ..color = Color(sourceNode.colorHex).withValues(alpha: 0.6)
            ..strokeWidth = 3.0
            ..style = PaintingStyle.stroke
            ..strokeCap = ui.StrokeCap.round;

          canvas.drawPath(path, paint);

          // Connection Node Dots
          final dotPaint = Paint()
            ..color = Color(sourceNode.colorHex)
            ..style = PaintingStyle.fill;

          canvas.drawCircle(sourceOffset, 5, dotPaint);
          canvas.drawCircle(targetOffset, 5, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MindMapConnectionPainter oldDelegate) => true;
}
