enum RelationshipType {
  aliado,
  rival,
  mentor,
  romantico,
  familiar,
  neutro,
}

extension RelationshipTypeExtension on RelationshipType {
  String get label {
    switch (this) {
      case RelationshipType.aliado:
        return 'Aliado';
      case RelationshipType.rival:
        return 'Rival / Antagonista';
      case RelationshipType.mentor:
        return 'Mentor / Aprendiz';
      case RelationshipType.romantico:
        return 'Vínculo Romántico';
      case RelationshipType.familiar:
        return 'Lazo Familiar';
      case RelationshipType.neutro:
        return 'Neutro / Conocidos';
    }
  }

  String get icon {
    switch (this) {
      case RelationshipType.aliado:
        return '🤝';
      case RelationshipType.rival:
        return '⚔️';
      case RelationshipType.mentor:
        return '🦉';
      case RelationshipType.romantico:
        return '❤️';
      case RelationshipType.familiar:
        return '👨‍👩‍👧';
      case RelationshipType.neutro:
        return '🔘';
    }
  }

  int get colorHex {
    switch (this) {
      case RelationshipType.aliado:
        return 0xFF38C793;
      case RelationshipType.rival:
        return 0xFFE05252;
      case RelationshipType.mentor:
        return 0xFF7C6AF5;
      case RelationshipType.romantico:
        return 0xFFE8567A;
      case RelationshipType.familiar:
        return 0xFFE89B56;
      case RelationshipType.neutro:
        return 0xFF8A8A9A;
    }
  }
}

class CharacterRelationshipModel {
  final String id;
  final String bookId;
  final String fromCharacterId;
  final String toCharacterId;
  final RelationshipType type;
  final String description;
  final int strength; // 1–5
  final bool isMutual; // If false, it's a one-way relationship

  CharacterRelationshipModel({
    required this.id,
    required this.bookId,
    required this.fromCharacterId,
    required this.toCharacterId,
    required this.type,
    this.description = '',
    this.strength = 3,
    this.isMutual = true,
  });

  CharacterRelationshipModel copyWith({
    String? id,
    String? bookId,
    String? fromCharacterId,
    String? toCharacterId,
    RelationshipType? type,
    String? description,
    int? strength,
    bool? isMutual,
  }) {
    return CharacterRelationshipModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      fromCharacterId: fromCharacterId ?? this.fromCharacterId,
      toCharacterId: toCharacterId ?? this.toCharacterId,
      type: type ?? this.type,
      description: description ?? this.description,
      strength: strength ?? this.strength,
      isMutual: isMutual ?? this.isMutual,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'fromCharacterId': fromCharacterId,
      'toCharacterId': toCharacterId,
      'type': type.name,
      'description': description,
      'strength': strength,
      'isMutual': isMutual,
    };
  }

  factory CharacterRelationshipModel.fromJson(Map<String, dynamic> json) {
    return CharacterRelationshipModel(
      id: json['id'] as String? ?? '',
      bookId: json['bookId'] as String? ?? '',
      fromCharacterId: json['fromCharacterId'] as String? ?? '',
      toCharacterId: json['toCharacterId'] as String? ?? '',
      type: RelationshipType.values.firstWhere(
        (t) => t.name == (json['type'] as String? ?? ''),
        orElse: () => RelationshipType.neutro,
      ),
      description: json['description'] as String? ?? '',
      strength: (json['strength'] as num?)?.toInt().clamp(1, 5) ?? 3,
      isMutual: json['isMutual'] as bool? ?? true,
    );
  }
}

