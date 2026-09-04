enum IdeaCategory {
  character,
  worldbuilding,
  plotTwist,
  dialogue,
  general,
}

class IdeaSnippetModel {
  final String id;
  final String title;
  final String content;
  final IdeaCategory category;
  final int colorHex;
  final DateTime createdAt;
  final bool isPinned;
  final List<String> tags;

  IdeaSnippetModel({
    required this.id,
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
        return 'Character';
      case IdeaCategory.worldbuilding:
        return 'Worldbuilding';
      case IdeaCategory.plotTwist:
        return 'Plot Twist';
      case IdeaCategory.dialogue:
        return 'Dialogue';
      case IdeaCategory.general:
        return 'General Note';
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
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
    );
  }
}
