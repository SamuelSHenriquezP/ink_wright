import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/chapter_model.dart';
import '../models/book_model.dart';
import '../controllers/editor_controller.dart';
import '../formatters/writer_text_formatter.dart';
import 'import_manuscript_dialog.dart';
import 'chapters/new_chapter_modal.dart';

class ChapterDrawer extends StatelessWidget {
  final EditorController controller;
  final bool isDark;
  final VoidCallback? onSelectChapter;
  final double? width;

  const ChapterDrawer({
    super.key,
    required this.controller,
    required this.isDark,
    this.onSelectChapter,
    this.width,
  });

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);
    if (difference.inMinutes < 60) {
      if (difference.inMinutes <= 1) return 'Ahora mismo';
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24 && now.day == dt.day) {
      return DateFormat('HH:mm').format(dt);
    } else {
      return DateFormat('dd MMM, HH:mm').format(dt);
    }
  }

  void _showNewChapterDialog(BuildContext context) {
    NewChapterModal.show(
      context,
      isDark: isDark,
      onChapterCreated: () {
        if (Scaffold.maybeOf(context)?.isDrawerOpen == true ||
            Scaffold.maybeOf(context)?.isEndDrawerOpen == true) {
          Navigator.of(context).pop();
        } else {
          onSelectChapter?.call();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final BookModel book = controller.activeBook;
    final ChapterModel activeChapter = controller.activeChapter;
    final chapters = book.chapters;

    final bgPrimary = isDark ? const Color(0xFF141416) : const Color(0xFFF9F9FB);
    final bgCard = isDark ? const Color(0xFF1E1E22) : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentColor = isDark ? Colors.white : Colors.black;

    int totalBookWords = 0;
    for (final ch in chapters) {
      totalBookWords += WriterTextFormatter.countWords(ch.id == activeChapter.id
          ? controller.textEditingController.text
          : ch.content);
    }

    return Drawer(
      backgroundColor: bgPrimary,
      width: width ?? MediaQuery.of(context).size.width * 0.84,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderSubtle)),
              ),
              child: Column(
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
                        child: Icon(Icons.menu_book_rounded, size: 20, color: textPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${chapters.length} capítulos • $totalBookWords palabras',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // New Chapter & Import Chapter Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              'Nuevo Capítulo',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            onPressed: () => _showNewChapterDialog(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Importar capítulo (.docx, .epub, .md, .txt)',
                        child: InkWell(
                          onTap: () {
                            if (Scaffold.maybeOf(context)?.isDrawerOpen == true ||
                                Scaffold.maybeOf(context)?.isEndDrawerOpen == true) {
                              Navigator.of(context).pop();
                            }
                            ImportManuscriptDialog.show(
                              context,
                              isDark: isDark,
                              forceChaptersMode: true,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderSubtle),
                            ),
                            child: Icon(Icons.file_download_outlined, size: 20, color: textPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chapter list
            Expanded(
              child: chapters.isEmpty
                  ? Center(
                      child: Text(
                        'Sin capítulos',
                        style: TextStyle(color: textSecondary),
                      ),
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      itemCount: chapters.length,
                      onReorderItem: (oldIndex, newIndex) {
                        controller.moveChapter(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final ch = chapters[index];
                        final isActive = ch.id == activeChapter.id;
                        final currentContent = isActive
                            ? controller.textEditingController.text
                            : ch.content;
                        final words = WriterTextFormatter.countWords(currentContent);

                        // Clean snippet (remove markdown symbols for preview)
                        String snippet = currentContent.trim();
                        if (snippet.startsWith('#')) {
                          final firstNewline = snippet.indexOf('\n');
                          if (firstNewline != -1) {
                            snippet = snippet.substring(firstNewline).trim();
                          }
                        }
                        snippet = snippet.replaceAll(RegExp(r'[#*`~_>]+'), '').trim();
                        if (snippet.isEmpty) snippet = 'Capítulo vacío...';
                        if (snippet.length > 80) snippet = '${snippet.substring(0, 80)}...';

                        return Container(
                          key: ValueKey(ch.id),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: isActive
                                ? (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06))
                                : bgCard,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                if (!isActive) {
                                  controller.selectChapter(ch);
                                }
                                if (Scaffold.maybeOf(context)?.isDrawerOpen == true ||
                                    Scaffold.maybeOf(context)?.isEndDrawerOpen == true) {
                                  Navigator.of(context).pop();
                                } else {
                                  onSelectChapter?.call();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isActive
                                        ? (isDark ? Colors.white54 : Colors.black)
                                        : borderSubtle,
                                    width: isActive ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Active dot indicator
                                        if (isActive)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(right: 8),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white : Colors.black,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            ch.title,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontSize: 14,
                                              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatDate(ch.lastEdited),
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 6),
                                            child: Icon(
                                              Icons.drag_indicator_rounded,
                                              size: 18,
                                              color: textSecondary.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      snippet,
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.08)
                                                : Colors.black.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$words palabras',
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        if (ch.isCompleted)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Terminado',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
