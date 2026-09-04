import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ink_wright/formatters/writer_text_formatter.dart';
import 'package:ink_wright/controllers/editor_controller.dart';

void main() {
  group('WriterTextFormatter Tests', () {
    test('Word counting logic', () {
      expect(WriterTextFormatter.countWords('Hello world'), equals(2));
      expect(WriterTextFormatter.countWords('   Multiple   spaces   here  '), equals(3));
      expect(WriterTextFormatter.countWords(''), equals(0));
    });

    test('Reading time estimation', () {
      expect(WriterTextFormatter.estimateReadingTime('Word ' * 400), equals(2));
      expect(WriterTextFormatter.formatReadingTime(45), equals('45 mins read'));
      expect(WriterTextFormatter.formatReadingTime(155), equals('2h 35m read'));
    });

    test('Numbered list formatting', () {
      final ctrl = TextEditingController(text: 'First line\nSecond line');
      ctrl.selection = const TextSelection(baseOffset: 0, extentOffset: 22);
      WriterTextFormatter.insertNumberedList(ctrl);
      expect(ctrl.text, equals('1. First line\n2. Second line'));
    });

    test('Checkbox list formatting', () {
      final ctrl = TextEditingController(text: 'Complete chapter');
      ctrl.selection = const TextSelection.collapsed(offset: 0);
      WriterTextFormatter.insertCheckboxList(ctrl);
      expect(ctrl.text.startsWith('- [ ] '), isTrue);
    });
  });

  group('EditorController Tests', () {
    test('Initial state loading', () {
      final controller = EditorController();
      expect(controller.allBooks.isNotEmpty, isTrue);
      expect(controller.activeBook.title, equals('The Cipher of St. Jude'));
      expect(controller.ideas.isNotEmpty, isTrue);
      expect(controller.isZenMode, isFalse);
    });

    test('Theme toggle action', () {
      final controller = EditorController();
      final initialMode = controller.isDarkMode;
      controller.toggleThemeMode();
      expect(controller.isDarkMode, equals(!initialMode));
    });

    test('Zen mode toggle action', () {
      final controller = EditorController();
      controller.toggleZenMode();
      expect(controller.isZenMode, isTrue);
    });
  });
}
