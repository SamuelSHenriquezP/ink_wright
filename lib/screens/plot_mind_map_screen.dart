import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../models/mind_map_node_model.dart';
import 'zen_editor_screen.dart';

class PlotMindMapScreen extends StatefulWidget {
  const PlotMindMapScreen({super.key});

  @override
  State<PlotMindMapScreen> createState() => _PlotMindMapScreenState();
}

class _PlotMindMapScreenState extends State<PlotMindMapScreen> {
  TimelineActItem? _selectedActFilter;
  late final TransformationController _transformationController;
  String? _connectingFromNodeId;
  bool _isTimelineMode = false;
  Set<String> _extraActIds = {};

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _loadSavedExtraActs();
  }

  Future<void> _loadSavedExtraActs() async {
    try {
      final bookId = Provider.of<EditorController>(context, listen: false).activeBook.id;
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final saved = prefs.getStringList('extra_acts_$bookId') ?? [];
      setState(() {
        _extraActIds = saved.toSet();
      });
    } catch (_) {}
  }

  Future<void> _saveExtraActs() async {
    try {
      final bookId = Provider.of<EditorController>(context, listen: false).activeBook.id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('extra_acts_$bookId', _extraActIds.toList());
    } catch (_) {}
  }

  List<TimelineActItem> _getTimelineActs(EditorController controller) {
    final items = <TimelineActItem>[
      const TimelineActItem(PlotAct.act1Exposition),
      const TimelineActItem(PlotAct.act2RisingAction),
      const TimelineActItem(PlotAct.midpoint),
      const TimelineActItem(PlotAct.act3Climax),
      const TimelineActItem(PlotAct.resolution),
    ];

    void maybeAdd(TimelineActItem item) {
      if (!items.any((i) => i.act == item.act && (i.customName ?? '').trim() == (item.customName ?? '').trim())) {
        items.add(item);
      }
    }

    // 1. Extra acts saved in preferences
    for (final id in _extraActIds) {
      if (id == PlotAct.prologue.name) {
        maybeAdd(const TimelineActItem(PlotAct.prologue));
      } else if (id == PlotAct.act4Fallout.name) {
        maybeAdd(const TimelineActItem(PlotAct.act4Fallout));
      } else if (id == PlotAct.act5Resolution.name) {
        maybeAdd(const TimelineActItem(PlotAct.act5Resolution));
      } else if (id == PlotAct.epilogue.name) {
        maybeAdd(const TimelineActItem(PlotAct.epilogue));
      } else if (id.startsWith('custom:')) {
        final name = id.substring(7).trim();
        if (name.isNotEmpty) {
          maybeAdd(TimelineActItem(PlotAct.custom, name));
        }
      }
    }

    // 2. Add acts from all existing nodes for active book
    for (final node in controller.mindMapNodes) {
      if (node.bookId == controller.activeBook.id) {
        if (node.act == PlotAct.custom) {
          final name = (node.customActName ?? '').trim();
          maybeAdd(TimelineActItem(PlotAct.custom, name.isNotEmpty ? name : 'Personalizado'));
        } else {
          maybeAdd(TimelineActItem(node.act));
        }
      }
    }

    // 3. Sort chronologically
    items.sort((a, b) {
      final cmp = a.orderWeight.compareTo(b.orderWeight);
      if (cmp != 0) return cmp;
      return (a.customName ?? '').compareTo(b.customName ?? '');
    });

    return items;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
  }

  void _zoomIn() {
    final matrix = _transformationController.value.clone();
    matrix.scaleByDouble(1.25, 1.25, 1.0, 1.0);
    _transformationController.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transformationController.value.clone();
    matrix.scaleByDouble(0.8, 0.8, 1.0, 1.0);
    _transformationController.value = matrix;
  }

  void _showAestheticNotification(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline_rounded,
    required bool isDark,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        elevation: 6,
        backgroundColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFF2E2E34) : Colors.white12,
            width: 1,
          ),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _autoArrange(EditorController controller) {
    controller.autoArrangeMindMapNodes();
    _resetView();
    _showAestheticNotification(
      context,
      'Nodos organizados cronológicamente por Actos.',
      icon: Icons.auto_awesome_mosaic_rounded,
      isDark: controller.isDarkMode,
    );
  }

  void _branchFromNode(BuildContext context, MindMapNodeModel parent, EditorController controller) {
    final newId = 'node_${DateTime.now().millisecondsSinceEpoch}';
    final newNode = MindMapNodeModel(
      id: newId,
      bookId: controller.activeBook.id,
      title: 'Subnodo de "${parent.title}"',
      description: 'Ramificación o evento consecuente.',
      act: parent.act,
      type: parent.type == PlotNodeType.mainPlot ? PlotNodeType.subplot : parent.type,
      dx: (parent.dx + 270.0).clamp(20.0, 2250.0),
      dy: (parent.dy + (parent.connectedToIds.length * 80.0)).clamp(20.0, 1600.0),
      connectedToIds: [],
      colorHex: parent.colorHex,
      iconEmoji: parent.iconEmoji,
    );
    controller.addMindMapNode(newNode);
    controller.connectMindMapNodes(parent.id, newId);
    _showAestheticNotification(
      context,
      'Ramificación conectada desde «${parent.title}».',
      icon: Icons.alt_route_rounded,
      isDark: controller.isDarkMode,
    );
  }

  void _showNodeFormModal(
    BuildContext context,
    EditorController controller, {
    MindMapNodeModel? existingNode,
    TimelineActItem? preselectedActItem,
    PlotAct? preselectedAct,
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
                                  '${controller.activeBook.title} • ${selectedActItem.label}',
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

                    // Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Selector de Emoji
                            Text(
                              'ÍCONO / SÍMBOLO NARRATIVO',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textSecondary),
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
                                      onTap: () => setModalState(() => selectedEmoji = e),
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

                            // 2. Title Field
                            Text(
                              'TÍTULO DEL PUNTO DE TRAMA *',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textSecondary),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: titleCtrl,
                              autofocus: !isEditing,
                              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Ej. Incidente Incitador: El robo del manuscrito',
                                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.normal),
                                prefixIcon: Icon(Icons.edit_road_rounded, size: 20, color: textSecondary),
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
                                final availableActItems = _getTimelineActs(controller);
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
                                          onPressed: () {
                                            _showAddActDialog(context, controller);
                                          },
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
                              initialValue: selectedChapterId,
                              dropdownColor: bgCard,
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
                                  return DropdownMenuItem<String?>(
                                    value: ch.id,
                                    child: Text(
                                      'Capítulo ${ch.chapterNumber}: ${ch.title}',
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
                            Wrap(
                              spacing: 10,
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
                                    _extraActIds.add('custom:$customName');
                                    _saveExtraActs();
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
                                    _showAestheticNotification(
                                      context,
                                      'Nodo «$title» actualizado.',
                                      icon: Icons.check_circle_outline_rounded,
                                      isDark: isDark,
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
                                    _showAestheticNotification(
                                      context,
                                      'Punto «$title» creado en ${selectedActItem.label}.',
                                      icon: Icons.add_task_rounded,
                                      isDark: isDark,
                                    );
                                  }
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

  void _showEditNodeDialog(BuildContext context, MindMapNodeModel node, EditorController controller) {
    _showNodeFormModal(context, controller, existingNode: node);
  }

  void _showAddNodeDialog(BuildContext context, EditorController controller) {
    _showNodeFormModal(context, controller);
  }

  /// Opens the add-node dialog with a specific act already pre-selected.
  void _showAddNodeDialogWithAct(BuildContext context, EditorController controller, TimelineActItem preselectedActItem) {
    _showNodeFormModal(context, controller, preselectedActItem: preselectedActItem);
  }

  void _showConnectDialog(BuildContext context, MindMapNodeModel node, EditorController controller, VoidCallback onUpdate) {
    final availableTargets = controller.mindMapNodes.where(
      (n) => n.id != node.id && !node.connectedToIds.contains(n.id),
    ).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Conectar a Otro Nodo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: availableTargets.isEmpty
              ? const Text('Todos los nodos existentes ya están conectados con este.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: availableTargets.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final target = availableTargets[index];
                      return ListTile(
                        leading: Text(target.iconEmoji, style: const TextStyle(fontSize: 20)),
                        title: Text(target.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(target.actLabel, style: const TextStyle(fontSize: 11)),
                        onTap: () {
                          controller.connectMindMapNodes(node.id, target.id);
                          Navigator.of(context).pop();
                          onUpdate();
                        },
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showAddActDialog(BuildContext context, EditorController controller) {
    final isDark = controller.isDarkMode;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final inputBg = isDark ? const Color(0xFF1E1E22) : const Color(0xFFF6F6F8);
    final customNameCtrl = TextEditingController();

    final standardOptions = [
      (PlotAct.prologue, 'Prólogo: Introducción', '📜', 'Establece el trasfondo o la premisa inicial antes del Acto I'),
      (PlotAct.act4Fallout, 'Acto IV: Revelación y Caída', '🌪️', 'Consecuencias del clímax, caída de máscaras y giros inesperados'),
      (PlotAct.act5Resolution, 'Acto V: Desenlace Final', '🏆', 'Estructura clásica en 5 actos: resolución épica o catarsis'),
      (PlotAct.epilogue, 'Epílogo: Conclusión', '🕊️', 'Cierre emocional o vistazo al futuro de los personajes tras la historia'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentTimelineActs = _getTimelineActs(controller);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                    // Drag handle
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
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderSubtle),
                            ),
                            child: const Text('📑', style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gestionar Actos Narrativos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'Personaliza la estructura y línea de tiempo de tu novela',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: textSecondary),
                            onPressed: () => Navigator.of(sheetCtx).pop(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(height: 1, color: borderSubtle),

                    // Scrollable content
                    Flexible(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        children: [
                          Text(
                            'ACTOS CANÓNICOS ADICIONALES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),

                          ...standardOptions.map((opt) {
                            final act = opt.$1;
                            final title = opt.$2;
                            final emoji = opt.$3;
                            final desc = opt.$4;
                            final isEnabled = currentTimelineActs.any((a) => a.act == act);
                            final nodeCount = controller.mindMapNodes
                                .where((n) => n.bookId == controller.activeBook.id && n.act == act)
                                .length;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isEnabled
                                    ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03))
                                    : inputBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isEnabled ? (isDark ? Colors.white24 : Colors.black26) : borderSubtle,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(emoji, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          desc,
                                          style: TextStyle(fontSize: 11, color: textSecondary),
                                        ),
                                        if (nodeCount > 0) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '$nodeCount nodos asignados',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: isEnabled,
                                    activeThumbColor: isDark ? Colors.white : Colors.black,
                                    onChanged: (val) {
                                      if (!val && nodeCount > 0) {
                                        _showAestheticNotification(
                                          context,
                                          'No puedes desactivar $title porque contiene $nodeCount nodos.',
                                          icon: Icons.warning_amber_rounded,
                                          isDark: isDark,
                                        );
                                        return;
                                      }
                                      setModalState(() {
                                        if (val) {
                                          _extraActIds.add(act.name);
                                        } else {
                                          _extraActIds.remove(act.name);
                                        }
                                      });
                                      setState(() {});
                                      _saveExtraActs();
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 16),
                          Text(
                            'CREAR ACTO PERSONALIZADO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: customNameCtrl,
                                  style: TextStyle(color: textPrimary, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Ej. Interludio, Acto II-B, Flashback...',
                                    hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5), fontSize: 12),
                                    filled: true,
                                    fillColor: inputBg,
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
                                      borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white : Colors.black,
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Añadir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                onPressed: () {
                                  final name = customNameCtrl.text.trim();
                                  if (name.isEmpty) return;
                                  setModalState(() {
                                    _extraActIds.add('custom:$name');
                                  });
                                  setState(() {});
                                  _saveExtraActs();
                                  customNameCtrl.clear();
                                  _showAestheticNotification(
                                    context,
                                    'Acto «$name» añadido.',
                                    icon: Icons.check_circle_outline_rounded,
                                    isDark: isDark,
                                  );
                                },
                              ),
                            ],
                          ),

                          // List of existing custom acts
                          Builder(
                            builder: (context) {
                              final customActs = currentTimelineActs.where((a) => a.act == PlotAct.custom).toList();
                              if (customActs.isEmpty) return const SizedBox.shrink();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  Text(
                                    'ACTOS PERSONALIZADOS ACTIVOS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...customActs.map((item) {
                                    final nodeCount = controller.mindMapNodes.where(
                                      (n) => n.bookId == controller.activeBook.id && n.act == PlotAct.custom && (n.customActName ?? '').trim() == (item.customName ?? '').trim(),
                                    ).length;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: inputBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: borderSubtle),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(item.emoji, style: const TextStyle(fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item.label,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '$nodeCount nodos',
                                            style: TextStyle(fontSize: 10, color: textSecondary),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline_rounded, size: 18, color: textSecondary),
                                            tooltip: 'Eliminar acto',
                                            onPressed: () {
                                              if (nodeCount > 0) {
                                                _showAestheticNotification(
                                                  context,
                                                  'Mueve o elimina los $nodeCount nodos antes de quitar «${item.label}».',
                                                  icon: Icons.warning_amber_rounded,
                                                  isDark: isDark,
                                                );
                                                return;
                                              }
                                              setModalState(() {
                                                _extraActIds.remove('custom:${item.customName}');
                                              });
                                              setState(() {});
                                              _saveExtraActs();
                                              _showAestheticNotification(
                                                context,
                                                'Acto «${item.label}» eliminado.',
                                                icon: Icons.delete_sweep_outlined,
                                                isDark: isDark,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
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

  // ─────────────────────────────────────────────
  //  TIMELINE (LÍNEA DE TIEMPO) VIEW
  // ─────────────────────────────────────────────

  Widget _buildTimelineView(
    BuildContext context,
    EditorController controller,
    bool isDark,
  ) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final cardBg = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final bgPrimary = isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary;

    final nodes = controller.mindMapNodes.where((n) => n.bookId == controller.activeBook.id).toList();
    final timelineActs = _getTimelineActs(controller);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...timelineActs.map((actItem) {
            final actNodes = nodes.where((n) {
              if (actItem.act == PlotAct.custom) {
                return n.act == PlotAct.custom &&
                    (n.customActName ?? '').trim() == (actItem.customName ?? '').trim();
              }
              return n.act == actItem.act;
            }).toList();

            return _buildTimelineColumn(
              context: context,
              controller: controller,
              actItem: actItem,
              actNodes: actNodes,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderColor: borderColor,
              cardBg: cardBg,
              bgPrimary: bgPrimary,
            );
          }),
          _buildAddActTimelineCard(context, controller, isDark, textSecondary, borderColor),
        ],
      ),
    );
  }

  Widget _buildAddActTimelineCard(
    BuildContext context,
    EditorController controller,
    bool isDark,
    Color textSecondary,
    Color borderColor,
  ) {
    return GestureDetector(
      onTap: () => _showAddActDialog(context, controller),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, size: 24, color: textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              'Agregar Acto',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Prólogo, Acto IV, Personalizado...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: textSecondary.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineColumn({
    required BuildContext context,
    required EditorController controller,
    required TimelineActItem actItem,
    required List<MindMapNodeModel> actNodes,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required Color cardBg,
    required Color bgPrimary,
  }) {
    const double columnWidth = 280.0;
    final headerBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5);

    final isRemovable = actNodes.isEmpty &&
        actItem.act != PlotAct.act1Exposition &&
        actItem.act != PlotAct.act2RisingAction &&
        actItem.act != PlotAct.act3Climax;

    return DragTarget<MindMapNodeModel>(
      onWillAcceptWithDetails: (details) {
        final node = details.data;
        if (actItem.act == PlotAct.custom) {
          return node.act != PlotAct.custom ||
              (node.customActName ?? '').trim() != (actItem.customName ?? '').trim();
        }
        return node.act != actItem.act;
      },
      onAcceptWithDetails: (details) {
        final node = details.data;
        final updated = node.copyWith(
          act: actItem.act,
          customActName: actItem.act == PlotAct.custom ? actItem.customName : null,
          clearCustomActName: actItem.act != PlotAct.custom,
        );
        controller.updateMindMapNode(updated);
        _showAestheticNotification(
          context,
          '«${node.title}» movido a ${actItem.label}.',
          icon: Icons.swap_horiz_rounded,
          isDark: isDark,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          width: columnWidth,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isHovered
                ? (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? (isDark ? Colors.white30 : Colors.black26) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Act Header ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: headerBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Text(actItem.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        actItem.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Node count badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${actNodes.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    if (isRemovable) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (actItem.act == PlotAct.custom) {
                              _extraActIds.remove('custom:${actItem.customName}');
                            } else {
                              _extraActIds.remove(actItem.act.name);
                            }
                          });
                          _saveExtraActs();
                          _showAestheticNotification(
                            context,
                            'Acto «${actItem.label}» removido.',
                            icon: Icons.remove_circle_outline_rounded,
                            isDark: isDark,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: textSecondary.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Node Cards ──────────────────────────────────────────
              ...actNodes.map((node) => _buildTimelineCard(
                    context: context,
                    node: node,
                    controller: controller,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                    cardBg: cardBg,
                  )),

              // ── Add button at bottom of column ──────────────────────
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showAddNodeDialogWithAct(context, controller, actItem),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Añadir nodo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineCard({
    required BuildContext context,
    required MindMapNodeModel node,
    required EditorController controller,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required Color cardBg,
  }) {
    return LongPressDraggable<MindMapNodeModel>(
      data: node,
      delay: const Duration(milliseconds: 250),
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.88,
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white38 : Colors.black26,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(node.iconEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    node.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTimelineCardContent(
          node: node,
          controller: controller,
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          cardBg: cardBg,
        ),
      ),
      child: GestureDetector(
        onLongPress: () => _showEditNodeDialog(context, node, controller),
        child: _buildTimelineCardContent(
          node: node,
          controller: controller,
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          cardBg: cardBg,
        ),
      ),
    );
  }

  Widget _buildTimelineCardContent({
    required MindMapNodeModel node,
    required EditorController controller,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required Color cardBg,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: AppTheme.getSoftShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: emoji + type badge ──────────────────────────────
          Row(
            children: [
              Text(node.iconEmoji, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  node.typeLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: textPrimary,
                  ),
                ),
              ),
              const Spacer(),
              // Drag hint icon
              Icon(Icons.drag_indicator_rounded, size: 14, color: textSecondary.withValues(alpha: 0.5)),
            ],
          ),

          const SizedBox(height: 8),

          // ── Row 2: Title ──────────────────────────────────────────
          Text(
            node.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.1,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // ── Row 3: Description ────────────────────────────────────
          if (node.description.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              node.description,
              style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // ── Row 4: Linked chapter badge ───────────────────────────
          if (node.linkedChapterId != null) ...[
            () {
              final linkedCh = controller.activeBook.chapters
                  .where((c) => c.id == node.linkedChapterId)
                  .firstOrNull;
              if (linkedCh == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 7),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 10, color: textPrimary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Cap. ${linkedCh.chapterNumber}: ${linkedCh.title}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }(),
          ],

          // ── Row 5: Footer hint ────────────────────────────────────
          const SizedBox(height: 7),
          Text(
            'Mantén presionado para editar • Arrastra para mover',
            style: TextStyle(
              fontSize: 9,
              color: textSecondary.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final controller = Provider.of<EditorController>(context);
    final isDark = controller.isDarkMode;
    final bgPrimary = isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final accentColor = isDark ? Colors.white : Colors.black;
    final cardBg = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final borderColor = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    final nodes = controller.mindMapNodes.where((n) => n.bookId == controller.activeBook.id).toList();
    final timelineActs = _getTimelineActs(controller);
    final filteredNodes = _selectedActFilter == null
        ? nodes
        : nodes.where((n) {
            if (_selectedActFilter!.act == PlotAct.custom) {
              return n.act == PlotAct.custom &&
                  (n.customActName ?? '').trim() == (_selectedActFilter!.customName ?? '').trim();
            }
            return n.act == _selectedActFilter!.act;
          }).toList();

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isTimelineMode ? 'Línea de Tiempo' : 'Mapa Mental de Trama',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            Text(
              '${controller.activeBook.title} • Planificación Narrativa',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        ),
        actions: [
          // ── View toggle button ──────────────────────────────────────
          Tooltip(
            message: _isTimelineMode ? 'Cambiar a Mapa Mental' : 'Cambiar a Línea de Tiempo',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _isTimelineMode = !_isTimelineMode),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isTimelineMode ? Icons.account_tree_outlined : Icons.view_week_outlined,
                        size: 15,
                        color: textPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isTimelineMode ? 'Mapa' : 'Timeline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── Map-only actions ─────────────────────────────────────────
          if (!_isTimelineMode) ...[
            IconButton(
              icon: Icon(Icons.auto_awesome_mosaic_outlined, color: textPrimary),
              onPressed: () => _autoArrange(controller),
              tooltip: 'Organizar Cronológicamente por Actos',
            ),
            IconButton(
              icon: Icon(Icons.center_focus_strong_outlined, color: textPrimary),
              onPressed: _resetView,
              tooltip: 'Centrar Lienzo',
            ),
          ],
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: textPrimary),
            onPressed: () => _showAddNodeDialog(context, controller),
            tooltip: 'Añadir Nodo de Trama',
          ),
        ],
      ),
      body: _isTimelineMode
          // ══════════════════════════════════════════════════════════════════
          //  TIMELINE VIEW (Kanban / Línea de Tiempo)
          // ══════════════════════════════════════════════════════════════════
          ? _buildTimelineView(context, controller, isDark)
          // ══════════════════════════════════════════════════════════════════
          //  MIND MAP CANVAS VIEW
          // ══════════════════════════════════════════════════════════════════
          : Column(
        children: [
          // Filter Pills for Story Acts
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildActFilterChip('Todos los Actos', null, textPrimary, textSecondary, accentColor, isDark),
                ...timelineActs.map((actItem) {
                  return _buildActFilterChip(
                    actItem.shortLabel,
                    actItem,
                    textPrimary,
                    textSecondary,
                    accentColor,
                    isDark,
                  );
                }),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(Icons.add_rounded, size: 16, color: textSecondary),
                    label: Text('Acto', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
                    backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                    onPressed: () => _showAddActDialog(context, controller),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Interactive Canvas Area with Floating Canvas Controls Overlay
          Expanded(
            child: Stack(
              children: [
                ClipRect(
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(1600),
                    minScale: 0.25,
                    maxScale: 2.2,
                    child: SizedBox(
                      width: 2500,
                      height: 1800,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Canvas Grid lines & Custom Painter Connections
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: MindMapConnectionPainter(
                                  nodes: nodes,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),

                          // Interactive Draggable Node Widgets
                          ...filteredNodes.map((node) {
                            final isConnectingSource = _connectingFromNodeId == node.id;
                            final isConnectingMode = _connectingFromNodeId != null;
                            final connectingSourceNode = isConnectingMode
                                ? controller.mindMapNodes.firstWhere(
                                    (n) => n.id == _connectingFromNodeId,
                                    orElse: () => node,
                                  )
                                : null;
                            final isAlreadyConnected = isConnectingMode &&
                                !isConnectingSource &&
                                connectingSourceNode != null &&
                                connectingSourceNode.connectedToIds.contains(node.id);

                            Color cardBorderColor;
                            double cardBorderWidth = 1.5;
                            if (isConnectingSource) {
                              cardBorderColor = isDark ? Colors.white : Colors.black;
                              cardBorderWidth = 2.0;
                            } else if (isConnectingMode) {
                              cardBorderColor = isAlreadyConnected
                                  ? (isDark ? const Color(0xFF52525B) : const Color(0xFFA1A1AA))
                                  : (isDark ? Colors.white70 : Colors.black87);
                              cardBorderWidth = 1.8;
                            } else if (node.colorHex != 0xFF18181B && node.colorHex != 0) {
                              cardBorderColor = Color(node.colorHex).withValues(alpha: 0.4);
                            } else {
                              cardBorderColor = borderColor;
                            }

                            return Positioned(
                              left: node.dx,
                              top: node.dy,
                              child: RepaintBoundary(
                                child: GestureDetector(
                                onPanUpdate: (details) {
                                  final scale = _transformationController.value.getMaxScaleOnAxis();
                                  final effectiveDelta = scale > 0 ? (details.delta / scale) : details.delta;
                                  controller.updateMindMapNodePosition(
                                    node.id,
                                    Offset(
                                      (node.dx + effectiveDelta.dx).clamp(20.0, 2250.0),
                                      (node.dy + effectiveDelta.dy).clamp(20.0, 1600.0),
                                    ),
                                  );
                                },
                                onDoubleTap: () => _showEditNodeDialog(context, node, controller),
                                onTap: () {
                                  if (_connectingFromNodeId != null) {
                                    if (_connectingFromNodeId == node.id) {
                                      setState(() => _connectingFromNodeId = null);
                                    } else {
                                      final fromId = _connectingFromNodeId!;
                                      final fromNode = controller.mindMapNodes.firstWhere(
                                        (n) => n.id == fromId,
                                        orElse: () => node,
                                      );
                                      if (fromNode.connectedToIds.contains(node.id)) {
                                        controller.disconnectMindMapNodes(fromId, node.id);
                                        _showAestheticNotification(
                                          context,
                                          'Enlace eliminado entre «${fromNode.title}» y «${node.title}».',
                                          icon: Icons.link_off_rounded,
                                          isDark: isDark,
                                        );
                                      } else {
                                        controller.connectMindMapNodes(fromId, node.id);
                                        _showAestheticNotification(
                                          context,
                                          '¡Conectado! «${fromNode.title}» ➔ «${node.title}»',
                                          icon: Icons.link_rounded,
                                          isDark: isDark,
                                        );
                                      }
                                      setState(() => _connectingFromNodeId = null);
                                    }
                                  } else {
                                    _showNodeDetailBottomSheet(context, node, controller, isDark);
                                  }
                                },
                                child: Container(
                                  width: 245,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: cardBorderColor,
                                      width: cardBorderWidth,
                                    ),
                                    boxShadow: AppTheme.getSoftShadow(isDark),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (isConnectingSource)
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white : Colors.black,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.link_rounded, size: 12, color: isDark ? Colors.black : Colors.white),
                                              const SizedBox(width: 4),
                                              Text(
                                                'ORIGEN • TOCA OTRO NODO',
                                                style: TextStyle(
                                                  color: isDark ? Colors.black : Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else if (isConnectingMode)
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isAlreadyConnected
                                                ? (isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7))
                                                : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isAlreadyConnected ? Icons.link_off_rounded : Icons.add_link_rounded,
                                                size: 12,
                                                color: textPrimary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isAlreadyConnected ? 'TOCA PARA DESCONECTAR' : 'TOCA PARA CONECTAR AQUÍ',
                                                style: TextStyle(
                                                  color: textPrimary,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              node.typeLabel.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                                color: textPrimary,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(node.iconEmoji, style: const TextStyle(fontSize: 16)),
                                              const SizedBox(width: 6),
                                              // Quick Edit text button
                                              InkWell(
                                                onTap: () => _showEditNodeDialog(context, node, controller),
                                                borderRadius: BorderRadius.circular(12),
                                                child: Tooltip(
                                                  message: 'Editar texto / notas',
                                                  child: Container(
                                                    padding: const EdgeInsets.all(3),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.edit_outlined,
                                                      size: 14,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              // Quick Connect button
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    if (_connectingFromNodeId == node.id) {
                                                      _connectingFromNodeId = null;
                                                    } else {
                                                      _connectingFromNodeId = node.id;
                                                    }
                                                  });
                                                },
                                                borderRadius: BorderRadius.circular(12),
                                                child: Tooltip(
                                                  message: isConnectingSource ? 'Cancelar conexión' : 'Conectar con otro nodo',
                                                  child: Container(
                                                    padding: const EdgeInsets.all(3),
                                                    decoration: BoxDecoration(
                                                      color: isConnectingSource
                                                          ? (isDark ? Colors.white : Colors.black)
                                                          : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.link_rounded,
                                                      size: 14,
                                                      color: isConnectingSource
                                                          ? (isDark ? Colors.black : Colors.white)
                                                          : textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              // Quick Branch button
                                              InkWell(
                                                onTap: () => _branchFromNode(context, node, controller),
                                                borderRadius: BorderRadius.circular(12),
                                                child: Tooltip(
                                                  message: 'Ramificar Subnodo',
                                                  child: Container(
                                                    padding: const EdgeInsets.all(3),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.alt_route_rounded,
                                                      size: 14,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        node.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (node.description.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          node.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textSecondary,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      if (node.linkedChapterId != null) ...[
                                        () {
                                          final linkedCh = controller.activeBook.chapters
                                              .where((c) => c.id == node.linkedChapterId)
                                              .firstOrNull;
                                          if (linkedCh == null) return const SizedBox.shrink();
                                          return InkWell(
                                            onTap: () {
                                              controller.selectChapter(linkedCh);
                                              Navigator.of(context).push(
                                                MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              margin: const EdgeInsets.only(top: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.menu_book_rounded, size: 11, color: textPrimary),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      'Cap. ${linkedCh.chapterNumber}: ${linkedCh.title}',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: textPrimary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Icon(Icons.arrow_forward_ios_rounded, size: 8, color: textSecondary),
                                                ],
                                              ),
                                            ),
                                          );
                                        }(),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            node.actLabel,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: textSecondary.withValues(alpha: 0.8),
                                            ),
                                          ),
                                          if (node.connectedToIds.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.hub_outlined, size: 10, color: textSecondary),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '${node.connectedToIds.length}',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textSecondary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ),
                            );
                            }),
                        ],
                      ),
                    ),
                  ),
                ),

                // Floating Banner for Active Connection Mode
                if (_connectingFromNodeId != null)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Center(
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(30),
                        color: isDark ? const Color(0xFF1E1E22) : const Color(0xFF18181B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF2E2E34) : Colors.white12,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.hub_outlined, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Conectar: toca cualquier otro nodo para enlazarlo',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () => setState(() => _connectingFromNodeId = null),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Floating Canvas Controls Toolbar (Zoom, Fit, Arrange) - Vertical Pill Dock
                Positioned(
                  bottom: 24,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: cardBg.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                      boxShadow: AppTheme.getSoftShadow(isDark),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.zoom_in_rounded, size: 20),
                          color: textPrimary,
                          onPressed: _zoomIn,
                          tooltip: 'Acercar lienzo',
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.zoom_out_rounded, size: 20),
                          color: textPrimary,
                          onPressed: _zoomOut,
                          tooltip: 'Alejar lienzo',
                          visualDensity: VisualDensity.compact,
                        ),
                        Container(
                          width: 20,
                          height: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: borderColor,
                        ),
                        IconButton(
                          icon: const Icon(Icons.center_focus_strong_outlined, size: 20),
                          color: textPrimary,
                          onPressed: _resetView,
                          tooltip: 'Restablecer vista 1:1',
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.auto_awesome_mosaic_rounded, size: 20),
                          color: textPrimary,
                          onPressed: () => _autoArrange(controller),
                          tooltip: 'Organizar por Actos',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _isTimelineMode ? 'Nuevo Nodo' : 'Punto de Trama',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        onPressed: () => _showAddNodeDialog(context, controller),
      ),
    );
  }

  Widget _buildActFilterChip(
    String label,
    TimelineActItem? actItem,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
    bool isDark,
  ) {
    final isSelected = _selectedActFilter == actItem;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: isDark ? Colors.white : Colors.black,
        backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? (isDark ? Colors.black : Colors.white)
              : textSecondary,
        ),
        onSelected: (selected) {
          setState(() {
            _selectedActFilter = selected ? actItem : null;
          });
        },
      ),
    );
  }

  void _showNodeDetailBottomSheet(
    BuildContext context,
    MindMapNodeModel node,
    EditorController controller,
    bool isDark,
  ) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentNode = controller.mindMapNodes.firstWhere(
              (n) => n.id == node.id,
              orElse: () => node,
            );
            final connectedNodes = controller.mindMapNodes
                .where((n) => currentNode.connectedToIds.contains(n.id))
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with title and quick actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(currentNode.iconEmoji, style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentNode.title,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${currentNode.actLabel} • ${currentNode.typeLabel}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              tooltip: 'Editar detalles',
                              color: textPrimary,
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showEditNodeDialog(context, currentNode, controller);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 19),
                              tooltip: 'Duplicar nodo',
                              color: textPrimary,
                              onPressed: () {
                                controller.duplicateMindMapNode(currentNode.id);
                                Navigator.of(context).pop();
                                _showAestheticNotification(
                                  context,
                                  'Nodo duplicado en el lienzo.',
                                  icon: Icons.copy_rounded,
                                  isDark: isDark,
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF27272A),
                                size: 20,
                              ),
                              tooltip: 'Eliminar nodo',
                              onPressed: () {
                                controller.deleteMindMapNode(currentNode.id);
                                Navigator.of(context).pop();
                                _showAestheticNotification(
                                  context,
                                  'Nodo eliminado.',
                                  icon: Icons.delete_outline_rounded,
                                  isDark: isDark,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    if (currentNode.description.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          currentNode.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],

                    if (currentNode.linkedChapterId != null) ...[
                      () {
                        final linkedCh = controller.activeBook.chapters
                            .where((c) => c.id == currentNode.linkedChapterId)
                            .firstOrNull;
                        if (linkedCh == null) return const SizedBox.shrink();
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.menu_book_rounded, size: 20, color: textPrimary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CAPÍTULO VINCULADO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Capítulo ${linkedCh.chapterNumber}: ${linkedCh.title}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                label: const Text('Ir al Capítulo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                onPressed: () {
                                  controller.selectChapter(linkedCh);
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }(),
                    ],

                    const SizedBox(height: 16),

                    // Section: Connections
                    Text(
                      'CONEXIONES E HILOS NARRATIVOS (${connectedNodes.length})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...connectedNodes.map((target) {
                          return Chip(
                            backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                            avatar: Text(target.iconEmoji, style: const TextStyle(fontSize: 13)),
                            label: Text(
                              target.title,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                            deleteIcon: const Icon(Icons.close_rounded, size: 14),
                            deleteButtonTooltipMessage: 'Desconectar',
                            onDeleted: () {
                              controller.disconnectMindMapNodes(currentNode.id, target.id);
                              setSheetState(() {});
                            },
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          );
                        }),
                        ActionChip(
                          avatar: const Icon(Icons.add_link_rounded, size: 16),
                          label: const Text('Conectar a...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onPressed: () {
                            _showConnectDialog(context, currentNode, controller, () {
                              setSheetState(() {});
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.alt_route_rounded, size: 16),
                          label: const Text('Ramificar Subnodo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _branchFromNode(context, currentNode, controller);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textPrimary,
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Editar Datos', style: TextStyle(fontWeight: FontWeight.w700)),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showEditNodeDialog(context, currentNode, controller);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            icon: const Icon(Icons.edit_note_rounded, size: 18),
                            label: const Text('Insertar en Texto', style: TextStyle(fontWeight: FontWeight.w700)),
                            onPressed: () {
                              controller.insertTextToEditor(
                                '\n\n/* Punto de Trama: ${currentNode.title} (${currentNode.actLabel}) */\n${currentNode.description}\n\n',
                              );
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                              );
                            },
                          ),
                        ),
                      ],
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
}

// Custom Painter for Monochrome Bezier connections between nodes
class MindMapConnectionPainter extends CustomPainter {
  final List<MindMapNodeModel> nodes;
  final bool isDark;

  MindMapConnectionPainter({
    required this.nodes,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle dot grid background for spatial orientation
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;
    const double step = 48.0;
    for (double x = 20; x < size.width; x += step) {
      for (double y = 20; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, gridPaint);
      }
    }

    final Map<String, MindMapNodeModel> nodeMap = {for (var n in nodes) n.id: n};
    final lineColor = isDark ? Colors.white24 : Colors.black26;

    for (var sourceNode in nodes) {
      final sourceOffset = Offset(sourceNode.dx + 115, sourceNode.dy + 50);

      for (var targetId in sourceNode.connectedToIds) {
        final targetNode = nodeMap[targetId];
        if (targetNode != null) {
          final targetOffset = Offset(targetNode.dx + 115, targetNode.dy + 50);

          final path = Path();
          path.moveTo(sourceOffset.dx, sourceOffset.dy);

          final controlPoint1 = Offset(sourceOffset.dx + 80, sourceOffset.dy);
          final controlPoint2 = Offset(targetOffset.dx - 80, targetOffset.dy);

          path.cubicTo(
            controlPoint1.dx,
            controlPoint1.dy,
            controlPoint2.dx,
            controlPoint2.dy,
            targetOffset.dx,
            targetOffset.dy,
          );

          final paint = Paint()
            ..color = lineColor
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke
            ..strokeCap = ui.StrokeCap.round;

          canvas.drawPath(path, paint);

          // Connection Node Dots
          final dotPaint = Paint()
            ..color = isDark ? Colors.white : Colors.black
            ..style = PaintingStyle.fill;

          canvas.drawCircle(sourceOffset, 4, dotPaint);
          canvas.drawCircle(targetOffset, 4, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MindMapConnectionPainter oldDelegate) => true;
}