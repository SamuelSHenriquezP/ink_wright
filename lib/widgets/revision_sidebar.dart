import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../models/revision_comment_model.dart';
import '../formatters/writer_text_formatter.dart';

class RevisionSidebar extends StatefulWidget {
  final VoidCallback? onClose;

  const RevisionSidebar({super.key, this.onClose});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RevisionSidebar(),
    );
  }

  @override
  State<RevisionSidebar> createState() => _RevisionSidebarState();
}

class _RevisionSidebarState extends State<RevisionSidebar> {
  bool _hideResolved = false;

  void _showAddCommentDialog(BuildContext context, EditorController controller) {
    final selection = controller.textEditingController.selection;
    final text = controller.textEditingController.text;

    String highlightedSnippet = '';
    int offset = 0;
    int length = 0;

    if (selection.isValid && !selection.isCollapsed && selection.start < selection.end) {
      offset = selection.start;
      length = selection.end - selection.start;
      final fullSnippet = text.substring(selection.start, selection.end).trim();
      highlightedSnippet = fullSnippet.substring(0, min(100, fullSnippet.length));
    }

    final commentCtrl = TextEditingController();
    final isDark = controller.isDarkMode;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final bgCard = isDark ? const Color(0xFF1E1E22) : Colors.white;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.rate_review_rounded, color: textPrimary, size: 22),
            const SizedBox(width: 10),
            Text(
              'Añadir Nota de Revisión',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (highlightedSnippet.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(
                      color: isDark ? Colors.amberAccent : Colors.amber.shade700,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TEXTO SELECCIONADO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '«$highlightedSnippet»',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: textPrimary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: commentCtrl,
              autofocus: true,
              maxLines: 3,
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Escribe tu nota, duda o corrección...',
                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6), fontSize: 13),
                filled: true,
                fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
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
              final commentText = commentCtrl.text.trim();
              if (commentText.isNotEmpty) {
                final comment = RevisionCommentModel(
                  id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
                  chapterId: controller.activeChapter.id,
                  charOffset: offset,
                  length: length,
                  commentText: commentText,
                  highlightedText: highlightedSnippet,
                  createdAt: DateTime.now(),
                );
                controller.addRevisionComment(comment);
                Navigator.of(ctx).pop();
                setState(() {});
              }
            },
            child: const Text('Guardar Nota'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final isDark = controller.isDarkMode;
    final bgCard = isDark ? const Color(0xFF1E1E22) : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    final allComments = controller.activeChapterComments;
    final comments = _hideResolved
        ? allComments.where((c) => !c.isResolved).toList()
        : allComments;
    final openCount = allComments.where((c) => !c.isResolved).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppTheme.getSoftShadow(isDark),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.rate_review_rounded, color: textPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panel de Revisión',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '$openCount abiertas • ${allComments.length} en total',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _hideResolved ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: textSecondary,
                        size: 20,
                      ),
                      tooltip: _hideResolved ? 'Mostrar resueltas' : 'Ocultar resueltas',
                      onPressed: () => setState(() => _hideResolved = !_hideResolved),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textSecondary),
                      onPressed: () {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Action bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    icon: const Icon(Icons.add_comment_rounded, size: 18),
                    label: const Text(
                      'Nueva Nota de Revisión',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    onPressed: () => _showAddCommentDialog(context, controller),
                  ),
                ),
              ],
            ),
          ),

          // Comments List
          Expanded(
            child: comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mark_chat_read_outlined,
                          size: 50,
                          color: textSecondary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _hideResolved && allComments.isNotEmpty
                              ? '¡No hay notas pendientes!'
                              : 'No hay notas en este capítulo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Selecciona texto en el editor o toca el botón para crear una',
                          style: TextStyle(fontSize: 12.5, color: textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: comments.length,
                    itemBuilder: (ctx, index) {
                      final comment = comments[index];
                      final isResolved = comment.isResolved;

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isResolved ? 0.55 : 1.0,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFFF9F9FB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isResolved
                                  ? borderColor.withValues(alpha: 0.5)
                                  : borderColor,
                            ),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left colored indicator
                                Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: isResolved
                                        ? const Color(0xFF38C793)
                                        : Color(comment.colorHex),
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(14),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Top row: status chip & date
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: isResolved
                                                    ? const Color(0xFF38C793).withValues(alpha: 0.15)
                                                    : const Color(0xFFFFC107).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isResolved ? 'RESUELTO' : 'PENDIENTE',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                  color: isResolved
                                                      ? const Color(0xFF38C793)
                                                      : (isDark ? Colors.amberAccent : Colors.amber.shade800),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              WriterTextFormatter.formatSpanishDate(comment.createdAt),
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: textSecondary.withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Highlighted quote preview if any
                                        if (comment.highlightedText.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '«${comment.highlightedText}»',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontStyle: FontStyle.italic,
                                                color: textSecondary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],

                                        const SizedBox(height: 8),

                                        // Comment text
                                        Text(
                                          comment.commentText,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                            decoration: isResolved ? TextDecoration.lineThrough : null,
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        // Actions: toggle resolved / delete
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                              icon: Icon(
                                                isResolved ? Icons.replay_rounded : Icons.check_circle_outline_rounded,
                                                size: 16,
                                                color: isResolved ? textSecondary : const Color(0xFF38C793),
                                              ),
                                              label: Text(
                                                isResolved ? 'Reabrir' : 'Resolver',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: isResolved ? textSecondary : const Color(0xFF38C793),
                                                ),
                                              ),
                                              onPressed: () {
                                                controller.toggleRevisionComment(comment.id);
                                                setState(() {});
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete_outline_rounded,
                                                size: 17,
                                                color: textSecondary.withValues(alpha: 0.6),
                                              ),
                                              visualDensity: VisualDensity.compact,
                                              tooltip: 'Eliminar nota',
                                              onPressed: () {
                                                controller.deleteRevisionComment(comment.id);
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

