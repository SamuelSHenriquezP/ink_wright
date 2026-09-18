import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../controllers/editor_controller.dart';
import '../../models/mind_map_node_model.dart';

/// Modal bottom sheet for creating or editing a mind map / plot node.
void showPlotNodeFormModal(
  BuildContext context,
  EditorController controller, {
  MindMapNodeModel? existingNode,
  TimelineActItem? preselectedActItem,
  PlotAct? preselectedAct,
  required List<TimelineActItem> Function() getTimelineActs,
  required VoidCallback onOpenAddActDialog,
  required void Function(String customActName) onAddCustomAct,
  required void Function(String message, {IconData icon}) onNotify,
}) {
  final isEditing = existingNode != null;
  final isDark = controller.isDarkMode;
  final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
  final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
  final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
  final inputBg = isDark ? const Color(0xFF1E1E22) : const Color(0xFFF6F6F8);

  final titleCtrl = TextEditingController(text: existingNode?.title ?? '');
  final descCtrl = TextEditingController(text: existingNode?.description ?? '');
  final customActCtrl = TextEditingController(
    text: existingNode?.customActName ?? preselectedActItem?.customName ?? '',
  );

  TimelineActItem selectedActItem;
  if (existingNode != null) {
    selectedActItem = TimelineActItem(existingNode.act, existingNode.customActName);
  } else if (preselectedActItem != null) {
    selectedActItem = preselectedActItem;
  } else if (preselectedAct != null) {
    selectedActItem = TimelineActItem(preselectedAct);
  } else {
    selectedActItem = const TimelineActItem(PlotAct.act1Exposition);
  }

  PlotNodeType selectedType = existingNode?.type ?? PlotNodeType.mainPlot;
  String selectedEmoji = existingNode?.iconEmoji ?? '📌';
  int selectedColor = existingNode?.colorHex ?? 0xFF18181B;
  String? selectedChapterId = existingNode?.linkedChapterId;

  const availableEmojis = [
    '📌', '🎬', '⚡', '🔍', '⚔️', '💔', '👑', '💡', '🗝️', '💥',
    '🩸', '🕊️', '🏰', '🎭', '🌙', '👁️', '📜', '🧭', '🛡️', '✨'
  ];

  const availableColors = [
    0xFF18181B, // Onyx
    0xFF3F3F46, // Graphite
    0xFF71717A, // Steel
    0xFFB91C1C, // Crimson
    0xFFB45309, // Amber
    0xFF047857, // Emerald
    0xFF1D4ED8, // Sapphire
    0xFF6D28D9, // Violet
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
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
                                isEditing ? 'Editar Punto de Trama' : 'Nuevo Punto de Trama',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                '${selectedActItem.label} • ${selectedType.label}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: textSecondary),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: borderSubtle),

                  // Scrollable Body con desvanecimiento superior suave para evitar recortes abruptos
                  Flexible(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.04, 0.96, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Emoji Picker
                          Text(
                            'ICONO REPRESENTATIVO',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textSecondary),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 48,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: availableEmojis.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final emoji = availableEmojis[index];
                                final isChosen = emoji == selectedEmoji;
                                return InkWell(
                                  onTap: () => setModalState(() => selectedEmoji = emoji),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isChosen
                                          ? (isDark ? Colors.white24 : Colors.black12)
                                          : inputBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isChosen ? (isDark ? Colors.white : Colors.black) : borderSubtle,
                                        width: isChosen ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. Title Field
                          Text(
                            'TÍTULO DEL HITO / EVENTO',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textSecondary),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: titleCtrl,
                            autofocus: !isEditing,
                            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Ej. El Descubrimiento del Códice Antiguo',
                              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontWeight: FontWeight.w400, fontSize: 13),
                              filled: true,
                              fillColor: inputBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3. Act Narrative Choice Chips
                          Text(
                            'ACTO NARRATIVO',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final availableActItems = getTimelineActs();
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    ...availableActItems.map((actItem) {
                                      final isSelected = selectedActItem == actItem;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          label: Text(actItem.shortLabel),
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
                                            if (selected) {
                                              setModalState(() => selectedActItem = actItem);
                                            }
                                          },
                                        ),
                                      );
                                    }),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ActionChip(
                                        avatar: Icon(Icons.add_rounded, size: 16, color: textSecondary),
                                        label: Text(
                                          'Más Actos',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                                        ),
                                        backgroundColor: inputBg,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        side: BorderSide(color: borderSubtle),
                                        onPressed: onOpenAddActDialog,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          if (selectedActItem.act == PlotAct.custom) ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: customActCtrl,
                              style: TextStyle(color: textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Nombre del Acto Personalizado',
                                labelStyle: TextStyle(color: textSecondary, fontSize: 12),
                                hintText: 'Ej. Interludio, Flashback, Acto II-B...',
                                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 12),
                                filled: true,
                                fillColor: inputBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderSubtle)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderSubtle)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // 4. Element Type Choice Chips
                          Text(
                            'TIPO DE ELEMENTO',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: PlotNodeType.values.map((type) {
                              final isSelected = selectedType == type;
                              return ChoiceChip(
                                label: Text(type.label),
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
                                  if (selected) setModalState(() => selectedType = type);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // 5. Linked Chapter Dropdown
                          Text(
                            'CAPÍTULO VINCULADO (OPCIONAL)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textSecondary),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String?>(
                            isExpanded: true,
                            initialValue: selectedChapterId,
                            dropdownColor: bgCard,
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: textSecondary),
                            style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.menu_book_rounded, size: 20, color: textSecondary),
                              filled: true,
                              fillColor: inputBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Ninguno (No vinculado)'),
                              ),
                              ...controller.activeBook.chapters.map((ch) {
                                final cleanTitle = ch.title.trim();
                                final hasPrefix = RegExp(r'^cap[ií]tulo\s*\d*[:\s.-]*', caseSensitive: false).hasMatch(cleanTitle);
                                final chapterLabel = hasPrefix ? cleanTitle : 'Capítulo ${ch.chapterNumber}: $cleanTitle';
                                return DropdownMenuItem<String?>(
                                  value: ch.id,
                                  child: Text(
                                    chapterLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setModalState(() => selectedChapterId = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // 6. Description Field
                          Text(
                            'DESCRIPCIÓN / SUCESOS CLAVE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textSecondary),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: descCtrl,
                            maxLines: 4,
                            style: TextStyle(color: textPrimary, fontSize: 13, height: 1.4),
                            decoration: InputDecoration(
                              hintText: '¿Qué ocurre en este hito? Consecuencias para los personajes, revelaciones o decisiones tomadas...',
                              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 12),
                              filled: true,
                              fillColor: inputBg,
                              contentPadding: const EdgeInsets.all(16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 7. Color Palette
                          Text(
                            'COLOR DE ACENTO',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: availableColors.map((c) {
                              final isChosen = c == selectedColor;
                              return InkWell(
                                onTap: () => setModalState(() => selectedColor = c),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Color(c),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isChosen ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: isChosen
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                                ),
                              );
                            }).toList(),
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
                              icon: Icon(isEditing ? Icons.save_rounded : Icons.add_rounded, size: 20),
                              label: Text(
                                isEditing ? 'Guardar Cambios' : 'Crear Punto de Trama',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              onPressed: () {
                                final title = titleCtrl.text.trim();
                                if (title.isEmpty) return;

                                final customName = selectedActItem.act == PlotAct.custom
                                    ? (customActCtrl.text.trim().isNotEmpty
                                        ? customActCtrl.text.trim()
                                        : (selectedActItem.customName ?? 'Personalizado'))
                                    : null;

                                if (selectedActItem.act == PlotAct.custom && customName != null && customName.isNotEmpty) {
                                  onAddCustomAct(customName);
                                }

                                if (isEditing) {
                                  final updated = existingNode.copyWith(
                                    title: title,
                                    description: descCtrl.text.trim(),
                                    act: selectedActItem.act,
                                    customActName: customName,
                                    clearCustomActName: selectedActItem.act != PlotAct.custom,
                                    type: selectedType,
                                    iconEmoji: selectedEmoji,
                                    colorHex: selectedColor,
                                    linkedChapterId: selectedChapterId,
                                    clearLinkedChapter: selectedChapterId == null,
                                  );
                                  controller.updateMindMapNode(updated);
                                  Navigator.of(sheetContext).pop();
                                  onNotify(
                                    'Nodo «$title» actualizado.',
                                    icon: Icons.check_circle_outline_rounded,
                                  );
                                } else {
                                  final newNode = MindMapNodeModel(
                                    id: 'node_${DateTime.now().millisecondsSinceEpoch}',
                                    bookId: controller.activeBook.id,
                                    title: title,
                                    description: descCtrl.text.trim(),
                                    act: selectedActItem.act,
                                    customActName: customName,
                                    type: selectedType,
                                    dx: 350 + (controller.mindMapNodes.length * 40),
                                    dy: 200 + (controller.mindMapNodes.length * 30),
                                    connectedToIds: [],
                                    colorHex: selectedColor,
                                    iconEmoji: selectedEmoji,
                                    linkedChapterId: selectedChapterId,
                                  );
                                  controller.addMindMapNode(newNode);
                                  Navigator.of(sheetContext).pop();
                                  onNotify(
                                    'Punto «$title» creado en ${selectedActItem.label}.',
                                    icon: Icons.add_task_rounded,
                                  );
                                }
                              },
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
          );
        },
      );
    },
  );
}
