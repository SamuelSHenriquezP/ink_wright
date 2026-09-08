import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/writing_sprint_model.dart';
import '../formatters/writer_text_formatter.dart';

class SprintController extends ChangeNotifier {
  WritingSprintModel? _activeSprint;
  Timer? _timer;
  int _secondsRemaining = 0;

  WritingSprintModel? get activeSprint => _activeSprint;
  int get secondsRemaining => _secondsRemaining;
  bool get isSprintActive => _activeSprint != null && _activeSprint!.isActive;

  String get formattedTimeRemaining {
    if (_secondsRemaining <= 0) return '00:00';
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void startSprint({
    required int durationMinutes,
    required int targetWords,
    required String currentContent,
  }) {
    _timer?.cancel();
    final startWordCount = WriterTextFormatter.countWords(currentContent);

    _activeSprint = WritingSprintModel(
      startTime: DateTime.now(),
      durationMinutes: durationMinutes,
      targetWords: targetWords,
      startingWordCount: startWordCount,
      wordsWritten: 0,
      isActive: true,
      isCompleted: false,
    );

    _secondsRemaining = durationMinutes * 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining <= 1) {
        t.cancel();
        _secondsRemaining = 0;
        _activeSprint = _activeSprint?.copyWith(
          isActive: false,
          isCompleted: true,
        );
        notifyListeners();
      } else {
        _secondsRemaining--;
        notifyListeners();
      }
    });

    notifyListeners();
  }

  void onTextUpdated(String newContent) {
    if (_activeSprint == null || !_activeSprint!.isActive) return;

    final currentWords = WriterTextFormatter.countWords(newContent);
    final delta = (currentWords - _activeSprint!.startingWordCount).clamp(0, 999999);

    if (delta != _activeSprint!.wordsWritten) {
      _activeSprint = _activeSprint!.copyWith(wordsWritten: delta);
      notifyListeners();
    }
  }

  void stopSprint() {
    _timer?.cancel();
    if (_activeSprint != null) {
      _activeSprint = _activeSprint!.copyWith(isActive: false);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

