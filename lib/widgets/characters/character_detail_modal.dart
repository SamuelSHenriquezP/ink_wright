import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../models/character_model.dart';
import '../../theme/app_theme.dart';
import 'character_form_modal.dart';

class CharacterDetailModal {
  static Future<void> show(
    BuildContext context,
    CharacterModel character,
    EditorController controller,
  ) {
    final isDark = controller.isDarkMode;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    return showModalBottomSheet(
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
                      CharacterFormModal.show(context, controller, initialCharacter: character);
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

                      // Written Biography
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

  static Widget _buildInfoCard({
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

  static void _confirmDeleteCharacter(
    BuildContext context,
    CharacterModel character,
    EditorController controller,
  ) {
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
}

