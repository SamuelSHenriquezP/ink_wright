import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../theme/app_theme.dart';

class ZenTypographySheet {
  static void show({
    required BuildContext context,
    required EditorController controller,
    required bool isDark,
    required VoidCallback onSettingsChanged,
  }) {
    final bgCard = isDark ? const Color(0xFF1E1E22) : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    const fontFamilies = ['Lora', 'Merriweather', 'Playfair Display', 'JetBrains Mono'];
    const lineHeights = [1.4, 1.65, 1.9, 2.2];
    const columnWidths = [560.0, 720.0, 900.0, double.infinity];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ajustes Tipométricos y de Edición',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Modo Máquina de Escribir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                    subtitle: Text('Mantiene la línea del cursor centrada verticalmente', style: TextStyle(fontSize: 12, color: textSecondary)),
                    value: controller.isTypewriterMode,
                    activeTrackColor: isDark ? Colors.white : Colors.black,
                    onChanged: (val) {
                      controller.toggleTypewriterMode();
                      setSheetState(() {});
                      onSettingsChanged();
                    },
                  ),
                  const Divider(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tamaño de Fuente', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                      Text('${controller.fontSize.toStringAsFixed(1)} px', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                    ],
                  ),
                  Slider(
                    value: controller.fontSize,
                    min: 13.0,
                    max: 24.0,
                    divisions: 22,
                    activeColor: isDark ? Colors.white : Colors.black,
                    inactiveColor: borderSubtle,
                    onChanged: (val) {
                      controller.setFontSize(val);
                      setSheetState(() {});
                      onSettingsChanged();
                    },
                  ),

                  const SizedBox(height: 8),
                  Text('Interlineado', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: lineHeights.map((lh) {
                      final isSelected = (controller.lineHeight - lh).abs() < 0.05;
                      return ChoiceChip(
                        label: Text('${lh}x'),
                        selected: isSelected,
                        selectedColor: isDark ? Colors.white : Colors.black,
                        backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? (isDark ? Colors.black : Colors.white) : textSecondary,
                        ),
                        onSelected: (_) {
                          controller.setLineHeight(lh);
                          setSheetState(() {});
                          onSettingsChanged();
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),
                  Text('Ancho de Columna', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: columnWidths.map((w) {
                      final isSelected = controller.maxEditorWidth == w;
                      final label = w == double.infinity ? '100% Pantalla' : '${w.toInt()}px';
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: isDark ? Colors.white : Colors.black,
                        backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? (isDark ? Colors.black : Colors.white) : textSecondary,
                        ),
                        onSelected: (_) {
                          controller.setMaxEditorWidth(w);
                          setSheetState(() {});
                          onSettingsChanged();
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),
                  Text('Familia Tipográfica', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: fontFamilies.map((font) {
                      final isSelected = controller.selectedFontFamily == font;
                      return ChoiceChip(
                        label: Text(font),
                        selected: isSelected,
                        selectedColor: isDark ? Colors.white : Colors.black,
                        backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? (isDark ? Colors.black : Colors.white) : textSecondary,
                        ),
                        onSelected: (_) {
                          controller.setFontFamily(font);
                          setSheetState(() {});
                          onSettingsChanged();
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderSubtle),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.call_split_rounded, size: 18),
                    label: const Text('Dividir capítulo en el cursor actual', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _splitChapterAtCursor(context, controller);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void _splitChapterAtCursor(BuildContext context, EditorController controller) {
    final text = controller.textEditingController.text;
    final pos = controller.textEditingController.selection.baseOffset;
    if (pos <= 0 || pos >= text.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coloca el cursor dentro del texto para dividir el capítulo.')),
      );
      return;
    }

    final titleCtrl = TextEditingController(text: '${controller.activeChapter.title} (Parte 2)');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dividir Capítulo Aquí'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se dividirá el texto en la posición del cursor (carácter $pos).'),
            const SizedBox(height: 14),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Título del nuevo capítulo'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () {
              final newChapter = controller.splitChapter(controller.activeChapter.id, pos, newChapterTitle: titleCtrl.text.trim());
              Navigator.of(ctx).pop();
              if (newChapter != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Capítulo dividido con éxito: "${newChapter.title}" creado.')),
                );
              }
            },
            child: const Text('Dividir'),
          ),
        ],
      ),
    );
  }
}

