import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/book_model.dart';
import '../models/chapter_model.dart';
import '../models/character_model.dart';
import '../models/codex_entry_model.dart';

class ExportService {
  /// Generates clean, well-formatted Markdown with YAML frontmatter
  static String exportToMarkdown(
    BookModel book, {
    List<CharacterModel>? characters,
    List<CodexEntryModel>? codexEntries,
  }) {
    final buffer = StringBuffer();

    // YAML Frontmatter
    buffer.writeln('---');
    buffer.writeln('title: "${book.title}"');
    if (book.subtitle.isNotEmpty) {
      buffer.writeln('subtitle: "${book.subtitle}"');
    }
    buffer.writeln('genre: "${book.genre}"');
    buffer.writeln('total_words: ${book.currentWordCount}');
    buffer.writeln('target_words: ${book.targetWordCount}');
    buffer.writeln('chapters_count: ${book.chapters.length}');
    buffer.writeln('exported_at: "${DateTime.now().toIso8601String()}"');
    if (book.tags.isNotEmpty) {
      buffer.writeln('tags: [${book.tags.map((t) => '"$t"').join(', ')}]');
    }
    buffer.writeln('---');
    buffer.writeln();

    // Book Title & Synopsis
    buffer.writeln('# ${book.title}');
    if (book.subtitle.isNotEmpty) {
      buffer.writeln('### *${book.subtitle}*');
    }
    buffer.writeln();

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

    buffer.writeln('---');
    buffer.writeln();

    // Chapters
    for (int i = 0; i < book.chapters.length; i++) {
      final ChapterModel ch = book.chapters[i];
      buffer.writeln('## Capítulo ${ch.chapterNumber}: ${ch.title}');
      if (ch.povCharacter.isNotEmpty) {
        buffer.writeln('*POV: ${ch.povCharacter}*');
      }
      buffer.writeln();
      buffer.writeln(ch.content.trim());
      buffer.writeln();
      if (i < book.chapters.length - 1) {
        buffer.writeln('***');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Generates classic plain text manuscript layout
  static String exportToPlainText(
    BookModel book, {
    List<CharacterModel>? characters,
    List<CodexEntryModel>? codexEntries,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('================================================================');
    buffer.writeln(book.title.toUpperCase());
    if (book.subtitle.isNotEmpty) {
      buffer.writeln(book.subtitle);
    }
    buffer.writeln('================================================================');
    buffer.writeln('Género: ${book.genre}');
    buffer.writeln('Palabras totales: ${book.currentWordCount}');
    buffer.writeln('Capítulos: ${book.chapters.length}');
    buffer.writeln('Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    buffer.writeln('================================================================');
    buffer.writeln();

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

    for (final ch in book.chapters) {
      buffer.writeln('CAPÍTULO ${ch.chapterNumber} — ${ch.title.toUpperCase()}');
      if (ch.povCharacter.isNotEmpty) {
        buffer.writeln('(POV: ${ch.povCharacter})');
      }
      buffer.writeln();
      buffer.writeln(ch.content.trim());
      buffer.writeln();
      buffer.writeln('----------------------------------------------------------------');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generates a beautiful HTML document ready for printing or viewing
  static String exportToHtml(
    BookModel book, {
    List<CharacterModel>? characters,
    List<CodexEntryModel>? codexEntries,
  }) {
    String charactersHtml = '';
    if (characters != null && characters.isNotEmpty) {
      charactersHtml = '''
    <section class="characters">
      <h2>Dramatis Personae (Personajes)</h2>
      ${characters.map((c) => '''
        <div class="character-card">
          <h3>${c.name} <small style="color: #666; font-size: 14px;">— ${c.role}${c.archetype.isNotEmpty ? ' (${c.archetype})' : ''}</small></h3>
          ${c.quote.isNotEmpty ? '<blockquote>«${c.quote}»</blockquote>' : ''}
          ${c.motivation.isNotEmpty ? '<p><strong>Motivación:</strong> ${c.motivation}</p>' : ''}
          ${c.writtenBiography.isNotEmpty ? '<p>${c.writtenBiography}</p>' : ''}
        </div>
      ''').join('\n')}
    </section>
    <hr class="chapter-divider"/>
''';
    }

    String codexHtml = '';
    if (codexEntries != null && codexEntries.isNotEmpty) {
      codexHtml = '''
    <section class="codex">
      <h2>Apéndice del Códice</h2>
      ${codexEntries.map((e) => '''
        <div class="codex-card">
          <h3>${e.name} <small style="color: #666; font-size: 14px;">(${e.typeLabel})</small></h3>
          ${e.role.isNotEmpty ? '<blockquote>${e.role}</blockquote>' : ''}
          ${e.description.isNotEmpty ? '<p>${e.description}</p>' : ''}
        </div>
      ''').join('\n')}
    </section>
    <hr class="chapter-divider"/>
''';
    }

    final chaptersHtml = book.chapters.map((ch) {
      final formattedContent = ch.content
          .split('\n\n')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .map((p) => '<p>$p</p>')
          .join('\n');

      return '''
    <section class="chapter">
      <h2>Capítulo ${ch.chapterNumber}: ${ch.title}</h2>
      ${ch.povCharacter.isNotEmpty ? '<p class="pov"><em>POV: ${ch.povCharacter}</em></p>' : ''}
      <div class="chapter-content">
        $formattedContent
      </div>
    </section>
''';
    }).join('\n<hr class="chapter-divider"/>\n');

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
      font-family: 'Lora', Georgia, serif;
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
      margin-bottom: 1.4em;
      text-align: justify;
      text-indent: 1.5em;
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
  <header>
    <h1>${book.title}</h1>
    ${book.subtitle.isNotEmpty ? '<p class="subtitle">${book.subtitle}</p>' : ''}
    <div class="meta">
      <span>Género: ${book.genre}</span> • 
      <span>${book.currentWordCount} palabras</span> • 
      <span>${book.chapters.length} capítulos</span>
    </div>
  </header>

  ${book.synopsis.isNotEmpty ? '<div class="synopsis"><strong>Sinopsis:</strong> ${book.synopsis}</div>' : ''}

  $charactersHtml
  $codexHtml
  $chaptersHtml
</body>
</html>''';
  }

  /// Generates a real native PDF document
  static Future<Uint8List> generatePdf(
    BookModel book, {
    List<CharacterModel>? characters,
    List<CodexEntryModel>? codexEntries,
  }) async {
    final pdf = pw.Document(
      title: _sanitizeForPdf(book.title),
      author: 'InkWright Studio',
    );

    // Cover Page
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
                  'Genero: ${_sanitizeForPdf(book.genre)}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  '${book.currentWordCount} palabras | ${book.chapters.length} capitulos',
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
                '${_sanitizeForPdf(book.title)} - Dramatis Personae',
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
                  pw.Text(
                    _sanitizeForPdf(c.writtenBiography),
                    style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
                  ),
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
                '${_sanitizeForPdf(book.title)} - Apendice del Codice',
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
                  pw.Text(
                    _sanitizeForPdf(e.description),
                    style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
                  ),
                ],
                pw.SizedBox(height: 14),
              ]),
            ];
          },
        ),
      );
    }

    // Chapters
    for (final chapter in book.chapters) {
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
                '${_sanitizeForPdf(book.title)} - Capitulo ${chapter.chapterNumber}',
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
            final paragraphs = chapter.content
                .split('\n\n')
                .map((p) => _sanitizeForPdf(p.trim()))
                .where((p) => p.isNotEmpty)
                .toList();

            return [
              pw.SizedBox(height: 20),
              pw.Text(
                'Capitulo ${chapter.chapterNumber}',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _sanitizeForPdf(chapter.title),
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (chapter.povCharacter.isNotEmpty) ...[
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
              ...paragraphs.map(
                (p) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Text(
                    p,
                    textAlign: pw.TextAlign.justify,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      lineSpacing: 3,
                    ),
                  ),
                ),
              ),
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

  /// Generates a genuine Microsoft Word (.docx) Open XML archive
  static List<int> generateDocx(
    BookModel book, {
    List<CharacterModel>? characters,
    List<CodexEntryModel>? codexEntries,
  }) {
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

    // Book Title
    docBuffer.writeln('<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:before="2400" w:after="200"/></w:pPr>');
    docBuffer.writeln('<w:r><w:rPr><w:b/><w:sz w:val="56"/><w:szCs w:val="56"/></w:rPr>');
    docBuffer.writeln('<w:t>${_xmlEscape(book.title)}</w:t></w:r></w:p>');

    // Subtitle
    if (book.subtitle.isNotEmpty) {
      docBuffer.writeln('<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:after="400"/></w:pPr>');
      docBuffer.writeln('<w:r><w:rPr><w:i/><w:sz w:val="32"/><w:szCs w:val="32"/><w:color w:val="555555"/></w:rPr>');
      docBuffer.writeln('<w:t>${_xmlEscape(book.subtitle)}</w:t></w:r></w:p>');
    }

    // Metadata
    docBuffer.writeln('<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:after="200"/></w:pPr>');
    docBuffer.writeln('<w:r><w:rPr><w:sz w:val="20"/><w:szCs w:val="20"/><w:color w:val="777777"/></w:rPr>');
    docBuffer.writeln('<w:t>${_xmlEscape("Género: ${book.genre}  •  ${book.currentWordCount} palabras  •  ${book.chapters.length} capítulos")}</w:t></w:r></w:p>');

    // Synopsis
    if (book.synopsis.isNotEmpty) {
      docBuffer.writeln('<w:p><w:pPr><w:spacing w:before="400" w:after="400"/></w:pPr>');
      docBuffer.writeln('<w:r><w:rPr><w:i/></w:rPr><w:t>${_xmlEscape("Sinopsis: ${book.synopsis}")}</w:t></w:r></w:p>');
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

    // Chapters
    for (final ch in book.chapters) {
      // Page break before chapter
      docBuffer.writeln('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');

      // Chapter Title
      docBuffer.writeln('<w:p><w:pPr><w:spacing w:before="400" w:after="160"/></w:pPr>');
      docBuffer.writeln('<w:r><w:rPr><w:b/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr>');
      docBuffer.writeln('<w:t>${_xmlEscape("Capítulo ${ch.chapterNumber}: ${ch.title}")}</w:t></w:r></w:p>');

      if (ch.povCharacter.isNotEmpty) {
        docBuffer.writeln('<w:p><w:pPr><w:spacing w:after="240"/></w:pPr>');
        docBuffer.writeln('<w:r><w:rPr><w:i/><w:sz w:val="20"/><w:szCs w:val="20"/><w:color w:val="666666"/></w:rPr>');
        docBuffer.writeln('<w:t>${_xmlEscape("POV: ${ch.povCharacter}")}</w:t></w:r></w:p>');
      }

      // Paragraphs
      final paragraphs = ch.content.split('\n\n').map((p) => p.trim()).where((p) => p.isNotEmpty);
      for (final p in paragraphs) {
        docBuffer.writeln('<w:p><w:pPr><w:ind w:firstLine="400"/></w:pPr>');
        docBuffer.writeln('<w:r><w:t xml:space="preserve">${_xmlEscape(p)}</w:t></w:r></w:p>');
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
  }) {
    final archive = Archive();

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
    const cssContent = '''
@namespace "http://www.w3.org/1999/xhtml";
body {
  font-family: Georgia, "Times New Roman", serif;
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
  text-indent: 1.5em;
  margin-top: 0;
  margin-bottom: 0.5em;
  text-align: justify;
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
  margin: 1em 2em;
  color: #444;
}
''';
    archive.addFile(ArchiveFile('OEBPS/style.css', cssContent.length, utf8.encode(cssContent)));

    // 4. OEBPS/titlepage.xhtml
    final titlePageBuffer = StringBuffer();
    titlePageBuffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
    titlePageBuffer.writeln('<!DOCTYPE html>');
    titlePageBuffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="es">');
    titlePageBuffer.writeln('<head><title>${_xmlEscape(book.title)}</title><link rel="stylesheet" type="text/css" href="style.css"/></head>');
    titlePageBuffer.writeln('<body>');
    titlePageBuffer.writeln('<div style="text-align:center; padding-top: 20%;">');
    titlePageBuffer.writeln('<h1>${_xmlEscape(book.title)}</h1>');
    if (book.subtitle.isNotEmpty) {
      titlePageBuffer.writeln('<p class="subtitle">${_xmlEscape(book.subtitle)}</p>');
    }
    titlePageBuffer.writeln('<div style="margin: 2em auto; width: 60px; height: 1px; background-color: #999;"></div>');
    titlePageBuffer.writeln('<p class="meta">Género: ${_xmlEscape(book.genre)}</p>');
    titlePageBuffer.writeln('<p class="meta">${book.currentWordCount} palabras • ${book.chapters.length} capítulos</p>');
    if (book.synopsis.isNotEmpty) {
      titlePageBuffer.writeln('<div style="margin: 2em 10%; font-style: italic; text-align: justify;"><p class="noindent"><strong>Sinopsis:</strong> ${_xmlEscape(book.synopsis)}</p></div>');
    }
    titlePageBuffer.writeln('<p class="meta" style="margin-top: 3em; font-size: 0.8em;">Compilado con Ink &amp; Wright</p>');
    titlePageBuffer.writeln('</div>');
    titlePageBuffer.writeln('</body></html>');
    final titlePageXml = titlePageBuffer.toString();
    archive.addFile(ArchiveFile('OEBPS/titlepage.xhtml', titlePageXml.length, utf8.encode(titlePageXml)));

    // Optional Dramatis Personae (OEBPS/characters.xhtml)
    final bool hasChars = characters != null && characters.isNotEmpty;
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
          charsBuffer.writeln('<p>${_xmlEscape(c.writtenBiography)}</p>');
        }
        charsBuffer.writeln('</div>');
      }
      charsBuffer.writeln('</body></html>');
      final charsXml = charsBuffer.toString();
      archive.addFile(ArchiveFile('OEBPS/characters.xhtml', charsXml.length, utf8.encode(charsXml)));
    }

    // Optional Codex (OEBPS/codex.xhtml)
    final bool hasCodex = codexEntries != null && codexEntries.isNotEmpty;
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
          codexBuffer.writeln('<p>${_xmlEscape(e.description)}</p>');
        }
        codexBuffer.writeln('</div>');
      }
      codexBuffer.writeln('</body></html>');
      final codexXml = codexBuffer.toString();
      archive.addFile(ArchiveFile('OEBPS/codex.xhtml', codexXml.length, utf8.encode(codexXml)));
    }

    // Chapters (OEBPS/chapter_1.xhtml, ...)
    for (int i = 0; i < book.chapters.length; i++) {
      final ch = book.chapters[i];
      final chBuffer = StringBuffer();
      chBuffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
      chBuffer.writeln('<!DOCTYPE html>');
      chBuffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml" lang="es">');
      chBuffer.writeln('<head><title>${_xmlEscape(ch.title)}</title><link rel="stylesheet" type="text/css" href="style.css"/></head>');
      chBuffer.writeln('<body>');
      chBuffer.writeln('<h2>Capítulo ${ch.chapterNumber}: ${_xmlEscape(ch.title)}</h2>');
      if (ch.povCharacter.isNotEmpty) {
        chBuffer.writeln('<p class="pov">POV: ${_xmlEscape(ch.povCharacter)}</p>');
      }
      final paragraphs = ch.content.split('\n\n').map((p) => p.trim()).where((p) => p.isNotEmpty);
      for (final p in paragraphs) {
        chBuffer.writeln('<p>${_xmlEscape(p)}</p>');
      }
      chBuffer.writeln('</body></html>');
      final chXml = chBuffer.toString();
      archive.addFile(ArchiveFile('OEBPS/chapter_${i + 1}.xhtml', chXml.length, utf8.encode(chXml)));
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
    navBuffer.writeln('<li><a href="titlepage.xhtml">Portada</a></li>');
    if (hasChars) {
      navBuffer.writeln('<li><a href="characters.xhtml">Dramatis Personae</a></li>');
    }
    if (hasCodex) {
      navBuffer.writeln('<li><a href="codex.xhtml">Apéndice del Códice</a></li>');
    }
    for (int i = 0; i < book.chapters.length; i++) {
      final ch = book.chapters[i];
      navBuffer.writeln('<li><a href="chapter_${i + 1}.xhtml">Capítulo ${ch.chapterNumber}: ${_xmlEscape(ch.title)}</a></li>');
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
    ncxBuffer.writeln('<docTitle><text>${_xmlEscape(book.title)}</text></docTitle>');
    ncxBuffer.writeln('<navMap>');
    int playOrder = 1;
    ncxBuffer.writeln('<navPoint id="navPoint-$playOrder" playOrder="$playOrder"><navLabel><text>Portada</text></navLabel><content src="titlepage.xhtml"/></navPoint>');
    if (hasChars) {
      playOrder++;
      ncxBuffer.writeln('<navPoint id="navPoint-$playOrder" playOrder="$playOrder"><navLabel><text>Dramatis Personae</text></navLabel><content src="characters.xhtml"/></navPoint>');
    }
    if (hasCodex) {
      playOrder++;
      ncxBuffer.writeln('<navPoint id="navPoint-$playOrder" playOrder="$playOrder"><navLabel><text>Apéndice del Códice</text></navLabel><content src="codex.xhtml"/></navPoint>');
    }
    for (int i = 0; i < book.chapters.length; i++) {
      playOrder++;
      final ch = book.chapters[i];
      ncxBuffer.writeln('<navPoint id="navPoint-$playOrder" playOrder="$playOrder"><navLabel><text>Capítulo ${ch.chapterNumber}: ${_xmlEscape(ch.title)}</text></navLabel><content src="chapter_${i + 1}.xhtml"/></navPoint>');
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
    opfBuffer.writeln('<dc:title>${_xmlEscape(book.title)}</dc:title>');
    opfBuffer.writeln('<dc:language>es</dc:language>');
    opfBuffer.writeln('<dc:creator>Ink &amp; Wright Author</dc:creator>');
    opfBuffer.writeln('<dc:publisher>Ink &amp; Wright Sanctuary</dc:publisher>');
    if (book.synopsis.isNotEmpty) {
      opfBuffer.writeln('<dc:description>${_xmlEscape(book.synopsis)}</dc:description>');
    }
    opfBuffer.writeln('<meta property="dcterms:modified">${DateTime.now().toUtc().toIso8601String().substring(0, 19)}Z</meta>');
    opfBuffer.writeln('</metadata>');

    opfBuffer.writeln('<manifest>');
    opfBuffer.writeln('<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>');
    opfBuffer.writeln('<item id="css" href="style.css" media-type="text/css"/>');
    opfBuffer.writeln('<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>');
    opfBuffer.writeln('<item id="titlepage" href="titlepage.xhtml" media-type="application/xhtml+xml"/>');
    if (hasChars) {
      opfBuffer.writeln('<item id="characters" href="characters.xhtml" media-type="application/xhtml+xml"/>');
    }
    if (hasCodex) {
      opfBuffer.writeln('<item id="codex" href="codex.xhtml" media-type="application/xhtml+xml"/>');
    }
    for (int i = 0; i < book.chapters.length; i++) {
      opfBuffer.writeln('<item id="chap_${i + 1}" href="chapter_${i + 1}.xhtml" media-type="application/xhtml+xml"/>');
    }
    opfBuffer.writeln('</manifest>');

    opfBuffer.writeln('<spine toc="ncx">');
    opfBuffer.writeln('<itemref idref="titlepage"/>');
    if (hasChars) {
      opfBuffer.writeln('<itemref idref="characters"/>');
    }
    if (hasCodex) {
      opfBuffer.writeln('<itemref idref="codex"/>');
    }
    for (int i = 0; i < book.chapters.length; i++) {
      opfBuffer.writeln('<itemref idref="chap_${i + 1}"/>');
    }
    opfBuffer.writeln('</spine>');
    opfBuffer.writeln('</package>');
    final opfXml = opfBuffer.toString();
    archive.addFile(ArchiveFile('OEBPS/content.opf', opfXml.length, utf8.encode(opfXml)));

    return ZipEncoder().encode(archive);
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
