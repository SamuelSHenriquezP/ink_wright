import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';

/// Representa un capítulo detectado durante la importación
class ImportedChapterData {
  final String title;
  final String content;
  final int chapterNumber;

  ImportedChapterData({
    required this.title,
    required this.content,
    required this.chapterNumber,
  });

  int get wordCount {
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }
}

/// Representa los datos completos extraídos de un manuscrito
class ImportedBookData {
  final String title;
  final String subtitle;
  final String author;
  final String genre;
  final String synopsis;
  final int targetWordCount;
  final List<ImportedChapterData> chapters;

  ImportedBookData({
    required this.title,
    this.subtitle = '',
    this.author = '',
    this.genre = 'Ficción',
    this.synopsis = '',
    this.targetWordCount = 0,
    required this.chapters,
  });

  int get totalWords => chapters.fold(0, (sum, ch) => sum + ch.wordCount);
}

class ImportService {
  /// Detecta automáticamente el tipo de archivo y lo parsea
  static Future<ImportedBookData?> parseFile(Uint8List bytes, String filename) async {
    final lowerName = filename.toLowerCase();

    if (lowerName.endsWith('.docx')) {
      return parseDocx(bytes, filename);
    } else if (lowerName.endsWith('.epub')) {
      return parseEpub(bytes, filename);
    } else if (lowerName.endsWith('.md') || lowerName.endsWith('.markdown')) {
      final text = _decodeBytes(bytes);
      return parseMarkdown(text, filename);
    } else if (lowerName.endsWith('.txt')) {
      final text = _decodeBytes(bytes);
      return parsePlainText(text, filename);
    }

    return null;
  }

  /// Decodifica bytes intentando UTF-8 primero y Latin-1 como fallback
  static String _decodeBytes(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      try {
        return latin1.decode(bytes);
      } catch (_) {
        return String.fromCharCodes(bytes);
      }
    }
  }

  /// Limpia el nombre del archivo para usarlo como título por defecto
  static String _titleFromFilename(String filename) {
    String name = filename;
    final lastDot = name.lastIndexOf('.');
    if (lastDot != -1) {
      name = name.substring(0, lastDot);
    }
    name = name.replaceAll(RegExp(r'[-_]'), ' ').trim();
    if (name.isEmpty) return 'Manuscrito Importado';
    // Capitalizar primera letra de cada palabra
    return name.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // ===========================================================================
  // MARKDOWN PARSER
  // ===========================================================================

  static ImportedBookData parseMarkdown(String rawText, String filename) {
    String text = rawText.replaceAll('\r\n', '\n');
    String title = _titleFromFilename(filename);
    String subtitle = '';
    String genre = 'Ficción';
    String synopsis = '';

    // 1. Extraer YAML Frontmatter si existe
    if (text.startsWith('---\n')) {
      final endFrontmatter = text.indexOf('\n---\n', 4);
      if (endFrontmatter != -1) {
        final frontmatter = text.substring(4, endFrontmatter);
        text = text.substring(endFrontmatter + 5).trim();

        for (final line in frontmatter.split('\n')) {
          final colonIdx = line.indexOf(':');
          if (colonIdx != -1) {
            final key = line.substring(0, colonIdx).trim().toLowerCase();
            final value = line.substring(colonIdx + 1).trim().replaceAll(RegExp(r'''^["']|["']$'''), '');
            if (key == 'title' && value.isNotEmpty) title = value;
            if (key == 'subtitle' && value.isNotEmpty) subtitle = value;
            if (key == 'genre' && value.isNotEmpty) genre = value;
            if (key == 'synopsis' && value.isNotEmpty) synopsis = value;
          }
        }
      }
    }

    // 2. Detectar título principal de nivel 1 si está al inicio
    final h1Regex = RegExp(r'^#\s+([^\n]+)\n+');
    final h1Match = h1Regex.firstMatch(text);
    if (h1Match != null && title == _titleFromFilename(filename)) {
      title = h1Match.group(1)?.trim() ?? title;
      text = text.substring(h1Match.end).trim();
    }

    // 3. Dividir capítulos usando encabezados Markdown (# o ##) o expresiones regulares de capítulo
    final chapterRegex = RegExp(
      r'^(#{1,3}\s+.+$|(?:Cap[ií]tulo|Chapter|Acto|Parte|Ep[ií]logo|Pr[óo]logo)\s+[\w\dIVXLCDM]+.*$)',
      multiLine: true,
      caseSensitive: false,
    );

    final matches = chapterRegex.allMatches(text).toList();
    final chapters = <ImportedChapterData>[];

    if (matches.isEmpty) {
      // Todo el contenido es un solo capítulo
      chapters.add(ImportedChapterData(
        title: title,
        content: text.trim(),
        chapterNumber: 1,
      ));
    } else {
      // Si hay contenido antes del primer encabezado
      if (matches.first.start > 0) {
        final preamble = text.substring(0, matches.first.start).trim();
        if (preamble.isNotEmpty) {
          if (preamble.length < 300 && synopsis.isEmpty) {
            synopsis = preamble;
          } else {
            chapters.add(ImportedChapterData(
              title: 'Prólogo',
              content: preamble,
              chapterNumber: 1,
            ));
          }
        }
      }

      for (int i = 0; i < matches.length; i++) {
        final match = matches[i];
        var rawHeading = match.group(0)?.trim() ?? 'Capítulo ${chapters.length + 1}';
        // Quitar símbolos de almohadilla (#)
        rawHeading = rawHeading.replaceAll(RegExp(r'^#+\s*'), '').trim();

        final contentStart = match.end;
        final contentEnd = (i + 1 < matches.length) ? matches[i + 1].start : text.length;
        final content = text.substring(contentStart, contentEnd).trim();

        chapters.add(ImportedChapterData(
          title: rawHeading.isEmpty ? 'Capítulo ${chapters.length + 1}' : rawHeading,
          content: content,
          chapterNumber: chapters.length + 1,
        ));
      }
    }

    return ImportedBookData(
      title: title,
      subtitle: subtitle,
      genre: genre,
      synopsis: synopsis,
      chapters: chapters.isEmpty
          ? [ImportedChapterData(title: 'Capítulo 1', content: text, chapterNumber: 1)]
          : chapters,
    );
  }

  // ===========================================================================
  // PLAIN TEXT PARSER
  // ===========================================================================

  static ImportedBookData parsePlainText(String rawText, String filename) {
    String text = rawText.replaceAll('\r\n', '\n');
    final title = _titleFromFilename(filename);

    // Expresión regular para detectar separadores de capítulos en texto plano
    final chapterRegex = RegExp(
      r'^(?:\s*[-=_*]{3,}\s*|(?:\*{1,2}|_{1,2})?(?:Cap[ií]tulo|Chapter|Acto|Act|Parte|Part|Ep[ií]logo|Pr[óo]logo)\s+[\w\dIVXLCDM]+.*)$',
      multiLine: true,
      caseSensitive: false,
    );

    final matches = chapterRegex.allMatches(text).toList();
    final chapters = <ImportedChapterData>[];

    if (matches.isEmpty) {
      chapters.add(ImportedChapterData(
        title: 'Capítulo 1',
        content: text.trim(),
        chapterNumber: 1,
      ));
    } else {
      if (matches.first.start > 0) {
        final preamble = text.substring(0, matches.first.start).trim();
        if (preamble.isNotEmpty) {
          chapters.add(ImportedChapterData(
            title: 'Prólogo',
            content: preamble,
            chapterNumber: 1,
          ));
        }
      }

      for (int i = 0; i < matches.length; i++) {
        final match = matches[i];
        var heading = match.group(0)?.trim() ?? 'Capítulo ${chapters.length + 1}';
        heading = heading.replaceAll(RegExp(r'^[-=_*]{3,}\s*'), '').trim();
        if (heading.isEmpty) {
          heading = 'Capítulo ${chapters.length + 1}';
        }

        final contentStart = match.end;
        final contentEnd = (i + 1 < matches.length) ? matches[i + 1].start : text.length;
        final content = text.substring(contentStart, contentEnd).trim();

        chapters.add(ImportedChapterData(
          title: heading,
          content: content,
          chapterNumber: chapters.length + 1,
        ));
      }
    }

    return ImportedBookData(
      title: title,
      genre: 'Ficción',
      chapters: chapters,
    );
  }

  // ===========================================================================
  // MICROSOFT WORD (.DOCX) PARSER
  // ===========================================================================

  static ImportedBookData parseDocx(Uint8List bytes, String filename) {
    final title = _titleFromFilename(filename);

    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final documentFile = archive.findFile('word/document.xml');

      if (documentFile == null) {
        throw Exception('El archivo .docx no contiene word/document.xml válido.');
      }

      final xmlContent = _decodeBytes(documentFile.content);

      // Extraer párrafos <w:p>
      final paragraphRegex = RegExp(r'<w:p(?: [^>]*)?>(.*?)</w:p>', dotAll: true);
      final pMatches = paragraphRegex.allMatches(xmlContent);

      final chapters = <ImportedChapterData>[];
      final currentChapterParagraphs = <String>[];
      String currentChapterTitle = 'Capítulo 1';

      for (final pMatch in pMatches) {
        final pXml = pMatch.group(1) ?? '';

        // Comprobar si el párrafo tiene estilo de encabezado
        final styleMatch = RegExp(r'<w:pStyle\s+w:val="([^"]+)"').firstMatch(pXml);
        final styleVal = styleMatch?.group(1)?.toLowerCase() ?? '';
        final isHeadingStyle = styleVal.contains('heading') ||
            styleVal.contains('titulo') ||
            styleVal.contains('título') ||
            styleVal.contains('title');

        // Extraer texto de los runs <w:t>
        final tRegex = RegExp(r'<w:t(?:\s+[^>]*)?>([^<]*)</w:t>');
        final textBuffer = StringBuffer();
        for (final tMatch in tRegex.allMatches(pXml)) {
          textBuffer.write(tMatch.group(1) ?? '');
        }

        final pText = _unescapeXml(textBuffer.toString()).trim();
        if (pText.isEmpty) continue;

        // Comprobar si el texto empieza como título de capítulo
        final isChapterPattern = RegExp(
          r'^(?:Cap[ií]tulo|Chapter|Acto|Parte|Ep[ií]logo|Pr[óo]logo)\s+[\w\dIVXLCDM]+',
          caseSensitive: false,
        ).hasMatch(pText);

        if (isHeadingStyle || isChapterPattern) {
          // Iniciar un nuevo capítulo si ya tenemos contenido acumulado
          if (currentChapterParagraphs.isNotEmpty) {
            chapters.add(ImportedChapterData(
              title: currentChapterTitle,
              content: currentChapterParagraphs.join('\n\n'),
              chapterNumber: chapters.length + 1,
            ));
            currentChapterParagraphs.clear();
          }
          currentChapterTitle = pText;
        } else {
          currentChapterParagraphs.add(pText);
        }
      }

      // Añadir último capítulo acumulado
      if (currentChapterParagraphs.isNotEmpty || chapters.isEmpty) {
        chapters.add(ImportedChapterData(
          title: currentChapterTitle,
          content: currentChapterParagraphs.join('\n\n'),
          chapterNumber: chapters.length + 1,
        ));
      }

      return ImportedBookData(
        title: title,
        genre: 'Ficción',
        chapters: chapters,
      );
    } catch (e) {
      // Fallback si falla la descompresión
      return ImportedBookData(
        title: title,
        genre: 'Ficción',
        chapters: [
          ImportedChapterData(
            title: 'Capítulo 1',
            content: 'No se pudo extraer el texto del documento Word: $e',
            chapterNumber: 1,
          ),
        ],
      );
    }
  }

  // ===========================================================================
  // EPUB (.EPUB) PARSER
  // ===========================================================================

  static ImportedBookData parseEpub(Uint8List bytes, String filename) {
    String title = _titleFromFilename(filename);
    String author = '';
    String description = '';

    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      // 1. Localizar archivo container.xml
      final containerFile = archive.findFile('META-INF/container.xml');
      String opfPath = 'OEBPS/content.opf';

      if (containerFile != null) {
        final containerXml = _decodeBytes(containerFile.content);
        final rootfileMatch = RegExp(r'<rootfile\s+[^>]*full-path="([^"]+)"').firstMatch(containerXml);
        if (rootfileMatch != null) {
          opfPath = rootfileMatch.group(1)!;
        }
      }

      // 2. Buscar archivo OPF
      var opfFile = archive.findFile(opfPath);
      if (opfFile == null) {
        // Buscar cualquier archivo con extensión .opf
        for (final file in archive.files) {
          if (file.name.toLowerCase().endsWith('.opf')) {
            opfFile = file;
            opfPath = file.name;
            break;
          }
        }
      }

      final chapters = <ImportedChapterData>[];

      if (opfFile != null) {
        final opfContent = _decodeBytes(opfFile.content);

        // Extraer metadatos
        final titleMatch = RegExp(r'<dc:title[^>]*>([^<]+)</dc:title>').firstMatch(opfContent);
        if (titleMatch != null && titleMatch.group(1)!.trim().isNotEmpty) {
          title = _unescapeXml(titleMatch.group(1)!.trim());
        }

        final creatorMatch = RegExp(r'<dc:creator[^>]*>([^<]+)</dc:creator>').firstMatch(opfContent);
        if (creatorMatch != null && creatorMatch.group(1)!.trim().isNotEmpty) {
          author = _unescapeXml(creatorMatch.group(1)!.trim());
        }

        final descMatch = RegExp(r'<dc:description[^>]*>([^<]+)</dc:description>').firstMatch(opfContent);
        if (descMatch != null && descMatch.group(1)!.trim().isNotEmpty) {
          description = _cleanHtmlTags(_unescapeXml(descMatch.group(1)!.trim()));
        }

        // Obtener directorio base del OPF
        final opfDir = opfPath.contains('/') ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1) : '';

        // Mapear manifest: id -> href
        final manifestMap = <String, String>{};
        final itemRegex = RegExp(r'<item\s+[^>]*id="([^"]+)"[^>]*href="([^"]+)"', caseSensitive: false);
        for (final m in itemRegex.allMatches(opfContent)) {
          manifestMap[m.group(1)!] = m.group(2)!;
        }
        // También intentar en orden inverso de atributos si falló
        if (manifestMap.isEmpty) {
          final itemAltRegex = RegExp(r'<item\s+[^>]*href="([^"]+)"[^>]*id="([^"]+)"', caseSensitive: false);
          for (final m in itemAltRegex.allMatches(opfContent)) {
            manifestMap[m.group(2)!] = m.group(1)!;
          }
        }

        // Obtener orden de lectura del spine
        final spineIds = <String>[];
        final itemrefRegex = RegExp(r'<itemref\s+[^>]*idref="([^"]+)"', caseSensitive: false);
        for (final m in itemrefRegex.allMatches(opfContent)) {
          spineIds.add(m.group(1)!);
        }

        // Procesar cada archivo en el orden del spine
        for (final id in spineIds) {
          final href = manifestMap[id];
          if (href == null) continue;

          // Normalizar ruta
          final decodedHref = Uri.decodeFull(href);
          final filePath = opfDir.isEmpty ? decodedHref : '$opfDir$decodedHref';

          var xhtmlFile = archive.findFile(filePath);
          if (xhtmlFile == null) {
            // Intento de búsqueda insensible a mayúsculas
            for (final f in archive.files) {
              if (f.name.toLowerCase() == filePath.toLowerCase() ||
                  f.name.toLowerCase().endsWith(decodedHref.toLowerCase())) {
                xhtmlFile = f;
                break;
              }
            }
          }

          if (xhtmlFile != null) {
            final rawHtml = _decodeBytes(xhtmlFile.content);
            final cleanText = _extractTextFromHtml(rawHtml);

            // Ignorar páginas que solo tienen portada o vacías (menos de 40 caracteres)
            if (cleanText.trim().length > 40) {
              final detectedTitle = _extractTitleFromHtml(rawHtml) ?? 'Capítulo ${chapters.length + 1}';
              chapters.add(ImportedChapterData(
                title: detectedTitle,
                content: cleanText.trim(),
                chapterNumber: chapters.length + 1,
              ));
            }
          }
        }
      }

      // Si no se encontraron capítulos mediante el spine, intentar con todos los archivos .xhtml/.html
      if (chapters.isEmpty) {
        for (final file in archive.files) {
          final lower = file.name.toLowerCase();
          if (lower.endsWith('.xhtml') || lower.endsWith('.html') || lower.endsWith('.htm')) {
            final rawHtml = _decodeBytes(file.content);
            final cleanText = _extractTextFromHtml(rawHtml);
            if (cleanText.trim().length > 80) {
              final detectedTitle = _extractTitleFromHtml(rawHtml) ?? 'Capítulo ${chapters.length + 1}';
              chapters.add(ImportedChapterData(
                title: detectedTitle,
                content: cleanText.trim(),
                chapterNumber: chapters.length + 1,
              ));
            }
          }
        }
      }

      return ImportedBookData(
        title: title,
        author: author,
        synopsis: description,
        genre: 'Ficción',
        chapters: chapters.isEmpty
            ? [ImportedChapterData(title: 'Capítulo 1', content: 'Contenido no encontrado en el EPUB.', chapterNumber: 1)]
            : chapters,
      );
    } catch (e) {
      return ImportedBookData(
        title: title,
        genre: 'Ficción',
        chapters: [
          ImportedChapterData(
            title: 'Capítulo 1',
            content: 'Error al procesar el libro EPUB: $e',
            chapterNumber: 1,
          ),
        ],
      );
    }
  }

  // ===========================================================================
  // UTILIDADES DE TEXTO Y LIMPIEZA
  // ===========================================================================

  static String _extractTextFromHtml(String html) {
    var text = html;
    // Eliminar bloques script y style
    text = text.replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true, caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true, caseSensitive: false), '');

    // Reemplazar saltos de bloque por dobles saltos de línea
    text = text.replaceAll(RegExp(r'</(?:p|div|h[1-6]|li|blockquote)>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    // Quitar todas las etiquetas HTML restantes
    text = _cleanHtmlTags(text);

    // Decodificar entidades
    text = _unescapeXml(text);

    // Normalizar saltos de línea excesivos
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  static String? _extractTitleFromHtml(String html) {
    // Intentar buscar <h1> o <h2>
    final h1Match = RegExp(r'<h[12][^>]*>(.*?)</h[12]>', dotAll: true, caseSensitive: false).firstMatch(html);
    if (h1Match != null) {
      final t = _cleanHtmlTags(_unescapeXml(h1Match.group(1)!)).trim();
      if (t.isNotEmpty && t.length < 120) return t;
    }

    // Intentar <title>
    final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>', dotAll: true, caseSensitive: false).firstMatch(html);
    if (titleMatch != null) {
      final t = _cleanHtmlTags(_unescapeXml(titleMatch.group(1)!)).trim();
      if (t.isNotEmpty && t.length < 120) return t;
    }

    return null;
  }

  static String _cleanHtmlTags(String text) {
    return text.replaceAll(RegExp(r'<[^>]+>'), '');
  }

  static String _unescapeXml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#160;', ' ');
  }
}
