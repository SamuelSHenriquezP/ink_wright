class SprintHistoryModel {
  final String id;
  final String bookId;
  final String chapterId;
  final String chapterTitle;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final int targetWords;
  final int wordsWritten;
  final bool completed;

  SprintHistoryModel({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.chapterTitle,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.targetWords,
    required this.wordsWritten,
    required this.completed,
  });

  double get completionRate {
    if (targetWords <= 0) return completed ? 1.0 : 0.0;
    return (wordsWritten / targetWords).clamp(0.0, 1.0);
  }

  int get actualDurationMinutes {
    final diff = endTime.difference(startTime).inMinutes;
    return diff.clamp(1, durationMinutes + 1);
  }

  double get wordsPerMinute {
    final minutes = actualDurationMinutes;
    if (minutes <= 0) return 0.0;
    return wordsWritten / minutes;
  }

  bool get goalReached => wordsWritten >= targetWords && targetWords > 0;

  SprintHistoryModel copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    String? chapterTitle,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    int? targetWords,
    int? wordsWritten,
    bool? completed,
  }) {
    return SprintHistoryModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      targetWords: targetWords ?? this.targetWords,
      wordsWritten: wordsWritten ?? this.wordsWritten,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'targetWords': targetWords,
      'wordsWritten': wordsWritten,
      'completed': completed,
    };
  }

  factory SprintHistoryModel.fromMap(Map<String, dynamic> map) {
    return SprintHistoryModel(
      id: map['id'] as String? ?? '',
      bookId: map['bookId'] as String? ?? '',
      chapterId: map['chapterId'] as String? ?? '',
      chapterTitle: map['chapterTitle'] as String? ?? '',
      startTime: map['startTime'] != null
          ? DateTime.tryParse(map['startTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      endTime: map['endTime'] != null
          ? DateTime.tryParse(map['endTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      durationMinutes: map['durationMinutes'] as int? ?? 25,
      targetWords: map['targetWords'] as int? ?? 0,
      wordsWritten: map['wordsWritten'] as int? ?? 0,
      completed: map['completed'] as bool? ?? false,
    );
  }
}

