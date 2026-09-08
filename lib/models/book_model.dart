import 'chapter_model.dart';

enum BookStatus {
  outlining,
  drafting,
  revising,
  completed,
}

class BookModel {
  final String id;
  final String title;
  final String subtitle;
  final String genre;
  final String coverEmoji;
  final int coverColorHex;
  final int targetWordCount;
  final List<ChapterModel> chapters;
  final DateTime lastEdited;
  final BookStatus status;
  final List<String> tags;
  final String synopsis;

  BookModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.genre,
    required this.coverEmoji,
    required this.coverColorHex,
    required this.targetWordCount,
    required this.chapters,
    required this.lastEdited,
    required this.status,
    required this.tags,
    required this.synopsis,
  });

  int get currentWordCount {
    return chapters.fold(0, (sum, chapter) => sum + chapter.wordCount);
  }

  double get progressPercentage {
    if (targetWordCount == 0) return 0.0;
    final progress = currentWordCount / targetWordCount;
    return progress.clamp(0.0, 1.0);
  }

  int get completedChaptersCount {
    return chapters.where((c) => c.isCompleted).length;
  }

  BookModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? genre,
    String? coverEmoji,
    int? coverColorHex,
    int? targetWordCount,
    List<ChapterModel>? chapters,
    DateTime? lastEdited,
    BookStatus? status,
    List<String>? tags,
    String? synopsis,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      genre: genre ?? this.genre,
      coverEmoji: coverEmoji ?? this.coverEmoji,
      coverColorHex: coverColorHex ?? this.coverColorHex,
      targetWordCount: targetWordCount ?? this.targetWordCount,
      chapters: chapters ?? this.chapters,
      lastEdited: lastEdited ?? this.lastEdited,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      synopsis: synopsis ?? this.synopsis,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'genre': genre,
      'coverEmoji': coverEmoji,
      'coverColorHex': coverColorHex,
      'targetWordCount': targetWordCount,
      'chapters': chapters.map((c) => c.toMap()).toList(),
      'lastEdited': lastEdited.toIso8601String(),
      'status': status.name,
      'tags': tags,
      'synopsis': synopsis,
    };
  }

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      genre: map['genre'] as String? ?? '',
      coverEmoji: map['coverEmoji'] as String? ?? '📖',
      coverColorHex: map['coverColorHex'] as int? ?? 0xFF18181B,
      targetWordCount: map['targetWordCount'] as int? ?? 50000,
      chapters: (map['chapters'] as List<dynamic>?)
              ?.map((c) => ChapterModel.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      lastEdited: map['lastEdited'] != null
          ? DateTime.tryParse(map['lastEdited'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: BookStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? ''),
        orElse: () => BookStatus.drafting,
      ),
      tags: (map['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? [],
      synopsis: map['synopsis'] as String? ?? '',
    );
  }
}
