import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/editor_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/characters/character_detail_modal.dart';
import '../widgets/characters/character_form_modal.dart';
import '../widgets/characters/relationships_tab_view.dart';

class CharactersScreen extends StatefulWidget {
  final bool isEmbedded;

  const CharactersScreen({super.key, this.isEmbedded = false});

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  int _selectedMainTabIndex = 0; // 0 = Fichas, 1 = Relaciones
  String _selectedRoleFilter = 'Todos';

  final List<String> _roleFilters = [
    'Todos',
    'Protagonista',
    'Antagonista',
    'Mentor',
    'Aliado',
    'Secundario',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final isDark = controller.isDarkMode;
    final bgPrimary = isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    final characters = controller.characters;
    final filteredCharacters = _selectedRoleFilter == 'Todos'
        ? characters
        : characters.where((c) => c.role.toLowerCase() == _selectedRoleFilter.toLowerCase()).toList();

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personajes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      '${controller.activeBook.title} • ${characters.length} personaje${characters.length == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 11, color: textSecondary),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Nuevo Personaje',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () => CharacterFormModal.show(context, controller),
              ),
            ],
          ),
        ),

        // Main Tab Switcher (Fichas vs Relaciones)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMainTabIndex = 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedMainTabIndex == 0
                            ? (isDark ? Colors.white : Colors.black)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Fichas (${characters.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _selectedMainTabIndex == 0
                              ? (isDark ? Colors.black : Colors.white)
                              : textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMainTabIndex = 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedMainTabIndex == 1
                            ? (isDark ? Colors.white : Colors.black)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hub_outlined,
                            size: 14,
                            color: _selectedMainTabIndex == 1
                                ? (isDark ? Colors.black : Colors.white)
                                : textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Relaciones (${controller.relationships.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _selectedMainTabIndex == 1
                                  ? (isDark ? Colors.black : Colors.white)
                                  : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),

        if (_selectedMainTabIndex == 0) ...[
          // Role Filter Pills
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _roleFilters.map((role) {
                final isSelected = _selectedRoleFilter == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedRoleFilter = role);
                    },
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : textSecondary,
                    ),
                    selectedColor: isDark ? Colors.white : Colors.black,
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark ? Colors.white12 : Colors.black12),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Characters List or Empty State
          Expanded(
            child: filteredCharacters.isEmpty
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
                            child: Icon(Icons.person_add_alt_1_rounded, size: 28, color: textSecondary),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _selectedRoleFilter == 'Todos'
                                ? 'Sin personajes registrados aún'
                                : 'No hay personajes con rol "$_selectedRoleFilter"',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Crea protagonistas, antagonistas y aliados con su psicología y biografía.',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Crear Primer Personaje', style: TextStyle(fontWeight: FontWeight.w700)),
                            onPressed: () => CharacterFormModal.show(context, controller),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredCharacters.length,
                    itemBuilder: (context, index) {
                      final character = filteredCharacters[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderSubtle),
                          boxShadow: AppTheme.getSoftShadow(isDark),
                        ),
                        child: InkWell(
                          onTap: () => CharacterDetailModal.show(context, character, controller),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Square Avatar Badge
                                    Container(
                                      width: 44,
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: borderSubtle),
                                      ),
                                      child: Text(character.avatarEmoji, style: const TextStyle(fontSize: 22)),
                                    ),
                                    const SizedBox(width: 12),

                                    // Name, Role & Archetype
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            character.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: textPrimary,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isDark ? Colors.white12 : Colors.black87,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  character.role.toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                              if (character.archetype.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    character.archetype,
                                                    style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Quick Action: Insert in Editor
                                    IconButton(
                                      icon: const Icon(Icons.post_add_rounded, size: 20),
                                      tooltip: 'Insertar en Manuscrito',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        controller.insertCharacterToEditor(character);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            behavior: SnackBarBehavior.floating,
                                            content: Text('Ficha de «${character.name}» insertada en el texto.'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),

                                // Motivation / Core drive if present
                                if (character.motivation.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.flag_outlined, size: 13, color: textSecondary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          character.motivation,
                                          style: TextStyle(fontSize: 12, color: textPrimary.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                // Quote if present
                                if (character.quote.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    character.quote,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],

                                // Biography snippet (El personaje escrito)
                                if (character.writtenBiography.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    character.writtenBiography,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textPrimary.withValues(alpha: 0.8),
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],

                                // Traits Chips
                                if (character.traits.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: character.traits.take(4).map((t) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: borderSubtle),
                                        ),
                                        child: Text(
                                          t,
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textSecondary),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ] else ...[
          Expanded(
            child: RelationshipsTabView(controller: controller),
          ),
        ],
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Personajes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
        ),
      ),
      body: SafeArea(child: content),
    );
  }
}
