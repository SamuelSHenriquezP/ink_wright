class WritingSprintModel {
  final int durationMinutes;
  final int targetWords;
  final int startingWordCount;
  final int wordsWritten;
  final DateTime startTime;
  final bool isActive;
  final bool isCompleted;

  WritingSprintModel({
    required this.durationMinutes,
    required this.targetWords,
    required this.startingWordCount,
    this.wordsWritten = 0,
    required this.startTime,
    this.isActive = false,
    this.isCompleted = false,
  });

  double get progress {
    if (targetWords <= 0) return 0.0;
    return (wordsWritten / targetWords).clamp(0.0, 1.0);
  }

  int get wordsRemaining {
    final rem = targetWords - wordsWritten;
    return rem < 0 ? 0 : rem;
  }

  WritingSprintModel copyWith({
    int? durationMinutes,
    int? targetWords,
    int? startingWordCount,
    int? wordsWritten,
    DateTime? startTime,
    bool? isActive,
    bool? isCompleted,
  }) {
    return WritingSprintModel(
      durationMinutes: durationMinutes ?? this.durationMinutes,
      targetWords: targetWords ?? this.targetWords,
      startingWordCount: startingWordCount ?? this.startingWordCount,
      wordsWritten: wordsWritten ?? this.wordsWritten,
      startTime: startTime ?? this.startTime,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'durationMinutes': durationMinutes,
      'targetWords': targetWords,
      'startingWordCount': startingWordCount,
      'wordsWritten': wordsWritten,
      'startTime': startTime.toIso8601String(),
      'isActive': isActive,
      'isCompleted': isCompleted,
    };
  }

  factory WritingSprintModel.fromMap(Map<String, dynamic> map) {
    return WritingSprintModel(
      durationMinutes: map['durationMinutes'] as int? ?? 25,
      targetWords: map['targetWords'] as int? ?? 500,
      startingWordCount: map['startingWordCount'] as int? ?? 0,
      wordsWritten: map['wordsWritten'] as int? ?? 0,
      startTime: map['startTime'] != null
          ? DateTime.tryParse(map['startTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      isActive: map['isActive'] as bool? ?? false,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}
