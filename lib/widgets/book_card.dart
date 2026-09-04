import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/book_model.dart';

class BookCard extends StatelessWidget {
  final BookModel book;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const BookCard({
    super.key,
    required this.book,
    required this.isDark,
    required this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentColor = isDark ? Colors.white : Colors.black;

    final formattedDate = DateFormat('d MMM', 'es_ES').format(book.lastEdited);
    final formattedWords = NumberFormat('#,###').format(book.currentWordCount);
    final formattedTarget = NumberFormat('#,###').format(book.targetWordCount);

    return Container(
      width: 270,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: borderSubtle, width: 1.5),
        boxShadow: AppTheme.getSoftShadow(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Book Cover Icon + Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: borderSubtle,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        book.coverEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),

                    // Status pill tag in Spanish & B&W
                    _buildStatusPill(book.status, accentColor, isDark),
                  ],
                ),

                const SizedBox(height: 14),

                // Title & Subtitle
                Text(
                  book.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  book.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Word count progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$formattedWords / $formattedTarget palabras',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          '${(book.progressPercentage * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: book.progressPercentage,
                        minHeight: 5,
                        backgroundColor: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 8),

                // Bottom Metadata: Chapters count + Last Edited
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_stories_rounded, size: 14, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${book.chapters.length} Capítulos',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Editado $formattedDate',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildStatusPill(BookStatus status, Color accentColor, bool isDark) {
    String label;

    switch (status) {
      case BookStatus.outlining:
        label = 'Planificación';
        break;
      case BookStatus.drafting:
        label = 'Borrador';
        break;
      case BookStatus.revising:
        label = 'Revisión';
        break;
      case BookStatus.completed:
        label = 'Completado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black12,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
