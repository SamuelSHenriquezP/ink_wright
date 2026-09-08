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

  Map<String, dynamic> toMap() {
    return {
      'dailyGoalWords': dailyGoalWords,
      'wordsToday': wordsToday,
      'streakDays': streakDays,
      'totalWordsWritten': totalWordsWritten,
      'writingTimeTodayMinutes': writingTimeTodayMinutes,
      'weeklyProgress': weeklyProgress,
      'wordsPerMinuteAvg': wordsPerMinuteAvg,
      'focusScore': focusScore,
    };
  }

  factory WriterStatsModel.fromMap(Map<String, dynamic> map) {
    return WriterStatsModel(
      dailyGoalWords: map['dailyGoalWords'] as int? ?? 2000,
      wordsToday: map['wordsToday'] as int? ?? 0,
      streakDays: map['streakDays'] as int? ?? 1,
      totalWordsWritten: map['totalWordsWritten'] as int? ?? 0,
      writingTimeTodayMinutes: map['writingTimeTodayMinutes'] as int? ?? 0,
      weeklyProgress: (map['weeklyProgress'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
      wordsPerMinuteAvg: map['wordsPerMinuteAvg'] as int? ?? 30,
      focusScore: map['focusScore'] as int? ?? 90,
    );
  }
}
