import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../controllers/editor_controller.dart';
import '../../models/mind_map_node_model.dart';
import '../../screens/zen_editor_screen.dart';

/// Modal bottom sheet to select a node to connect with, featuring search, act filter, and rich card layout.
void showPlotConnectDialog(
  BuildContext context,
  MindMapNodeModel node,
  EditorController controller,
  VoidCallback onUpdate, {
  void Function(String message, {IconData icon})? onNotify,
}) {
  final isDark = controller.isDarkMode;
  final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
  final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
  final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
  final inputBg = isDark ? const Color(0xFF1E1E22) : const Color(0xFFF6F6F8);

  final allCandidates = controller.mindMapNodes
      .where((n) => n.id != node.id && !node.connectedToIds.contains(n.id))
      .toList();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      String searchQuery = '';
      String selectedActFilter = 'Todos';

      return StatefulBuilder(
        builder: (context, setSheetState) {
          final availableActs = <String>{'Todos'};
          for (final c in allCandidates) {
            availableActs.add(c.actLabel);
          }

          final filteredTargets = allCandidates.where((n) {
            if (selectedActFilter != 'Todos' && n.actLabel != selectedActFilter) {
              return false;
            }
            if (searchQuery.trim().isNotEmpty) {
              final query = searchQuery.toLowerCase();
              final matchesTitle = n.title.toLowerCase().contains(query);
              final matchesAct = n.actLabel.toLowerCase().contains(query);
              final matchesType = n.typeLabel.toLowerCase().contains(query);
              final matchesDesc = n.description.toLowerCase().contains(query);
              return matchesTitle || matchesAct || matchesType || matchesDesc;
            }
            return true;
          }).toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          child: Icon(Icons.hub_rounded, size: 22, color: textPrimary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Conectar Hilo Narrativo',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    'Origen: ',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
                                  ),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: inputBg,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: borderSubtle),
                                      ),
                                      child: Text(
                                        '${node.iconEmoji} ${node.title}',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
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
                  const SizedBox(height: 12),
                  Divider(height: 1, color: borderSubtle),

                  // Search and filters
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: TextField(
                      style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Buscar por título, acto o tipo...',
                        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w400),
                        prefixIcon: Icon(Icons.search_rounded, size: 20, color: textSecondary),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, size: 18, color: textSecondary),
                                onPressed: () => setSheetState(() => searchQuery = ''),
                              )
                            : null,
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderSubtle)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                      ),
                      onChanged: (val) => setSheetState(() => searchQuery = val),
                    ),
                  ),

                  // Act filter pills
                  if (availableActs.length > 2)
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        physics: const BouncingScrollPhysics(),
                        children: availableActs.map((act) {
                          final isChosen = selectedActFilter == act;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(act),
                              selected: isChosen,
                              selectedColor: isDark ? Colors.white : Colors.black,
                              backgroundColor: inputBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: isChosen ? Colors.transparent : borderSubtle),
                              ),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: isChosen ? FontWeight.w700 : FontWeight.w500,
                                color: isChosen ? (isDark ? Colors.black : Colors.white) : textSecondary,
                              ),
                              showCheckmark: false,
                              visualDensity: VisualDensity.compact,
                              onSelected: (selected) {
                                if (selected) {
                                  setSheetState(() => selectedActFilter = act);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // List of targets with smooth scroll
                  Flexible(
                    child: filteredTargets.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.hub_outlined,
                                    size: 40,
                                    color: textSecondary.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    searchQuery.isNotEmpty
                                        ? 'Sin resultados para «$searchQuery»'
                                        : (allCandidates.isEmpty
                                            ? 'Todos los nodos ya están conectados'
                                            : 'No hay nodos en este acto'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    searchQuery.isNotEmpty
                                        ? 'Prueba con otra palabra clave o limpia el filtro.'
                                        : 'Crea más puntos de trama para seguir expandiendo tu mapa narrativo.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredTargets.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final target = filteredTargets[index];
                              final accentColor = Color(target.colorHex != 0 ? target.colorHex : 0xFF18181B);

                              return InkWell(
                                onTap: () {
                                  controller.connectMindMapNodes(node.id, target.id);
                                  Navigator.of(sheetContext).pop();
                                  onUpdate();
                                  if (onNotify != null) {
                                    onNotify(
                                      '¡Conectado! «${node.title}» ➔ «${target.title}»',
                                      icon: Icons.link_rounded,
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: inputBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: borderSubtle),
                                  ),
                                  child: Row(
                                    children: [
                                      // Emoji avatar with colored border
                                      Container(
                                        width: 42,
                                        height: 42,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF27272A) : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: accentColor.withValues(alpha: 0.6),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(target.iconEmoji, style: const TextStyle(fontSize: 20)),
                                      ),
                                      const SizedBox(width: 12),
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              target.title,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    target.actLabel,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  target.typeLabel,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: textSecondary.withValues(alpha: 0.8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (target.description.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                target.description,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: textSecondary.withValues(alpha: 0.7),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Connect button
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white : Colors.black,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add_link_rounded,
                                              size: 14,
                                              color: isDark ? Colors.black : Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Conectar',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? Colors.black : Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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

/// Modal bottom sheet showing detailed information and connections for a selected node.
void showPlotNodeDetailModal({
  required BuildContext context,
  required MindMapNodeModel node,
  required EditorController controller,
  required void Function(MindMapNodeModel node) onEditNode,
  required void Function(MindMapNodeModel parentNode) onBranchNode,
  required void Function(String message, {IconData icon}) onNotify,
}) {
  final isDark = controller.isDarkMode;
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
                              onEditNode(currentNode);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 19),
                            tooltip: 'Duplicar nodo',
                            color: textPrimary,
                            onPressed: () {
                              controller.duplicateMindMapNode(currentNode.id);
                              Navigator.of(context).pop();
                              onNotify(
                                'Nodo duplicado en el lienzo.',
                                icon: Icons.copy_rounded,
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
                              onNotify(
                                'Nodo eliminado.',
                                icon: Icons.delete_outline_rounded,
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

                  if (connectedNodes.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.hub_outlined, size: 18, color: textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sin conexiones activas con otros eventos.',
                                  style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white : Colors.black,
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.add_link_rounded, size: 15),
                                label: const Text('Conectar a un Nodo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                onPressed: () {
                                  showPlotConnectDialog(context, currentNode, controller, () {
                                    setSheetState(() {});
                                  }, onNotify: onNotify);
                                },
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(color: borderColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.alt_route_rounded, size: 15),
                                label: const Text('Ramificar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  onBranchNode(currentNode);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...connectedNodes.map((target) {
                      final targetAccent = Color(target.colorHex != 0 ? target.colorHex : 0xFF18181B);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black26 : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: targetAccent.withValues(alpha: 0.5)),
                              ),
                              child: Text(target.iconEmoji, style: const TextStyle(fontSize: 16)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    target.title,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${target.actLabel} • ${target.typeLabel}',
                                    style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.link_off_rounded, size: 18),
                              tooltip: 'Desconectar enlace',
                              color: isDark ? Colors.white60 : Colors.black54,
                              onPressed: () {
                                controller.disconnectMindMapNodes(currentNode.id, target.id);
                                setSheetState(() {});
                                onNotify(
                                  'Enlace deshecho con «${target.title}».',
                                  icon: Icons.link_off_rounded,
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.add_link_rounded, size: 16),
                          label: const Text('Conectar a otro...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide(color: borderColor),
                          onPressed: () {
                            showPlotConnectDialog(context, currentNode, controller, () {
                              setSheetState(() {});
                            }, onNotify: onNotify);
                          },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.alt_route_rounded, size: 16),
                          label: const Text('Ramificar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide(color: borderColor),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onBranchNode(currentNode);
                          },
                        ),
                      ],
                    ),
                  ],

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
                            onEditNode(currentNode);
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
