import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../controllers/editor_controller.dart';
import '../../models/mind_map_node_model.dart';

/// Kanban-style Timeline view organized by narrative acts with drag & drop reordering.
class PlotTimelineView extends StatelessWidget {
  final EditorController controller;
  final List<TimelineActItem> timelineActs;
  final VoidCallback onOpenAddActDialog;
  final void Function(TimelineActItem actItem) onAddNodeWithAct;
  final void Function(MindMapNodeModel node) onEditNode;
  final void Function(TimelineActItem actItem) onRemoveAct;
  final void Function(String message, {IconData icon}) onNotify;

  const PlotTimelineView({
    super.key,
    required this.controller,
    required this.timelineActs,
    required this.onOpenAddActDialog,
    required this.onAddNodeWithAct,
    required this.onEditNode,
    required this.onRemoveAct,
    required this.onNotify,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = controller.isDarkMode;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final cardBg = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final bgPrimary = isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary;

    final nodes = controller.mindMapNodes.where((n) => n.bookId == controller.activeBook.id).toList();

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
          _buildAddActTimelineCard(context, isDark, textSecondary, borderColor),
        ],
      ),
    );
  }

  Widget _buildAddActTimelineCard(
    BuildContext context,
    bool isDark,
    Color textSecondary,
    Color borderColor,
  ) {
    return GestureDetector(
      onTap: onOpenAddActDialog,
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
        onNotify(
          '«${node.title}» movido a ${actItem.label}.',
          icon: Icons.swap_horiz_rounded,
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
                        onTap: () => onRemoveAct(actItem),
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
                onTap: () => onAddNodeWithAct(actItem),
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
          opacity: 0.85,
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white38 : Colors.black38, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
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
        opacity: 0.35,
        child: _buildCardContent(
          context: context,
          node: node,
          controller: controller,
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          cardBg: cardBg,
        ),
      ),
      child: _buildCardContent(
        context: context,
        node: node,
        controller: controller,
        isDark: isDark,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        borderColor: borderColor,
        cardBg: cardBg,
      ),
    );
  }

  Widget _buildCardContent({
    required BuildContext context,
    required MindMapNodeModel node,
    required EditorController controller,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required Color cardBg,
  }) {
    final accentColor = Color(node.colorHex != 0 ? node.colorHex : 0xFF18181B);
    final hasChapter = node.linkedChapterId != null;
    final chapter = hasChapter
        ? controller.activeBook.chapters.where((c) => c.id == node.linkedChapterId).firstOrNull
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onEditNode(node),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: emoji + title + color pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node.iconEmoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        node.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),

                // Description snippet
                if (node.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    node.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 8),

                // Badges row: type + linked chapter
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        node.typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                    if (chapter != null) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.menu_book_rounded, size: 11, color: textSecondary),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                'Cap. ${chapter.chapterNumber}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
