import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  PlotAct? _selectedActFilter;
  late final TransformationController _transformationController;
  String? _connectingFromNodeId;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
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

  void _showEditNodeDialog(BuildContext context, MindMapNodeModel node, EditorController controller) {
    final titleCtrl = TextEditingController(text: node.title);
    final descCtrl = TextEditingController(text: node.description);
    PlotAct selectedAct = node.act;
    PlotNodeType selectedType = node.type;
    String selectedEmoji = node.iconEmoji;
    int selectedColor = node.colorHex;

    const availableEmojis = [
      '📌', '🧭', '⚔️', '📜', '⚡', '🗝️', '🏰', '👤', '💡', '🔥', '💀', '🌫️', '🏛️', '👁️', '🎭', '🛡️', '👑', '✨'
    ];
    const availableColors = [
      0xFF18181B, // Onyx
      0xFF27272A, // Charcoal
      0xFF3F3F46, // Graphite
      0xFF52525B, // Slate
      0xFF71717A, // Steel
      0xFFA1A1AA, // Ash
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Text(selectedEmoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Editar Contenido del Nodo',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Título del Nodo',
                        hintText: 'Texto o suceso principal',
                        prefixIcon: Icon(Icons.title_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Texto Interior / Notas',
                        hintText: 'Escribe lo que contiene o pasa en este nodo...',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PlotAct>(
                      initialValue: selectedAct,
                      decoration: const InputDecoration(labelText: 'Acto Narrativo'),
                      items: PlotAct.values.map((act) {
                        final dummy = MindMapNodeModel(
                          id: '', bookId: '', title: '', description: '', act: act,
                          type: PlotNodeType.mainPlot, dx: 0, dy: 0, connectedToIds: [],
                          colorHex: 0, iconEmoji: '',
                        );
                        return DropdownMenuItem(value: act, child: Text(dummy.actLabel));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedAct = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PlotNodeType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Tipo de Elemento'),
                      items: PlotNodeType.values.map((type) {
                        final dummy = MindMapNodeModel(
                          id: '', bookId: '', title: '', description: '', act: PlotAct.act1Exposition,
                          type: type, dx: 0, dy: 0, connectedToIds: [], colorHex: 0, iconEmoji: '',
                        );
                        return DropdownMenuItem(value: type, child: Text(dummy.typeLabel));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Icono / Emoji:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: availableEmojis.map((e) {
                        final isChosen = e == selectedEmoji;
                        return InkWell(
                          onTap: () => setState(() => selectedEmoji = e),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isChosen ? Colors.black12 : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isChosen ? Colors.black : Colors.transparent),
                            ),
                            child: Text(e, style: const TextStyle(fontSize: 20)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Color de Acento:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: availableColors.map((c) {
                        final isChosen = c == selectedColor;
                        return InkWell(
                          onTap: () => setState(() => selectedColor = c),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isChosen ? Colors.black : Colors.white,
                                width: isChosen ? 3 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isNotEmpty) {
                      final updated = node.copyWith(
                        title: title,
                        description: descCtrl.text.trim(),
                        act: selectedAct,
                        type: selectedType,
                        iconEmoji: selectedEmoji,
                        colorHex: selectedColor,
                      );
                      controller.updateMindMapNode(updated);
                      Navigator.of(context).pop();
                      _showAestheticNotification(
                        context,
                        'Nodo «$title» actualizado.',
                        icon: Icons.check_circle_outline_rounded,
                        isDark: controller.isDarkMode,
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
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

  void _showAddNodeDialog(BuildContext context, EditorController controller) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    PlotAct selectedAct = PlotAct.act1Exposition;
    PlotNodeType selectedType = PlotNodeType.mainPlot;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Nuevo Punto de Trama',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título del Punto de Trama',
                        hintText: 'Ej. Incidente Incitador: El Descubrimiento',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<PlotAct>(
                      initialValue: selectedAct,
                      decoration: const InputDecoration(labelText: 'Acto Narrativo'),
                      items: PlotAct.values.map((act) {
                        final dummy = MindMapNodeModel(
                          id: '',
                          bookId: '',
                          title: '',
                          description: '',
                          act: act,
                          type: PlotNodeType.mainPlot,
                          dx: 0,
                          dy: 0,
                          connectedToIds: [],
                          colorHex: 0,
                          iconEmoji: '',
                        );
                        return DropdownMenuItem(
                          value: act,
                          child: Text(dummy.actLabel),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedAct = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<PlotNodeType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Tipo de Elemento'),
                      items: PlotNodeType.values.map((type) {
                        final dummy = MindMapNodeModel(
                          id: '',
                          bookId: '',
                          title: '',
                          description: '',
                          act: PlotAct.act1Exposition,
                          type: type,
                          dx: 0,
                          dy: 0,
                          connectedToIds: [],
                          colorHex: 0,
                          iconEmoji: '',
                        );
                        return DropdownMenuItem(
                          value: type,
                          child: Text(dummy.typeLabel),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción / Notas de la Escena',
                        hintText: 'Detalles clave sobre la trama o personaje...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isNotEmpty) {
                      final newNode = MindMapNodeModel(
                        id: 'node_${DateTime.now().millisecondsSinceEpoch}',
                        bookId: controller.activeBook.id,
                        title: title,
                        description: descCtrl.text.trim(),
                        act: selectedAct,
                        type: selectedType,
                        dx: 350 + (controller.mindMapNodes.length * 40),
                        dy: 200 + (controller.mindMapNodes.length * 30),
                        connectedToIds: [],
                        colorHex: 0xFF18181B,
                        iconEmoji: '📌',
                      );
                      controller.addMindMapNode(newNode);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Crear Nodo'),
                ),
              ],
            );
          },
        );
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

    final nodes = controller.mindMapNodes;
    final filteredNodes = _selectedActFilter == null
        ? nodes
        : nodes.where((n) => n.act == _selectedActFilter).toList();

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
              'Mapa Mental de Trama',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            Text(
              '${controller.activeBook.title} • Planificación Narrativa',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        ),
        actions: [
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
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: textPrimary),
            onPressed: () => _showAddNodeDialog(context, controller),
            tooltip: 'Añadir Nodo de Trama',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Pills for Story Acts
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildActFilterChip('Todos los Actos', null, textPrimary, textSecondary, accentColor, isDark),
                _buildActFilterChip('Acto I', PlotAct.act1Exposition, textPrimary, textSecondary, accentColor, isDark),
                _buildActFilterChip('Acto II', PlotAct.act2RisingAction, textPrimary, textSecondary, accentColor, isDark),
                _buildActFilterChip('Punto Medio', PlotAct.midpoint, textPrimary, textSecondary, accentColor, isDark),
                _buildActFilterChip('Acto III', PlotAct.act3Climax, textPrimary, textSecondary, accentColor, isDark),
                _buildActFilterChip('Resolución', PlotAct.resolution, textPrimary, textSecondary, accentColor, isDark),
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
                            child: CustomPaint(
                              painter: MindMapConnectionPainter(
                                nodes: nodes,
                                isDark: isDark,
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

                // Floating Canvas Controls Toolbar (Zoom, Fit, Arrange)
                Positioned(
                  bottom: 24,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardBg.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: borderColor),
                      boxShadow: AppTheme.getSoftShadow(isDark),
                    ),
                    child: Row(
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
                          width: 1,
                          height: 20,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
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
        label: const Text(
          'Punto de Trama',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        onPressed: () => _showAddNodeDialog(context, controller),
      ),
    );
  }

  Widget _buildActFilterChip(
    String label,
    PlotAct? act,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
    bool isDark,
  ) {
    final isSelected = _selectedActFilter == act;
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
            _selectedActFilter = act;
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
