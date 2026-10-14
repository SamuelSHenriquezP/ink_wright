import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../models/character_relationship_model.dart';
import '../../theme/app_theme.dart';
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
  RelationshipType? _selectedTypeFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final allRelationships = controller.relationships;
    final characters = controller.characters;
    final charMap = {for (final c in characters) c.id: c};
    final isDark = controller.isDarkMode;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;
    final borderSubtle = isDark ? Colors.white12 : Colors.black12;

    // Filter relationships based on type and search query
    final filteredRelationships = allRelationships.where((rel) {
      if (_selectedTypeFilter != null && rel.type != _selectedTypeFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final fromName = charMap[rel.fromCharacterId]?.name.toLowerCase() ?? '';
        final toName = charMap[rel.toCharacterId]?.name.toLowerCase() ?? '';
        final desc = rel.description.toLowerCase();
        if (!fromName.contains(query) && !toName.contains(query) && !desc.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Sub-toolbar: count, View toggle (List vs Graph), New relationship button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                    '${filteredRelationships.length} ${filteredRelationships.length == 1 ? "vínculo" : "vínculos"}',
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

        // Filter and Search Bar (When not in graph view and relationships exist)
        if (allRelationships.isNotEmpty && !_isGraphView) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: TextStyle(fontSize: 12.5, color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Buscar por personaje o conflicto...',
                  hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                  prefixIcon: Icon(Icons.search_rounded, size: 16, color: textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 14),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF242428) : const Color(0xFFF1F3F5),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal Type Filter Chips
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(
                  label: 'Todos',
                  isSelected: _selectedTypeFilter == null,
                  onTap: () => setState(() => _selectedTypeFilter = null),
                  isDark: isDark,
                  textSecondary: textSecondary,
                ),
                ...RelationshipType.values.map((type) {
                  return _buildFilterChip(
                    label: type.label,
                    icon: type.iconData,
                    isSelected: _selectedTypeFilter == type,
                    activeColor: Color(type.colorHex),
                    onTap: () => setState(() {
                      if (_selectedTypeFilter == type) {
                        _selectedTypeFilter = null;
                      } else {
                        _selectedTypeFilter = type;
                      }
                    }),
                    isDark: isDark,
                    textSecondary: textSecondary,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Body: Graph or List
        Expanded(
          child: allRelationships.isEmpty
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
                  : filteredRelationships.isEmpty
                      ? Center(
                          child: Text(
                            'No se encontraron vínculos con los filtros actuales',
                            style: TextStyle(color: textSecondary, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: filteredRelationships.length,
                          itemBuilder: (ctx, index) {
                            final rel = filteredRelationships[index];
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
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor: isDark
                                                    ? Colors.white12
                                                    : Colors.black.withValues(alpha: 0.06),
                                                child: Icon(
                                                  Icons.person_rounded,
                                                  size: 15,
                                                  color: isDark ? Colors.white70 : Colors.black87,
                                                ),
                                              ),
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
                                              Icon(
                                                type.iconData,
                                                size: 13,
                                                color: Color(type.colorHex),
                                              ),
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
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor: isDark
                                                    ? Colors.white12
                                                    : Colors.black.withValues(alpha: 0.06),
                                                child: Icon(
                                                  Icons.person_rounded,
                                                  size: 15,
                                                  color: isDark ? Colors.white70 : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Description / Conflict Notes
                                    if (rel.description.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          rel.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 8),
                                    const Divider(height: 1),
                                    const SizedBox(height: 6),

                                    // Bottom row: Intensity indicator & Action Buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Intensidad: ',
                                              style: TextStyle(fontSize: 11, color: textSecondary),
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

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    Color? activeColor,
    required VoidCallback onTap,
    required bool isDark,
    required Color textSecondary,
  }) {
    final effectiveActiveColor = activeColor ?? (isDark ? Colors.white : Colors.black);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveActiveColor.withValues(alpha: 0.15)
                : (isDark ? const Color(0xFF242428) : const Color(0xFFF1F3F5)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? effectiveActiveColor.withValues(alpha: 0.6)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? effectiveActiveColor : textSecondary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? effectiveActiveColor
                      : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
