import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/codex_entry_model.dart';

class CodexCard extends StatelessWidget {
  final CodexEntryModel entry;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onPinTap;

  const CodexCard({
    super.key,
    required this.entry,
    required this.isDark,
    required this.onTap,
    this.onPinTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: borderSubtle, width: 1.5),
          boxShadow: AppTheme.getSoftShadow(isDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Emoji Avatar + Type + Pin Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        entry.defaultEmoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.typeLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          entry.role,
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),

                if (onPinTap != null)
                  IconButton(
                    icon: Icon(
                      entry.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                      size: 16,
                      color: entry.isPinned ? accentColor : textSecondary,
                    ),
                    onPressed: onPinTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Entry Name
            Text(
              entry.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Entry Description
            Text(
              entry.description,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Traits Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: entry.traits.take(3).map((trait) {
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#$trait',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
