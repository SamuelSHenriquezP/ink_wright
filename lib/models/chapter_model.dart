class ChapterModel {
  final String id;
  final String bookId;
  final int chapterNumber;
  final String title;
  final String content;
  final DateTime lastEdited;
  final bool isCompleted;
  final String notes;
  final String povCharacter;

  ChapterModel({
    required this.id,
    required this.bookId,
    required this.chapterNumber,
    required this.title,
    required this.content,
    required this.lastEdited,
    this.isCompleted = false,
    this.notes = '',
    this.povCharacter = '',
  });

  int get wordCount {
    if (content.trim().isEmpty) return 0;
    final cleanText = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleanText.split(' ').length;
  }

  int get readingTimeMinutes {
    // Average reading speed: 200 words per minute
    final minutes = (wordCount / 200).ceil();
    return minutes == 0 ? 1 : minutes;
  }

  ChapterModel copyWith({
    String? id,
    String? bookId,
    int? chapterNumber,
    String? title,
    String? content,
    DateTime? lastEdited,
    bool? isCompleted,
    String? notes,
    String? povCharacter,
  }) {
    return ChapterModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      title: title ?? this.title,
      content: content ?? this.content,
      lastEdited: lastEdited ?? this.lastEdited,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      povCharacter: povCharacter ?? this.povCharacter,
    );
  }
}
