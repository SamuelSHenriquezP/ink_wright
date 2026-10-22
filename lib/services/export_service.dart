import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/book_model.dart';
import '../models/chapter_model.dart';
import '../models/character_model.dart';
import '../models/codex_entry_model.dart';
import '../models/book_compilation_config_model.dart';

class CompiledChapterItem {
  final ChapterModel chapter;
  final String displayTitle;
  final String displayHeader;
  final int index;

  CompiledChapterItem({
    required this.chapter,
    required this.displayTitle,
    required this.displayHeader,
    required this.index,
  });
}

class ExportService {
  static final RegExp _docInlineRegex = RegExp(
    r'(\*\*\*.*?\*\*\*|___.*?___|\*\*.*?\*\*|__.*?__|\*.*?\*|_.*?_|~~.*?~~|`.*?`|==.*?==)',
  );
  /// Sorts, filters, and formats chapters according to the compilation configuration.
  /// Prologues first, followed by regular chapters, followed by epilogues.
  static List<CompiledChapterItem> getCompiledChapters(
    BookModel book, [
    BookCompilationConfig? config,
  ]) {
    final cfg = config ?? book.compilationConfig;
    final excluded = cfg?.excludedChapterIds.toSet() ?? const <String>{};
    final active = book.chapters.where((c) => !excluded.contains(c.id)).toList();

    if (cfg != null && cfg.orderedChapterIds.isNotEmpty) {
      final orderMap = {for (int i = 0; i < cfg.orderedChapterIds.length; i++) cfg.orderedChapterIds[i]: i};
      active.sort((a, b) {
        final orderA = orderMap[a.id] ?? 999999;
        final orderB = orderMap[b.id] ?? 999999;
        return orderA.compareTo(orderB);
      });
    }

    final prologues = active.where((c) => c.chapterType == ChapterType.prologue).toList();
    final regulars = active.where((c) => c.chapterType == ChapterType.chapter).toList();
    final epilogues = active.where((c) => c.chapterType == ChapterType.epilogue).toList();

    final List<CompiledChapterItem> result = [];
    int counter = 1;

    for (final p in prologues) {
      final custom = cfg?.customChapterTitles[p.id]?.trim();
      final title = (custom != null && custom.isNotEmpty) ? custom : p.title;
      final header = title.toLowerCase().contains('prólogo') || title.toLowerCase().contains('prologo')
          ? title
          : (title.isEmpty ? 'Prólogo' : 'Prólogo: $title');
      result.add(CompiledChapterItem(chapter: p, displayTitle: title, displayHeader: header, index: counter++));
    }

    int regNum = 1;
    for (final r in regulars) {
      final custom = cfg?.customChapterTitles[r.id]?.trim();
      final title = (custom != null && custom.isNotEmpty) ? custom : r.title;
      final header = 'Capítulo $regNum${title.isNotEmpty ? ': $title' : ''}';
      result.add(CompiledChapterItem(chapter: r, displayTitle: title, displayHeader: header, index: counter++));
      regNum++;
    }

    for (final e in epilogues) {
      final custom = cfg?.customChapterTitles[e.id]?.trim();
      final title = (custom != null && custom.isNotEmpty) ? custom : e.title;
      final header = title.toLowerCase().contains('epílogo') || title.toLowerCase().contains('epilogo')
          ? title
          : (title.isEmpty ? 'Epílogo' : 'Epílogo: $title');
      result.add(CompiledChapterItem(chapter: e, displayTitle: title, displayHeader: header, index: counter++));
    }

    return result;
  }

  /// Formats scene breaks in chapter text with the user's custom scene separator (e.g. * * *, * * *, ~ * ~)
  static String formatChapterText(String rawText, BookCompilationConfig? cfg) {
    if (cfg == null || cfg.sceneSeparator.trim().isEmpty) return rawText;
    final sep = cfg.sceneSeparator.trim();
    return rawText.replaceAll(RegExp(r'\n\s*(\*\s*\*\s*\*|---|___|\#\#\#)\s*\n'), '\n\n$sep\n\n');
  }

  /// Exports purely the story text without any metadata, statistics, cover, or extra dividers.
  /// Permite exportar únicamente el texto de la obra sin agregados adicionales.
  static String exportRawText(
    BookModel book, {
    bool includeChapterHeaders = true,
    BookCompilationConfig? compilationConfig,
  }) {
    final cfg = compilationConfig ?? book.compilationConfig;
    final compiledChapters = getCompiledChapters(book, cfg);
    final buffer = StringBuffer();

    for (int i = 0; i < compiledChapters.length; i++) {
      final item = compiledChapters[i];
      if (includeChapterHeaders && item.displayHeader.isNotEmpty) {
        buffer.writeln(item.displayHeader);
        buffer.writeln();
      }
      buffer.writeln(item.chapter.content.trim());
      if (i < compiledChapters.length - 1) {
        buffer.writeln();
        buffer.writeln();
      }
    }

    return buffer.toString().trim();
  }

  /// Generates clean, well-formatted Markdown with optional YAML frontmatter and editorial additions
  static String exportToMarkdown(
    BookModel book, {
    List<CharacterModel>? characters,
    List<CodexEntryModel>? codexEntries,
    BookCompilationConfig? compilationConfig,
    bool includeEditorialElements = true,
  }) {
    final cfg = compilationConfig ?? book.compilationConfig;
    final compiledChapters = getCompiledChapters(book, cfg);
    final buffer = StringBuffer();

    if (includeEditorialElements) {
      final title = cfg?.cover.title.isNotEmpty == true ? cfg!.cover.title : book.title;
      final subtitle = cfg?.cover.subtitle.isNotEmpty == true ? cfg!.cover.subtitle : book.subtitle;
      final author = cfg?.cover.author.isNotEmpty == true ? cfg!.cover.author : 'InkWright Author';

      // YAML Frontmatter
      buffer.writeln('---');
      buffer.writeln('title: "$title"');
      if (subtitle.isNotEmpty) {
        buffer.writeln('subtitle: "$subtitle"');
      }
      buffer.writeln('author: "$author"');
      buffer.writeln('genre: "${book.genre}"');
      buffer.writeln('total_words: ${book.currentWordCount}');
      buffer.writeln('target_words: ${book.targetWordCount}');
      buffer.writeln('chapters_count: ${compiledChapters.length}');
      buffer.writeln('exported_at: "${DateTime.now().toIso8601String()}"');
      if (book.tags.isNotEmpty) {
        buffer.writeln('tags: [${book.tags.map((t) => '"$t"').join(', ')}]');
      }
      buffer.writeln('---');
      buffer.writeln();

      // Book Title & Author
      buffer.writeln('# $title');
      if (subtitle.isNotEmpty) {
        buffer.writeln('### *$subtitle*');
      }
      buffer.writeln('**Por: $author**');
      buffer.writeln();

      // Dedication
      if (cfg != null && cfg.dedication.trim().isNotEmpty) {
        buffer.writeln('> *«${cfg.dedication.trim()}»*');
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }

      if (book.synopsis.isNotEmpty) {
        buffer.writeln('> **Sinopsis:** ${book.synopsis}');
        buffer.writeln();
      }

      // Optional Dramatis Personae
      if (characters != null && characters.isNotEmpty) {
        buffer.writeln('## Dramatis Personae (Personajes)');
        buffer.writeln();
        for (final char in characters) {
          buffer.writeln('### ${char.avatarEmoji} ${char.name} — ${char.role}${char.archetype.isNotEmpty ? ' (${char.archetype})' : ''}');
          if (char.quote.isNotEmpty) {
            buffer.writeln('> ${char.quote}');
          }
          if (char.traits.isNotEmpty) {
            buffer.writeln('- **Rasgos:** ${char.traits.join(", ")}');
          }
          if (char.motivation.isNotEmpty) {
            buffer.writeln('- **Motivación:** ${char.motivation}');
          }
          if (char.flawOrGhost.isNotEmpty) {
            buffer.writeln('- **Conflicto interno:** ${char.flawOrGhost}');
          }
          if (char.writtenBiography.isNotEmpty) {
            buffer.writeln('\n${char.writtenBiography}');
          }
          buffer.writeln();
        }
        buffer.writeln('***');
        buffer.writeln();
      }

      // Optional Codex Entries
      if (codexEntries != null && codexEntries.isNotEmpty) {
        buffer.writeln('## Apéndice del Códice');
        buffer.writeln();
        for (final entry in codexEntries) {
          buffer.writeln('### ${entry.avatarEmoji.isNotEmpty ? entry.avatarEmoji : entry.defaultEmoji} ${entry.name} (${entry.typeLabel})');
          if (entry.role.isNotEmpty) {
            buffer.writeln('> ${entry.role}');
          }
          if (entry.description.isNotEmpty) {
            buffer.writeln('\n${entry.description}');
          }
          buffer.writeln();
        }
        buffer.writeln('***');
        buffer.writeln();
      }

      // Table of contents
      if (cfg?.includeTableOfContents == true) {
        buffer.writeln('## Índice de Contenido');
        buffer.writeln();
        for (final item in compiledChapters) {
          buffer.writeln('- ${item.displayHeader}');
        }
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
    }

    // Chapters
    for (int i = 0; i < compiledChapters.length; i++) {
      final item = compiledChapters[i];
      final ChapterModel ch = item.chapter;
      buffer.writeln('## ${item.displayHeader}');
      if (includeEditorialElements && ch.povCharacter.isNotEmpty) {
        buffer.writeln('*POV: ${ch.povCharacter}*');
      }
      buffer.writeln();
      buffer.writeln(formatChapterText(ch.content, cfg).trim());
      buffer.writeln();
      if (i < compiledChapters.length - 1) {
        buffer.writeln(cfg?.sceneSeparator.trim().isNotEmpty == true ? cfg!.sceneSeparator.trim() : '***');
        buffer.writeln();
      }
    }

    if (includeEditorialElements && cfg != null && cfg.acknowledgments.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('## Agradecimientos');
      buffer.writeln();
      buffer.writeln(cfg.acknowledgments.trim());
      buffer.writeln();
      buffer.writeln('***');
    }

    if (includeEditorialElements && cfg != null && (cfg.authorBio.trim().isNotEmpty || cfg.authorSocials.trim().isNotEmpty)) {
      buffer.writeln();
      buffer.writeln('## Sobre el Autor');
      buffer.writeln();
      if (cfg.authorBio.trim().isNotEmpty) {
        buffer.writeln(cfg.authorBio.trim());
        buffer.writeln();
      }
      if (cfg.authorSocials.trim().isNotEmpty) {
        buffer.writeln('*Contacto y Redes:* ${cfg.authorSocials.trim()}');
        buffer.writeln();
      }
      buffer.writeln('***');
    }

    if (includeEditorialElements && cfg != null && cfg.copyrightNotice.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('*${cfg.copyrightNotice.trim()}*');
    }

    return buffer.toString().trim();
  }

  /// Generates classic plain text manuscript layout
  static String exportToPlainText(
    BookModel book, {
    List<CharacterModel>? characters,
    List<CodexEntryModel>? codexEntries,
    BookCompilationConfig? compilationConfig,
    bool rawTextOnly = false,
    bool includeEditorialElements = true,
  }) {
    if (rawTextOnly || !includeEditorialElements) {
      return exportRawText(book, includeChapterHeaders: true, compilationConfig: compilationConfig);
    }
    final cfg = compilationConfig ?? book.compilationConfig;
    final compiledChapters = getCompiledChapters(book, cfg);
    final buffer = StringBuffer();

    final title = cfg?.cover.title.isNotEmpty == true ? cfg!.cover.title : book.title;
    final subtitle = cfg?.cover.subtitle.isNotEmpty == true ? cfg!.cover.subtitle : book.subtitle;
    final author = cfg?.cover.author.isNotEmpty == true ? cfg!.cover.author : 'InkWright Author';

    buffer.writeln('================================================================');
    buffer.writeln(title.toUpperCase());
    if (subtitle.isNotEmpty) {
      buffer.writeln(subtitle);
    }
    buffer.writeln('Por: $author');
    buffer.writeln('================================================================');
    buffer.writeln('Género: ${book.genre}');
    buffer.writeln('Palabras totales: ${book.currentWordCount}');
    buffer.writeln('Capítulos: ${compiledChapters.length}');
    buffer.writeln('Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    buffer.writeln('================================================================');
    buffer.writeln();

    if (cfg != null && cfg.dedication.trim().isNotEmpty) {
      buffer.writeln('DEDICATORIA:');
      buffer.writeln('"${cfg.dedication.trim()}"');
      buffer.writeln();
      buffer.writeln('----------------------------------------------------------------');
      buffer.writeln();
    }

    if (book.synopsis.isNotEmpty) {
      buffer.writeln('SINOPSIS:');
      buffer.writeln(book.synopsis);
      buffer.writeln();
      buffer.writeln('----------------------------------------------------------------');
      buffer.writeln();
    }

    if (characters != null && characters.isNotEmpty) {
      buffer.writeln('DRAMATIS PERSONAE (PERSONAJES)');
      buffer.writeln('----------------------------------------------------------------');
      for (final char in characters) {
        buffer.writeln('${char.name.toUpperCase()} — ${char.role}${char.archetype.isNotEmpty ? ' (${char.archetype})' : ''}');
        if (char.quote.isNotEmpty) buffer.writeln('"${char.quote}"');
        if (char.traits.isNotEmpty) buffer.writeln('Rasgos: ${char.traits.join(", ")}');
        if (char.motivation.isNotEmpty) buffer.writeln('Motivación: ${char.motivation}');
        if (char.writtenBiography.isNotEmpty) buffer.writeln('\n${char.writtenBiography}');
        buffer.writeln();
        buffer.writeln('----------------------------------------------------------------');
      }
      buffer.writeln();
    }

    if (codexEntries != null && codexEntries.isNotEmpty) {
      buffer.writeln('APÉNDICE DEL CÓDICE');
      buffer.writeln('----------------------------------------------------------------');
      for (final entry in codexEntries) {
        buffer.writeln('${entry.name.toUpperCase()} (${entry.typeLabel.toUpperCase()})');
        if (entry.role.isNotEmpty) buffer.writeln(entry.role);
        if (entry.description.isNotEmpty) buffer.writeln('\n${entry.description}');
        buffer.writeln();
        buffer.writeln('----------------------------------------------------------------');
      }
      buffer.writeln();
    }

    if (cfg?.includeTableOfContents == true) {
      buffer.writeln('ÍNDICE DE CONTENIDO');
      buffer.writeln('----------------------------------------------------------------');
      for (final item in compiledChapters) {
        buffer.writeln('• ${item.displayHeader}');
      }
      buffer.writeln();
      buffer.writeln('----------------------------------------------------------------');
      buffer.writeln();
    }

    for (final item in compiledChapters) {
      final ch = item.chapter;
      buffer.writeln(item.displayHeader.toUpperCase());
      if (ch.povCharacter.isNotEmpty) {
        buffer.writeln('(POV: ${ch.povCharacter})');
      }
      buffer.writeln();
      buffer.writeln(formatChapterText(ch.content, cfg).trim());
      buffer.writeln();
      buffer.writeln('----------------------------------------------------------------');
      buffer.writeln();
    }

    if (cfg != null && cfg.acknowledgments.trim().isNotEmpty) {
      buffer.writeln('AGRADECIMIENTOS');
      buffer.writeln('----------------------------------------------------------------');
      buffer.writeln(cfg.acknowledgments.trim());
      buffer.writeln();
      buffer.writeln('----------------------------------------------------------------');
      buffer.writeln();
    }

    if (cfg != null && (cfg.authorBio.trim().isNotEmpty || cfg.authorSocials.trim().isNotEmpty)) {
      buffer.writeln('SOBRE EL AUTOR');
      buffer.writeln('----------------------------------------------------------------');
      if (cfg.authorBio.trim().isNotEmpty) {
        buffer.writeln(cfg.authorBio.trim());
        buffer.writeln();
      }
      if (cfg.authorSocials.trim().isNotEmpty) {
        buffer.writeln('Contacto y Redes: ${cfg.authorSocials.trim()}');
        buffer.writeln();
      }
      buffer.writeln('----------------------------------------------------------------');
      buffer.writeln();
    }

    if (cfg != null && cfg.copyrightNotice.trim().isNotEmpty) {
      buffer.writeln(cfg.copyrightNotice.trim());
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generates a beautiful HTML document ready for printing or viewing
  static String exportToHtml(
    BookModel book, {
    List<CharacterModel>? characters,
    List<CodexEntryModel>? codexEntries,
    BookCompilationConfig? compilationConfig,
    bool includeEditorialElements = true,
  }) {
    final cfg = compilationConfig ?? book.compilationConfig;
    final compiledChapters = getCompiledChapters(book, cfg);
    final title = cfg?.cover.title.isNotEmpty == true ? cfg!.cover.title : book.title;
    final subtitle = cfg?.cover.subtitle.isNotEmpty == true ? cfg!.cover.subtitle : book.subtitle;
    final author = cfg?.cover.author.isNotEmpty == true ? cfg!.cover.author : 'InkWright Author';

    String dedicationHtml = '';
    if (includeEditorialElements && cfg != null && cfg.dedication.trim().isNotEmpty) {
      dedicationHtml = '''
    <section class="dedication" style="text-align: center; margin: 40px auto; font-style: italic; max-width: 500px;">
      <blockquote>«${_xmlEscape(cfg.dedication.trim())}»</blockquote>
    </section>
    <hr class="chapter-divider"/>
''';
    }

    String tocHtml = '';
    if (includeEditorialElements && cfg?.includeTableOfContents == true) {
      tocHtml = '''
    <section class="toc" style="margin: 40px 0;">
      <h2>Índice de Contenido</h2>
      <ul style="list-style-type: none; padding-left: 0;">
        ${compiledChapters.map((item) => '<li style="padding: 6px 0; border-bottom: 1px dotted #ccc;"><strong>${_xmlEscape(item.displayHeader)}</strong></li>').join('\n')}
      </ul>
    </section>
    <hr class="chapter-divider"/>
''';
    }

    String charactersHtml = '';
    if (includeEditorialElements && characters != null && characters.isNotEmpty) {
      charactersHtml = '''
    <section class="characters">
      <h2>Dramatis Personae (Personajes)</h2>
      ${characters.map((c) => '''
        <div class="character-card">
          <h3>${c.name} <small style="color: #666; font-size: 14px;">— ${c.role}${c.archetype.isNotEmpty ? ' (${c.archetype})' : ''}</small></h3>
          ${c.quote.isNotEmpty ? '<blockquote>«${c.quote}»</blockquote>' : ''}
          ${c.motivation.isNotEmpty ? '<p><strong>Motivación:</strong> ${c.motivation}</p>' : ''}
          ${c.writtenBiography.isNotEmpty ? _convertMarkdownToEpubHtml(c.writtenBiography) : ''}
        </div>
      ''').join('\n')}
    </section>
    <hr class="chapter-divider"/>
''';
    }

    String codexHtml = '';
    if (includeEditorialElements && codexEntries != null && codexEntries.isNotEmpty) {
      codexHtml = '''
    <section class="codex">
      <h2>Apéndice del Códice</h2>
      ${codexEntries.map((e) => '''
        <div class="codex-card">
          <h3>${e.name} <small style="color: #666; font-size: 14px;">(${e.typeLabel})</small></h3>
          ${e.role.isNotEmpty ? '<blockquote>${e.role}</blockquote>' : ''}
          ${e.description.isNotEmpty ? _convertMarkdownToEpubHtml(e.description) : ''}
        </div>
      ''').join('\n')}
    </section>
    <hr class="chapter-divider"/>
''';
    }

    final sceneSep = cfg?.sceneSeparator.trim().isNotEmpty == true ? cfg!.sceneSeparator.trim() : '* * *';

    final chaptersHtml = compiledChapters.map((item) {
      final ch = item.chapter;
      final formattedContent = _convertMarkdownToEpubHtml(formatChapterText(ch.content, cfg), sceneSeparator: sceneSep);

      return '''
    <section class="chapter">
      <h2>${_xmlEscape(item.displayHeader)}</h2>
      ${(includeEditorialElements && ch.povCharacter.isNotEmpty) ? '<p class="pov"><em>POV: ${ch.povCharacter}</em></p>' : ''}
      <div class="chapter-content">
        $formattedContent
      </div>
    </section>
''';
    }).join('\n<hr class="chapter-divider"/>\n');

    String acknowledgmentsHtml = '';
    if (includeEditorialElements && cfg != null && cfg.acknowledgments.trim().isNotEmpty) {
      acknowledgmentsHtml = '''
    <section class="acknowledgments" style="margin: 40px 0;">
      <h2>Agradecimientos</h2>
      ${_convertMarkdownToEpubHtml(cfg.acknowledgments.trim(), sceneSeparator: sceneSep)}
    </section>
    <hr class="chapter-divider"/>
''';
    }

    String authorBioHtml = '';
    if (includeEditorialElements && cfg != null && (cfg.authorBio.trim().isNotEmpty || cfg.authorSocials.trim().isNotEmpty)) {
      authorBioHtml = '''
    <section class="author-bio" style="margin: 40px 0;">
      <h2>Sobre el Autor</h2>
      ${cfg.authorBio.trim().isNotEmpty ? _convertMarkdownToEpubHtml(cfg.authorBio.trim(), sceneSeparator: sceneSep) : ''}
      ${cfg.authorSocials.trim().isNotEmpty ? '<p class="author-socials" style="margin-top: 16px; font-style: italic; color: #555;"><strong>Contacto y Redes:</strong> ${_xmlEscape(cfg.authorSocials.trim())}</p>' : ''}
    </section>
    <hr class="chapter-divider"/>
''';
    }

    String copyrightHtml = '';
    if (includeEditorialElements && cfg != null && cfg.copyrightNotice.trim().isNotEmpty) {
      copyrightHtml = '''
    <footer style="margin-top: 60px; text-align: center; font-size: 13px; color: #777;">
      <p>${_xmlEscape(cfg.copyrightNotice.trim())}</p>
    </footer>
''';
    }

    final String fontFamilyCss;
    final String paragraphStyleCss;
    switch (cfg?.preset ?? EditorialPreset.classic) {
      case EditorialPreset.modern:
        fontFamilyCss = "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif";
        paragraphStyleCss = 'margin-bottom: 1.2em; text-align: left; text-indent: 0;';
        break;
      case EditorialPreset.manuscriptSubmission:
        fontFamilyCss = "'Courier New', Courier, monospace";
        paragraphStyleCss = 'margin-bottom: 0; line-height: 2.0; text-indent: 2em;';
        break;
      case EditorialPreset.classic:
      default:
        fontFamilyCss = "'Lora', Georgia, serif";
        paragraphStyleCss = 'margin-bottom: 1.4em; text-align: justify; text-indent: 1.5em;';
        break;
    }

    return '''<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>${book.title}</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400;0,600;1,400&family=Plus+Jakarta+Sans:wght@400;700;800&display=swap');
    body {
      max-width: 760px;
      margin: 40px auto;
      padding: 0 24px;
      font-family: $fontFamilyCss;
      color: #1a1a1a;
      background: #faf8f5;
      line-height: 1.8;
      font-size: 17px;
    }
    header {
      text-align: center;
      margin-bottom: 60px;
      border-bottom: 2px solid #1a1a1a;
      padding-bottom: 40px;
    }
    h1 {
      font-family: 'Plus Jakarta Sans', sans-serif;
      font-size: 36px;
      font-weight: 800;
      letter-spacing: -0.5px;
      margin-bottom: 8px;
    }
    .subtitle {
      font-family: 'Plus Jakarta Sans', sans-serif;
      font-size: 18px;
      color: #666;
      font-weight: 500;
      margin-top: 0;
    }
    .meta {
      font-size: 13px;
      color: #888;
      font-family: 'Plus Jakarta Sans', sans-serif;
      margin-top: 20px;
    }
    .synopsis {
      background: #fff;
      border-left: 4px solid #1a1a1a;
      padding: 16px 20px;
      margin: 30px 0;
      border-radius: 4px;
      font-style: italic;
    }
    h2 {
      font-family: 'Plus Jakarta Sans', sans-serif;
      font-size: 24px;
      font-weight: 700;
      margin-top: 40px;
      margin-bottom: 12px;
      border-bottom: 1px solid #e5e5e5;
      padding-bottom: 8px;
    }
    .pov {
      font-size: 14px;
      color: #777;
      margin-bottom: 24px;
    }
    p {
      $paragraphStyleCss
    }
    .scene-break {
      text-align: center;
      margin: 32px 0;
      font-weight: bold;
      letter-spacing: 3px;
      color: #777;
    }
    .chapter-divider {
      border: 0;
      height: 1px;
      background: #ccc;
      margin: 50px 0;
    }
    @media print {
      body { background: white; }
      .chapter { page-break-after: always; }
    }
  </style>
</head>
<body>
  ${includeEditorialElements ? '''<header>
    <h1>${book.title}</h1>
    ${book.subtitle.isNotEmpty ? '<p class="subtitle">${book.subtitle}</p>' : ''}
    <div class="meta">
      <span>Género: ${book.genre}</span> • 
      <span>${book.currentWordCount} palabras</span> • 
      <span>${book.chapters.length} capítulos</span>
    </div>
  </header>''' : ''}

  ${(includeEditorialElements && book.synopsis.isNotEmpty) ? '<div class="synopsis"><strong>Sinopsis:</strong> ${book.synopsis}</div>' : ''}
  $dedicationHtml
  $tocHtml
  $charactersHtml
  $codexHtml
  $chaptersHtml
  $acknowledgmentsHtml
  $authorBioHtml
  $copyrightHtml
</body>
</html>''';
  }

  /// Generates a real native PDF document
  static Future<Uint8List> generatePdf(
    BookModel book, {
    List<CharacterModel>? characters,
    List<CodexEntryModel>? codexEntries,
    BookCompilationConfig? compilationConfig,
    bool includeEditorialElements = true,
  }) async {
    final cfg = compilationConfig ?? book.compilationConfig;
    final compiledChapters = getCompiledChapters(book, cfg);

    final title = cfg?.cover.title.isNotEmpty == true ? cfg!.cover.title : book.title;
    final subtitle = cfg?.cover.subtitle.isNotEmpty == true ? cfg!.cover.subtitle : book.subtitle;
    final author = cfg?.cover.author.isNotEmpty == true ? cfg!.cover.author : 'InkWright Author';

    final pdf = pw.Document(
      title: _sanitizeForPdf(title),
      author: _sanitizeForPdf(author),
    );

    if (includeEditorialElements) {
      // Cover Page
      if (cfg != null) {
      final hexBg = cfg.cover.backgroundColorHex;
      final hexText = cfg.cover.textColorHex;
      final bgColor = PdfColor(
        ((hexBg >> 16) & 0xFF) / 255.0,
        ((hexBg >> 8) & 0xFF) / 255.0,
        (hexBg & 0xFF) / 255.0,
      );
      final textColor = PdfColor(
        ((hexText >> 16) & 0xFF) / 255.0,
        ((hexText >> 8) & 0xFF) / 255.0,
        (hexText & 0xFF) / 255.0,
      );

      pw.MemoryImage? coverImg;
      if (cfg.cover.imagePath != null && cfg.cover.imagePath!.isNotEmpty) {
        try {
          final file = File(cfg.cover.imagePath!);
          if (file.existsSync()) {
            coverImg = pw.MemoryImage(file.readAsBytesSync());
          }
        } catch (_) {}
      }

      pw.MainAxisAlignment alignment;
      switch (cfg.cover.textPosition) {
        case CoverTextPosition.top:
          alignment = pw.MainAxisAlignment.start;
          break;
        case CoverTextPosition.bottom:
          alignment = pw.MainAxisAlignment.end;
          break;
        case CoverTextPosition.center:
        default:
          alignment = pw.MainAxisAlignment.center;
          break;
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Container(
              width: double.infinity,
              height: double.infinity,
              color: bgColor,
              child: pw.Stack(
                children: [
                  if (coverImg != null)
                    pw.Positioned.fill(
                      child: pw.Image(coverImg, fit: pw.BoxFit.cover),
                    ),
                  if (coverImg != null)
                    pw.Positioned.fill(
                      child: pw.Container(
                        color: const PdfColor(0, 0, 0, 0.45),
                      ),
                    ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 56, vertical: 70),
                    child: pw.Column(
                      mainAxisAlignment: alignment,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          _sanitizeForPdf(title),
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        if (subtitle.isNotEmpty) ...[
                          pw.SizedBox(height: 12),
                          pw.Text(
                            _sanitizeForPdf(subtitle),
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontStyle: pw.FontStyle.italic,
                              color: textColor,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                        pw.SizedBox(height: 28),
                        pw.Container(
                          width: 80,
                          height: 2,
                          color: textColor,
                        ),
                        pw.SizedBox(height: 24),
                        pw.Text(
                          _sanitizeForPdf(author),
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 2,
                            color: textColor,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 20),
                        pw.Text(
                          '${book.currentWordCount} palabras • ${compiledChapters.length} capítulos',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: textColor,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      // Classic default cover
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(60),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 72,
                    height: 90,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey800, width: 2),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'IW',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 28),
                  pw.Text(
                    _sanitizeForPdf(book.title),
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  if (book.subtitle.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text(
                      _sanitizeForPdf(book.subtitle),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                  pw.SizedBox(height: 40),
                  pw.Container(
                    width: 120,
                    height: 1,
                    color: PdfColors.grey400,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Género: ${_sanitizeForPdf(book.genre)}',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    '${book.currentWordCount} palabras | ${book.chapters.length} capítulos',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    'Generado con InkWright Sanctuary',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Copyright Page
    if (cfg != null && cfg.copyrightNotice.trim().isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(72),
          build: (pw.Context context) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _sanitizeForPdf(title),
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _sanitizeForPdf(author),
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 14),
                pw.Text(
                  _sanitizeForPdf(cfg.copyrightNotice.trim()),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700, lineSpacing: 2),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Compilado y diagramado con InkWright Sanctuary Editorial',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ],
            );
          },
        ),
      );
    }

    // Dedication Page
    if (cfg != null && cfg.dedication.trim().isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(90),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    _sanitizeForPdf(cfg.dedication.trim()),
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontStyle: pw.FontStyle.italic,
                      lineSpacing: 4,
                      color: PdfColors.grey800,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Table of Contents Page
    if (cfg?.includeTableOfContents == true) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 54, vertical: 60),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Índice de Contenido',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 16),
                ...compiledChapters.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            _sanitizeForPdf(item.displayHeader),
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: item.chapter.chapterType != ChapterType.chapter
                                  ? pw.FontWeight.bold
                                  : pw.FontWeight.normal,
                            ),
                          ),
                        ),
                        pw.Text(
                          '${item.chapter.wordCount} palabras',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      );
    }

    // Optional Dramatis Personae PDF Section
    if (characters != null && characters.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
          header: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 16),
              child: pw.Text(
                '${_sanitizeForPdf(title)} - Dramatis Personae',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.SizedBox(height: 10),
              pw.Text(
                'Dramatis Personae (Personajes)',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 12),
              ...characters.expand((c) => [
                pw.Text(
                  _sanitizeForPdf('${c.name} - ${c.role}${c.archetype.isNotEmpty ? " (${c.archetype})" : ""}'),
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                if (c.quote.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _sanitizeForPdf('"${c.quote}"'),
                    style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                  ),
                ],
                if (c.traits.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _sanitizeForPdf('Rasgos: ${c.traits.join(", ")}'),
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
                if (c.motivation.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _sanitizeForPdf('Motivacion: ${c.motivation}'),
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
                if (c.writtenBiography.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  ..._convertMarkdownToPdfWidgets(c.writtenBiography),
                ],
                pw.SizedBox(height: 14),
              ]),
            ];
          },
        ),
      );
    }

    // Optional Codex Entries PDF Section
    if (codexEntries != null && codexEntries.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
          header: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 16),
              child: pw.Text(
                '${_sanitizeForPdf(title)} - Apendice del Codice',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.SizedBox(height: 10),
              pw.Text(
                'Apendice del Codice',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 12),
              ...codexEntries.expand((e) => [
                pw.Text(
                  _sanitizeForPdf('${e.name} (${e.typeLabel})'),
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                if (e.role.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _sanitizeForPdf(e.role),
                    style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                  ),
                ],
                if (e.description.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  ..._convertMarkdownToPdfWidgets(e.description),
                ],
                pw.SizedBox(height: 14),
              ]),
            ];
          },
        ),
      );
    }
    }

    // Chapters
    for (final item in compiledChapters) {
      final chapter = item.chapter;
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
          header: (pw.Context context) {
            if (context.pageNumber == 1) return pw.SizedBox.shrink();
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 16),
              child: pw.Text(
                '${_sanitizeForPdf(title)} - ${_sanitizeForPdf(item.displayHeader)}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(top: 16),
              child: pw.Text(
                'Pagina ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.SizedBox(height: 20),
              pw.Text(
                _sanitizeForPdf(item.displayHeader),
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (includeEditorialElements && chapter.povCharacter.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  'Punto de vista (POV): ${_sanitizeForPdf(chapter.povCharacter)}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
              pw.SizedBox(height: 14),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 14),
              ..._convertMarkdownToPdfWidgets(
                chapter.content,
                sceneSeparator: cfg?.sceneSeparator ?? '* * *',
                preset: cfg?.preset ?? EditorialPreset.classic,
              ),
            ];
          },
        ),
      );
    }

    if (includeEditorialElements && cfg != null && cfg.acknowledgments.trim().isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
          header: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 16),
              child: pw.Text(
                '${_sanitizeForPdf(title)} - Agradecimientos',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.SizedBox(height: 20),
              pw.Text(
                'Agradecimientos',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 14),
              ..._convertMarkdownToPdfWidgets(
                cfg.acknowledgments.trim(),
                sceneSeparator: cfg.sceneSeparator,
                preset: cfg.preset,
              ),
            ];
          },
        ),
      );
    }

    if (includeEditorialElements && cfg != null && (cfg.authorBio.trim().isNotEmpty || cfg.authorSocials.trim().isNotEmpty)) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
          header: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 16),
              child: pw.Text(
                '${_sanitizeForPdf(title)} - Sobre el Autor',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.SizedBox(height: 20),
              pw.Text(
                'Sobre el Autor',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 14),
              if (cfg.authorBio.trim().isNotEmpty)
                ..._convertMarkdownToPdfWidgets(
                  cfg.authorBio.trim(),
                  sceneSeparator: cfg.sceneSeparator,
                  preset: cfg.preset,
                ),
              if (cfg.authorSocials.trim().isNotEmpty) ...[
                pw.SizedBox(height: 18),
                pw.Text(
                  _sanitizeForPdf('Contacto y Redes: ${cfg.authorSocials.trim()}'),
                  style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                ),
              ],
            ];
          },
        ),
      );
    }

    return pdf.save();
  }

  static String _sanitizeForPdf(String text) {
    final clean = text
        .replaceAll('…', '...')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('«', '"')
        .replaceAll('»', '"')
        .replaceAll('•', '*')
        .replaceAll('\t', '    ');

    final buffer = StringBuffer();
    for (final rune in clean.runes) {
      if (rune <= 255) {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Converts Markdown text into native PDF widgets (headings, blockquotes, lists, dialogue, paragraphs)
  static List<pw.Widget> _convertMarkdownToPdfWidgets(
    String content, {
    String sceneSeparator = '* * *',
    EditorialPreset preset = EditorialPreset.classic,
  }) {
    if (content.trim().isEmpty) return [];

    final lines = content.split(RegExp(r'\r?\n'));
    final List<pw.Widget> widgets = [];
    final List<String> currentParagraphLines = [];

    final double baseFontSize;
    final double baseLineSpacing;
    final pw.TextAlign paragraphAlign;

    switch (preset) {
      case EditorialPreset.manuscriptSubmission:
        baseFontSize = 11.5;
        baseLineSpacing = 5.5;
        paragraphAlign = pw.TextAlign.left;
        break;
      case EditorialPreset.modern:
        baseFontSize = 10.5;
        baseLineSpacing = 2.5;
        paragraphAlign = pw.TextAlign.left;
        break;
      case EditorialPreset.classic:
      default:
        baseFontSize = 11.0;
        baseLineSpacing = 3.2;
        paragraphAlign = pw.TextAlign.justify;
        break;
    }

    void flushParagraph() {
      if (currentParagraphLines.isEmpty) return;
      final fullText = currentParagraphLines.join(' ').trim();
      currentParagraphLines.clear();
      if (fullText.isEmpty) return;

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.RichText(
            textAlign: paragraphAlign,
            text: pw.TextSpan(
              children: _parseInlineToPdfSpans(
                fullText,
                baseStyle: pw.TextStyle(
                  fontSize: baseFontSize,
                  lineSpacing: baseLineSpacing,
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        flushParagraph();
        continue;
      }

      // 1. Headings (#, ##, ###, ####)
      if (trimmed.startsWith('# ') ||
          trimmed.startsWith('## ') ||
          trimmed.startsWith('### ') ||
          trimmed.startsWith('#### ')) {
        flushParagraph();
        int level = 1;
        if (trimmed.startsWith('#### ')) {
          level = 4;
        } else if (trimmed.startsWith('### ')) {
          level = 3;
        } else if (trimmed.startsWith('## ')) {
          level = 2;
        }

        final titleText = trimmed.substring(level + 1).trim();
        final fontSize = level == 1 ? 16.0 : (level == 2 ? 14.0 : (level == 3 ? 12.5 : 11.5));
        final topPad = level == 1 ? 14.0 : (level == 2 ? 11.0 : 8.0);

        widgets.add(
          pw.Padding(
            padding: pw.EdgeInsets.only(top: topPad, bottom: 5),
            child: pw.RichText(
              text: pw.TextSpan(
                children: _parseInlineToPdfSpans(
                  titleText,
                  baseStyle: pw.TextStyle(
                    fontSize: fontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: level <= 2 ? PdfColors.grey900 : PdfColors.grey800,
                  ),
                ),
              ),
            ),
          ),
        );
        continue;
      }

      // 2. Scene separators (***, ---, ___, or custom)
      if (trimmed == '***' || trimmed == '---' || trimmed == '___' || trimmed == sceneSeparator.trim()) {
        flushParagraph();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 12),
            child: pw.Center(
              child: pw.Text(
                _sanitizeForPdf(sceneSeparator.isNotEmpty ? sceneSeparator : '*  *  *'),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey500,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
        );
        continue;
      }

      // 3. Blockquotes (> quote)
      if (trimmed.startsWith('> ') || trimmed == '>') {
        flushParagraph();
        final quoteText = trimmed == '>' ? '' : trimmed.substring(2).trim();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, top: 3, bottom: 6),
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: PdfColors.grey400, width: 2.5)),
              ),
              padding: const pw.EdgeInsets.only(left: 8, top: 2, bottom: 2),
              child: pw.RichText(
                text: pw.TextSpan(
                  children: _parseInlineToPdfSpans(
                    quoteText,
                    baseStyle: const pw.TextStyle(
                      fontSize: 10.5,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700,
                      lineSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        continue;
      }

      // 4. Checklist items (- [ ] or - [x])
      if (trimmed.startsWith('- [ ] ') || trimmed.startsWith('- [x] ') || trimmed.startsWith('- [X] ')) {
        flushParagraph();
        final isChecked = trimmed.startsWith('- [x] ') || trimmed.startsWith('- [X] ');
        final itemText = trimmed.substring(6).trim();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isChecked ? '[x] ' : '[ ] ',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Expanded(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: _parseInlineToPdfSpans(
                        itemText,
                        baseStyle: pw.TextStyle(
                          fontSize: 11,
                          lineSpacing: 2,
                          color: isChecked ? PdfColors.grey600 : PdfColors.black,
                          decoration: isChecked ? pw.TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 5. Bullet lists (- item, * item, + item)
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ') || trimmed.startsWith('+ ')) {
        flushParagraph();
        final itemText = trimmed.substring(2).trim();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '- ',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Expanded(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: _parseInlineToPdfSpans(
                        itemText,
                        baseStyle: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 6. Numbered lists (1. item, 2. item)
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        flushParagraph();
        final numPrefix = numMatch.group(1)!;
        final itemText = numMatch.group(2)!.trim();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '$numPrefix. ',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.Expanded(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: _parseInlineToPdfSpans(
                        itemText,
                        baseStyle: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 7. Spanish narrative dialogue turns (em-dash lines get individual paragraph spacing)
      if (trimmed.startsWith('—') || trimmed.startsWith('--')) {
        flushParagraph();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                children: _parseInlineToPdfSpans(
                  trimmed,
                  baseStyle: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
                ),
              ),
            ),
          ),
        );
        continue;
      }

      // 8. Normal prose lines (accumulate into current paragraph)
      currentParagraphLines.add(trimmed);
    }

    flushParagraph();
    return widgets;
  }

  /// Parses inline Markdown tokens (bold, italic, strike, code, highlight) into native PDF TextSpans
  static List<pw.TextSpan> _parseInlineToPdfSpans(
    String rawText, {
    required pw.TextStyle baseStyle,
  }) {
    final text = _sanitizeForPdf(rawText);
    if (text.isEmpty) return [];

    final matches = _docInlineRegex.allMatches(text);
    if (matches.isEmpty) {
      return [pw.TextSpan(text: text, style: baseStyle)];
    }

    final List<pw.TextSpan> spans = [];
    int lastIndex = 0;

    for (final m in matches) {
      if (m.start > lastIndex) {
        final pre = text.substring(lastIndex, m.start);
        spans.add(pw.TextSpan(text: pre, style: baseStyle));
      }

      final matched = m.group(0)!;
      if (matched.startsWith('***') && matched.endsWith('***')) {
        final inner = matched.substring(3, matched.length - 3);
        spans.add(pw.TextSpan(
          text: inner,
          style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic),
        ));
      } else if (matched.startsWith('___') && matched.endsWith('___')) {
        final inner = matched.substring(3, matched.length - 3);
        spans.add(pw.TextSpan(
          text: inner,
          style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic),
        ));
      } else if (matched.startsWith('**') && matched.endsWith('**')) {
        final inner = matched.substring(2, matched.length - 2);
        spans.add(pw.TextSpan(
          text: inner,
          style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold),
        ));
      } else if (matched.startsWith('__') && matched.endsWith('__')) {
        final inner = matched.substring(2, matched.length - 2);
        spans.add(pw.TextSpan(
          text: inner,
          style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold),
        ));
      } else if (matched.startsWith('*') && matched.endsWith('*')) {
        final inner = matched.substring(1, matched.length - 1);
        spans.add(pw.TextSpan(
          text: inner,
          style: baseStyle.copyWith(fontStyle: pw.FontStyle.italic),
        ));
      } else if (matched.startsWith('_') && matched.endsWith('_')) {
        final inner = matched.substring(1, matched.length - 1);
        spans.add(pw.TextSpan(
          text: inner,
          style: baseStyle.copyWith(fontStyle: pw.FontStyle.italic),
        ));
      } else if (matched.startsWith('~~') && matched.endsWith('~~')) {
        final inner = matched.substring(2, matched.length - 2);
        spans.add(pw.TextSpan(
          text: inner,
          style: baseStyle.copyWith(decoration: pw.TextDecoration.lineThrough),
        ));
      } else if (matched.startsWith('`') && matched.endsWith('`')) {
        final inner = matched.substring(1, matched.length - 1);
        spans.add(pw.TextSpan(
          text: inner,
          style: baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? 11) * 0.9,
            color: PdfColors.blueGrey800,
          ),
        ));
      } else if (matched.startsWith('==') && matched.endsWith('==')) {
        final inner = matched.substring(2, matched.length - 2);
        spans.add(pw.TextSpan(
          text: inner,
          style: baseStyle.copyWith(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.amber900,
          ),
        ));
      } else {
        spans.add(pw.TextSpan(text: matched, style: baseStyle));
      }

      lastIndex = m.end;
    }

    if (lastIndex < text.length) {
      final post = text.substring(lastIndex);
      spans.add(pw.TextSpan(text: post, style: baseStyle));
    }

    return spans;
  }

  /// Generates a genuine Microsoft Word (.docx) Open XML archive
  static List<int> generateDocx(
    BookModel book, {
    List<CharacterModel>? characters,
    List<CodexEntryModel>? codexEntries,
    BookCompilationConfig? compilationConfig,
    bool includeEditorialElements = true,
  }) {
    final cfg = compilationConfig ?? book.compilationConfig;
    final compiledChapters = getCompiledChapters(book, cfg);
    final title = cfg?.cover.title.isNotEmpty == true ? cfg!.cover.title : book.title;
    final subtitle = cfg?.cover.subtitle.isNotEmpty == true ? cfg!.cover.subtitle : book.subtitle;
    final author = cfg?.cover.author.isNotEmpty == true ? cfg!.cover.author : 'InkWright Author';

    final archive = Archive();

    // 1. [Content_Types].xml
    const contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypes.length, utf8.encode(contentTypes)));

    // 2. _rels/.rels
    const rootRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('_rels/.rels', rootRels.length, utf8.encode(rootRels)));

    // 3. word/_rels/document.xml.rels
    const docRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('word/_rels/document.xml.rels', docRels.length, utf8.encode(docRels)));

    // 4. word/styles.xml
    const stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Georgia" w:hAnsi="Georgia" w:cs="Georgia"/>
        <w:sz w:val="24"/>
        <w:szCs w:val="24"/>
        <w:lang w:val="es-ES"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:line="360" w:lineRule="auto" w:after="160"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>
</w:styles>''';
    archive.addFile(ArchiveFile('word/styles.xml', stylesXml.length, utf8.encode(stylesXml)));

    // 5. word/document.xml
    final docBuffer = StringBuffer();
    docBuffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    docBuffer.writeln('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">');
    docBuffer.writeln('<w:body>');

    if (includeEditorialElements) {
      // Book Title
      docBuffer.writeln('<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:before="2400" w:after="200"/></w:pPr>');
      docBuffer.writeln('<w:r><w:rPr><w:b/><w:sz w:val="56"/><w:szCs w:val="56"/></w:rPr>');
      docBuffer.writeln('<w:t>${_xmlEscape(title)}</w:t></w:r></w:p>');

    // Subtitle
    if (subtitle.isNotEmpty) {
      docBuffer.writeln('<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:after="300"/></w:pPr>');
      docBuffer.writeln('<w:r><w:rPr><w:i/><w:sz w:val="32"/><w:szCs w:val="32"/><w:color w:val="555555"/></w:rPr>');
      docBuffer.writeln('<w:t>${_xmlEscape(subtitle)}</w:t></w:r></w:p>');
    }

    // Author
    docBuffer.writeln('<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:after="300"/></w:pPr>');
    docBuffer.writeln('<w:r><w:rPr><w:b/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr>');
    docBuffer.writeln('<w:t>${_xmlEscape("Por: $author")}</w:t></w:r></w:p>');

    // Metadata
    docBuffer.writeln('<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:after="200"/></w:pPr>');
    docBuffer.writeln('<w:r><w:rPr><w:sz w:val="20"/><w:szCs w:val="20"/><w:color w:val="777777"/></w:rPr>');
    docBuffer.writeln('<w:t>${_xmlEscape("Género: ${book.genre}  •  ${book.currentWordCount} palabras  •  ${compiledChapters.length} capítulos")}</w:t></w:r></w:p>');

    // Synopsis
    if (book.synopsis.isNotEmpty) {
      docBuffer.writeln('<w:p><w:pPr><w:spacing w:before="400" w:after="400"/></w:pPr>');
      docBuffer.writeln('<w:r><w:rPr><w:i/></w:rPr><w:t>${_xmlEscape("Sinopsis: ${book.synopsis}")}</w:t></w:r></w:p>');
    }

    // Dedication in Word
    if (cfg != null && cfg.dedication.trim().isNotEmpty) {
      docBuffer.writeln('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      docBuffer.writeln('<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:before="3600" w:after="400"/></w:pPr>');
      docBuffer.writeln('<w:r><w:rPr><w:i/><w:sz w:val="26"/><w:szCs w:val="26"/></w:rPr>');
      docBuffer.writeln('<w:t>${_xmlEscape("«${cfg.dedication.trim()}»")}</w:t></w:r></w:p>');
    }

    // Copyright in Word
    if (cfg != null && cfg.copyrightNotice.trim().isNotEmpty) {
      docBuffer.writeln('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      docBuffer.writeln('<w:p><w:pPr><w:jc w:val="left"/><w:spacing w:before="6000" w:after="200"/></w:pPr>');
      docBuffer.writeln('<w:r><w:rPr><w:sz w:val="18"/><w:szCs w:val="18"/><w:color w:val="777777"/></w:rPr>');
      docBuffer.writeln('<w:t>${_xmlEscape(cfg.copyrightNotice.trim())}</w:t></w:r></w:p>');
    }

    // Table of contents in Word
    if (cfg?.includeTableOfContents == true) {
      docBuffer.writeln('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      docBuffer.writeln('<w:p><w:pPr><w:spacing w:before="400" w:after="240"/></w:pPr>');
      docBuffer.writeln('<w:r><w:rPr><w:b/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr>');
      docBuffer.writeln('<w:t>${_xmlEscape("Índice de Contenido")}</w:t></w:r></w:p>');
      for (final item in compiledChapters) {
        docBuffer.writeln('<w:p><w:pPr><w:spacing w:after="120"/></w:pPr>');
        docBuffer.writeln('<w:r><w:rPr><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr>');
        docBuffer.writeln('<w:t>${_xmlEscape(item.displayHeader)}</w:t></w:r></w:p>');
      }
    }

    // Optional Characters Section (Word)
    if (characters != null && characters.isNotEmpty) {
      docBuffer.writeln('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      docBuffer.writeln('<w:p><w:pPr><w:spacing w:before="400" w:after="200"/></w:pPr>');
      docBuffer.writeln('<w:r><w:rPr><w:b/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr>');
      docBuffer.writeln('<w:t>${_xmlEscape("Dramatis Personae (Personajes)")}</w:t></w:r></w:p>');

      for (final char in characters) {
        docBuffer.writeln('<w:p><w:pPr><w:spacing w:before="240" w:after="80"/></w:pPr>');
        docBuffer.writeln('<w:r><w:rPr><w:b/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr>');
        docBuffer.writeln('<w:t>${_xmlEscape("${char.name} — ${char.role}${char.archetype.isNotEmpty ? ' (${char.archetype})' : ''}")}</w:t></w:r></w:p>');

        if (char.quote.isNotEmpty) {
          docBuffer.writeln('<w:p><w:pPr><w:spacing w:after="80"/></w:pPr>');
          docBuffer.writeln('<w:r><w:rPr><w:i/><w:color w:val="555555"/></w:rPr>');
          docBuffer.writeln('<w:t>${_xmlEscape("«${char.quote}»")}</w:t></w:r></w:p>');
        }

        if (char.motivation.isNotEmpty) {
          docBuffer.writeln('<w:p><w:pPr><w:spacing w:after="80"/></w:pPr>');
          docBuffer.writeln('<w:r><w:rPr><w:b/></w:rPr><w:t>${_xmlEscape("Motivación: ")}</w:t></w:r>');
          docBuffer.writeln('<w:r><w:t>${_xmlEscape(char.motivation)}</w:t></w:r></w:p>');
        }

        if (char.writtenBiography.isNotEmpty) {
          docBuffer.writeln('<w:p><w:pPr><w:spacing w:after="160"/><w:ind w:firstLine="400"/></w:pPr>');
          docBuffer.writeln('<w:r><w:t>${_xmlEscape(char.writtenBiography)}</w:t></w:r></w:p>');
        }
      }
    }

    // Optional Codex Section (Word)
    if (codexEntries != null && codexEntries.isNotEmpty) {
      docBuffer.writeln('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      docBuffer.writeln('<w:p><w:pPr><w:spacing w:before="400" w:after="200"/></w:pPr>');
      docBuffer.writeln('<w:r><w:rPr><w:b/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr>');
      docBuffer.writeln('<w:t>${_xmlEscape("Apéndice del Códice")}</w:t></w:r></w:p>');

      for (final entry in codexEntries) {
        docBuffer.writeln('<w:p><w:pPr><w:spacing w:before="240" w:after="80"/></w:pPr>');
        docBuffer.writeln('<w:r><w:rPr><w:b/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr>');
        docBuffer.writeln('<w:t>${_xmlEscape("${entry.name} (${entry.typeLabel})")}</w:t></w:r></w:p>');

        if (entry.role.isNotEmpty) {
          docBuffer.writeln('<w:p><w:pPr><w:spacing w:after="80"/></w:pPr>');
          docBuffer.writeln('<w:r><w:rPr><w:i/><w:color w:val="555555"/></w:rPr>');
          docBuffer.writeln('<w:t>${_xmlEscape(entry.role)}</w:t></w:r></w:p>');
        }

        if (entry.description.isNotEmpty) {
          docBuffer.writeln('<w:p><w:pPr><w:spacing w:after="160"/><w:ind w:firstLine="400"/></w:pPr>');
          docBuffer.writeln('<w:r><w:t>${_xmlEscape(entry.description)}</w:t></w:r></w:p>');
        }
      }
    }
    }

    // Chapters
    for (int i = 0; i < compiledChapters.length; i++) {
      final item = compiledChapters[i];
      final ch = item.chapter;
      // Page break before chapter
      if (includeEditorialElements || i > 0) {
        docBuffer.writeln('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      }

      // Chapter Title
      docBuffer.writeln('<w:p><w:pPr><w:spacing w:before="400" w:after="160"/></w:pPr>');
      docBuffer.writeln('<w:r><w:rPr><w:b/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr>');
      docBuffer.writeln('<w:t>${_xmlEscape(item.displayHeader)}</w:t></w:r></w:p>');

      if (includeEditorialElements && ch.povCharacter.isNotEmpty) {
        docBuffer.writeln('<w:p><w:pPr><w:spacing w:after="240"/></w:pPr>');
        docBuffer.writeln('<w:r><w:rPr><w:i/><w:sz w:val="20"/><w:szCs w:val="20"/><w:color w:val="666666"/></w:rPr>');
        docBuffer.writeln('<w:t>${_xmlEscape("POV: ${ch.povCharacter}")}</w:t></w:r></w:p>');
      }

      // Paragraphs
      final paragraphs = formatChapterText(ch.content, cfg).split('\n\n').map((p) => p.trim()).where((p) => p.isNotEmpty);
      for (final p in paragraphs) {
        if (p == '***' || p == '---' || p == '___' || p == '* * *' || p == cfg?.sceneSeparator.trim()) {
          docBuffer.writeln('<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:before="240" w:after="240"/></w:pPr>');
          docBuffer.writeln('<w:r><w:rPr><w:b/><w:sz w:val="24"/><w:szCs w:val="24"/><w:color w:val="777777"/></w:rPr>');
          docBuffer.writeln('<w:t xml:space="preserve">${_xmlEscape(cfg?.sceneSeparator.trim().isNotEmpty == true ? cfg!.sceneSeparator.trim() : "*  *  *")}</w:t></w:r></w:p>');
        } else {
          docBuffer.writeln('<w:p><w:pPr><w:ind w:firstLine="400"/></w:pPr>');
          docBuffer.writeln('<w:r><w:t xml:space="preserve">${_xmlEscape(p)}</w:t></w:r></w:p>');
        }
      }
    }

    if (includeEditorialElements && cfg != null && cfg.acknowledgments.trim().isNotEmpty) {
      docBuffer.writeln('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      docBuffer.writeln('<w:p><w:pPr><w:spacing w:before="400" w:after="200"/></w:pPr>');
      docBuffer.writeln('<w:r><w:rPr><w:b/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr>');
      docBuffer.writeln('<w:t>${_xmlEscape("Agradecimientos")}</w:t></w:r></w:p>');
      final ackParagraphs = cfg.acknowledgments.trim().split('\n\n').map((p) => p.trim()).where((p) => p.isNotEmpty);
      for (final p in ackParagraphs) {
        docBuffer.writeln('<w:p><w:pPr><w:ind w:firstLine="400"/></w:pPr>');
        docBuffer.writeln('<w:r><w:t xml:space="preserve">${_xmlEscape(p)}</w:t></w:r></w:p>');
      }
    }

    if (includeEditorialElements && cfg != null && (cfg.authorBio.trim().isNotEmpty || cfg.authorSocials.trim().isNotEmpty)) {
      docBuffer.writeln('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      docBuffer.writeln('<w:p><w:pPr><w:spacing w:before="400" w:after="200"/></w:pPr>');
      docBuffer.writeln('<w:r><w:rPr><w:b/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr>');
      docBuffer.writeln('<w:t>${_xmlEscape("Sobre el Autor")}</w:t></w:r></w:p>');
      if (cfg.authorBio.trim().isNotEmpty) {
        final bioParagraphs = cfg.authorBio.trim().split('\n\n').map((p) => p.trim()).where((p) => p.isNotEmpty);
        for (final p in bioParagraphs) {
          docBuffer.writeln('<w:p><w:pPr><w:ind w:firstLine="400"/></w:pPr>');
          docBuffer.writeln('<w:r><w:t xml:space="preserve">${_xmlEscape(p)}</w:t></w:r></w:p>');
        }
      }
      if (cfg.authorSocials.trim().isNotEmpty) {
        docBuffer.writeln('<w:p><w:pPr><w:spacing w:before="240" w:after="160"/></w:pPr>');
        docBuffer.writeln('<w:r><w:rPr><w:i/><w:color w:val="555555"/></w:rPr>');
        docBuffer.writeln('<w:t xml:space="preserve">${_xmlEscape("Contacto y Redes: ${cfg.authorSocials.trim()}")}</w:t></w:r></w:p>');
      }
    }

    // Section properties (A4, 1 inch margins)
    docBuffer.writeln('<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/></w:sectPr>');
    docBuffer.writeln('</w:body>');
    docBuffer.writeln('</w:document>');

    final docXml = docBuffer.toString();
    archive.addFile(ArchiveFile('word/document.xml', docXml.length, utf8.encode(docXml)));

    return ZipEncoder().encode(archive);
  }

  /// Generates a standard, valid EPUB 3 / EPUB 2 ebook file (Open Container Format)
  static List<int> generateEpub(
    BookModel book, {
    List<CharacterModel>? characters,
    List<CodexEntryModel>? codexEntries,
    BookCompilationConfig? compilationConfig,
    bool includeEditorialElements = true,
  }) {
    final cfg = compilationConfig ?? book.compilationConfig;
    final compiledChapters = getCompiledChapters(book, cfg);
    final title = cfg?.cover.title.isNotEmpty == true ? cfg!.cover.title : book.title;
    final subtitle = cfg?.cover.subtitle.isNotEmpty == true ? cfg!.cover.subtitle : book.subtitle;
    final author = cfg?.cover.author.isNotEmpty == true ? cfg!.cover.author : 'InkWright Author';

    final bool hasCover = includeEditorialElements;
    Uint8List? coverImgBytes;
    String? coverImgExt;
    String? coverImgMime;
    if (hasCover && cfg?.cover.imagePath != null && cfg!.cover.imagePath!.isNotEmpty) {
      try {
        final f = File(cfg.cover.imagePath!);
        if (f.existsSync()) {
          coverImgBytes = f.readAsBytesSync();
          final pathLower = f.path.toLowerCase();
          if (pathLower.endsWith('.png')) {
            coverImgExt = 'png';
            coverImgMime = 'image/png';
          } else if (pathLower.endsWith('.webp')) {
            coverImgExt = 'webp';
            coverImgMime = 'image/webp';
          } else {
            coverImgExt = 'jpg';
            coverImgMime = 'image/jpeg';
          }
        }
      } catch (_) {}
    }
    final bool hasCoverImage = coverImgBytes != null && coverImgBytes.isNotEmpty;
    final bool hasDedication = includeEditorialElements && cfg != null && cfg.dedication.trim().isNotEmpty;
    final bool hasCopyright = includeEditorialElements && cfg != null && cfg.copyrightNotice.trim().isNotEmpty;
    final bool hasChars = includeEditorialElements && characters != null && characters.isNotEmpty;
    final bool hasCodex = includeEditorialElements && codexEntries != null && codexEntries.isNotEmpty;
    final bool hasAcknowledgments = includeEditorialElements && cfg != null && cfg.acknowledgments.trim().isNotEmpty;
    final bool hasAuthorBio = includeEditorialElements && cfg != null && (cfg.authorBio.trim().isNotEmpty || cfg.authorSocials.trim().isNotEmpty);

    final archive = Archive();

    if (hasCoverImage) {
      archive.addFile(ArchiveFile('OEBPS/images/cover.$coverImgExt', coverImgBytes!.length, coverImgBytes));
    }

    // 1. mimetype (MUST be first and uncompressed)
    const mimetypeContent = 'application/epub+zip';
    final mimeFile = ArchiveFile('mimetype', mimetypeContent.length, utf8.encode(mimetypeContent));
    mimeFile.compression = CompressionType.none;
    archive.addFile(mimeFile);

    // 2. META-INF/container.xml
    const containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
    archive.addFile(ArchiveFile('META-INF/container.xml', containerXml.length, utf8.encode(containerXml)));

    // 3. OEBPS/style.css
    final String epubFontFamily;
    final String epubPStyle;
    switch (cfg?.preset ?? EditorialPreset.classic) {
      case EditorialPreset.modern:
        epubFontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif';
        epubPStyle = 'text-indent: 0;\n  margin-top: 0;\n  margin-bottom: 1em;\n  text-align: left;';
        break;
      case EditorialPreset.manuscriptSubmission:
        epubFontFamily = '"Courier New", Courier, monospace';
        epubPStyle = 'text-indent: 2em;\n  line-height: 2.0;\n  margin-top: 0;\n  margin-bottom: 0;\n  text-align: justify;';
        break;
      case EditorialPreset.classic:
      default:
        epubFontFamily = 'Georgia, "Times New Roman", serif';
        epubPStyle = 'text-indent: 1.5em;\n  margin-top: 0;\n  margin-bottom: 0.5em;\n  text-align: justify;';
        break;
    }

    final cssContent = '''
@namespace "http://www.w3.org/1999/xhtml";
body {
  font-family: $epubFontFamily;
  line-height: 1.6;
  margin: 5%;
  color: #1a1a1a;
  background-color: #faf8f5;
}
h1, h2, h3 {
  font-family: sans-serif;
  text-align: center;
  font-weight: bold;
}
h1 {
  font-size: 2em;
  margin-top: 1.8em;
  margin-bottom: 0.5em;
}
h2 {
  font-size: 1.4em;
  margin-top: 1.4em;
  margin-bottom: 0.4em;
}
p {
  $epubPStyle
}
.noindent {
  text-indent: 0;
}
.subtitle {
  text-align: center;
  font-style: italic;
  color: #555;
  font-size: 1.1em;
}
.meta {
  text-align: center;
  font-size: 0.9em;
  color: #777;
  margin-top: 2em;
}
.pov {
  text-align: center;
  font-style: italic;
  font-size: 0.9em;
  color: #666;
  margin-bottom: 1.5em;
}
.card {
  border-bottom: 1px solid #ddd;
  padding-bottom: 1em;
  margin-bottom: 1em;
}
blockquote {
  font-style: italic;
  margin: 1em 1.5em;
  padding-left: 1em;
  border-left: 3px solid #ccc;
  color: #444;
}
.scene-break {
  text-align: center;
  margin: 1.5em 0;
  letter-spacing: 0.3em;
  font-weight: bold;
  color: #777;
}
ul, ol {
  margin: 0.5em 0 1em 2em;
  padding: 0;
}
li {
  margin-bottom: 0.3em;
  text-indent: 0;
}
code {
  font-family: monospace;
  font-size: 0.9em;
  background-color: #eee;
  padding: 1px 4px;
}
mark {
  background-color: #ffe066;
  padding: 1px 3px;
}
''';
    archive.addFile(ArchiveFile('OEBPS/style.css', cssContent.length, utf8.encode(cssContent)));

    // 4. OEBPS/titlepage.xhtml
    if (hasCover) {
      final titlePageBuffer = StringBuffer();
      titlePageBuffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
      titlePageBuffer.writeln('<!DOCTYPE html>');
      titlePageBuffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="es">');
      titlePageBuffer.writeln('<head><title>${_xmlEscape(title)}</title><link rel="stylesheet" type="text/css" href="style.css"/></head>');
      titlePageBuffer.writeln('<body>');
      titlePageBuffer.writeln('<div style="text-align:center; padding-top: 10%;">');
      if (hasCoverImage) {
        titlePageBuffer.writeln('<div style="margin-bottom: 2em;">');
        titlePageBuffer.writeln('<img src="images/cover.$coverImgExt" alt="${_xmlEscape(title)}" style="max-width: 85%; max-height: 60vh; height: auto; border-radius: 6px; box-shadow: 0 4px 14px rgba(0,0,0,0.25);" />');
        titlePageBuffer.writeln('</div>');
      }
      titlePageBuffer.writeln('<h1>${_xmlEscape(title)}</h1>');
      if (subtitle.isNotEmpty) {
        titlePageBuffer.writeln('<p class="subtitle">${_xmlEscape(subtitle)}</p>');
      }
      titlePageBuffer.writeln('<p style="font-weight: bold; margin-top: 1.2em;">Por: ${_xmlEscape(author)}</p>');
      titlePageBuffer.writeln('<div style="margin: 2em auto; width: 60px; height: 1px; background-color: #999;"></div>');
      titlePageBuffer.writeln('<p class="meta">Género: ${_xmlEscape(book.genre)}</p>');
      titlePageBuffer.writeln('<p class="meta">${book.currentWordCount} palabras • ${compiledChapters.length} capítulos</p>');
      if (book.synopsis.isNotEmpty) {
        titlePageBuffer.writeln('<div style="margin: 2em 10%; font-style: italic; text-align: justify;"><p class="noindent"><strong>Sinopsis:</strong> ${_xmlEscape(book.synopsis)}</p></div>');
      }
      titlePageBuffer.writeln('<p class="meta" style="margin-top: 3em; font-size: 0.8em;">Compilado con Ink &amp; Wright Sanctuary</p>');
      titlePageBuffer.writeln('</div>');
      titlePageBuffer.writeln('</body></html>');
      final titlePageXml = titlePageBuffer.toString();
      archive.addFile(ArchiveFile('OEBPS/titlepage.xhtml', titlePageXml.length, utf8.encode(titlePageXml)));
    }

    // Optional Dedication (OEBPS/dedication.xhtml)
    if (hasDedication) {
      final dedBuffer = StringBuffer();
      dedBuffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
      dedBuffer.writeln('<!DOCTYPE html>');
      dedBuffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" lang="es">');
      dedBuffer.writeln('<head><title>Dedicatoria</title><link rel="stylesheet" type="text/css" href="style.css"/></head>');
      dedBuffer.writeln('<body>');
      dedBuffer.writeln('<div style="text-align:center; padding-top: 25%; font-style: italic; margin: 0 10%;">');
      dedBuffer.writeln('<p class="noindent">«${_xmlEscape(cfg.dedication.trim())}»</p>');
      dedBuffer.writeln('</div>');
      dedBuffer.writeln('</body></html>');
      final dedXml = dedBuffer.toString();
      archive.addFile(ArchiveFile('OEBPS/dedication.xhtml', dedXml.length, utf8.encode(dedXml)));
    }

    // Optional Copyright (OEBPS/copyright.xhtml)
    if (hasCopyright) {
      final crBuffer = StringBuffer();
      crBuffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
      crBuffer.writeln('<!DOCTYPE html>');
      crBuffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" lang="es">');
      crBuffer.writeln('<head><title>Créditos</title><link rel="stylesheet" type="text/css" href="style.css"/></head>');
      crBuffer.writeln('<body>');
      crBuffer.writeln('<div style="padding-top: 40%; font-size: 0.85em; color: #555; text-align: center;">');
      crBuffer.writeln('<p class="noindent">${_xmlEscape(title)}</p>');
      crBuffer.writeln('<p class="noindent">${_xmlEscape(author)}</p>');
      crBuffer.writeln('<p class="noindent" style="margin-top: 2em;">${_xmlEscape(cfg.copyrightNotice.trim())}</p>');
      crBuffer.writeln('</div>');
      crBuffer.writeln('</body></html>');
      final crXml = crBuffer.toString();
      archive.addFile(ArchiveFile('OEBPS/copyright.xhtml', crXml.length, utf8.encode(crXml)));
    }

    // Optional Dramatis Personae (OEBPS/characters.xhtml)
    if (hasChars) {
      final charsBuffer = StringBuffer();
      charsBuffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
      charsBuffer.writeln('<!DOCTYPE html>');
      charsBuffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" lang="es">');
      charsBuffer.writeln('<head><title>Dramatis Personae</title><link rel="stylesheet" type="text/css" href="style.css"/></head>');
      charsBuffer.writeln('<body>');
      charsBuffer.writeln('<h2>Dramatis Personae (Personajes)</h2>');
      for (final c in characters) {
        charsBuffer.writeln('<div class="card">');
        charsBuffer.writeln('<h3>${_xmlEscape(c.name)} <small>— ${_xmlEscape(c.role)}${c.archetype.isNotEmpty ? ' (${_xmlEscape(c.archetype)})' : ''}</small></h3>');
        if (c.quote.isNotEmpty) {
          charsBuffer.writeln('<blockquote>«${_xmlEscape(c.quote)}»</blockquote>');
        }
        if (c.traits.isNotEmpty) {
          charsBuffer.writeln('<p class="noindent"><strong>Rasgos:</strong> ${_xmlEscape(c.traits.join(', '))}</p>');
        }
        if (c.motivation.isNotEmpty) {
          charsBuffer.writeln('<p class="noindent"><strong>Motivación:</strong> ${_xmlEscape(c.motivation)}</p>');
        }
        if (c.writtenBiography.isNotEmpty) {
          charsBuffer.writeln(_convertMarkdownToEpubHtml(c.writtenBiography));
        }
        charsBuffer.writeln('</div>');
      }
      charsBuffer.writeln('</body></html>');
      final charsXml = charsBuffer.toString();
      archive.addFile(ArchiveFile('OEBPS/characters.xhtml', charsXml.length, utf8.encode(charsXml)));
    }

    // Optional Codex (OEBPS/codex.xhtml)
    if (hasCodex) {
      final codexBuffer = StringBuffer();
      codexBuffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
      codexBuffer.writeln('<!DOCTYPE html>');
      codexBuffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" lang="es">');
      codexBuffer.writeln('<head><title>Códice y Lore</title><link rel="stylesheet" type="text/css" href="style.css"/></head>');
      codexBuffer.writeln('<body>');
      codexBuffer.writeln('<h2>Apéndice del Códice</h2>');
      for (final e in codexEntries) {
        codexBuffer.writeln('<div class="card">');
        codexBuffer.writeln('<h3>${_xmlEscape(e.name)} <small>(${_xmlEscape(e.typeLabel)})</small></h3>');
        if (e.role.isNotEmpty) {
          codexBuffer.writeln('<blockquote>${_xmlEscape(e.role)}</blockquote>');
        }
        if (e.description.isNotEmpty) {
          codexBuffer.writeln(_convertMarkdownToEpubHtml(e.description));
        }
        codexBuffer.writeln('</div>');
      }
      codexBuffer.writeln('</body></html>');
      final codexXml = codexBuffer.toString();
      archive.addFile(ArchiveFile('OEBPS/codex.xhtml', codexXml.length, utf8.encode(codexXml)));
    }

    final sceneSep = cfg?.sceneSeparator.trim().isNotEmpty == true ? cfg!.sceneSeparator.trim() : '* * *';

    // Chapters (OEBPS/chapter_1.xhtml, ...)
    for (int i = 0; i < compiledChapters.length; i++) {
      final item = compiledChapters[i];
      final ch = item.chapter;
      final chBuffer = StringBuffer();
      chBuffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
      chBuffer.writeln('<!DOCTYPE html>');
      chBuffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" lang="es">');
      chBuffer.writeln('<head><title>${_xmlEscape(item.displayHeader)}</title><link rel="stylesheet" type="text/css" href="style.css"/></head>');
      chBuffer.writeln('<body>');
      chBuffer.writeln('<h2>${_xmlEscape(item.displayHeader)}</h2>');
      if (includeEditorialElements && ch.povCharacter.isNotEmpty) {
        chBuffer.writeln('<p class="pov">POV: ${_xmlEscape(ch.povCharacter)}</p>');
      }
      chBuffer.write(_convertMarkdownToEpubHtml(formatChapterText(ch.content, cfg), sceneSeparator: sceneSep));
      chBuffer.writeln('</body></html>');
      final chXml = chBuffer.toString();
      archive.addFile(ArchiveFile('OEBPS/chapter_${i + 1}.xhtml', chXml.length, utf8.encode(chXml)));
    }

    // Optional Acknowledgments (OEBPS/acknowledgments.xhtml)
    if (hasAcknowledgments) {
      final ackBuffer = StringBuffer();
      ackBuffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
      ackBuffer.writeln('<!DOCTYPE html>');
      ackBuffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" lang="es">');
      ackBuffer.writeln('<head><title>Agradecimientos</title><link rel="stylesheet" type="text/css" href="style.css"/></head>');
      ackBuffer.writeln('<body>');
      ackBuffer.writeln('<h2>Agradecimientos</h2>');
      ackBuffer.write(_convertMarkdownToEpubHtml(cfg.acknowledgments.trim(), sceneSeparator: sceneSep));
      ackBuffer.writeln('</body></html>');
      final ackXml = ackBuffer.toString();
      archive.addFile(ArchiveFile('OEBPS/acknowledgments.xhtml', ackXml.length, utf8.encode(ackXml)));
    }

    // Optional Author Bio & Socials (OEBPS/author.xhtml)
    if (hasAuthorBio) {
      final bioBuffer = StringBuffer();
      bioBuffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
      bioBuffer.writeln('<!DOCTYPE html>');
      bioBuffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" lang="es">');
      bioBuffer.writeln('<head><title>Sobre el Autor</title><link rel="stylesheet" type="text/css" href="style.css"/></head>');
      bioBuffer.writeln('<body>');
      bioBuffer.writeln('<h2>Sobre el Autor</h2>');
      if (cfg.authorBio.trim().isNotEmpty) {
        bioBuffer.write(_convertMarkdownToEpubHtml(cfg.authorBio.trim(), sceneSeparator: sceneSep));
      }
      if (cfg.authorSocials.trim().isNotEmpty) {
        bioBuffer.writeln('<p class="meta" style="margin-top: 2em; font-style: italic;"><strong>Contacto y Redes:</strong> ${_xmlEscape(cfg.authorSocials.trim())}</p>');
      }
      bioBuffer.writeln('</body></html>');
      final bioXml = bioBuffer.toString();
      archive.addFile(ArchiveFile('OEBPS/author.xhtml', bioXml.length, utf8.encode(bioXml)));
    }

    // 5. OEBPS/nav.xhtml (EPUB 3 Table of Contents)
    final navBuffer = StringBuffer();
    navBuffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
    navBuffer.writeln('<!DOCTYPE html>');
    navBuffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="es">');
    navBuffer.writeln('<head><title>Índice</title><link rel="stylesheet" type="text/css" href="style.css"/></head>');
    navBuffer.writeln('<body>');
    navBuffer.writeln('<nav epub:type="toc" id="toc">');
    navBuffer.writeln('<h2>Índice</h2>');
    navBuffer.writeln('<ol>');
    if (hasCover) {
      navBuffer.writeln('<li><a href="titlepage.xhtml">Portada</a></li>');
    }
    if (hasDedication) {
      navBuffer.writeln('<li><a href="dedication.xhtml">Dedicatoria</a></li>');
    }
    if (hasCopyright) {
      navBuffer.writeln('<li><a href="copyright.xhtml">Créditos</a></li>');
    }
    if (hasChars) {
      navBuffer.writeln('<li><a href="characters.xhtml">Dramatis Personae</a></li>');
    }
    if (hasCodex) {
      navBuffer.writeln('<li><a href="codex.xhtml">Apéndice del Códice</a></li>');
    }
    for (int i = 0; i < compiledChapters.length; i++) {
      final item = compiledChapters[i];
      navBuffer.writeln('<li><a href="chapter_${i + 1}.xhtml">${_xmlEscape(item.displayHeader)}</a></li>');
    }
    if (hasAcknowledgments) {
      navBuffer.writeln('<li><a href="acknowledgments.xhtml">Agradecimientos</a></li>');
    }
    if (hasAuthorBio) {
      navBuffer.writeln('<li><a href="author.xhtml">Sobre el Autor</a></li>');
    }
    navBuffer.writeln('</ol>');
    navBuffer.writeln('</nav>');
    navBuffer.writeln('</body></html>');
    final navXml = navBuffer.toString();
    archive.addFile(ArchiveFile('OEBPS/nav.xhtml', navXml.length, utf8.encode(navXml)));

    // 6. OEBPS/toc.ncx (EPUB 2 / Kindle compatibility)
    final ncxBuffer = StringBuffer();
    ncxBuffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    ncxBuffer.writeln('<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">');
    ncxBuffer.writeln('<head><meta name="dtb:uid" content="urn:uuid:${book.id}"/></head>');
    ncxBuffer.writeln('<docTitle><text>${_xmlEscape(title)}</text></docTitle>');
    ncxBuffer.writeln('<navMap>');
    int playOrder = 0;
    if (hasCover) {
      playOrder++;
      ncxBuffer.writeln('<navPoint id="navPoint-$playOrder" playOrder="$playOrder"><navLabel><text>Portada</text></navLabel><content src="titlepage.xhtml"/></navPoint>');
    }
    if (hasDedication) {
      playOrder++;
      ncxBuffer.writeln('<navPoint id="navPoint-$playOrder" playOrder="$playOrder"><navLabel><text>Dedicatoria</text></navLabel><content src="dedication.xhtml"/></navPoint>');
    }
    if (hasCopyright) {
      playOrder++;
      ncxBuffer.writeln('<navPoint id="navPoint-$playOrder" playOrder="$playOrder"><navLabel><text>Créditos</text></navLabel><content src="copyright.xhtml"/></navPoint>');
    }
    if (hasChars) {
      playOrder++;
      ncxBuffer.writeln('<navPoint id="navPoint-$playOrder" playOrder="$playOrder"><navLabel><text>Dramatis Personae</text></navLabel><content src="characters.xhtml"/></navPoint>');
    }
    if (hasCodex) {
      playOrder++;
      ncxBuffer.writeln('<navPoint id="navPoint-$playOrder" playOrder="$playOrder"><navLabel><text>Apéndice del Códice</text></navLabel><content src="codex.xhtml"/></navPoint>');
    }
    for (int i = 0; i < compiledChapters.length; i++) {
      playOrder++;
      final item = compiledChapters[i];
      ncxBuffer.writeln('<navPoint id="navPoint-$playOrder" playOrder="$playOrder"><navLabel><text>${_xmlEscape(item.displayHeader)}</text></navLabel><content src="chapter_${i + 1}.xhtml"/></navPoint>');
    }
    if (hasAcknowledgments) {
      playOrder++;
      ncxBuffer.writeln('<navPoint id="navPoint-$playOrder" playOrder="$playOrder"><navLabel><text>Agradecimientos</text></navLabel><content src="acknowledgments.xhtml"/></navPoint>');
    }
    if (hasAuthorBio) {
      playOrder++;
      ncxBuffer.writeln('<navPoint id="navPoint-$playOrder" playOrder="$playOrder"><navLabel><text>Sobre el Autor</text></navLabel><content src="author.xhtml"/></navPoint>');
    }
    ncxBuffer.writeln('</navMap>');
    ncxBuffer.writeln('</ncx>');
    final ncxXml = ncxBuffer.toString();
    archive.addFile(ArchiveFile('OEBPS/toc.ncx', ncxXml.length, utf8.encode(ncxXml)));

    // 7. OEBPS/content.opf
    final opfBuffer = StringBuffer();
    opfBuffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    opfBuffer.writeln('<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="3.0">');
    opfBuffer.writeln('<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">');
    opfBuffer.writeln('<dc:identifier id="BookId">urn:uuid:${book.id}</dc:identifier>');
    opfBuffer.writeln('<dc:title>${_xmlEscape(title)}</dc:title>');
    opfBuffer.writeln('<dc:language>es</dc:language>');
    opfBuffer.writeln('<dc:creator>${_xmlEscape(author)}</dc:creator>');
    opfBuffer.writeln('<dc:publisher>Ink &amp; Wright Sanctuary</dc:publisher>');
    if (book.synopsis.isNotEmpty) {
      opfBuffer.writeln('<dc:description>${_xmlEscape(book.synopsis)}</dc:description>');
    }
    if (hasCoverImage) {
      opfBuffer.writeln('<meta name="cover" content="cover-image"/>');
    }
    opfBuffer.writeln('<meta property="dcterms:modified">${DateTime.now().toUtc().toIso8601String().substring(0, 19)}Z</meta>');
    opfBuffer.writeln('</metadata>');

    opfBuffer.writeln('<manifest>');
    if (hasCoverImage) {
      opfBuffer.writeln('<item id="cover-image" href="images/cover.$coverImgExt" media-type="$coverImgMime" properties="cover-image"/>');
    }
    opfBuffer.writeln('<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>');
    opfBuffer.writeln('<item id="css" href="style.css" media-type="text/css"/>');
    opfBuffer.writeln('<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>');
    if (hasCover) {
      opfBuffer.writeln('<item id="titlepage" href="titlepage.xhtml" media-type="application/xhtml+xml"/>');
    }
    if (hasDedication) {
      opfBuffer.writeln('<item id="dedication" href="dedication.xhtml" media-type="application/xhtml+xml"/>');
    }
    if (hasCopyright) {
      opfBuffer.writeln('<item id="copyright" href="copyright.xhtml" media-type="application/xhtml+xml"/>');
    }
    if (hasChars) {
      opfBuffer.writeln('<item id="characters" href="characters.xhtml" media-type="application/xhtml+xml"/>');
    }
    if (hasCodex) {
      opfBuffer.writeln('<item id="codex" href="codex.xhtml" media-type="application/xhtml+xml"/>');
    }
    for (int i = 0; i < compiledChapters.length; i++) {
      opfBuffer.writeln('<item id="chap_${i + 1}" href="chapter_${i + 1}.xhtml" media-type="application/xhtml+xml"/>');
    }
    if (hasAcknowledgments) {
      opfBuffer.writeln('<item id="acknowledgments" href="acknowledgments.xhtml" media-type="application/xhtml+xml"/>');
    }
    if (hasAuthorBio) {
      opfBuffer.writeln('<item id="author" href="author.xhtml" media-type="application/xhtml+xml"/>');
    }
    opfBuffer.writeln('</manifest>');

    opfBuffer.writeln('<spine toc="ncx">');
    if (hasCover) {
      opfBuffer.writeln('<itemref idref="titlepage"/>');
    }
    if (hasDedication) {
      opfBuffer.writeln('<itemref idref="dedication"/>');
    }
    if (hasCopyright) {
      opfBuffer.writeln('<itemref idref="copyright"/>');
    }
    if (hasChars) {
      opfBuffer.writeln('<itemref idref="characters"/>');
    }
    if (hasCodex) {
      opfBuffer.writeln('<itemref idref="codex"/>');
    }
    for (int i = 0; i < compiledChapters.length; i++) {
      opfBuffer.writeln('<itemref idref="chap_${i + 1}"/>');
    }
    if (hasAcknowledgments) {
      opfBuffer.writeln('<itemref idref="acknowledgments"/>');
    }
    if (hasAuthorBio) {
      opfBuffer.writeln('<itemref idref="author"/>');
    }
    opfBuffer.writeln('</spine>');
    opfBuffer.writeln('</package>');
    final opfXml = opfBuffer.toString();
    archive.addFile(ArchiveFile('OEBPS/content.opf', opfXml.length, utf8.encode(opfXml)));

    return ZipEncoder().encode(archive);
  }

  /// Converts Markdown text into native semantic XHTML (paragraphs, headings, blockquotes, lists, dialogue) for EPUB and HTML
  static String _convertMarkdownToEpubHtml(String content, {String sceneSeparator = '* * *'}) {
    if (content.trim().isEmpty) return '';

    final lines = content.split(RegExp(r'\r?\n'));
    final buffer = StringBuffer();
    final List<String> currentParagraphLines = [];
    String? currentListType; // 'ul' or 'ol'

    void flushParagraph() {
      if (currentParagraphLines.isEmpty) return;
      final fullText = currentParagraphLines.join(' ').trim();
      currentParagraphLines.clear();
      if (fullText.isEmpty) return;

      buffer.writeln('<p>${_parseInlineToHtml(fullText)}</p>');
    }

    void closeList() {
      if (currentListType != null) {
        buffer.writeln('</$currentListType>');
        currentListType = null;
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        flushParagraph();
        closeList();
        continue;
      }

      // 1. Headings (#, ##, ###, ####)
      if (trimmed.startsWith('# ') ||
          trimmed.startsWith('## ') ||
          trimmed.startsWith('### ') ||
          trimmed.startsWith('#### ')) {
        flushParagraph();
        closeList();
        int level = 1;
        if (trimmed.startsWith('#### ')) {
          level = 4;
        } else if (trimmed.startsWith('### ')) {
          level = 3;
        } else if (trimmed.startsWith('## ')) {
          level = 2;
        }

        final titleText = trimmed.substring(level + 1).trim();
        final tag = level == 1 ? 'h3' : (level == 2 ? 'h4' : 'h5');
        buffer.writeln('<$tag>${_parseInlineToHtml(titleText)}</$tag>');
        continue;
      }

      // 2. Scene separators (***, ---, ___)
      if (trimmed == '***' || trimmed == '---' || trimmed == '___' || trimmed == sceneSeparator.trim()) {
        flushParagraph();
        closeList();
        buffer.writeln('<div class="scene-break">${_xmlEscape(sceneSeparator.isNotEmpty ? sceneSeparator : "*  *  *")}</div>');
        continue;
      }

      // 3. Blockquotes (> quote)
      if (trimmed.startsWith('> ') || trimmed == '>') {
        flushParagraph();
        closeList();
        final quoteText = trimmed == '>' ? '' : trimmed.substring(2).trim();
        buffer.writeln('<blockquote><p class="noindent">${_parseInlineToHtml(quoteText)}</p></blockquote>');
        continue;
      }

      // 4. Checklist items (- [ ] or - [x])
      if (trimmed.startsWith('- [ ] ') || trimmed.startsWith('- [x] ') || trimmed.startsWith('- [X] ')) {
        flushParagraph();
        if (currentListType != 'ul') {
          closeList();
          buffer.writeln('<ul style="list-style-type:none; padding-left:1em;">');
          currentListType = 'ul';
        }
        final isChecked = trimmed.startsWith('- [x] ') || trimmed.startsWith('- [X] ');
        final itemText = trimmed.substring(6).trim();
        final box = isChecked ? '[x] ' : '[ ] ';
        buffer.writeln('<li>$box${_parseInlineToHtml(itemText)}</li>');
        continue;
      }

      // 5. Bullet lists (- item, * item, + item)
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ') || trimmed.startsWith('+ ')) {
        flushParagraph();
        if (currentListType != 'ul') {
          closeList();
          buffer.writeln('<ul>');
          currentListType = 'ul';
        }
        final itemText = trimmed.substring(2).trim();
        buffer.writeln('<li>${_parseInlineToHtml(itemText)}</li>');
        continue;
      }

      // 6. Numbered lists (1. item, 2. item)
      final numMatch = RegExp(r'^\d+\.\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        flushParagraph();
        if (currentListType != 'ol') {
          closeList();
          buffer.writeln('<ol>');
          currentListType = 'ol';
        }
        final itemText = numMatch.group(1)!.trim();
        buffer.writeln('<li>${_parseInlineToHtml(itemText)}</li>');
        continue;
      }

      // If we reach regular prose, close any active list
      closeList();

      // 7. Spanish dialogue turns (em-dash lines get individual paragraph)
      if (trimmed.startsWith('—') || trimmed.startsWith('--')) {
        flushParagraph();
        buffer.writeln('<p>${_parseInlineToHtml(trimmed)}</p>');
        continue;
      }

      // 8. Normal prose line
      currentParagraphLines.add(trimmed);
    }

    flushParagraph();
    closeList();
    return buffer.toString();
  }

  /// Parses inline Markdown tokens (bold, italic, strike, code, highlight) into XHTML tags for EPUB
  static String _parseInlineToHtml(String text) {
    if (text.isEmpty) return '';

    final matches = _docInlineRegex.allMatches(text);
    if (matches.isEmpty) {
      return _xmlEscape(text);
    }

    final buffer = StringBuffer();
    int lastIndex = 0;

    for (final m in matches) {
      if (m.start > lastIndex) {
        buffer.write(_xmlEscape(text.substring(lastIndex, m.start)));
      }

      final matched = m.group(0)!;
      if (matched.startsWith('***') && matched.endsWith('***')) {
        final inner = matched.substring(3, matched.length - 3);
        buffer.write('<strong><em>${_xmlEscape(inner)}</em></strong>');
      } else if (matched.startsWith('___') && matched.endsWith('___')) {
        final inner = matched.substring(3, matched.length - 3);
        buffer.write('<strong><em>${_xmlEscape(inner)}</em></strong>');
      } else if (matched.startsWith('**') && matched.endsWith('**')) {
        final inner = matched.substring(2, matched.length - 2);
        buffer.write('<strong>${_xmlEscape(inner)}</strong>');
      } else if (matched.startsWith('__') && matched.endsWith('__')) {
        final inner = matched.substring(2, matched.length - 2);
        buffer.write('<strong>${_xmlEscape(inner)}</strong>');
      } else if (matched.startsWith('*') && matched.endsWith('*')) {
        final inner = matched.substring(1, matched.length - 1);
        buffer.write('<em>${_xmlEscape(inner)}</em>');
      } else if (matched.startsWith('_') && matched.endsWith('_')) {
        final inner = matched.substring(1, matched.length - 1);
        buffer.write('<em>${_xmlEscape(inner)}</em>');
      } else if (matched.startsWith('~~') && matched.endsWith('~~')) {
        final inner = matched.substring(2, matched.length - 2);
        buffer.write('<del>${_xmlEscape(inner)}</del>');
      } else if (matched.startsWith('`') && matched.endsWith('`')) {
        final inner = matched.substring(1, matched.length - 1);
        buffer.write('<code>${_xmlEscape(inner)}</code>');
      } else if (matched.startsWith('==') && matched.endsWith('==')) {
        final inner = matched.substring(2, matched.length - 2);
        buffer.write('<mark>${_xmlEscape(inner)}</mark>');
      } else {
        buffer.write(_xmlEscape(matched));
      }

      lastIndex = m.end;
    }

    if (lastIndex < text.length) {
      buffer.write(_xmlEscape(text.substring(lastIndex)));
    }

    return buffer.toString();
  }

  static String _xmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
