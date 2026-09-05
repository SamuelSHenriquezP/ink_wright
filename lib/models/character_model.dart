class CharacterModel {
  final String id;
  final String bookId;
  final String name;
  final String role; // Protagonista, Antagonista, Mentor, Aliado, Secundario
  final String archetype; // e.g. El Investigador, El Rebelde, El Sabio
  final List<String> traits; // ['Metódico', 'Reservado', 'Audaz']
  final String physicalAppearance; // Descripción física, rasgos y vestimenta
  final String motivation; // Lo que quiere (meta consciente)
  final String flawOrGhost; // Debilidad, fantasma o herida del pasado
  final String characterArc; // Cómo cambia a lo largo de la historia
  final String writtenBiography; // Texto narrativo completo / biografía escrita
  final String quote; // Frase o diálogo icónico
  final String avatarEmoji; // 🧙‍♂️, ⚔️, 🕵️‍♀️, 👑, 🦉, etc.
  final DateTime createdAt;

  CharacterModel({
    required this.id,
    required this.bookId,
    required this.name,
    required this.role,
    this.archetype = '',
    this.traits = const [],
    this.physicalAppearance = '',
    this.motivation = '',
    this.flawOrGhost = '',
    this.characterArc = '',
    this.writtenBiography = '',
    this.quote = '',
    this.avatarEmoji = '👤',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  CharacterModel copyWith({
    String? id,
    String? bookId,
    String? name,
    String? role,
    String? archetype,
    List<String>? traits,
    String? physicalAppearance,
    String? motivation,
    String? flawOrGhost,
    String? characterArc,
    String? writtenBiography,
    String? quote,
    String? avatarEmoji,
    DateTime? createdAt,
  }) {
    return CharacterModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      name: name ?? this.name,
      role: role ?? this.role,
      archetype: archetype ?? this.archetype,
      traits: traits ?? this.traits,
      physicalAppearance: physicalAppearance ?? this.physicalAppearance,
      motivation: motivation ?? this.motivation,
      flawOrGhost: flawOrGhost ?? this.flawOrGhost,
      characterArc: characterArc ?? this.characterArc,
      writtenBiography: writtenBiography ?? this.writtenBiography,
      quote: quote ?? this.quote,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'name': name,
      'role': role,
      'archetype': archetype,
      'traits': traits,
      'physicalAppearance': physicalAppearance,
      'motivation': motivation,
      'flawOrGhost': flawOrGhost,
      'characterArc': characterArc,
      'writtenBiography': writtenBiography,
      'quote': quote,
      'avatarEmoji': avatarEmoji,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'Personaje',
      archetype: json['archetype'] as String? ?? '',
      traits: (json['traits'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      physicalAppearance: json['physicalAppearance'] as String? ?? '',
      motivation: json['motivation'] as String? ?? '',
      flawOrGhost: json['flawOrGhost'] as String? ?? '',
      characterArc: json['characterArc'] as String? ?? '',
      writtenBiography: json['writtenBiography'] as String? ?? '',
      quote: json['quote'] as String? ?? '',
      avatarEmoji: json['avatarEmoji'] as String? ?? '👤',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
