class ChapterBookmarkModel {
  final String id;
  final String label;
  final int charOffset;
  final String previewText;
  final DateTime createdAt;
  final int? colorHex;

  const ChapterBookmarkModel({
    required this.id,
    required this.label,
    required this.charOffset,
    required this.previewText,
    required this.createdAt,
    this.colorHex,
  });

  ChapterBookmarkModel copyWith({
    String? id,
    String? label,
    int? charOffset,
    String? previewText,
    DateTime? createdAt,
    int? colorHex,
  }) {
    return ChapterBookmarkModel(
      id: id ?? this.id,
      label: label ?? this.label,
      charOffset: charOffset ?? this.charOffset,
      previewText: previewText ?? this.previewText,
      createdAt: createdAt ?? this.createdAt,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'charOffset': charOffset,
      'previewText': previewText,
      'createdAt': createdAt.toIso8601String(),
      'colorHex': colorHex,
    };
  }

  factory ChapterBookmarkModel.fromMap(Map<String, dynamic> map) {
    return ChapterBookmarkModel(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? 'Marcador',
      charOffset: (map['charOffset'] as num?)?.toInt() ?? 0,
      previewText: map['previewText'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      colorHex: (map['colorHex'] as num?)?.toInt(),
    );
  }
}

