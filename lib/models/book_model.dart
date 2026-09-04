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
}
