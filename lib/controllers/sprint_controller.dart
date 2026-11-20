import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/writing_sprint_model.dart';
import '../formatters/writer_text_formatter.dart';

class SprintController extends ChangeNotifier with WidgetsBindingObserver {
  WritingSprintModel? _activeSprint;
  Timer? _timer;
  int _secondsRemaining = 0;
  final DateTime Function() _now;

  SprintController({DateTime Function()? now}) : _now = now ?? DateTime.now {
    WidgetsBinding.instance.addObserver(this);
  }

  WritingSprintModel? get activeSprint => _activeSprint;
  int get secondsRemaining => _secondsRemaining;
  bool get isSprintActive => _activeSprint != null && _activeSprint!.isActive;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _updateRemainingTime();
  }

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
    if (durationMinutes <= 0 || targetWords <= 0) return;
    _timer?.cancel();
    final startWordCount = WriterTextFormatter.countWords(currentContent);

    _activeSprint = WritingSprintModel(
      startTime: _now(),
      durationMinutes: durationMinutes,
      targetWords: targetWords,
      startingWordCount: startWordCount,
      wordsWritten: 0,
      isActive: true,
      isCompleted: false,
    );

    _secondsRemaining = durationMinutes * 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _updateRemainingTime();
    });

    notifyListeners();
  }

  void _updateRemainingTime() {
    final sprint = _activeSprint;
    if (sprint == null || !sprint.isActive) return;
    final end = sprint.startTime.add(Duration(minutes: sprint.durationMinutes));
    _secondsRemaining = ((end.difference(_now()).inMilliseconds + 999) ~/ 1000)
        .clamp(0, sprint.durationMinutes * 60);
    if (_secondsRemaining == 0) {
      _timer?.cancel();
      _activeSprint = sprint.copyWith(isActive: false, isCompleted: true);
    }
    notifyListeners();
  }

  void onTextUpdated(String newContent) {
    _updateRemainingTime();
    if (_activeSprint == null || !_activeSprint!.isActive) return;

    final currentWords = WriterTextFormatter.countWords(newContent);
    final delta = (currentWords - _activeSprint!.startingWordCount).clamp(
      0,
      999999,
    );

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
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}
