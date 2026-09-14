class RevisionCommentModel {
  final String id;
  final String chapterId;
  final int charOffset;
  final int length;
  final String commentText;
  final String highlightedText; // Snippet of the text being commented on
  final bool isResolved;
  final int colorHex;
  final DateTime createdAt;

  RevisionCommentModel({
    required this.id,
    required this.chapterId,
    required this.charOffset,
    required this.length,
    required this.commentText,
    required this.highlightedText,
    this.isResolved = false,
    this.colorHex = 0xFFFFC107,
    required this.createdAt,
  });

  RevisionCommentModel copyWith({
    String? id,
    String? chapterId,
    int? charOffset,
    int? length,
    String? commentText,
    String? highlightedText,
    bool? isResolved,
    int? colorHex,
    DateTime? createdAt,
  }) {
    return RevisionCommentModel(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      charOffset: charOffset ?? this.charOffset,
      length: length ?? this.length,
      commentText: commentText ?? this.commentText,
      highlightedText: highlightedText ?? this.highlightedText,
      isResolved: isResolved ?? this.isResolved,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapterId': chapterId,
      'charOffset': charOffset,
      'length': length,
      'commentText': commentText,
      'highlightedText': highlightedText,
      'isResolved': isResolved,
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RevisionCommentModel.fromMap(Map<String, dynamic> map) {
    return RevisionCommentModel(
      id: map['id'] as String? ?? '',
      chapterId: map['chapterId'] as String? ?? '',
      charOffset: map['charOffset'] as int? ?? 0,
      length: map['length'] as int? ?? 0,
      commentText: map['commentText'] as String? ?? '',
      highlightedText: map['highlightedText'] as String? ?? '',
      isResolved: map['isResolved'] as bool? ?? false,
      colorHex: map['colorHex'] as int? ?? 0xFFFFC107,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

