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
    final accentMint = isDark ? AppTheme.darkAccentMint : AppTheme.lightAccentMint;

    final formattedDate = DateFormat('MMM d').format(book.lastEdited);
    final formattedWords = NumberFormat('#,###').format(book.currentWordCount);
    final formattedTarget = NumberFormat('#,###').format(book.targetWordCount);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: borderSubtle, width: 1),
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
                    // Mini Book Jacket Graphic
                    Container(
                      width: 48,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Color(book.coverColorHex).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(book.coverColorHex).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        book.coverEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),

                    // Status pill tag
                    _buildStatusPill(book.status, accentMint, isDark),
                  ],
                ),

                const SizedBox(height: 14),

                // Title & Subtitle
                Text(
                  book.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
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
                          '$formattedWords / $formattedTarget words',
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
                            color: accentMint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: book.progressPercentage,
                        minHeight: 6,
                        backgroundColor: accentMint.withValues(alpha: 0.12),
                        color: accentMint,
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
                          '${book.chapters.length} Chapters',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Edited $formattedDate',
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
    ).animate().fadeIn(duration: 350.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildStatusPill(BookStatus status, Color accentMint, bool isDark) {
    String label;
    Color color;

    switch (status) {
      case BookStatus.outlining:
        label = 'Outlining';
        color = const Color(0xFFF5A623);
        break;
      case BookStatus.drafting:
        label = 'Drafting';
        color = accentMint;
        break;
      case BookStatus.revising:
        label = 'Revising';
        color = const Color(0xFF4A90E2);
        break;
      case BookStatus.completed:
        label = 'Completed';
        color = const Color(0xFF9013FE);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
