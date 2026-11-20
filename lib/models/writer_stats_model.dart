class WriterStatsModel {
  final int dailyGoalWords;
  final int wordsToday;
  final int streakDays;
  final int totalWordsWritten;
  final int writingTimeTodayMinutes;
  final Map<String, int> weeklyProgress; // Day name (Lun, Mar) -> words
  final Map<String, int> dailyWordsByDate; // YYYY-MM-DD -> words
  final int wordsPerMinuteAvg;
  final int focusScore; // 0 - 100

  WriterStatsModel({
    required this.dailyGoalWords,
    required this.wordsToday,
    required this.streakDays,
    required this.totalWordsWritten,
    required this.writingTimeTodayMinutes,
    required this.weeklyProgress,
    this.dailyWordsByDate = const {},
    required this.wordsPerMinuteAvg,
    required this.focusScore,
  });

  static String dateKeyFor(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String spanishWeekdayShort(int weekday) {
    const labels = {
      DateTime.monday: 'Lun',
      DateTime.tuesday: 'Mar',
      DateTime.wednesday: 'Mié',
      DateTime.thursday: 'Jue',
      DateTime.friday: 'Vie',
      DateTime.saturday: 'Sáb',
      DateTime.sunday: 'Dom',
    };
    return labels[weekday] ?? 'Lun';
  }

  double get dailyGoalRatio {
    if (dailyGoalWords == 0) return 0.0;
    return (wordsToday / dailyGoalWords).clamp(0.0, 1.0);
  }

  int get dailyPercentage {
    return (dailyGoalRatio * 100).round();
  }

  /// Registra palabras nuevas escritas en la fecha dada (por defecto hoy) en formato YYYY-MM-DD
  WriterStatsModel recordWordsForDate(int deltaWords, {DateTime? date}) {
    if (deltaWords <= 0) return this;
    final targetDate = date ?? DateTime.now();
    final key = dateKeyFor(targetDate);
    final todayKey = dateKeyFor(DateTime.now());
    final weekdayKey = spanishWeekdayShort(targetDate.weekday);

    final updatedByDate = Map<String, int>.from(dailyWordsByDate);
    updatedByDate[key] = (updatedByDate[key] ?? 0) + deltaWords;

    final updatedWeekly = Map<String, int>.from(weeklyProgress);
    updatedWeekly[weekdayKey] = (updatedWeekly[weekdayKey] ?? 0) + deltaWords;

    final isToday = key == todayKey;
    return copyWith(
      wordsToday: isToday ? wordsToday + deltaWords : wordsToday,
      totalWordsWritten: totalWordsWritten + deltaWords,
      weeklyProgress: updatedWeekly,
      dailyWordsByDate: updatedByDate,
    );
  }

  /// Devuelve la serie ordenada cronológicamente de los últimos 7 días hasta [referenceDate]
  List<MapEntry<DateTime, int>> last7DaysSeries({DateTime? referenceDate}) {
    final end = referenceDate ?? DateTime.now();
    final endDate = DateTime(end.year, end.month, end.day);
    return List.generate(7, (index) {
      final day = endDate.subtract(Duration(days: 6 - index));
      final key = dateKeyFor(day);
      return MapEntry(day, dailyWordsByDate[key] ?? 0);
    });
  }

  WriterStatsModel copyWith({
    int? dailyGoalWords,
    int? wordsToday,
    int? streakDays,
    int? totalWordsWritten,
    int? writingTimeTodayMinutes,
    Map<String, int>? weeklyProgress,
    Map<String, int>? dailyWordsByDate,
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
      dailyWordsByDate: dailyWordsByDate ?? this.dailyWordsByDate,
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
      'dailyWordsByDate': dailyWordsByDate,
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
      dailyWordsByDate: (map['dailyWordsByDate'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
      wordsPerMinuteAvg: map['wordsPerMinuteAvg'] as int? ?? 30,
      focusScore: map['focusScore'] as int? ?? 90,
    );
  }
}
