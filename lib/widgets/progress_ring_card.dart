import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/writer_stats_model.dart';

class ProgressRingCard extends StatelessWidget {
  final WriterStatsModel stats;
  final bool isDark;
  final VoidCallback? onTap;

  const ProgressRingCard({
    super.key,
    required this.stats,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentMint = isDark ? AppTheme.darkAccentMint : AppTheme.lightAccentMint;
    final accentMintLight = isDark ? AppTheme.darkAccentMintLight : AppTheme.lightAccentMintLight;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: borderSubtle, width: 1),
        boxShadow: AppTheme.getSoftShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Streak Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Writing Goal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${stats.wordsToday} / ${stats.dailyGoalWords} words',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              // Streak Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentMintLight,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  border: Border.all(color: accentMint.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded, size: 16, color: accentMint),
                    const SizedBox(width: 4),
                    Text(
                      '${stats.streakDays} Day Streak',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accentMint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Main Visual: Radial Ring + Metrics Summary
          Row(
            children: [
              // Radial Progress Ring
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: stats.dailyGoalRatio,
                        strokeWidth: 9,
                        backgroundColor: accentMint.withValues(alpha: 0.12),
                        color: accentMint,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${stats.dailyPercentage}%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'COMPLETED',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Breakdown Stats Cards
              Expanded(
                child: Column(
                  children: [
                    _buildStatRow(
                      icon: Icons.timer_outlined,
                      label: 'Focus Time',
                      value: '${stats.writingTimeTodayMinutes} mins',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      accentMint: accentMint,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(),
                    ),
                    _buildStatRow(
                      icon: Icons.speed_rounded,
                      label: 'Avg Speed',
                      value: '${stats.wordsPerMinuteAvg} wpm',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      accentMint: accentMint,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Weekly Progress Bar Micro-Chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stats.weeklyProgress.entries.map((entry) {
              final day = entry.key;
              final words = entry.value;
              final isToday = day == 'Wed' || day == 'Sun';
              final barRatio = (words / 2500).clamp(0.1, 1.0);

              return Column(
                children: [
                  Container(
                    width: 24,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isToday ? accentMintLight : (isDark ? const Color(0xFF252525) : const Color(0xFFF4F3EF)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        FractionallySizedBox(
                          heightFactor: barRatio,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isToday ? accentMint : textSecondary.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? accentMint : textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentMint,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accentMint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: accentMint),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}
