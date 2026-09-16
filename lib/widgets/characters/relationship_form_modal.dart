import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../models/character_relationship_model.dart';
import '../../theme/app_theme.dart';

class RelationshipFormModal {
  static void show(
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
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: DropdownButton<String>(
                      value: fromId,
                      isExpanded: true,
                      underline: const SizedBox(),
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
                  const SizedBox(height: 12),

                  Text('Personaje Destino', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: DropdownButton<String>(
                      value: toId,
                      isExpanded: true,
                      underline: const SizedBox(),
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
                  const SizedBox(height: 12),

                  Text('Tipo de Relación', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: RelationshipType.values.map((type) {
                      final isSelected = selectedType == type;
                      return ChoiceChip(
                        avatar: Text(type.icon, style: const TextStyle(fontSize: 13)),
                        label: Text(type.label, style: const TextStyle(fontSize: 11)),
                        selected: isSelected,
                        selectedColor: Color(type.colorHex),
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (sel) {
                          if (sel) setDialogState(() => selectedType = type);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  Text('Fuerza del Vínculo ($strength/5)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary)),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: isDark ? Colors.white : Colors.black,
                      thumbColor: isDark ? Colors.white : Colors.black,
                      inactiveTrackColor: borderSubtle,
                    ),
                    child: Slider(
                      value: strength.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: strength.toString(),
                      onChanged: (val) => setDialogState(() => strength = val.toInt()),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('¿Es Mutua / Bidireccional?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                      Switch(
                        value: isMutual,
                        activeThumbColor: isDark ? Colors.white : Colors.black,
                        onChanged: (val) => setDialogState(() => isMutual = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Text('Dinámica o Notas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: TextStyle(color: textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Ej. Se conocen desde la infancia pero desconfían...',
                      hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5), fontSize: 12),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderSubtle)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderSubtle)),
                      contentPadding: const EdgeInsets.all(10),
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
                      const SnackBar(content: Text('Un personaje no puede tener una relación consigo mismo.')),
                    );
                    return;
                  }

                  if (isEditing) {
                    final updated = initialRelationship.copyWith(
                      fromCharacterId: fromId,
                      toCharacterId: toId,
                      type: selectedType,
                      strength: strength,
                      isMutual: isMutual,
                      description: descCtrl.text.trim(),
                    );
                    controller.updateRelationship(updated);
                  } else {
                    final newRel = CharacterRelationshipModel(
                      id: 'rel_${DateTime.now().millisecondsSinceEpoch}',
                      bookId: controller.activeBook.id,
                      fromCharacterId: fromId,
                      toCharacterId: toId,
                      type: selectedType,
                      strength: strength,
                      isMutual: isMutual,
                      description: descCtrl.text.trim(),
                    );
                    controller.addRelationship(newRel);
                  }
                  Navigator.of(ctx).pop();
                },
                child: Text(isEditing ? 'Guardar' : 'Crear Vínculo'),
              ),
            ],
          );
        },
      ),
    );
  }

  static void confirmDelete(
    BuildContext context,
    EditorController controller,
    CharacterRelationshipModel rel,
  ) {
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
}
