import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../models/character_model.dart';
import '../models/character_relationship_model.dart';

class CharactersScreen extends StatefulWidget {
  final bool isEmbedded;

  const CharactersScreen({super.key, this.isEmbedded = false});

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  int _selectedMainTabIndex = 0; // 0 = Fichas, 1 = Relaciones
  bool _isGraphView = false;
  String? _highlightedCharacterId;
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
      '👤', '🕵️‍♀️', '🧙‍♂️', '⚔️', '👑', '🦉', '🎭', '🛡️', '🌙', '🖋️',
      '👁️', '⚡', '🗝️', '💀', '🔥', '✨', '🧝', '🧛', '🏹', '🐺'
    ];

    const roleOptions = ['Protagonista', 'Antagonista', 'Mentor', 'Aliado', 'Secundario'];

    const suggestedTraits = [
      'Leal', 'Desconfiado', 'Valiente', 'Metódico', 'Ambicioso',
      'Melancólico', 'Impulsivo', 'Sabio', 'Enigmático', 'Rebelde'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = controller.isDarkMode;
        final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
        final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
        final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
        final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
        final inputBg = isDark ? const Color(0xFF1E1E22) : const Color(0xFFF6F6F8);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
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
                            child: Text(selectedEmoji, style: const TextStyle(fontSize: 22)),
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
                                  '${controller.activeBook.title} • Ficha Narrativa',
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
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: borderSubtle),

                    // Scrollable Form Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── SECCIÓN 1: IDENTIDAD BÁSICA ──
                            Text(
                              'IDENTIDAD BÁSICA',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textSecondary),
                            ),
                            const SizedBox(height: 10),

                            // Emoji Picker
                            Text(
                              'Avatar o Símbolo',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: availableEmojis.map((e) {
                                  final isChosen = e == selectedEmoji;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: InkWell(
                                      onTap: () => setDialogState(() => selectedEmoji = e),
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

                            // Nombre
                            Text(
                              'Nombre del Personaje *',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: nameCtrl,
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

                            // Rol Narrativo Chips
                            Text(
                              'Rol Narrativo',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: roleOptions.map((role) {
                                  final isSelected = selectedRole == role;
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
                                        if (selected) setDialogState(() => selectedRole = role);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Arquetipo y Cita
                            Text(
                              'Arquetipo Narrativo',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: archetypeCtrl,
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

                            // Frase o Cita Icónica
                            Text(
                              'Frase o Cita Icónica',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: quoteCtrl,
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
                            const SizedBox(height: 24),

                            // ── SECCIÓN 2: PSICOLOGÍA Y CONFLICTO ──
                            Text(
                              'PSICOLOGÍA & CONFLICTO NARRATIVO',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textSecondary),
                            ),
                            const SizedBox(height: 10),

                            // Deseo / Meta Consciente
                            Text(
                              'Deseo / Meta Consciente',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: motivationCtrl,
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
                            const SizedBox(height: 14),

                            // Herida / Fantasma del Pasado
                            Text(
                              'Herida o Fantasma del Pasado (Debilidad interna)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: flawCtrl,
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
                            const SizedBox(height: 14),

                            // Arco de Transformación
                            Text(
                              'Arco de Transformación (Evolución)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: arcCtrl,
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
                            const SizedBox(height: 24),

                            // ── SECCIÓN 3: RASGOS Y APARIENCIA ──
                            Text(
                              'RASGOS & APARIENCIA FÍSICA',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textSecondary),
                            ),
                            const SizedBox(height: 10),

                            // Rasgos de Personalidad
                            Text(
                              'Rasgos de Personalidad (separados por coma)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: traitsCtrl,
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
                                children: suggestedTraits.map((trait) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                      avatar: const Icon(Icons.add_rounded, size: 14),
                                      label: Text(trait, style: const TextStyle(fontSize: 11)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      backgroundColor: inputBg,
                                      onPressed: () {
                                        final current = traitsCtrl.text.trim();
                                        if (current.isEmpty) {
                                          traitsCtrl.text = trait;
                                        } else if (!current.toLowerCase().contains(trait.toLowerCase())) {
                                          traitsCtrl.text = '$current, $trait';
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Apariencia Física
                            Text(
                              'Apariencia Física y Vestimenta',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: appearanceCtrl,
                              maxLines: 2,
                              style: TextStyle(color: textPrimary, fontSize: 13, height: 1.35),
                              decoration: InputDecoration(
                                hintText: 'Rasgos distintivos, mirada, porte, cicatrices o atuendo característico...',
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
                            const SizedBox(height: 24),

                            // ── SECCIÓN 4: BIOGRAFÍA NARRATIVA COMPLETA ──
                            Text(
                              'BIOGRAFÍA Y REDACCIÓN NARRATIVA',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Escribe aquí el trasfondo del personaje, su historia de origen, dinámicas familiares y secretos:',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: biographyCtrl,
                              maxLines: 6,
                              style: TextStyle(color: textPrimary, fontSize: 13, height: 1.5),
                              decoration: InputDecoration(
                                hintText: 'Nació en los confines del reino... Guarda un secreto que podría derrocar a la dinastía...',
                                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 12),
                                filled: true,
                                fillColor: inputBg,
                                contentPadding: const EdgeInsets.all(16),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Guardar Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white : Colors.black,
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                icon: Icon(isEditing ? Icons.save_rounded : Icons.person_add_alt_1_rounded, size: 20),
                                label: Text(
                                  isEditing ? 'Guardar Cambios de Ficha' : 'Crear Ficha de Personaje',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
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

                                  Navigator.of(sheetContext).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                      borderRadius: BorderRadius.circular(10),
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
                                borderRadius: BorderRadius.circular(6),
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

  void _confirmDeleteRelationship(BuildContext context, EditorController controller, CharacterRelationshipModel rel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar relación?'),
        content: const Text('Esta conexión entre personajes se eliminará.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              controller.deleteRelationship(rel.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showRelationshipFormDialog(
    BuildContext context,
    EditorController controller, {
    CharacterRelationshipModel? initialRelationship,
  }) {
    final characters = controller.characters;
    if (characters.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas al menos 2 personajes para crear relaciones.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isEditing = initialRelationship != null;
    String fromId = initialRelationship?.fromCharacterId ?? characters.first.id;
    String toId = initialRelationship?.toCharacterId ??
        (characters.length > 1 ? characters[1].id : characters.first.id);
    RelationshipType selectedType = initialRelationship?.type ?? RelationshipType.aliado;
    int strength = initialRelationship?.strength ?? 3;
    bool isMutual = initialRelationship?.isMutual ?? true;
    final descCtrl = TextEditingController(text: initialRelationship?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = controller.isDarkMode;
          final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
          final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
          final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
          final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

          return AlertDialog(
            backgroundColor: bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: borderSubtle),
            ),
            title: Row(
              children: [
                Icon(Icons.hub_rounded, color: textPrimary, size: 22),
                const SizedBox(width: 10),
                Text(
                  isEditing ? 'Editar Vínculo' : 'Nuevo Vínculo Narrativo',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Personaje Origen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: fromId,
                        isExpanded: true,
                        dropdownColor: bgCard,
                        items: characters.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.avatarEmoji} ${c.name}', style: TextStyle(color: textPrimary, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => fromId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Personaje Destino', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: toId,
                        isExpanded: true,
                        dropdownColor: bgCard,
                        items: characters.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.avatarEmoji} ${c.name}', style: TextStyle(color: textPrimary, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => toId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Tipo de Relación', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: RelationshipType.values.map((t) {
                      final isSelected = selectedType == t;
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t.icon, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(t.label, style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: Color(t.colorHex).withValues(alpha: 0.25),
                        backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected ? Color(t.colorHex) : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Color(t.colorHex) : textSecondary,
                        ),
                        onSelected: (_) => setDialogState(() => selectedType = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Intensidad del Vínculo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary)),
                      Row(
                        children: List.generate(5, (i) {
                          final isFilled = i < strength;
                          return GestureDetector(
                            onTap: () => setDialogState(() => strength = i + 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Icon(
                                isFilled ? Icons.circle : Icons.circle_outlined,
                                size: 14,
                                color: isFilled ? Color(selectedType.colorHex) : textSecondary.withValues(alpha: 0.4),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Vínculo Mutuo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                      Switch.adaptive(
                        value: isMutual,
                        activeTrackColor: Color(selectedType.colorHex),
                        onChanged: (val) => setDialogState(() => isMutual = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Detalles o Dinámica', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: TextStyle(color: textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ej: Se conocen desde niños, pero ahora compiten...',
                      hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6), fontSize: 12),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancelar', style: TextStyle(color: textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (fromId == toId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecciona dos personajes distintos.'), behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }

                  if (isEditing) {
                    controller.updateRelationship(
                      initialRelationship.copyWith(
                        fromCharacterId: fromId,
                        toCharacterId: toId,
                        type: selectedType,
                        description: descCtrl.text.trim(),
                        strength: strength,
                        isMutual: isMutual,
                      ),
                    );
                  } else {
                    controller.addRelationship(
                      CharacterRelationshipModel(
                        id: 'rel_${DateTime.now().millisecondsSinceEpoch}',
                        bookId: controller.activeBook.id,
                        fromCharacterId: fromId,
                        toCharacterId: toId,
                        type: selectedType,
                        description: descCtrl.text.trim(),
                        strength: strength,
                        isMutual: isMutual,
                      ),
                    );
                  }
                  Navigator.of(ctx).pop();
                },
                child: Text(isEditing ? 'Guardar Cambios' : 'Crear Relación'),
              ),
            ],
          );
        },
      ),
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
                onPressed: () => _showCharacterFormDialog(context, controller),
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
                          onPressed: () => _showCharacterFormDialog(context, controller),
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
                        onTap: () => _showCharacterDetailSheet(context, character, controller),
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
            child: _buildRelationshipsView(context, controller, isDark, textPrimary, textSecondary, bgCard, borderSubtle),
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

  Widget _buildRelationshipsView(
    BuildContext context,
    EditorController controller,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color bgCard,
    Color borderSubtle,
  ) {
    final relationships = controller.relationships;
    final characters = controller.characters;
    final charMap = {for (final c in characters) c.id: c};

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
                onPressed: () => _showRelationshipFormDialog(context, controller),
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
                          onPressed: () => _showRelationshipFormDialog(context, controller),
                        ),
                      ],
                    ),
                  ),
                )
              : _isGraphView
                  ? _buildRelationshipGraph(context, controller, isDark, textPrimary, textSecondary, bgCard, borderSubtle)
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
                                          onTap: () => _showRelationshipFormDialog(context, controller, initialRelationship: rel),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Icon(Icons.edit_outlined, size: 16, color: textSecondary),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _confirmDeleteRelationship(context, controller, rel),
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

  Widget _buildRelationshipGraph(
    BuildContext context,
    EditorController controller,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color bgCard,
    Color borderSubtle,
  ) {
    final characters = controller.characters;
    final relationships = controller.relationships;

    if (characters.isEmpty) {
      return const Center(child: Text('No hay personajes'));
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
                painter: _RelationshipGraphPainter(
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

class _RelationshipGraphPainter extends CustomPainter {
  final List<CharacterRelationshipModel> relationships;
  final Map<String, Offset> nodePositions;
  final String? highlightedCharacterId;

  _RelationshipGraphPainter({
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
  bool shouldRepaint(covariant _RelationshipGraphPainter oldDelegate) {
    return oldDelegate.highlightedCharacterId != highlightedCharacterId ||
        oldDelegate.relationships != relationships;
  }
}
