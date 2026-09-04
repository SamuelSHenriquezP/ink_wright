import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/idea_snippet_model.dart';

class IdeaChipCard extends StatelessWidget {
  final IdeaSnippetModel idea;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onPinTap;
  final VoidCallback? onInsertTap;

  const IdeaChipCard({
    super.key,
    required this.idea,
    required this.isDark,
    this.onTap,
    this.onPinTap,
    this.onInsertTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentColor = isDark ? Colors.white : Colors.black;

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: idea.isPinned ? accentColor : borderSubtle,
          width: idea.isPinned ? 1.5 : 1.0,
        ),
        boxShadow: AppTheme.getSoftShadow(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category Chip + Pin Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                        border: Border.all(
                          color: borderSubtle,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(idea.categoryIcon, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            idea.categoryLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        idea.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                        size: 16,
                        color: idea.isPinned ? textPrimary : textSecondary.withValues(alpha: 0.5),
                      ),
                      onPressed: onPinTap,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Title
                Text(
                  idea.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Content Preview
                Expanded(
                  child: Text(
                    idea.content,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 10),

                // Footer Row: Tags + Quick Insert Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        idea.tags.map((t) => '#$t').join(' '),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textSecondary.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onInsertTap != null)
                      InkWell(
                        onTap: onInsertTap,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.add_rounded, size: 14, color: textPrimary),
                              Text(
                                'Insertar',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ],
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
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.08, end: 0);
  }
}
