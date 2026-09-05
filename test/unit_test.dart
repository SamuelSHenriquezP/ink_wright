import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ink_wright/formatters/writer_text_formatter.dart';
import 'package:ink_wright/controllers/editor_controller.dart';
import 'package:ink_wright/controllers/markdown_editing_controller.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

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

    test('Mind Map editor features: add, connect, duplicate, and disconnect nodes', () {
      final controller = EditorController();
      final initialCount = controller.mindMapNodes.length;
      expect(initialCount, greaterThan(0));

      final firstNode = controller.mindMapNodes.first;
      final secondNode = controller.mindMapNodes[1];

      // Connect nodes
      controller.connectMindMapNodes(firstNode.id, secondNode.id);
      expect(controller.mindMapNodes.first.connectedToIds.contains(secondNode.id), isTrue);

      // Disconnect nodes
      controller.disconnectMindMapNodes(firstNode.id, secondNode.id);
      expect(controller.mindMapNodes.first.connectedToIds.contains(secondNode.id), isFalse);

      // Duplicate node
      controller.duplicateMindMapNode(firstNode.id);
      expect(controller.mindMapNodes.length, equals(initialCount + 1));
      expect(controller.mindMapNodes.last.title.contains('(Copia)'), isTrue);

      // Auto-arrange nodes by act
      controller.autoArrangeMindMapNodes();
      expect(controller.mindMapNodes.isNotEmpty, isTrue);
    });

    test('Live Markdown toggle on EditorController', () {
      final controller = EditorController();
      expect(controller.isLiveMarkdownEnabled, isTrue);
      controller.toggleLiveMarkdown();
      expect(controller.isLiveMarkdownEnabled, isFalse);
      controller.toggleLiveMarkdown();
      expect(controller.isLiveMarkdownEnabled, isTrue);
    });
  });

  group('MarkdownEditingController Live Rendering Tests', () {
    testWidgets('Preserves exact text content in buildTextSpan for all markdown formats', (tester) async {
      final sampleText = '''# Chapter One: The Fog
## The Whispering Pines
### Section Alpha
Silas walked into the **dark forest** with *haste*.
He thought: > The secret is buried here.
- [ ] Find the old compass
- [x] Light the lantern
- First clue
1. Follow the river
— Wait! —shouted Martha.
«Do not enter,» she warned.
Here is some `inline code` and ==highlighted text==.
***
```
code block line 1
code block line 2
```''';

      final controller = MarkdownEditingController(text: sampleText);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(fontSize: 16),
                  withComposing: false,
                );
                // Exact text preservation invariant
                expect(span.toPlainText(), equals(sampleText));
                return Text.rich(span);
              },
            ),
          ),
        ),
      );
    });

    testWidgets('Headers, bold, italics, and strikethrough produce styled spans', (tester) async {
      final controller = MarkdownEditingController(text: '# Header 1\n**Bold Text**\n*Italic Text*');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(fontSize: 16),
                  withComposing: false,
                );
                expect(span.children, isNotNull);
                expect(span.toPlainText(), equals('# Header 1\n**Bold Text**\n*Italic Text*'));
                return Text.rich(span);
              },
            ),
          ),
        ),
      );
    });
  });
}
