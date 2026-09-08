import '../formatters/writer_text_formatter.dart';

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

  int get wordCount => WriterTextFormatter.countWords(content);

  int get readingTimeMinutes {
    // Average reading speed: 200 words per minute
    if (wordCount == 0) return 0;
    final minutes = (wordCount / 200).ceil();
    return minutes;
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterNumber': chapterNumber,
      'title': title,
      'content': content,
      'lastEdited': lastEdited.toIso8601String(),
      'isCompleted': isCompleted,
      'notes': notes,
      'povCharacter': povCharacter,
    };
  }

  factory ChapterModel.fromMap(Map<String, dynamic> map) {
    return ChapterModel(
      id: map['id'] as String? ?? '',
      bookId: map['bookId'] as String? ?? '',
      chapterNumber: map['chapterNumber'] as int? ?? 1,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      lastEdited: map['lastEdited'] != null
          ? DateTime.tryParse(map['lastEdited'] as String) ?? DateTime.now()
          : DateTime.now(),
      isCompleted: map['isCompleted'] as bool? ?? false,
      notes: map['notes'] as String? ?? '',
      povCharacter: map['povCharacter'] as String? ?? '',
    );
  }
}
