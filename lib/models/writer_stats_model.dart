class WriterStatsModel {
  final int dailyGoalWords;
  final int wordsToday;
  final int streakDays;
  final int totalWordsWritten;
  final int writingTimeTodayMinutes;
  final Map<String, int> weeklyProgress; // Day name (Mon, Tue) -> words
  final int wordsPerMinuteAvg;
  final int focusScore; // 0 - 100

  WriterStatsModel({
    required this.dailyGoalWords,
    required this.wordsToday,
    required this.streakDays,
    required this.totalWordsWritten,
    required this.writingTimeTodayMinutes,
    required this.weeklyProgress,
    required this.wordsPerMinuteAvg,
    required this.focusScore,
  });

  double get dailyGoalRatio {
    if (dailyGoalWords == 0) return 0.0;
    return (wordsToday / dailyGoalWords).clamp(0.0, 1.0);
  }

  int get dailyPercentage {
    return (dailyGoalRatio * 100).round();
  }

  WriterStatsModel copyWith({
    int? dailyGoalWords,
    int? wordsToday,
    int? streakDays,
    int? totalWordsWritten,
    int? writingTimeTodayMinutes,
    Map<String, int>? weeklyProgress,
    int? wordsPerMinuteAvg,
    int? focusScore,
  }) {
    return WriterStatsModel(
      dailyGoalWords: dailyGoalWords ?? this.dailyGoalWords,
      wordsToday: wordsToday ?? this.wordsToday,
      streakDays: streakDays ?? this.streakDays,
      totalWordsWritten: totalWordsWritten ?? this.totalWordsWritten,
      writingTimeTodayMinutes: writingTimeTodayMinutes ?? this.writingTimeTodayMinutes,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      wordsPerMinuteAvg: wordsPerMinuteAvg ?? this.wordsPerMinuteAvg,
      focusScore: focusScore ?? this.focusScore,
    );
  }
}
