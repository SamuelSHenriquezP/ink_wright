import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../formatters/writer_text_formatter.dart';

class WritingSprintDialog extends StatefulWidget {
  final bool isDark;

  const WritingSprintDialog({
    super.key,
    required this.isDark,
  });

  @override
  State<WritingSprintDialog> createState() => _WritingSprintDialogState();
}

class _WritingSprintDialogState extends State<WritingSprintDialog> {
  int _selectedDuration = 25; // default 25 min
  final TextEditingController _targetWordsCtrl = TextEditingController(text: '500');

  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<EditorController>(context, listen: false);
    if (controller.activeSprint != null && controller.activeSprint!.isActive) {
      _secondsRemaining = controller.activeSprint!.durationMinutes * 60 -
          DateTime.now().difference(controller.activeSprint!.startTime).inSeconds;
      if (_secondsRemaining > 0) {
        _startTimerCountdown();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _targetWordsCtrl.dispose();
    super.dispose();
  }

  void _startTimerCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final bgCard = widget.isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = widget.isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentMint = widget.isDark ? AppTheme.darkAccentMint : AppTheme.lightAccentMint;

    final sprint = controller.activeSprint;
    final isSprintActive = sprint != null && sprint.isActive;

    final currentWords = WriterTextFormatter.countWords(controller.textEditingController.text);
    final wordsWrittenInSprint = isSprintActive
        ? (currentWords - sprint.startingWordCount).clamp(0, 99999)
        : 0;

    return Dialog(
      backgroundColor: bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('⏱️', style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      'Writing Sprint Studio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (isSprintActive) ...[
              // Active Sprint Display Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF1B2B23) : const Color(0xFFEBF9F3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentMint.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      _formatTimer(_secondsRemaining),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: accentMint,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TIME REMAINING IN SPRINT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accentMint,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: (wordsWrittenInSprint / sprint.targetWords).clamp(0.0, 1.0),
                      backgroundColor: accentMint.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(accentMint),
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$wordsWrittenInSprint / ${sprint.targetWords} words written',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '${((wordsWrittenInSprint / sprint.targetWords) * 100).clamp(0, 100).round()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: accentMint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.stop_circle_rounded),
                label: const Text('Stop Current Sprint', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () {
                  _timer?.cancel();
                  controller.stopSprint();
                },
              ),
            ] else ...[
              // Setup New Sprint Interface
              Text(
                'Set a time limit and word goal to trigger uninterrupted creative flow.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [15, 25, 45].map((duration) {
                  final isSelected = duration == _selectedDuration;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDuration = duration;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? accentMint : (widget.isDark ? const Color(0xFF252525) : const Color(0xFFF2F1EC)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$duration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : textPrimary,
                            ),
                          ),
                          Text(
                            'MIN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white.withValues(alpha: 0.9) : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: _targetWordsCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Target Word Goal',
                  labelStyle: TextStyle(color: textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: accentMint, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentMint,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text('Start Writing Sprint', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                onPressed: () {
                  final target = int.tryParse(_targetWordsCtrl.text) ?? 500;
                  controller.startSprint(
                    durationMinutes: _selectedDuration,
                    targetWords: target,
                  );
                  _secondsRemaining = _selectedDuration * 60;
                  _startTimerCountdown();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
