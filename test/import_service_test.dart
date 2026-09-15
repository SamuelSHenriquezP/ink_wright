import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ink_wright/controllers/editor_controller.dart';
import 'package:ink_wright/services/import_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ImportService - Markdown & Text Tests', () {
    test('Parsea Markdown con YAML frontmatter y capítulos', () {
      const mdContent = '''---
title: "La Crónica del Viento"
genre: "Fantasía Épica"
synopsis: "Una historia sobre magos y tormentas."
---

# Capítulo 1: El Despertar

El viento soplaba furioso sobre las colinas de plata.
Kaelen ajustó su capa y miró hacia el horizonte.

# Capítulo 2: La Ciudadela

Las murallas de granito se alzaban imponentes contra las nubes negras.
''';

      final result = ImportService.parseMarkdown(mdContent, 'la_cronica.md');

      expect(result.title, equals('La Crónica del Viento'));
      expect(result.genre, equals('Fantasía Épica'));
      expect(result.synopsis, equals('Una historia sobre magos y tormentas.'));
      expect(result.chapters.length, equals(2));
      expect(result.chapters[0].title, equals('Capítulo 1: El Despertar'));
      expect(result.chapters[0].content, contains('El viento soplaba furioso'));
      expect(result.chapters[1].title, equals('Capítulo 2: La Ciudadela'));
      expect(result.chapters[1].content, contains('Las murallas de granito'));
    });

    test('Parsea Texto Plano con delimitadores de capítulos', () {
      const txtContent = '''
Capítulo 1: Sombras en la Niebla
El carruaje avanzaba lentamente por el camino de adoquines.

Capítulo 2: Encuentro Inesperado
Una figura encapuchada esperaba bajo el farol de gas.
''';

      final result = ImportService.parsePlainText(txtContent, 'manuscrito_misterio.txt');

      expect(result.title, equals('Manuscrito Misterio'));
      expect(result.chapters.length, equals(2));
      expect(result.chapters[0].title, equals('Capítulo 1: Sombras en la Niebla'));
      expect(result.chapters[0].content, contains('El carruaje avanzaba lentamente'));
      expect(result.chapters[1].title, equals('Capítulo 2: Encuentro Inesperado'));
    });
  });

  group('ImportService - Docx & EPUB Tests', () {
    test('Parsea archivo docx comprimido con párrafos y títulos', () {
      final docxXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:pPr><w:pStyle w:val="Heading1"/></w:pPr>
      <w:r><w:t>Capítulo 1: Las Cenizas</w:t></w:r>
    </w:p>
    <w:p>
      <w:r><w:t>Todo lo que quedaba del castillo era polvo y recuerdos.</w:t></w:r>
    </w:p>
    <w:p>
      <w:pPr><w:pStyle w:val="Heading1"/></w:pPr>
      <w:r><w:t>Capítulo 2: El Renacer</w:t></w:r>
    </w:p>
    <w:p>
      <w:r><w:t>Entre las ruinas brotó un retoño verde.</w:t></w:r>
    </w:p>
  </w:body>
</w:document>''';

      final archive = Archive();
      archive.addFile(ArchiveFile('word/document.xml', docxXml.length, utf8.encode(docxXml)));
      final zipBytes = ZipEncoder().encode(archive);

      final result = ImportService.parseDocx(Uint8List.fromList(zipBytes), 'novela_cenizas.docx');

      expect(result.title, equals('Novela Cenizas'));
      expect(result.chapters.length, equals(2));
      expect(result.chapters[0].title, equals('Capítulo 1: Las Cenizas'));
      expect(result.chapters[0].content, contains('Todo lo que quedaba del castillo'));
      expect(result.chapters[1].title, equals('Capítulo 2: El Renacer'));
      expect(result.chapters[1].content, contains('Entre las ruinas brotó'));
    });

    test('Parsea archivo EPUB con spine y documentos XHTML', () {
      final containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

      final opfXml = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>El Navegante Solitario</dc:title>
    <dc:creator>Elena Vance</dc:creator>
  </metadata>
  <manifest>
    <item id="ch1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch2" href="chapter2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="ch1"/>
    <itemref idref="ch2"/>
  </spine>
</package>''';

      final ch1Xhtml = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html>
<head><title>Capítulo 1: Zarpando</title></head>
<body>
  <h1>Capítulo 1: Zarpando</h1>
  <p>El barco abandonó el puerto con las velas hinchadas por el viento del este. Los marineros cantaban en la cubierta mientras la costa desaparecía.</p>
</body>
</html>''';

      final ch2Xhtml = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html>
<head><title>Capítulo 2: En Alta Mar</title></head>
<body>
  <h2>Capítulo 2: En Alta Mar</h2>
  <p>Tres días de calma chicha precedieron a la tormenta más violenta que jamás hubieran visto en el archipiélago.</p>
</body>
</html>''';

      final archive = Archive();
      archive.addFile(ArchiveFile('META-INF/container.xml', containerXml.length, utf8.encode(containerXml)));
      archive.addFile(ArchiveFile('OEBPS/content.opf', opfXml.length, utf8.encode(opfXml)));
      archive.addFile(ArchiveFile('OEBPS/chapter1.xhtml', ch1Xhtml.length, utf8.encode(ch1Xhtml)));
      archive.addFile(ArchiveFile('OEBPS/chapter2.xhtml', ch2Xhtml.length, utf8.encode(ch2Xhtml)));
      final zipBytes = ZipEncoder().encode(archive);

      final result = ImportService.parseEpub(Uint8List.fromList(zipBytes), 'navegante.epub');

      expect(result.title, equals('El Navegante Solitario'));
      expect(result.author, equals('Elena Vance'));
      expect(result.chapters.length, equals(2));
      expect(result.chapters[0].title, equals('Capítulo 1: Zarpando'));
      expect(result.chapters[0].content, contains('El barco abandonó el puerto'));
      expect(result.chapters[1].title, equals('Capítulo 2: En Alta Mar'));
      expect(result.chapters[1].content, contains('Tres días de calma chicha'));
    });
  });

  group('EditorController Integration Tests', () {
    test('importNewBook crea un nuevo libro con capítulos y lo activa', () {
      final controller = EditorController();

      final importedData = ImportedBookData(
        title: 'Las Estrellas Lejanas',
        genre: 'Ciencia Ficción',
        chapters: [
          ImportedChapterData(
            title: 'Capítulo 1',
            content: 'La nave nodriza orbitaba la luna helada.',
            chapterNumber: 1,
          ),
          ImportedChapterData(
            title: 'Capítulo 2',
            content: 'El transmisor captó una señal extraña.',
            chapterNumber: 2,
          ),
        ],
      );

      final initialBookCount = controller.allBooks.length;
      controller.importNewBook(importedData);

      expect(controller.allBooks.length, equals(initialBookCount + 1));
      expect(controller.activeBook.title, equals('Las Estrellas Lejanas'));
      expect(controller.activeBook.chapters.length, equals(2));
      expect(controller.activeChapter.title, equals('Capítulo 1'));
      expect(controller.activeChapter.content, equals('La nave nodriza orbitaba la luna helada.'));
    });

    test('importChaptersIntoActiveBook añade capítulos al libro activo', () {
      final controller = EditorController();
      final initialChCount = controller.activeBook.chapters.length;

      final newChapters = [
        ImportedChapterData(
          title: 'Capítulo Extra A',
          content: 'Contenido adicional importado.',
          chapterNumber: 1,
        ),
      ];

      controller.importChaptersIntoActiveBook(newChapters);

      expect(controller.activeBook.chapters.length, equals(initialChCount + 1));
      expect(controller.activeChapter.title, equals('Capítulo Extra A'));
      expect(controller.activeChapter.content, equals('Contenido adicional importado.'));
    });
  });
}

