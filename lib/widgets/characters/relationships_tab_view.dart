import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../models/character_relationship_model.dart';
import 'relationship_form_modal.dart';
import 'relationship_graph_view.dart';

class RelationshipsTabView extends StatefulWidget {
  final EditorController controller;

  const RelationshipsTabView({super.key, required this.controller});

  @override
  State<RelationshipsTabView> createState() => _RelationshipsTabViewState();
}

class _RelationshipsTabViewState extends State<RelationshipsTabView> {
  bool _isGraphView = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final relationships = controller.relationships;
    final characters = controller.characters;
    final charMap = {for (final c in characters) c.id: c};
    final isDark = controller.isDarkMode;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;
    final borderSubtle = isDark ? Colors.white12 : Colors.black12;

    return Column(
      children: [
        // Sub-toolbar: count, View toggle (List vs Graph), New relationship button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.view_list_rounded,
                            size: 18,
                            color: !_isGraphView ? (isDark ? Colors.white : Colors.black) : textSecondary,
                          ),
                          tooltip: 'Vista Lista',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() => _isGraphView = false),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.bubble_chart_rounded,
                            size: 18,
                            color: _isGraphView ? (isDark ? Colors.white : Colors.black) : textSecondary,
                          ),
                          tooltip: 'Vista Red / Grafo',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() => _isGraphView = true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${relationships.length} ${relationships.length == 1 ? "vínculo" : "vínculos"}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add_link_rounded, size: 16),
                label: const Text(
                  'Vincular',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () => RelationshipFormModal.show(context, controller),
              ),
            ],
          ),
        ),

        // Body: Graph or List
        Expanded(
          child: relationships.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.hub_outlined, size: 28, color: textSecondary),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Sin vínculos aún',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Conecta personajes para visualizar alianzas, rivalidades, mentores y romances',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderSubtle),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Crear Primer Vínculo'),
                          onPressed: () => RelationshipFormModal.show(context, controller),
                        ),
                      ],
                    ),
                  ),
                )
              : _isGraphView
                  ? RelationshipGraphView(controller: controller)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: relationships.length,
                      itemBuilder: (ctx, index) {
                        final rel = relationships[index];
                        final fromChar = charMap[rel.fromCharacterId];
                        final toChar = charMap[rel.toCharacterId];
                        final type = rel.type;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFFF9F9FB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderSubtle),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // From Character
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(fromChar?.avatarEmoji ?? '👤', style: const TextStyle(fontSize: 20)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              fromChar?.name ?? 'Desconocido',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Relation Chip in middle
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Color(type.colorHex).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Color(type.colorHex).withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(type.icon, style: const TextStyle(fontSize: 11)),
                                          const SizedBox(width: 4),
                                          Text(
                                            type.label,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(type.colorHex),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            rel.isMutual ? Icons.swap_horiz_rounded : Icons.arrow_forward_rounded,
                                            size: 13,
                                            color: Color(type.colorHex),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // To Character
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              toChar?.name ?? 'Desconocido',
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(toChar?.avatarEmoji ?? '👤', style: const TextStyle(fontSize: 20)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                if (rel.description.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    rel.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 8),

                                // Footer: Strength dots & action buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Fuerza: ',
                                          style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w600),
                                        ),
                                        Row(
                                          children: List.generate(5, (i) {
                                            final isFilled = i < rel.strength;
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 1.5),
                                              child: Icon(
                                                isFilled ? Icons.circle : Icons.circle_outlined,
                                                size: 10,
                                                color: isFilled ? Color(type.colorHex) : textSecondary.withValues(alpha: 0.3),
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => RelationshipFormModal.show(context, controller, initialRelationship: rel),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Icon(Icons.edit_outlined, size: 16, color: textSecondary),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => RelationshipFormModal.confirmDelete(context, controller, rel),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Icon(Icons.delete_outline_rounded, size: 16, color: textSecondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

