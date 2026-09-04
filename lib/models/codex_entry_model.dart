enum CodexType {
  character,
  location,
  artifact,
  lore,
}

class CodexEntryModel {
  final String id;
  final String bookId;
  final String name;
  final CodexType type;
  final String role; // e.g. "Protagonist", "Ancient Relic", "Abandoned Abbey"
  final String description;
  final List<String> traits;
  final String secrets;
  final String avatarEmoji;
  final bool isPinned;
  final DateTime createdAt;

  CodexEntryModel({
    required this.id,
    required this.bookId,
    required this.name,
    required this.type,
    required this.role,
    required this.description,
    required this.traits,
    required this.secrets,
    required this.avatarEmoji,
    this.isPinned = false,
    required this.createdAt,
  });

  String get typeLabel {
    switch (type) {
      case CodexType.character:
        return 'Character';
      case CodexType.location:
        return 'Location';
      case CodexType.artifact:
        return 'Artifact / Relic';
      case CodexType.lore:
        return 'Lore & Faction';
    }
  }

  String get defaultEmoji {
    if (avatarEmoji.isNotEmpty) return avatarEmoji;
    switch (type) {
      case CodexType.character:
        return '🧙‍♂️';
      case CodexType.location:
        return '🏰';
      case CodexType.artifact:
        return '🗝️';
      case CodexType.lore:
        return '📜';
    }
  }

  CodexEntryModel copyWith({
    String? id,
    String? bookId,
    String? name,
    CodexType? type,
    String? role,
    String? description,
    List<String>? traits,
    String? secrets,
    String? avatarEmoji,
    bool? isPinned,
    DateTime? createdAt,
  }) {
    return CodexEntryModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      name: name ?? this.name,
      type: type ?? this.type,
      role: role ?? this.role,
      description: description ?? this.description,
      traits: traits ?? this.traits,
      secrets: secrets ?? this.secrets,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
