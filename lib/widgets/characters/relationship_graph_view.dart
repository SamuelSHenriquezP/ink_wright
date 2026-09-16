import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../models/character_relationship_model.dart';
import '../../theme/app_theme.dart';

class RelationshipGraphView extends StatefulWidget {
  final EditorController controller;

  const RelationshipGraphView({super.key, required this.controller});

  @override
  State<RelationshipGraphView> createState() => _RelationshipGraphViewState();
}

class _RelationshipGraphViewState extends State<RelationshipGraphView> {
  String? _highlightedCharacterId;

  @override
  Widget build(BuildContext context) {
    final characters = widget.controller.characters;
    final relationships = widget.controller.relationships;
    final isDark = widget.controller.isDarkMode;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    if (characters.isEmpty) {
      return Center(
        child: Text(
          'No hay personajes para mostrar el grafo',
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final radius = (size / 2) - 45;
        final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

        // Calculate positions for each character around the circle
        final nodePositions = <String, Offset>{};
        final angleStep = (2 * math.pi) / characters.length;

        for (int i = 0; i < characters.length; i++) {
          final angle = (i * angleStep) - (math.pi / 2);
          final x = center.dx + (radius * math.cos(angle));
          final y = center.dy + (radius * math.sin(angle));
          nodePositions[characters[i].id] = Offset(x, y);
        }

        return Stack(
          children: [
            // Custom Painter for relationship lines
            Positioned.fill(
              child: CustomPaint(
                painter: RelationshipGraphPainter(
                  relationships: relationships,
                  nodePositions: nodePositions,
                  highlightedCharacterId: _highlightedCharacterId,
                ),
              ),
            ),

            // Character Nodes positioned in circle
            ...characters.map((char) {
              final pos = nodePositions[char.id] ?? center;
              final isHighlighted = _highlightedCharacterId == char.id;

              return Positioned(
                left: pos.dx - 26,
                top: pos.dy - 26,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_highlightedCharacterId == char.id) {
                        _highlightedCharacterId = null;
                      } else {
                        _highlightedCharacterId = char.id;
                      }
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: bgCard,
                          border: Border.all(
                            color: isHighlighted
                                ? (isDark ? Colors.white : Colors.black)
                                : borderSubtle,
                            width: isHighlighted ? 2.5 : 1.2,
                          ),
                          boxShadow: isHighlighted ? AppTheme.getSoftShadow(isDark) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(char.avatarEmoji, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black87 : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderSubtle, width: 0.8),
                        ),
                        child: Text(
                          char.name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class RelationshipGraphPainter extends CustomPainter {
  final List<CharacterRelationshipModel> relationships;
  final Map<String, Offset> nodePositions;
  final String? highlightedCharacterId;

  RelationshipGraphPainter({
    required this.relationships,
    required this.nodePositions,
    this.highlightedCharacterId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final rel in relationships) {
      final p1 = nodePositions[rel.fromCharacterId];
      final p2 = nodePositions[rel.toCharacterId];
      if (p1 == null || p2 == null) continue;

      final isHighlighted = highlightedCharacterId != null &&
          (rel.fromCharacterId == highlightedCharacterId || rel.toCharacterId == highlightedCharacterId);
      final isDimmed = highlightedCharacterId != null && !isHighlighted;

      final paint = Paint()
        ..color = Color(rel.type.colorHex).withValues(alpha: isDimmed ? 0.15 : (isHighlighted ? 0.9 : 0.6))
        ..strokeWidth = (rel.strength * 0.8 + 1.0) * (isHighlighted ? 1.5 : 1.0)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RelationshipGraphPainter oldDelegate) {
    return oldDelegate.highlightedCharacterId != highlightedCharacterId ||
        oldDelegate.relationships != relationships;
  }
}

