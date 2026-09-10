enum IdeaCategory {
  character,
  worldbuilding,
  plotTwist,
  dialogue,
  general,
}

class IdeaSnippetModel {
  final String id;
  final String bookId;
  final String title;
  final String content;
  final IdeaCategory category;
  final int colorHex;
  final DateTime createdAt;
  final bool isPinned;
  final List<String> tags;

  IdeaSnippetModel({
    required this.id,
    this.bookId = '',
    required this.title,
    required this.content,
    required this.category,
    required this.colorHex,
    required this.createdAt,
    this.isPinned = false,
    required this.tags,
  });

  String get categoryLabel {
    switch (category) {
      case IdeaCategory.character:
        return 'Personaje';
      case IdeaCategory.worldbuilding:
        return 'Mundo / Entorno';
      case IdeaCategory.plotTwist:
        return 'Giro de Trama';
      case IdeaCategory.dialogue:
        return 'Diálogo';
      case IdeaCategory.general:
        return 'Nota General';
    }
  }

  String get categoryIcon {
    switch (category) {
      case IdeaCategory.character:
        return '👤';
      case IdeaCategory.worldbuilding:
        return '🗺️';
      case IdeaCategory.plotTwist:
        return '⚡';
      case IdeaCategory.dialogue:
        return '💬';
      case IdeaCategory.general:
        return '📝';
    }
  }

  IdeaSnippetModel copyWith({
    String? id,
    String? bookId,
    String? title,
    String? content,
    IdeaCategory? category,
    int? colorHex,
    DateTime? createdAt,
    bool? isPinned,
    List<String>? tags,
  }) {
    return IdeaSnippetModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'title': title,
      'content': content,
      'category': category.name,
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
      'isPinned': isPinned,
      'tags': tags,
    };
  }

  factory IdeaSnippetModel.fromMap(Map<String, dynamic> map) {
    return IdeaSnippetModel(
      id: map['id'] as String? ?? '',
      bookId: map['bookId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      category: IdeaCategory.values.firstWhere(
        (c) => c.name == (map['category'] as String? ?? ''),
        orElse: () => IdeaCategory.general,
      ),
      colorHex: map['colorHex'] as int? ?? 0xFF18181B,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isPinned: map['isPinned'] as bool? ?? false,
      tags: (map['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? [],
    );
  }
}
