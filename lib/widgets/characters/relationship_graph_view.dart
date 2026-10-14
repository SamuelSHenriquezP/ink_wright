import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../models/character_model.dart';
import '../../models/character_relationship_model.dart';
import '../../theme/app_theme.dart';
import 'character_detail_modal.dart';
import 'relationship_form_modal.dart';

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

    final selectedChar = _highlightedCharacterId != null
        ? characters.firstWhere(
            (c) => c.id == _highlightedCharacterId,
            orElse: () => characters.first,
          )
        : null;

    final selectedRelationships = selectedChar != null
        ? relationships
            .where((r) =>
                r.fromCharacterId == selectedChar.id ||
                r.toCharacterId == selectedChar.id)
            .toList()
        : <CharacterRelationshipModel>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final radius = math.max(60.0, (size / 2) - 55);
        final center = Offset(constraints.maxWidth / 2, (constraints.maxHeight / 2) - (selectedChar != null ? 35 : 0));

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
            // Custom Painter for relationship lines with midpoint icon badges
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
                                ? AppTheme.accentTeal
                                : borderSubtle,
                            width: isHighlighted ? 2.5 : 1.2,
                          ),
                          boxShadow: isHighlighted
                              ? [
                                  BoxShadow(
                                    color: AppTheme.accentTeal.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          char.name.isNotEmpty ? char.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isHighlighted ? AppTheme.accentTeal : textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? AppTheme.accentTeal
                              : (isDark ? Colors.black87 : Colors.white),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isHighlighted ? AppTheme.accentTeal : borderSubtle,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          char.name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
                            color: isHighlighted
                                ? Colors.white
                                : textPrimary,
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

            // Interactive Bottom Card for Selected Character
            if (selectedChar != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentTeal.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.accentTeal.withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 19,
                              color: AppTheme.accentTeal,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedChar.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  '${selectedChar.role.isNotEmpty ? selectedChar.role : "Personaje"} • ${selectedChar.archetype.isNotEmpty ? selectedChar.archetype : "Sin arquetipo"}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            visualDensity: VisualDensity.compact,
                            color: textSecondary,
                            onPressed: () => setState(() => _highlightedCharacterId = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // List of connections
                      if (selectedRelationships.isEmpty)
                        Text(
                          'No tiene vínculos con otros personajes aún.',
                          style: TextStyle(fontSize: 11.5, color: textSecondary, fontStyle: FontStyle.italic),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: selectedRelationships.map((rel) {
                            final otherId = rel.fromCharacterId == selectedChar.id
                                ? rel.toCharacterId
                                : rel.fromCharacterId;
                            final otherChar = characters.firstWhere(
                              (c) => c.id == otherId,
                              orElse: () => CharacterModel(
                                id: '',
                                bookId: '',
                                name: 'Desconocido',
                                role: 'Secundario',
                              ),
                            );

                            return InkWell(
                              onTap: () {
                                RelationshipFormModal.show(
                                  context,
                                  widget.controller,
                                  initialRelationship: rel,
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(rel.type.colorHex).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Color(rel.type.colorHex).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      rel.type.iconData,
                                      size: 13,
                                      color: Color(rel.type.colorHex),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${rel.type.label} con ${otherChar.name}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(rel.type.colorHex),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              side: BorderSide(color: borderSubtle),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            icon: const Icon(Icons.person_outline_rounded, size: 14),
                            label: const Text('Ver Ficha', style: TextStyle(fontSize: 11.5)),
                            onPressed: () {
                              CharacterDetailModal.show(context, selectedChar, widget.controller);
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentTeal,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            icon: const Icon(Icons.add_link_rounded, size: 14),
                            label: const Text('Añadir Vínculo', style: TextStyle(fontSize: 11.5)),
                            onPressed: () {
                              RelationshipFormModal.show(
                                context,
                                widget.controller,
                                initialFromCharacterId: selectedChar.id,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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

      // Draw relationship line
      final paint = Paint()
        ..color = Color(rel.type.colorHex).withValues(alpha: isDimmed ? 0.15 : (isHighlighted ? 0.9 : 0.6))
        ..strokeWidth = (rel.strength * 0.8 + 1.2) * (isHighlighted ? 1.5 : 1.0)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, paint);

      // Midpoint badge with icon
      final midpoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      final badgeBgPaint = Paint()
        ..color = Color(rel.type.colorHex).withValues(alpha: isDimmed ? 0.2 : (isHighlighted ? 1.0 : 0.85))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(midpoint, 9.5, badgeBgPaint);

      // Paint relationship icon
      final icon = rel.type.iconData;
      final textSpan = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 10,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white.withValues(alpha: isDimmed ? 0.3 : 1.0),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(midpoint.dx - (textPainter.width / 2), midpoint.dy - (textPainter.height / 2)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RelationshipGraphPainter oldDelegate) {
    return oldDelegate.highlightedCharacterId != highlightedCharacterId ||
        oldDelegate.relationships != relationships;
  }
}
