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

  static String _xmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
