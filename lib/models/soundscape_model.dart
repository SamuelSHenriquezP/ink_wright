class SoundscapeModel {
  final String id;
  final String title;
  final String category;
  final String iconEmoji;
  final String description;
  final int colorHex;
  final bool isPlaying;

  const SoundscapeModel({
    required this.id,
    required this.title,
    required this.category,
    required this.iconEmoji,
    required this.description,
    required this.colorHex,
    this.isPlaying = false,
  });

  SoundscapeModel copyWith({
    String? id,
    String? title,
    String? category,
    String? iconEmoji,
    String? description,
    int? colorHex,
    bool? isPlaying,
  }) {
    return SoundscapeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
