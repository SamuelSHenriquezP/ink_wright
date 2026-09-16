import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../models/codex_entry_model.dart';
import '../../screens/zen_editor_screen.dart';
import '../../theme/app_theme.dart';

class DashboardCodexModals {
  static void showAddCodexDialog(BuildContext context, EditorController controller, bool isDark) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final traitsCtrl = TextEditingController();
    CodexType category = CodexType.lore;

    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final inputBg = isDark ? const Color(0xFF1E1E22) : const Color(0xFFF6F6F8);

    String selectedEmoji = '📜';

    const availableEmojis = [
      '📜', '🏰', '🌲', '🌋', '🏛️', '🌌', '🗝️', '🗡️', '💍', '🔮',
      '👑', '🛡️', '🎭', '⚖️', '🧙‍♂️', '👁️', '🐉', '🌙', '⚓', '🧪'
    ];

    const suggestedCodexTraits = [
      'Antiguo', 'Prohibido', 'Sagrado', 'Místico', 'Oculto',
      'Legendario', 'Peligroso', 'Olvidado', 'Maldito', 'Secreto'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            String defaultEmojiForCategory(CodexType c) {
              switch (c) {
                case CodexType.character:
                  return '🧙‍♂️';
                case CodexType.location:
                  return '🏰';
                case CodexType.artifact:
                  return '🗝️';
                case CodexType.lore:
                  return '📜';
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.90,
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
                                  'Nueva Entrada al Códice',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${controller.activeBook.title} • Lore & Construcción de Mundo',
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
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: borderSubtle),

                    // Scrollable form body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Tipo de Elemento
                            Text(
                              'CATEGORÍA DEL ELEMENTO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: CodexType.values.map((c) {
                                  final isSelected = category == c;
                                  final emoji = defaultEmojiForCategory(c);
                                  String label;
                                  switch (c) {
                                    case CodexType.character:
                                      label = 'Personaje';
                                      break;
                                    case CodexType.location:
                                      label = 'Lugar / Reino';
                                      break;
                                    case CodexType.artifact:
                                      label = 'Objeto / Reliquia';
                                      break;
                                    case CodexType.lore:
                                      label = 'Códice / Lore';
                                      break;
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(emoji, style: const TextStyle(fontSize: 13)),
                                          const SizedBox(width: 6),
                                          Text(label),
                                        ],
                                      ),
                                      selected: isSelected,
                                      selectedColor: isDark ? Colors.white : Colors.black,
                                      backgroundColor: inputBg,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isSelected ? Colors.transparent : borderSubtle,
                                        ),
                                      ),
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? (isDark ? Colors.black : Colors.white) : textPrimary,
                                      ),
                                      showCheckmark: false,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            category = c;
                                            selectedEmoji = defaultEmojiForCategory(c);
                                          });
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 2. Icon / Emoji Selector
                            Text(
                              'ÍCONO / SÍMBOLO DEL ELEMENTO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: textSecondary,
                                letterSpacing: 0.8,
                              ),
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
                                      onTap: () => setState(() => selectedEmoji = e),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isChosen
                                              ? (isDark ? Colors.white24 : Colors.black12)
                                              : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isChosen
                                                ? (isDark ? Colors.white : Colors.black)
                                                : borderSubtle,
                                            width: isChosen ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Text(e, style: const TextStyle(fontSize: 18)),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 3. Name Field
                            Text(
                              'NOMBRE DEL ELEMENTO *',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: titleCtrl,
                              autofocus: true,
                              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'ej: Valle de las Sombras, La Orden del Fénix, El Orbe Solar',
                                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.normal),
                                prefixIcon: Icon(Icons.title_rounded, size: 20, color: textSecondary),
                                filled: true,
                                fillColor: inputBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderSubtle),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderSubtle),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 4. Role / Classification Field
                            Text(
                              'ROL O CLASIFICACIÓN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: roleCtrl,
                              style: TextStyle(color: textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'ej: Fortaleza Capital, Culto Fanático, Amuleto Ancestral',
                                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13),
                                prefixIcon: Icon(Icons.category_outlined, size: 20, color: textSecondary),
                                filled: true,
                                fillColor: inputBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderSubtle),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderSubtle),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 5. Description Field
                            Text(
                              'DESCRIPCIÓN Y LORE DEL MUNDO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: descCtrl,
                              maxLines: 4,
                              style: TextStyle(color: textPrimary, fontSize: 13, height: 1.4),
                              decoration: InputDecoration(
                                hintText: 'Historia, atmósfera, reglas mágicas, leyendas o importancia en el argumento...',
                                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 12),
                                filled: true,
                                fillColor: inputBg,
                                contentPadding: const EdgeInsets.all(16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderSubtle),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderSubtle),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 6. Traits Field & Quick Tags
                            Text(
                              'RASGOS DISTINTIVOS Y ETIQUETAS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: traitsCtrl,
                              style: TextStyle(color: textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Separados por comas: Antiguo, Místico, Fortificado',
                                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13),
                                prefixIcon: Icon(Icons.label_outline_rounded, size: 20, color: textSecondary),
                                filled: true,
                                fillColor: inputBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderSubtle),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderSubtle),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: suggestedCodexTraits.map((t) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                      avatar: const Icon(Icons.add_rounded, size: 14),
                                      label: Text(t, style: const TextStyle(fontSize: 11)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      backgroundColor: inputBg,
                                      onPressed: () {
                                        final cur = traitsCtrl.text.trim();
                                        if (cur.isEmpty) {
                                          traitsCtrl.text = t;
                                        } else if (!cur.toLowerCase().contains(t.toLowerCase())) {
                                          traitsCtrl.text = '$cur, $t';
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Save Button
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
                                icon: const Icon(Icons.check_rounded, size: 20),
                                label: const Text(
                                  'Guardar Entrada en el Códice',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                                onPressed: () {
                                  final title = titleCtrl.text.trim();
                                  if (title.isEmpty) return;

                                  final rawTraits = traitsCtrl.text.split(',');
                                  final traitsList = rawTraits
                                      .map((t) => t.trim())
                                      .where((t) => t.isNotEmpty)
                                      .toList();
                                  if (traitsList.isEmpty) traitsList.add('Lore');

                                  final role = roleCtrl.text.trim().isNotEmpty
                                      ? roleCtrl.text.trim()
                                      : 'Elemento de ${category.name}';

                                  final newEntry = CodexEntryModel(
                                    id: 'codex_${DateTime.now().millisecondsSinceEpoch}',
                                    bookId: controller.activeBook.id,
                                    name: title,
                                    type: category,
                                    role: role,
                                    description: descCtrl.text.trim(),
                                    traits: traitsList,
                                    secrets: '',
                                    avatarEmoji: selectedEmoji,
                                    createdAt: DateTime.now(),
                                  );
                                  controller.addCodexEntry(newEntry);
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('«$title» guardado en el códice.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
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

  static void showCodexDetailModal(BuildContext context, EditorController controller, CodexEntryModel entry, bool isDark) {
    final titleCtrl = TextEditingController(text: entry.name);
    final descCtrl = TextEditingController(text: entry.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bgCard = isDark ? const Color(0xFF1E1E22) : Colors.white;
        final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
        final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(entry.avatarEmoji, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              entry.type.name.toUpperCase(),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        tooltip: 'Eliminar entrada',
                        onPressed: () {
                          controller.deleteCodexEntry(entry.id);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Entrada eliminada'), behavior: SnackBarBehavior.floating),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'Título / Nombre',
                      labelStyle: TextStyle(color: textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 4,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Descripción / Lore',
                      labelStyle: TextStyle(color: textSecondary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Guardar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            final updated = entry.copyWith(
                              name: titleCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                            );
                            controller.updateCodexEntry(updated);
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Entrada actualizada'), behavior: SnackBarBehavior.floating),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Insertar en Editor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          controller.insertTextToEditor(
                            '\n/* Referencia Códice: ${entry.name} */\n${entry.description}\n',
                          );
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

