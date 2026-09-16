import '../models/mind_map_node_model.dart';

/// Service handling mind map auto-layout, node duplications, and connection topology.
class MindMapLayoutService {
  const MindMapLayoutService._();

  /// Duplicates an existing node with an offset position.
  static MindMapNodeModel duplicateNode(MindMapNodeModel original) {
    return original.copyWith(
      id: 'node_${DateTime.now().millisecondsSinceEpoch}',
      bookId: original.bookId,
      title: '${original.title} (Copia)',
      dx: original.dx + 40,
      dy: original.dy + 40,
      connectedToIds: [],
    );
  }

  /// Automatically arranges nodes into columns by Act in chronological order.
  static List<MindMapNodeModel> autoArrangeNodes({
    required List<MindMapNodeModel> allNodes,
    required String activeBookId,
  }) {
    final activeBookNodes = allNodes.where((n) => n.bookId == activeBookId).toList();
    if (activeBookNodes.isEmpty) return allNodes;

    // Collect all distinct act / customName pairs present in the nodes
    final presentItems = <TimelineActItem>[];
    for (final node in activeBookNodes) {
      final item = TimelineActItem(
        node.act,
        node.act == PlotAct.custom ? node.customActName : null,
      );
      if (!presentItems.any((i) =>
          i.act == item.act &&
          (i.customName ?? '').trim() == (item.customName ?? '').trim())) {
        presentItems.add(item);
      }
    }

    if (presentItems.isEmpty) {
      presentItems.addAll([
        const TimelineActItem(PlotAct.act1Exposition),
        const TimelineActItem(PlotAct.act2RisingAction),
        const TimelineActItem(PlotAct.midpoint),
        const TimelineActItem(PlotAct.act3Climax),
        const TimelineActItem(PlotAct.resolution),
      ]);
    } else {
      presentItems.sort((a, b) {
        final cmp = a.orderWeight.compareTo(b.orderWeight);
        if (cmp != 0) return cmp;
        return (a.customName ?? '').compareTo(b.customName ?? '');
      });
    }

    // Map acts to column X coordinates
    final Map<String, double> actX = {};
    final Map<String, int> actCounters = {};
    for (int i = 0; i < presentItems.length; i++) {
      final key = presentItems[i].id;
      actX[key] = 80.0 + (i * 400.0);
      actCounters[key] = 0;
    }

    // Auto-arrange only the nodes belonging to the active book
    return allNodes.map((node) {
      if (node.bookId == activeBookId) {
        final key = node.act == PlotAct.custom
            ? 'custom:${node.customActName ?? 'Personalizado'}'
            : node.act.name;
        final count = actCounters[key] ?? 0;
        actCounters[key] = count + 1;
        final newX = actX[key] ?? 80.0;
        final newY = 120.0 + (count * 170.0);
        return node.copyWith(dx: newX, dy: newY);
      }
      return node;
    }).toList();
  }

  /// Connects two nodes if not already connected.
  static List<MindMapNodeModel> connectNodes(
    List<MindMapNodeModel> nodes,
    String fromId,
    String toId,
  ) {
    if (fromId == toId) return nodes;
    return nodes.map((n) {
      if (n.id == fromId && !n.connectedToIds.contains(toId)) {
        final updated = List<String>.from(n.connectedToIds)..add(toId);
        return n.copyWith(connectedToIds: updated);
      }
      return n;
    }).toList();
  }

  /// Disconnects two nodes.
  static List<MindMapNodeModel> disconnectNodes(
    List<MindMapNodeModel> nodes,
    String fromId,
    String toId,
  ) {
    return nodes.map((n) {
      if (n.id == fromId) {
        final updated = List<String>.from(n.connectedToIds)..remove(toId);
        return n.copyWith(connectedToIds: updated);
      }
      return n;
    }).toList();
  }

  /// Removes a node and cleans up connections pointing to it.
  static List<MindMapNodeModel> deleteNode(
    List<MindMapNodeModel> nodes,
    String nodeId,
  ) {
    final remaining = nodes.where((n) => n.id != nodeId).toList();
    return remaining.map((n) {
      if (n.connectedToIds.contains(nodeId)) {
        final updated = List<String>.from(n.connectedToIds)..remove(nodeId);
        return n.copyWith(connectedToIds: updated);
      }
      return n;
    }).toList();
  }
}

