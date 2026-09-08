import '../formatters/writer_text_formatter.dart';

class ChapterSnapshotModel {
  final String id;
  final String chapterId;
  final String label;
  final String content;
  final DateTime createdAt;
  final int wordCount;

  ChapterSnapshotModel({
    required this.id,
    required this.chapterId,
    required this.label,
    required this.content,
    required this.createdAt,
    int? wordCount,
  }) : wordCount = wordCount ?? WriterTextFormatter.countWords(content);

  ChapterSnapshotModel copyWith({
    String? id,
    String? chapterId,
    String? label,
    String? content,
    DateTime? createdAt,
    int? wordCount,
  }) {
    return ChapterSnapshotModel(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      label: label ?? this.label,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      wordCount: wordCount ?? (content != null ? WriterTextFormatter.countWords(content) : this.wordCount),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapterId': chapterId,
      'label': label,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'wordCount': wordCount,
    };
  }

  factory ChapterSnapshotModel.fromMap(Map<String, dynamic> map) {
    final rawContent = map['content'] as String? ?? '';
    return ChapterSnapshotModel(
      id: map['id'] as String? ?? '',
      chapterId: map['chapterId'] as String? ?? '',
      label: map['label'] as String? ?? 'Versión guardada',
      content: rawContent,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      wordCount: (map['wordCount'] as num?)?.toInt() ?? WriterTextFormatter.countWords(rawContent),
    );
  }
}
