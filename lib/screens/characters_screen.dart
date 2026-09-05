import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../models/character_model.dart';

class CharactersScreen extends StatefulWidget {
  final bool isEmbedded;

  const CharactersScreen({super.key, this.isEmbedded = false});

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  String _selectedRoleFilter = 'Todos';

  final List<String> _roleFilters = [
    'Todos',
    'Protagonista',
    'Antagonista',
    'Mentor',
    'Aliado',
    'Secundario',
  ];

  void _showCharacterFormDialog(
    BuildContext context,
    EditorController controller, {
    CharacterModel? initialCharacter,
  }) {
    final isEditing = initialCharacter != null;
    final nameCtrl = TextEditingController(text: initialCharacter?.name ?? '');
    final archetypeCtrl = TextEditingController(text: initialCharacter?.archetype ?? '');
    final traitsCtrl = TextEditingController(text: initialCharacter?.traits.join(', ') ?? '');
    final appearanceCtrl = TextEditingController(text: initialCharacter?.physicalAppearance ?? '');
    final motivationCtrl = TextEditingController(text: initialCharacter?.motivation ?? '');
    final flawCtrl = TextEditingController(text: initialCharacter?.flawOrGhost ?? '');
    final arcCtrl = TextEditingController(text: initialCharacter?.characterArc ?? '');
    final biographyCtrl = TextEditingController(text: initialCharacter?.writtenBiography ?? '');
    final quoteCtrl = TextEditingController(text: initialCharacter?.quote ?? '');

    String selectedRole = initialCharacter?.role ?? 'Protagonista';
    String selectedEmoji = initialCharacter?.avatarEmoji ?? '👤';

    const availableEmojis = [
      '👤', '🕵️‍♀️', '🧙‍♂️', '⚔️', '👑', '🦉', '🎭', '🛡️', '🌙', '🖋️', '👁️', '⚡', '🗝️', '💀', '🔥', '✨'
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = controller.isDarkMode;
        final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
        final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
        final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: borderSubtle),
              ),
              title: Row(
                children: [
                  Text(selectedEmoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Editar Ficha de Personaje' : 'Crear Nuevo Personaje',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '${controller.activeBook.title} • Ficha Narrativa',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 580,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emoji Selector
                      const Text('Icono / Avatar:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: availableEmojis.map((e) {
                          final isChosen = e == selectedEmoji;
                          return InkWell(
                            onTap: () => setDialogState(() => selectedEmoji = e),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isChosen
                                    ? (isDark ? Colors.white24 : Colors.black12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isChosen
                                      ? (isDark ? Colors.white70 : Colors.black87)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(e, style: const TextStyle(fontSize: 20)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Nombre
                      TextField(
                        controller: nameCtrl,
                        autofocus: !isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Personaje *',
                          hintText: 'Ej. Evelyn Vance',
                          prefixIcon: Icon(Icons.badge_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Rol y Arquetipo (en dos columnas)
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedRole,
                              decoration: const InputDecoration(labelText: 'Rol Narrativo'),
                              items: ['Protagonista', 'Antagonista', 'Mentor', 'Aliado', 'Secundario']
                                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedRole = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: archetypeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Arquetipo',
                                hintText: 'Ej. El Investigador, El Rebelde',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Frase o Cita Icónica
                      TextField(
                        controller: quoteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Frase o Cita Icónica',
                          hintText: '«Una línea que defina su voz o visión del mundo...»',
                          prefixIcon: Icon(Icons.format_quote_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Rasgos y Etiquetas
                      TextField(
                        controller: traitsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Rasgos de Personalidad (separados por coma)',
                          hintText: 'Metódica, Desconfiada, Leal, Analítica',
                          prefixIcon: Icon(Icons.label_outline_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Motivación y Deseo Profundo
                      TextField(
                        controller: motivationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Deseo / Meta Consciente',
                          hintText: '¿Qué quiere conseguir el personaje a toda costa?',
                          prefixIcon: Icon(Icons.track_changes_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Conflicto Interno / Fantasma del Pasado
                      TextField(
                        controller: flawCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Herida o Debilidad (Su Fantasma)',
                          hintText: '¿Cuál es su miedo, error pasado o mayor inseguridad?',
                          prefixIcon: Icon(Icons.warning_amber_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Arco de Transformación
                      TextField(
                        controller: arcCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Arco del Personaje (Transformación)',
                          hintText: '¿Cómo cambia o evoluciona de principio a fin de la novela?',
                          prefixIcon: Icon(Icons.trending_up_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Apariencia Física
                      TextField(
                        controller: appearanceCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Apariencia Física y Vestimenta',
                          hintText: 'Rasgos distintivos, ojos, porte, cicatrices o accesorios clave...',
                          prefixIcon: Icon(Icons.remove_red_eye_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Texto Escrito / Biografía Narrativa Completa
                      Row(
                        children: [
                          Icon(Icons.edit_note_rounded, size: 18, color: textPrimary),
                          const SizedBox(width: 6),
                          Text(
                            'Biografía & Redacción del Personaje *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Escribe la historia del personaje, orígenes, voz interior y detalles narrativos completos:',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: biographyCtrl,
                        maxLines: 7,
                        decoration: InputDecoration(
                          hintText:
                              'Escribe aquí la historia de fondo del personaje, sus relaciones familiares, cómo habla y qué secretos guarda...',
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final rawTraits = traitsCtrl.text.trim();
                    final traitsList = rawTraits.isNotEmpty
                        ? rawTraits.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
                        : <String>[];

                    if (isEditing) {
                      final updated = initialCharacter.copyWith(
                        name: name,
                        role: selectedRole,
                        archetype: archetypeCtrl.text.trim(),
                        traits: traitsList,
                        physicalAppearance: appearanceCtrl.text.trim(),
                        motivation: motivationCtrl.text.trim(),
                        flawOrGhost: flawCtrl.text.trim(),
                        characterArc: arcCtrl.text.trim(),
                        writtenBiography: biographyCtrl.text.trim(),
                        quote: quoteCtrl.text.trim(),
                        avatarEmoji: selectedEmoji,
                      );
                      controller.updateCharacter(updated);
                    } else {
                      final newChar = CharacterModel(
                        id: 'char_${DateTime.now().millisecondsSinceEpoch}',
                        bookId: controller.activeBook.id,
                        name: name,
                        role: selectedRole,
                        archetype: archetypeCtrl.text.trim(),
                        traits: traitsList,
                        physicalAppearance: appearanceCtrl.text.trim(),
                        motivation: motivationCtrl.text.trim(),
                        flawOrGhost: flawCtrl.text.trim(),
                        characterArc: arcCtrl.text.trim(),
                        writtenBiography: biographyCtrl.text.trim(),
                        quote: quoteCtrl.text.trim(),
                        avatarEmoji: selectedEmoji,
                      );
                      controller.addCharacter(newChar);
                    }

                    Navigator.of(ctx).pop();
                  },
                  child: Text(isEditing ? 'Guardar Cambios' : 'Crear Ficha'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCharacterDetailSheet(BuildContext context, CharacterModel character, EditorController controller) {
    final isDark = controller.isDarkMode;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
            border: Border.all(color: borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header with Avatar and Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Text(character.avatarEmoji, style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          character.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : Colors.black87,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                character.role.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            if (character.archetype.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '• ${character.archetype}',
                                style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Editar Ficha',
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showCharacterFormDialog(context, controller, initialCharacter: character);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    tooltip: 'Eliminar Personaje',
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _confirmDeleteCharacter(context, character, controller);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: borderSubtle),
              const SizedBox(height: 16),

              // Scrollable Details
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quote
                      if (character.quote.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderSubtle),
                          ),
                          child: Text(
                            character.quote,
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Traits Tags
                      if (character.traits.isNotEmpty) ...[
                        Text(
                          'Rasgos de Personalidad',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: character.traits.map((t) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderSubtle),
                              ),
                              child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Pillars: Motivation & Flaw
                      if (character.motivation.isNotEmpty || character.flawOrGhost.isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (character.motivation.isNotEmpty)
                              Expanded(
                                child: _buildInfoCard(
                                  title: 'Deseo / Meta',
                                  content: character.motivation,
                                  icon: Icons.track_changes_rounded,
                                  isDark: isDark,
                                  borderSubtle: borderSubtle,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                ),
                              ),
                            if (character.motivation.isNotEmpty && character.flawOrGhost.isNotEmpty)
                              const SizedBox(width: 12),
                            if (character.flawOrGhost.isNotEmpty)
                              Expanded(
                                child: _buildInfoCard(
                                  title: 'Herida / Fantasma',
                                  content: character.flawOrGhost,
                                  icon: Icons.warning_amber_rounded,
                                  isDark: isDark,
                                  borderSubtle: borderSubtle,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Character Arc
                      if (character.characterArc.isNotEmpty) ...[
                        _buildInfoCard(
                          title: 'Arco de Transformación',
                          content: character.characterArc,
                          icon: Icons.trending_up_rounded,
                          isDark: isDark,
                          borderSubtle: borderSubtle,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Physical Appearance
                      if (character.physicalAppearance.isNotEmpty) ...[
                        _buildInfoCard(
                          title: 'Apariencia Física',
                          content: character.physicalAppearance,
                          icon: Icons.remove_red_eye_outlined,
                          isDark: isDark,
                          borderSubtle: borderSubtle,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Written Biography (El personaje escrito)
                      Text(
                        'Texto Narrativo & Biografía Escrita',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: Text(
                          character.writtenBiography.isNotEmpty
                              ? character.writtenBiography
                              : 'Sin redacción biográfica escrita aún. Pulsa editar para redactar su historia.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.65,
                            color: character.writtenBiography.isNotEmpty
                                ? textPrimary
                                : textSecondary.withValues(alpha: 0.6),
                            fontStyle: character.writtenBiography.isNotEmpty
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button: Insert to Manuscript
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.post_add_rounded, size: 20),
                  label: const Text(
                    'Insertar Ficha en el Manuscrito',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  onPressed: () {
                    controller.insertCharacterToEditor(character);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Ficha de «${character.name}» insertada en el texto.'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required bool isDark,
    required Color borderSubtle,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: textSecondary),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(fontSize: 13, color: textPrimary, height: 1.4),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCharacter(BuildContext context, CharacterModel character, EditorController controller) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('¿Eliminar Personaje?'),
          content: Text('¿Deseas eliminar la ficha de «${character.name}»? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () {
                controller.deleteCharacter(character.id);
                Navigator.of(ctx).pop();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personajes de la Historia',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    '${controller.activeBook.title} • ${characters.length} personaje${characters.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Nuevo Personaje',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () => _showCharacterFormDialog(context, controller),
              ),
            ],
          ),
        ),

        // Role Filter Pills
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _roleFilters.map((role) {
              final isSelected = _selectedRoleFilter == role;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(role),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedRoleFilter = role);
                  },
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : textSecondary,
                  ),
                  selectedColor: isDark ? Colors.white : Colors.black,
                  backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_add_alt_1_rounded, size: 32, color: textSecondary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedRoleFilter == 'Todos'
                              ? 'No hay personajes en este libro aún'
                              : 'No hay personajes con rol "$_selectedRoleFilter"',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Crea a tus protagonistas, antagonistas y secundarios con su psicología y biografía escrita.',
                          style: TextStyle(fontSize: 13, color: textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderSubtle),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Crear Primer Personaje'),
                          onPressed: () => _showCharacterFormDialog(context, controller),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredCharacters.length,
                  itemBuilder: (context, index) {
                    final character = filteredCharacters[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        border: Border.all(color: borderSubtle),
                        boxShadow: AppTheme.getSoftShadow(isDark),
                      ),
                      child: InkWell(
                        onTap: () => _showCharacterDetailSheet(context, character, controller),
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar
                                  Container(
                                    width: 46,
                                    height: 46,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: borderSubtle),
                                    ),
                                    child: Text(character.avatarEmoji, style: const TextStyle(fontSize: 24)),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name & Role
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
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.white12 : Colors.black87,
                                                borderRadius: BorderRadius.circular(10),
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
                                              Text(
                                                character.archetype,
                                                style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quick Insert Button
                                  IconButton(
                                    icon: const Icon(Icons.post_add_rounded, size: 20),
                                    tooltip: 'Insertar en Manuscrito',
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

                              // Quote if present
                              if (character.quote.isNotEmpty) ...[
                                const SizedBox(height: 10),
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
                                const SizedBox(height: 10),
                                Text(
                                  character.writtenBiography,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textPrimary.withValues(alpha: 0.85),
                                    height: 1.45,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],

                              // Traits Chips
                              if (character.traits.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: character.traits.take(4).map((t) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(12),
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
