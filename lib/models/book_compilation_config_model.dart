enum CoverTextPosition {
  top,
  center,
  bottom,
}

class BookCoverConfig {
  final String title;
  final String author;
  final String subtitle;
  final String? imagePath;
  final int backgroundColorHex;
  final int textColorHex;
  final String fontFamily;
  final CoverTextPosition textPosition;

  const BookCoverConfig({
    required this.title,
    required this.author,
    this.subtitle = '',
    this.imagePath,
    this.backgroundColorHex = 0xFF18181B, // Elegant Charcoal
    this.textColorHex = 0xFFF4F4F5, // Ivory / Platinum
    this.fontFamily = 'Playfair Display',
    this.textPosition = CoverTextPosition.center,
  });

  BookCoverConfig copyWith({
    String? title,
    String? author,
    String? subtitle,
    String? imagePath,
    bool clearImage = false,
    int? backgroundColorHex,
    int? textColorHex,
    String? fontFamily,
    CoverTextPosition? textPosition,
  }) {
    return BookCoverConfig(
      title: title ?? this.title,
      author: author ?? this.author,
      subtitle: subtitle ?? this.subtitle,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      textColorHex: textColorHex ?? this.textColorHex,
      fontFamily: fontFamily ?? this.fontFamily,
      textPosition: textPosition ?? this.textPosition,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'subtitle': subtitle,
      'imagePath': imagePath,
      'backgroundColorHex': backgroundColorHex,
      'textColorHex': textColorHex,
      'fontFamily': fontFamily,
      'textPosition': textPosition.name,
    };
  }

  factory BookCoverConfig.fromMap(Map<String, dynamic> map) {
    return BookCoverConfig(
      title: map['title'] as String? ?? '',
      author: map['author'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      imagePath: map['imagePath'] as String?,
      backgroundColorHex: (map['backgroundColorHex'] as num?)?.toInt() ?? 0xFF18181B,
      textColorHex: (map['textColorHex'] as num?)?.toInt() ?? 0xFFF4F4F5,
      fontFamily: map['fontFamily'] as String? ?? 'Playfair Display',
      textPosition: CoverTextPosition.values.firstWhere(
        (p) => p.name == (map['textPosition'] as String? ?? ''),
        orElse: () => CoverTextPosition.center,
      ),
    );
  }
}

enum EditorialPreset {
  classic,
  modern,
  manuscriptSubmission,
}

class BookCompilationConfig {
  final BookCoverConfig cover;
  final String dedication;
  final String copyrightNotice;
  final bool includeTableOfContents;
  final Map<String, String> customChapterTitles;
  final List<String> excludedChapterIds;
  final List<String> orderedChapterIds;
  final EditorialPreset preset;
  final String sceneSeparator;
  final String authorBio;
  final String acknowledgments;
  final String authorSocials;

  const BookCompilationConfig({
    required this.cover,
    this.dedication = '',
    this.copyrightNotice = '',
    this.includeTableOfContents = true,
    this.customChapterTitles = const {},
    this.excludedChapterIds = const [],
    this.orderedChapterIds = const [],
    this.preset = EditorialPreset.classic,
    this.sceneSeparator = '* * *',
    this.authorBio = '',
    this.acknowledgments = '',
    this.authorSocials = '',
  });

  BookCompilationConfig copyWith({
    BookCoverConfig? cover,
    String? dedication,
    String? copyrightNotice,
    bool? includeTableOfContents,
    Map<String, String>? customChapterTitles,
    List<String>? excludedChapterIds,
    List<String>? orderedChapterIds,
    EditorialPreset? preset,
    String? sceneSeparator,
    String? authorBio,
    String? acknowledgments,
    String? authorSocials,
  }) {
    return BookCompilationConfig(
      cover: cover ?? this.cover,
      dedication: dedication ?? this.dedication,
      copyrightNotice: copyrightNotice ?? this.copyrightNotice,
      includeTableOfContents: includeTableOfContents ?? this.includeTableOfContents,
      customChapterTitles: customChapterTitles ?? this.customChapterTitles,
      excludedChapterIds: excludedChapterIds ?? this.excludedChapterIds,
      orderedChapterIds: orderedChapterIds ?? this.orderedChapterIds,
      preset: preset ?? this.preset,
      sceneSeparator: sceneSeparator ?? this.sceneSeparator,
      authorBio: authorBio ?? this.authorBio,
      acknowledgments: acknowledgments ?? this.acknowledgments,
      authorSocials: authorSocials ?? this.authorSocials,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cover': cover.toMap(),
      'dedication': dedication,
      'copyrightNotice': copyrightNotice,
      'includeTableOfContents': includeTableOfContents,
      'customChapterTitles': customChapterTitles,
      'excludedChapterIds': excludedChapterIds,
      'orderedChapterIds': orderedChapterIds,
      'preset': preset.name,
      'sceneSeparator': sceneSeparator,
      'authorBio': authorBio,
      'acknowledgments': acknowledgments,
      'authorSocials': authorSocials,
    };
  }

  factory BookCompilationConfig.fromMap(Map<String, dynamic> map, {String defaultTitle = '', String defaultAuthor = ''}) {
    return BookCompilationConfig(
      cover: map['cover'] != null
          ? BookCoverConfig.fromMap(Map<String, dynamic>.from(map['cover'] as Map))
          : BookCoverConfig(title: defaultTitle, author: defaultAuthor),
      dedication: map['dedication'] as String? ?? '',
      copyrightNotice: map['copyrightNotice'] as String? ?? '',
      includeTableOfContents: map['includeTableOfContents'] as bool? ?? true,
      customChapterTitles: (map['customChapterTitles'] as Map<dynamic, dynamic>?)
              ?.map((k, v) => MapEntry(k.toString(), v.toString())) ??
          const {},
      excludedChapterIds: (map['excludedChapterIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      orderedChapterIds: (map['orderedChapterIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      preset: EditorialPreset.values.firstWhere(
        (p) => p.name == (map['preset'] as String? ?? ''),
        orElse: () => EditorialPreset.classic,
      ),
      sceneSeparator: map['sceneSeparator'] as String? ?? '* * *',
      authorBio: map['authorBio'] as String? ?? '',
      acknowledgments: map['acknowledgments'] as String? ?? '',
      authorSocials: map['authorSocials'] as String? ?? '',
    );
  }
}

