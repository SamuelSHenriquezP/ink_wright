import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../controllers/editor_controller.dart';
import '../../models/character_model.dart';

/// Modal emergente minimalista para crear un nuevo capítulo
class NewChapterModal extends StatefulWidget {
  final bool isDark;
  final VoidCallback? onChapterCreated;

  const NewChapterModal({
    super.key,
    required this.isDark,
    this.onChapterCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isDark,
    VoidCallback? onChapterCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewChapterModal(
        isDark: isDark,
        onChapterCreated: onChapterCreated,
      ),
    );
  }

  @override
  State<NewChapterModal> createState() => _NewChapterModalState();
}

class _NewChapterModalState extends State<NewChapterModal> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  String _selectedPovCharacter = '';

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<EditorController>(context, listen: false);
    final nextNum = controller.activeBook.chapters.length + 1;
    _titleController = TextEditingController(text: 'Capítulo $nextNum');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final controller = Provider.of<EditorController>(context, listen: false);
    controller.addNewChapter(
      title,
      povCharacter: _selectedPovCharacter,
      notes: _notesController.text.trim(),
    );

    Navigator.of(context).pop();
    widget.onChapterCreated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final controller = Provider.of<EditorController>(context);
    final characters = controller.characters;

    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentBg = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: AppTheme.getSoftShadow(isDark),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de arrastre superior
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

              // Cabecera
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bookmark_add_outlined, color: textPrimary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nuevo Capítulo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Añade una nueva escena o capítulo al manuscrito',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Campo: Título
              Text(
                'Título del capítulo',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                autofocus: true,
                style: TextStyle(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ej. Capítulo 1: El despertar',
                  hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: textPrimary, width: 1.2),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),

              // Campo: Punto de vista (POV) si hay personajes
              if (characters.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Punto de vista (POV)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPovChip(
                        label: 'Sin asignar',
                        emoji: '👤',
                        isSelected: _selectedPovCharacter.isEmpty,
                        onTap: () => setState(() => _selectedPovCharacter = ''),
                        isDark: isDark,
                        textPrimary: textPrimary,
                        borderSubtle: borderSubtle,
                      ),
                      const SizedBox(width: 8),
                      ...characters.map((CharacterModel c) {
                        final isSelected = _selectedPovCharacter == c.name;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildPovChip(
                            label: c.name,
                            emoji: c.avatarEmoji,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedPovCharacter = c.name),
                            isDark: isDark,
                            textPrimary: textPrimary,
                            borderSubtle: borderSubtle,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              // Campo: Premisa / Notas de escena (opcional)
              const SizedBox(height: 16),
              Text(
                'Premisa o conflicto (opcional)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 2,
                style: TextStyle(color: textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: '¿Qué ocurre en este capítulo? ¿Cuál es el conflicto?',
                  hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: textPrimary, width: 1.2),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        'Crear Capítulo',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPovChip({
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
    required Color borderSubtle,
  }) {
    final bg = isSelected
        ? (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.07))
        : Colors.transparent;

    final border = isSelected
        ? (isDark ? Colors.white : Colors.black)
        : borderSubtle;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: isSelected ? 1.4 : 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

