import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/mind_map_node_model.dart';

/// Custom Painter for Monochrome Bezier connections between nodes
class MindMapConnectionPainter extends CustomPainter {
  final List<MindMapNodeModel> nodes;
  final bool isDark;

  MindMapConnectionPainter({
    required this.nodes,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle dot grid background for spatial orientation
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;
    const double step = 48.0;
    for (double x = 20; x < size.width; x += step) {
      for (double y = 20; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, gridPaint);
      }
    }

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
