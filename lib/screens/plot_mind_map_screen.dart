import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../models/mind_map_node_model.dart';
import '../widgets/plot_mind_map/act_management_sheet.dart';
import '../widgets/plot_mind_map/node_form_modal.dart';
import '../widgets/plot_mind_map/node_detail_modal.dart';
import '../widgets/plot_mind_map/plot_timeline_view.dart';
import '../widgets/plot_mind_map/plot_connection_painter.dart';
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
    showPlotNodeFormModal(
      context,
      controller,
      existingNode: existingNode,
      preselectedActItem: preselectedActItem,
      preselectedAct: preselectedAct,
      getTimelineActs: () => _getTimelineActs(controller),
      onOpenAddActDialog: () => _showAddActDialog(context, controller),
      onAddCustomAct: (customActName) {
        _extraActIds.add('custom:$customActName');
        _saveExtraActs();
        setState(() {});
      },
      onNotify: (msg, {icon = Icons.info_outline_rounded}) {
        _showAestheticNotification(context, msg, icon: icon, isDark: controller.isDarkMode);
      },
    );
  }

  void _showEditNodeDialog(BuildContext context, MindMapNodeModel node, EditorController controller) {
    _showNodeFormModal(context, controller, existingNode: node);
  }

  void _showAddNodeDialog(BuildContext context, EditorController controller) {
    _showNodeFormModal(context, controller);
  }

  void _showAddNodeDialogWithAct(BuildContext context, EditorController controller, TimelineActItem preselectedActItem) {
    _showNodeFormModal(context, controller, preselectedActItem: preselectedActItem);
  }


  void _showAddActDialog(BuildContext context, EditorController controller) {
    showActManagementSheet(
      context: context,
      controller: controller,
      getTimelineActs: () => _getTimelineActs(controller),
      extraActIds: _extraActIds,
      onActsUpdated: () {
        setState(() {});
        _saveExtraActs();
      },
      onNotify: (msg, {icon = Icons.info_outline_rounded}) {
        _showAestheticNotification(context, msg, icon: icon, isDark: controller.isDarkMode);
      },
    );
  }

  Widget _buildTimelineView(BuildContext context, EditorController controller, bool isDark) {
    return PlotTimelineView(
      controller: controller,
      timelineActs: _getTimelineActs(controller),
      onOpenAddActDialog: () => _showAddActDialog(context, controller),
      onAddNodeWithAct: (actItem) => _showAddNodeDialogWithAct(context, controller, actItem),
      onEditNode: (node) => _showEditNodeDialog(context, node, controller),
      onRemoveAct: (actItem) {
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
      onNotify: (msg, {icon = Icons.info_outline_rounded}) {
        _showAestheticNotification(context, msg, icon: icon, isDark: isDark);
      },
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
    showPlotNodeDetailModal(
      context: context,
      node: node,
      controller: controller,
      onEditNode: (n) => _showEditNodeDialog(context, n, controller),
      onBranchNode: (n) => _branchFromNode(context, n, controller),
      onNotify: (msg, {icon = Icons.info_outline_rounded}) {
        _showAestheticNotification(context, msg, icon: icon, isDark: isDark);
      },
    );
  }
}