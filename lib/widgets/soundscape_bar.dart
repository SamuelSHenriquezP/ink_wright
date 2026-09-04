import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';

class SoundscapeBar extends StatelessWidget {
  final bool isDark;

  const SoundscapeBar({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentMint = isDark ? AppTheme.darkAccentMint : AppTheme.lightAccentMint;

    final activeSoundscape = controller.activeSoundscape;
    final isPlaying = controller.isPlayingAmbience;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderSubtle),
        boxShadow: AppTheme.getSoftShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    activeSoundscape?.iconEmoji ?? '🎧',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeSoundscape?.title ?? 'Ambient Soundscapes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        isPlaying ? 'Playing focus ambience' : 'Paused • Select soundscape',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),

              // Animated Visualizer or Play Button
              Row(
                children: [
                  if (isPlaying)
                    Row(
                      children: List.generate(4, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: accentMint,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleY(
                              begin: 0.3,
                              end: 1.0,
                              duration: Duration(milliseconds: 300 + index * 120),
                            );
                      }),
                    ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                      size: 32,
                      color: accentMint,
                    ),
                    onPressed: () {
                      if (activeSoundscape != null) {
                        controller.toggleSoundscape(activeSoundscape);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Horizontal Soundscapes Selector Chips
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: controller.soundscapes.length,
              itemBuilder: (context, index) {
                final item = controller.soundscapes[index];
                final isSelected = activeSoundscape?.id == item.id;

                return GestureDetector(
                  onTap: () => controller.toggleSoundscape(item),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentMint.withValues(alpha: 0.15)
                          : (isDark ? const Color(0xFF252525) : const Color(0xFFF2F1EC)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? accentMint : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(item.iconEmoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? accentMint : textSecondary,
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
    );
  }
}
