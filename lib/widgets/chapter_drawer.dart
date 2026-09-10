import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/chapter_model.dart';
import '../models/book_model.dart';
import '../controllers/editor_controller.dart';
import '../formatters/writer_text_formatter.dart';

class ChapterDrawer extends StatelessWidget {
  final EditorController controller;
  final bool isDark;

  const ChapterDrawer({
    super.key,
    required this.controller,
    required this.isDark,
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
    final titleCtrl = TextEditingController(
      text: 'Capítulo ${controller.activeBook.chapters.length + 1}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
        title: Text(
          'Nuevo Capítulo',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
          decoration: InputDecoration(
            labelText: 'Título del capítulo',
            labelStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isNotEmpty) {
                controller.addNewChapter(title);
              }
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Close drawer to focus on new chapter
            },
            child: const Text('Crear'),
          ),
        ],
      ),
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
      width: MediaQuery.of(context).size.width * 0.84,
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
                  // New Chapter Button
                  SizedBox(
                    width: double.infinity,
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
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      itemCount: chapters.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
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

                        return Material(
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
                              Navigator.of(context).pop();
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
