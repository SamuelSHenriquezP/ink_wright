import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ink_wright/models/book_compilation_config_model.dart';
import 'package:ink_wright/services/export_service.dart';
import 'package:ink_wright/services/initial_sample_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'EPUB with image cover keeps uncompressed mimetype first and cover first in spine',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'inkwright_cover_test_',
      );
      final image = File('${directory.path}/cover.png');
      await image.writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
        ),
      );
      try {
        final book = InitialSampleDataService.create().activeBook.copyWith(
          compilationConfig: BookCompilationConfig(
            cover: BookCoverConfig(
              title: 'Título de portada',
              author: 'Autora real',
              imagePath: image.path,
              textPosition: CoverTextPosition.top,
              authorPosition: CoverTextPosition.bottom,
            ),
          ),
        );
        final bytes = ExportService.generateEpub(book);
        // Local ZIP file header: compression method is stored at offset 8.
        expect(bytes[8], 0);
        final zip = ZipDecoder().decodeBytes(bytes);
        expect(zip.files.first.name, 'mimetype');
        expect(utf8.decode(zip.files.first.content), 'application/epub+zip');
        expect(zip.findFile('OEBPS/images/cover.png'), isNotNull);
        final cover = utf8.decode(zip.findFile('OEBPS/cover.xhtml')!.content);
        expect(cover, contains('Título de portada'));
        expect(cover, contains('Autora real'));
        final opf = utf8.decode(zip.findFile('OEBPS/content.opf')!.content);
        final spine = opf.substring(opf.indexOf('<spine'));
        expect(
          RegExp(r'<itemref idref="([^"]+)"').firstMatch(spine)!.group(1),
          'cover',
        );
      } finally {
        await image.delete();
        await directory.delete();
      }
    },
  );
}
