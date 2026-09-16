import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../models/character_model.dart';
import '../../theme/app_theme.dart';

class CharacterFormModal extends StatefulWidget {
  final EditorController controller;
  final CharacterModel? initialCharacter;

  const CharacterFormModal({
    super.key,
    required this.controller,
    this.initialCharacter,
  });

  static Future<void> show(
    BuildContext context,
    EditorController controller, {
    CharacterModel? initialCharacter,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CharacterFormModal(
        controller: controller,
        initialCharacter: initialCharacter,
      ),
    );
  }

  @override
  State<CharacterFormModal> createState() => _CharacterFormModalState();
}

class _CharacterFormModalState extends State<CharacterFormModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameCtrl;
  late TextEditingController _archetypeCtrl;
  late TextEditingController _traitsCtrl;
  late TextEditingController _appearanceCtrl;
  late TextEditingController _motivationCtrl;
  late TextEditingController _flawCtrl;
  late TextEditingController _arcCtrl;
  late TextEditingController _biographyCtrl;
  late TextEditingController _quoteCtrl;

  late String _selectedRole;
  late String _selectedEmoji;

  static const List<String> _availableEmojis = [
    '👤', '🕵️‍♀️', '🧙‍♂️', '⚔️', '👑', '🦉', '🎭', '🛡️', '🌙', '🖋️',
    '👁️', '⚡', '🗝️', '💀', '🔥', '✨', '🧝', '🧛', '🏹', '🐺'
  ];

  static const List<String> _roleOptions = [
    'Protagonista',
    'Antagonista',
    'Mentor',
    'Aliado',
    'Secundario'
  ];

  static const List<String> _suggestedTraits = [
    'Leal', 'Desconfiado', 'Valiente', 'Metódico', 'Ambicioso',
    'Melancólico', 'Impulsivo', 'Sabio', 'Enigmático', 'Rebelde'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final init = widget.initialCharacter;
    _nameCtrl = TextEditingController(text: init?.name ?? '');
    _archetypeCtrl = TextEditingController(text: init?.archetype ?? '');
    _traitsCtrl = TextEditingController(text: init?.traits.join(', ') ?? '');
    _appearanceCtrl = TextEditingController(text: init?.physicalAppearance ?? '');
    _motivationCtrl = TextEditingController(text: init?.motivation ?? '');
    _flawCtrl = TextEditingController(text: init?.flawOrGhost ?? '');
    _arcCtrl = TextEditingController(text: init?.characterArc ?? '');
    _biographyCtrl = TextEditingController(text: init?.writtenBiography ?? '');
    _quoteCtrl = TextEditingController(text: init?.quote ?? '');

    _selectedRole = init?.role ?? 'Protagonista';
    _selectedEmoji = init?.avatarEmoji ?? '👤';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _archetypeCtrl.dispose();
    _traitsCtrl.dispose();
    _appearanceCtrl.dispose();
    _motivationCtrl.dispose();
    _flawCtrl.dispose();
    _arcCtrl.dispose();
    _biographyCtrl.dispose();
    _quoteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final rawTraits = _traitsCtrl.text.trim();
    final traitsList = rawTraits.isNotEmpty
        ? rawTraits.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
        : <String>[];

    final isEditing = widget.initialCharacter != null;
    if (isEditing) {
      final updated = widget.initialCharacter!.copyWith(
        name: name,
        role: _selectedRole,
        archetype: _archetypeCtrl.text.trim(),
        traits: traitsList,
        physicalAppearance: _appearanceCtrl.text.trim(),
        motivation: _motivationCtrl.text.trim(),
        flawOrGhost: _flawCtrl.text.trim(),
        characterArc: _arcCtrl.text.trim(),
        writtenBiography: _biographyCtrl.text.trim(),
        quote: _quoteCtrl.text.trim(),
        avatarEmoji: _selectedEmoji,
      );
      widget.controller.updateCharacter(updated);
    } else {
      final newChar = CharacterModel(
        id: 'char_${DateTime.now().millisecondsSinceEpoch}',
        bookId: widget.controller.activeBook.id,
        name: name,
        role: _selectedRole,
        archetype: _archetypeCtrl.text.trim(),
        traits: traitsList,
        physicalAppearance: _appearanceCtrl.text.trim(),
        motivation: _motivationCtrl.text.trim(),
        flawOrGhost: _flawCtrl.text.trim(),
        characterArc: _arcCtrl.text.trim(),
        writtenBiography: _biographyCtrl.text.trim(),
        quote: _quoteCtrl.text.trim(),
        avatarEmoji: _selectedEmoji,
      );
      widget.controller.addCharacter(newChar);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.controller.isDarkMode;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final inputBg = isDark ? const Color(0xFF1E1E22) : const Color(0xFFF6F6F8);
    final isEditing = widget.initialCharacter != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: AppTheme.getSoftShadow(isDark),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Text(_selectedEmoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
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
                          '${widget.controller.activeBook.title} • Ficha Narrativa',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Tab bar for clean, organized sections
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderSubtle)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: isDark ? Colors.white : Colors.black,
                indicatorWeight: 2,
                labelColor: textPrimary,
                unselectedLabelColor: textSecondary,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Identidad'),
                  Tab(text: 'Psicología'),
                  Tab(text: 'Rasgos & Bio'),
                ],
              ),
            ),

            // Scrollable Tab View
            Flexible(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  // TAB 1: IDENTIDAD
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Avatar o Símbolo',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _availableEmojis.map((e) {
                              final isChosen = e == _selectedEmoji;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedEmoji = e),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isChosen
                                          ? (isDark ? Colors.white24 : Colors.black12)
                                          : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isChosen ? (isDark ? Colors.white : Colors.black) : borderSubtle,
                                        width: isChosen ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Text(e, style: const TextStyle(fontSize: 20)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Nombre del Personaje *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameCtrl,
                          autofocus: !isEditing,
                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ej. Evelyn Vance, Marcus Thorne',
                            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.normal),
                            prefixIcon: Icon(Icons.badge_outlined, size: 20, color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Rol Narrativo',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _roleOptions.map((role) {
                              final isSelected = _selectedRole == role;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(role),
                                  selected: isSelected,
                                  selectedColor: isDark ? Colors.white : Colors.black,
                                  backgroundColor: inputBg,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: isSelected ? Colors.transparent : borderSubtle),
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? (isDark ? Colors.black : Colors.white) : textSecondary,
                                  ),
                                  showCheckmark: false,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedRole = role);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Arquetipo Narrativo',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _archetypeCtrl,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Ej. El Investigador Obsesivo, El Rebelde Solitario',
                            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13),
                            prefixIcon: Icon(Icons.psychology_outlined, size: 20, color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Frase o Cita Icónica',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _quoteCtrl,
                          style: TextStyle(color: textPrimary, fontSize: 13, fontStyle: FontStyle.italic),
                          decoration: InputDecoration(
                            hintText: '«Una línea memorable que defina su voz o visión...»',
                            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13),
                            prefixIcon: Icon(Icons.format_quote_rounded, size: 20, color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // TAB 2: PSICOLOGÍA
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deseo / Meta Consciente',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _motivationCtrl,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: '¿Qué quiere conseguir el personaje a toda costa?',
                            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13),
                            prefixIcon: Icon(Icons.track_changes_rounded, size: 20, color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Herida o Fantasma del Pasado (Debilidad interna)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _flawCtrl,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: '¿Cuál es su culpa, mayor trauma o mentira que se dice a sí mismo?',
                            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13),
                            prefixIcon: Icon(Icons.warning_amber_rounded, size: 20, color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Arco de Transformación (Evolución)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _arcCtrl,
                          maxLines: 3,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: '¿Cómo cambia de principio a fin de la novela?',
                            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13),
                            prefixIcon: Icon(Icons.trending_up_rounded, size: 20, color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // TAB 3: RASGOS & BIO
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rasgos de Personalidad (separados por coma)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _traitsCtrl,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Metódica, Desconfiada, Leal, Analítica',
                            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13),
                            prefixIcon: Icon(Icons.label_outline_rounded, size: 20, color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Suggested trait chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _suggestedTraits.map((trait) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  avatar: const Icon(Icons.add_rounded, size: 14),
                                  label: Text(trait, style: const TextStyle(fontSize: 11)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  backgroundColor: inputBg,
                                  onPressed: () {
                                    final current = _traitsCtrl.text.trim();
                                    if (current.isEmpty) {
                                      _traitsCtrl.text = trait;
                                    } else if (!current.toLowerCase().contains(trait.toLowerCase())) {
                                      _traitsCtrl.text = '$current, $trait';
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Apariencia Física y Vestimenta',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _appearanceCtrl,
                          maxLines: 2,
                          style: TextStyle(color: textPrimary, fontSize: 13, height: 1.35),
                          decoration: InputDecoration(
                            hintText: 'Rasgos distintivos, mirada, porte, cicatrices o atuendo...',
                            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 12),
                            prefixIcon: Icon(Icons.remove_red_eye_outlined, size: 20, color: textSecondary),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Biografía y Redacción Narrativa',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _biographyCtrl,
                          maxLines: 5,
                          style: TextStyle(color: textPrimary, fontSize: 13, height: 1.5),
                          decoration: InputDecoration(
                            hintText: 'Nació en los confines del reino... Guarda un secreto...',
                            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 12),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  icon: Icon(isEditing ? Icons.save_rounded : Icons.person_add_alt_1_rounded, size: 20),
                  label: Text(
                    isEditing ? 'Guardar Cambios de Ficha' : 'Crear Ficha de Personaje',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  onPressed: _save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

