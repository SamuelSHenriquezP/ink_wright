import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:ink_wright/formatters/writer_text_formatter.dart';
import 'package:ink_wright/controllers/editor_controller.dart';
import 'package:ink_wright/controllers/markdown_editing_controller.dart';
import 'package:ink_wright/controllers/sprint_controller.dart';
import 'package:ink_wright/models/book_model.dart';
import 'package:ink_wright/models/chapter_model.dart';
import 'package:ink_wright/models/chapter_snapshot_model.dart';
import 'package:ink_wright/models/character_model.dart';
import 'package:ink_wright/models/codex_entry_model.dart';
import 'package:ink_wright/models/idea_snippet_model.dart';
import 'package:ink_wright/models/mind_map_node_model.dart';
import 'package:ink_wright/models/writer_stats_model.dart';
import 'package:ink_wright/services/export_service.dart';
import 'package:ink_wright/services/persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WriterTextFormatter Tests', () {
    test('Word counting logic', () {
      expect(WriterTextFormatter.countWords('Hello world'), equals(2));
      expect(WriterTextFormatter.countWords('   Multiple   spaces   here  '), equals(3));
      expect(WriterTextFormatter.countWords(''), equals(0));
    });

    test('Paragraph counting logic only increments when separated by empty lines', () {
      expect(WriterTextFormatter.countParagraphs(''), equals(0));
      expect(WriterTextFormatter.countParagraphs('   \n  \n  '), equals(0));

      // Single newlines without empty lines are lines/sentences of the SAME paragraph
      const singleNewlineText = 'Tú eres lo más hermoso que tengo\nSeñor.\nY te tengo porque te placio darte a mi.\nTe necesito.';
      expect(WriterTextFormatter.countParagraphs(singleNewlineText), equals(1));

      // Empty line distance separates paragraphs
      const twoParagraphs = 'Primer párrafo con varias líneas.\nSegunda línea del primer párrafo.\n\nSegundo párrafo tras una línea vacía.';
      expect(WriterTextFormatter.countParagraphs(twoParagraphs), equals(2));

      // Multiple blank lines
      const threeParagraphs = 'Párrafo 1.\n\n\nPárrafo 2.\n  \n Párrafo 3.';
      expect(WriterTextFormatter.countParagraphs(threeParagraphs), equals(3));
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

    test('Aloud reading time estimation', () {
      expect(WriterTextFormatter.estimateReadingTimeAloud(''), equals(0));
      expect(WriterTextFormatter.estimateReadingTimeAloud('Palabra ' * 260), equals(2));
    });

    test('Sentence counting logic', () {
      expect(WriterTextFormatter.countSentences(''), equals(0));
      expect(WriterTextFormatter.countSentences('Hola mundo. ¿Cómo estás? ¡Excelente!'), equals(3));
    });

    test('Dialogue vs Narrative analysis', () {
      const sample = '—Hola, dijo Juan.\nEl sol brillaba en lo alto.\n—Nos vemos mañana.';
      final result = WriterTextFormatter.analyzeDialogueVsNarrative(sample);
      expect(result['dialogue'], isNotNull);
      expect(result['narrative'], isNotNull);
      expect(result['dialogue']! + result['narrative']!, closeTo(1.0, 0.01));
      expect(result['dialogue']!, greaterThan(0.5));
    });

    test('Vocabulary richness analysis', () {
      expect(WriterTextFormatter.analyzeVocabularyRichness(''), equals(0.0));
      final richnessAllUnique = WriterTextFormatter.analyzeVocabularyRichness('El cielo azul resplandece');
      expect(richnessAllUnique, equals(1.0));
      final richnessRepeats = WriterTextFormatter.analyzeVocabularyRichness('hola hola hola hola');
      expect(richnessRepeats, equals(0.25));
    });

    test('Top frequent words extraction without stopwords', () {
      const sample = 'El castillo era un castillo oscuro en el bosque y el castillo dominaba el bosque.';
      final top = WriterTextFormatter.getTopFrequentWords(sample, limit: 3);
      final wordKeys = top.map((e) => e.key).toList();
      expect(wordKeys, contains('castillo'));
      expect(wordKeys, contains('bosque'));
      expect(wordKeys, isNot(contains('el')));
      expect(wordKeys, isNot(contains('un')));
    });
  });

  group('ChapterModel Tests', () {
    test('Reading time for 0 words is 0 minutes', () {
      final emptyChapter = ChapterModel(
        id: 'c0',
        bookId: 'b0',
        chapterNumber: 1,
        title: 'Empty',
        content: '',
        lastEdited: DateTime.now(),
      );
      expect(emptyChapter.readingTimeMinutes, equals(0));
    });

    test('Serialization and deserialization', () {
      final chapter = ChapterModel(
        id: 'c1',
        bookId: 'b1',
        chapterNumber: 2,
        title: 'El Valle',
        content: 'El viento silbaba en la noche.',
        lastEdited: DateTime(2026, 9, 7),
        isCompleted: true,
        notes: 'Nota clave',
        povCharacter: 'Silas',
      );

      final map = chapter.toMap();
      final restored = ChapterModel.fromMap(map);

      expect(restored.id, equals(chapter.id));
      expect(restored.title, equals(chapter.title));
      expect(restored.chapterNumber, equals(chapter.chapterNumber));
      expect(restored.isCompleted, isTrue);
      expect(restored.povCharacter, equals('Silas'));
    });
  });

  group('BookModel & Codex Serialization', () {
    test('Book serialization preserves chapters', () {
      final ch = ChapterModel(
        id: 'c1',
        bookId: 'b1',
        chapterNumber: 1,
        title: 'Inicio',
        content: 'Había una vez...',
        lastEdited: DateTime.now(),
      );
      final book = BookModel(
        id: 'b1',
        title: 'El Faro',
        subtitle: 'Novela corta',
        genre: 'Misterio',
        coverEmoji: '🕯️',
        coverColorHex: 0xFF123456,
        targetWordCount: 40000,
        chapters: [ch],
        lastEdited: DateTime.now(),
        status: BookStatus.drafting,
        tags: ['Gótico'],
        synopsis: 'Un faro misterioso.',
      );

      final map = book.toMap();
      final restored = BookModel.fromMap(map);

      expect(restored.title, equals('El Faro'));
      expect(restored.chapters.length, equals(1));
      expect(restored.chapters.first.title, equals('Inicio'));
    });

    test('CodexEntry preserves type properly', () {
      final entry = CodexEntryModel(
        id: 'codex_test',
        bookId: 'b1',
        name: 'Castillo de Niebla',
        type: CodexType.location,
        role: 'Fortaleza',
        description: 'Antigua fortaleza en las cumbres.',
        traits: ['Antiguo'],
        secrets: 'Puerta secreta',
        avatarEmoji: '🏰',
        createdAt: DateTime.now(),
      );

      final map = entry.toMap();
      final restored = CodexEntryModel.fromMap(map);

      expect(restored.type, equals(CodexType.location));
      expect(restored.typeLabel, equals('Lugar'));
      expect(restored.name, equals('Castillo de Niebla'));
    });

    test('IdeaSnippetModel Spanish labels', () {
      final idea = IdeaSnippetModel(
        id: 'i1',
        title: 'Giro',
        content: 'El mayordomo no existía.',
        category: IdeaCategory.plotTwist,
        colorHex: 0,
        createdAt: DateTime.now(),
        tags: ['Pista'],
      );

      expect(idea.categoryLabel, equals('Giro de Trama'));
    });

    test('MindMapNodeModel extensions', () {
      expect(PlotAct.act1Exposition.label, equals('Acto I: Planteamiento'));
      expect(PlotNodeType.turningPoint.label, equals('Punto de Giro'));
    });
  });

  group('EditorController Tests', () {
    test('Initial state loading: only tutorial book exists', () {
      final controller = EditorController();
      expect(controller.allBooks.length, equals(1));
      expect(controller.activeBook.title, equals('Manual del Escritor — Guía de Ink & Wright'));
      expect(controller.activeBook.chapters.length, equals(3));
      // Verify chapter 2 is numbered 2
      expect(controller.activeBook.chapters[1].chapterNumber, equals(2));
      expect(controller.ideas.isNotEmpty, isTrue);
      expect(controller.characters.isNotEmpty, isTrue);
      expect(controller.characters.first.name, equals('Evelyn Vance'));
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

    test('Mind Map isolation per book', () {
      final controller = EditorController();
      final tutorialNodesCount = controller.mindMapNodes.length;
      expect(tutorialNodesCount, equals(3));

      // Create a second novel
      controller.createNewBook('El Laberinto de Cristal', 'Fantasía Oscura', 60000);
      expect(controller.activeBook.title, equals('El Laberinto de Cristal'));

      // New book only has its own premise node
      expect(controller.mindMapNodes.length, equals(1));
      expect(controller.mindMapNodes.first.title.contains('El Laberinto de Cristal'), isTrue);

      // Switch back to tutorial book
      controller.switchBook('b_tutorial');
      expect(controller.mindMapNodes.length, equals(tutorialNodesCount));
      expect(controller.mindMapNodes.first.title.contains('Acto I'), isTrue);
    });

    test('Character creation and book-scoped management', () {
      final controller = EditorController();
      expect(controller.characters.length, equals(1));
      expect(controller.characters.first.name, equals('Evelyn Vance'));

      // Add a new character
      controller.addCharacter(CharacterModel(
        id: 'char_test_1',
        bookId: controller.activeBook.id,
        name: 'Julian Blackwood',
        role: 'Antagonista',
        archetype: 'El Rival Ambicioso',
        writtenBiography: 'Julian fue el rival académico de Evelyn en la Sociedad Cartográfica.',
      ));
      expect(controller.characters.length, equals(2));
      expect(controller.characters.first.name, equals('Julian Blackwood'));

      // Insert character to manuscript editor
      controller.insertCharacterToEditor(controller.characters.first);
      expect(controller.textEditingController.text.contains('Julian Blackwood'), isTrue);
      expect(controller.textEditingController.text.contains('Antagonista'), isTrue);

      // Create a new book and verify character isolation
      controller.createNewBook('Cuentos del Mar', 'Aventuras', 40000);
      expect(controller.characters.isEmpty, isTrue);

      // Switch back to tutorial book
      controller.switchBook('b_tutorial');
      expect(controller.characters.length, equals(2));
    });

    test('Live Markdown toggle on EditorController', () {
      final controller = EditorController();
      expect(controller.isLiveMarkdownEnabled, isTrue);
      controller.toggleLiveMarkdown();
      expect(controller.isLiveMarkdownEnabled, isFalse);
      controller.toggleLiveMarkdown();
      expect(controller.isLiveMarkdownEnabled, isTrue);
    });

    test('Undo and Redo history', () {
      final controller = EditorController();
      final initialText = controller.textEditingController.text;
      expect(controller.canUndo, isFalse);

      // Edit text with space to trigger undo snapshot
      controller.textEditingController.text = '$initialText Nuevo párrafo añadido ';

      expect(controller.canUndo, isTrue);
      controller.undo();
      expect(controller.textEditingController.text, equals(initialText));
      expect(controller.canRedo, isTrue);

      controller.redo();
      expect(controller.textEditingController.text, equals('$initialText Nuevo párrafo añadido '));
    });

    test('Chapter reordering', () {
      final controller = EditorController();
      final title0 = controller.activeBook.chapters[0].title;
      final title1 = controller.activeBook.chapters[1].title;

      // Move chapter 0 to position 1
      controller.reorderChapters(0, 2);

      expect(controller.activeBook.chapters[0].title, equals(title1));
      expect(controller.activeBook.chapters[0].chapterNumber, equals(1));
      expect(controller.activeBook.chapters[1].title, equals(title0));
      expect(controller.activeBook.chapters[1].chapterNumber, equals(2));
    });

    test('deleteChapter removes chapter and maintains sequential numbers', () {
      final controller = EditorController();
      final initialCount = controller.activeBook.chapters.length;
      expect(initialCount, greaterThan(1));

      final targetChapterId = controller.activeBook.chapters[1].id;
      final success = controller.deleteChapter(targetChapterId);

      expect(success, isTrue);
      expect(controller.activeBook.chapters.length, equals(initialCount - 1));
      expect(controller.activeBook.chapters[0].chapterNumber, equals(1));
    });

    test('deleteBook removes book, its nodes and characters', () {
      final controller = EditorController();
      final initialBooks = controller.allBooks.length;

      controller.createNewBook('Libro Temporal', 'Subtítulo', 50000);
      expect(controller.allBooks.length, equals(initialBooks + 1));
      final createdBookId = controller.activeBook.id;

      final success = controller.deleteBook(createdBookId);
      expect(success, isTrue);
      expect(controller.allBooks.any((b) => b.id == createdBookId), isFalse);
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

    testWidgets('hideMarkdownSymbols hides syntax markers while preserving text and formatting', (tester) async {
      final controller = MarkdownEditingController(
        text: '# Título\n**Negrita**\n*Cursiva*\n— Diálogo\n«Cita»',
        hideMarkdownSymbols: true,
      );

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
                // Exact text invariant is strictly preserved
                expect(span.toPlainText(), equals('# Título\n**Negrita**\n*Cursiva*\n— Diálogo\n«Cita»'));

                // Verify hidden markers exist and have transparent color
                bool hasHiddenSpan = false;
                void inspectSpan(InlineSpan s) {
                  if (s is TextSpan) {
                    if (s.style?.color == Colors.transparent) {
                      hasHiddenSpan = true;
                    }
                    if (s.children != null) {
                      for (final child in s.children!) {
                        inspectSpan(child);
                      }
                    }
                  }
                }

                inspectSpan(span);
                expect(hasHiddenSpan, isTrue);

                // Toggle hideMarkdownSymbols
                controller.toggleHideMarkdownSymbols();
                expect(controller.hideMarkdownSymbols, isFalse);

                return Text.rich(span);
              },
            ),
          ),
        ),
      );
    });

    testWidgets('Markdown hidden markers do not apply negative letterSpacing that truncates line edges', (tester) async {
      const sentence = '**Tú** eres lo más hermoso que tengo Señor.';
      final controller = MarkdownEditingController(
        text: sentence,
        hideMarkdownSymbols: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(fontSize: 16.5),
                  withComposing: false,
                );

                expect(span.toPlainText(), equals(sentence));

                // Assert no child span has negative letter spacing
                void checkNoNegativeSpacing(InlineSpan s) {
                  if (s is TextSpan) {
                    final spacing = s.style?.letterSpacing;
                    if (spacing != null) {
                      expect(spacing >= 0.0, isTrue, reason: 'letterSpacing must not be negative');
                    }
                    if (s.children != null) {
                      for (final child in s.children!) {
                        checkNoNegativeSpacing(child);
                      }
                    }
                  }
                }

                checkNoNegativeSpacing(span);
                return Text.rich(span);
              },
            ),
          ),
        ),
      );
    });

    test('MarkdownEditingController format shortcut methods apply formatting', () {
      final controller = MarkdownEditingController(text: 'Palabra');
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 7);

      controller.formatBold();
      expect(controller.text, equals('**Palabra**'));

      // Toggling bold again unwraps it
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 11);
      controller.formatBold();
      expect(controller.text, equals('Palabra'));

      // Test Italic formatting
      final italicController = MarkdownEditingController(text: 'Palabra');
      italicController.selection = const TextSelection(baseOffset: 0, extentOffset: 7);
      italicController.formatItalic();
      expect(italicController.text, equals('*Palabra*'));

      final lineController = MarkdownEditingController(text: 'Capítulo Uno');
      lineController.selection = const TextSelection.collapsed(offset: 0);
      lineController.formatHeading(1);
      expect(lineController.text, equals('# Capítulo Uno'));
    });

    test('EditorController CRUD for Ideas and Codex entries', () {
      final controller = EditorController();
      final initialIdeasCount = controller.ideas.length;
      final initialCodexCount = controller.codexEntries.length;

      // Add Idea
      final idea = IdeaSnippetModel(
        id: 'test_idea_1',
        title: 'Idea de Prueba',
        content: 'Un misterio en el bosque',
        category: IdeaCategory.general,
        colorHex: 0xFF18181B,
        createdAt: DateTime.now(),
        tags: ['Nota'],
      );
      controller.addIdea(idea);
      expect(controller.ideas.length, equals(initialIdeasCount + 1));

      // Update Idea
      final updatedIdea = idea.copyWith(title: 'Idea Modificada');
      controller.updateIdea(updatedIdea);
      expect(controller.ideas.first.title, equals('Idea Modificada'));

      // Delete Idea
      controller.deleteIdea('test_idea_1');
      expect(controller.ideas.length, equals(initialIdeasCount));

      // Add Codex Entry
      final entry = CodexEntryModel(
        id: 'test_codex_1',
        bookId: controller.activeBook.id,
        name: 'Castillo Sombrío',
        type: CodexType.location,
        role: 'Fortaleza antigua',
        description: 'Construido en el siglo XIV',
        traits: ['Antiguo'],
        secrets: '',
        avatarEmoji: '🏰',
        createdAt: DateTime.now(),
      );
      controller.addCodexEntry(entry);
      expect(controller.codexEntries.length, equals(initialCodexCount + 1));

      // Update Codex Entry
      final updatedEntry = entry.copyWith(name: 'Castillo Renovado');
      controller.updateCodexEntry(updatedEntry);
      expect(controller.codexEntries.first.name, equals('Castillo Renovado'));

      // Delete Codex Entry
      controller.deleteCodexEntry('test_codex_1');
      expect(controller.codexEntries.length, equals(initialCodexCount));
    });

    test('Ideas and Codex entries are strictly isolated per book and cascade delete with book', () {
      final controller = EditorController();
      final initialBookId = controller.activeBook.id;

      // Ensure initial book has its own ideas and codex entries
      expect(controller.ideas.every((i) => i.bookId == initialBookId), isTrue);
      expect(controller.codexEntries.every((c) => c.bookId == initialBookId), isTrue);

      // Create a second book
      controller.createNewBook('Segundo Libro', 'Subtítulo', 50000);
      final secondBookId = controller.activeBook.id;
      expect(secondBookId, isNot(equals(initialBookId)));

      // Second book should start with empty ideas and codex entries
      expect(controller.ideas, isEmpty);
      expect(controller.codexEntries, isEmpty);

      // Add idea and codex entry to the second book
      controller.addIdea(IdeaSnippetModel(
        id: 'idea_book_2',
        title: 'Idea Exclusiva Libro 2',
        content: 'Detalles solo para el segundo libro',
        category: IdeaCategory.plotTwist,
        colorHex: 0,
        createdAt: DateTime.now(),
        tags: ['Giro'],
      ));

      controller.addCodexEntry(CodexEntryModel(
        id: 'codex_book_2',
        bookId: secondBookId,
        name: 'Templo Olvidado',
        type: CodexType.location,
        role: 'Lugar místico',
        description: 'Sólo existe en el libro 2',
        traits: ['Místico'],
        secrets: '',
        avatarEmoji: '🏛️',
        createdAt: DateTime.now(),
      ));

      expect(controller.ideas.length, equals(1));
      expect(controller.ideas.first.id, equals('idea_book_2'));
      expect(controller.ideas.first.bookId, equals(secondBookId));

      expect(controller.codexEntries.length, equals(1));
      expect(controller.codexEntries.first.id, equals('codex_book_2'));
      expect(controller.codexEntries.first.bookId, equals(secondBookId));

      // Switch back to initial book
      controller.switchBook(initialBookId);
      expect(controller.activeBook.id, equals(initialBookId));
      expect(controller.ideas.any((i) => i.id == 'idea_book_2'), isFalse);
      expect(controller.codexEntries.any((c) => c.id == 'codex_book_2'), isFalse);

      // Delete the second book -> should cascade delete its ideas and codex entries
      final deleted = controller.deleteBook(secondBookId);
      expect(deleted, isTrue);
      expect(controller.allIdeas.any((i) => i.id == 'idea_book_2'), isFalse);
      expect(controller.allCodexEntries.any((c) => c.id == 'codex_book_2'), isFalse);
    });

    test('EditorController chapter navigation and title update', () {
      final controller = EditorController();
      expect(controller.activeChapterIndex, equals(0));
      expect(controller.hasPreviousChapter, isFalse);
      expect(controller.hasNextChapter, isTrue);

      // Navigate to next chapter
      controller.goToNextChapter();
      expect(controller.activeChapterIndex, equals(1));
      expect(controller.hasPreviousChapter, isTrue);

      // Update chapter title
      controller.updateActiveChapterTitle('Capítulo 2: Renombrado');
      expect(controller.activeChapter.title, equals('Capítulo 2: Renombrado'));

      // Navigate back to previous chapter
      controller.goToPreviousChapter();
      expect(controller.activeChapterIndex, equals(0));
      expect(controller.hasPreviousChapter, isFalse);
    });
  });

  group('ExportService Tests', () {
    test('Export to Markdown generates valid frontmatter and chapters', () {
      final ch = ChapterModel(
        id: 'c1',
        bookId: 'b1',
        chapterNumber: 1,
        title: 'El Amanecer',
        content: 'El sol iluminaba las montañas.',
        lastEdited: DateTime.now(),
      );
      final book = BookModel(
        id: 'b1',
        title: 'Misterio en el Valle',
        subtitle: 'Novela gótica',
        genre: 'Misterio',
        coverEmoji: '🧭',
        coverColorHex: 0,
        targetWordCount: 50000,
        chapters: [ch],
        lastEdited: DateTime.now(),
        status: BookStatus.drafting,
        tags: ['Gótico'],
        synopsis: 'Una historia de misterio.',
      );

      final md = ExportService.exportToMarkdown(book);
      expect(md.contains('---'), isTrue);
      expect(md.contains('title: "Misterio en el Valle"'), isTrue);
      expect(md.contains('## Capítulo 1: El Amanecer'), isTrue);
      expect(md.contains('El sol iluminaba las montañas.'), isTrue);

      final txt = ExportService.exportToPlainText(book);
      expect(txt.contains('MISTERIO EN EL VALLE'), isTrue);
      expect(txt.contains('CAPÍTULO 1 — EL AMANECER'), isTrue);

      final html = ExportService.exportToHtml(book);
      expect(html.contains('<!DOCTYPE html>'), isTrue);
      expect(html.contains('<h1>Misterio en el Valle</h1>'), isTrue);
    });

    test('Export to PDF generates valid PDF bytes with header', () async {
      final ch = ChapterModel(
        id: 'c1',
        bookId: 'b1',
        chapterNumber: 1,
        title: 'El Amanecer',
        content: 'El sol iluminaba las montañas.',
        lastEdited: DateTime.now(),
      );
      final book = BookModel(
        id: 'b1',
        title: 'Misterio en el Valle',
        subtitle: 'Novela gótica',
        genre: 'Misterio',
        coverEmoji: '🧭',
        coverColorHex: 0,
        targetWordCount: 50000,
        chapters: [ch],
        lastEdited: DateTime.now(),
        status: BookStatus.drafting,
        tags: ['Gótico'],
        synopsis: 'Una historia de misterio.',
      );

      final pdfBytes = await ExportService.generatePdf(book);
      expect(pdfBytes, isNotEmpty);
      // Verify PDF magic header: %PDF- (0x25, 0x50, 0x44, 0x46, 0x2D)
      expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));
    });

    test('Export to Word DOCX generates valid OpenXML ZIP archive with document.xml', () {
      final ch = ChapterModel(
        id: 'c1',
        bookId: 'b1',
        chapterNumber: 1,
        title: 'El Amanecer',
        content: 'El sol iluminaba las montañas con destellos dorados.',
        lastEdited: DateTime.now(),
      );
      final book = BookModel(
        id: 'b1',
        title: 'Misterio en el Valle',
        subtitle: 'Novela gótica',
        genre: 'Misterio',
        coverEmoji: '🧭',
        coverColorHex: 0,
        targetWordCount: 50000,
        chapters: [ch],
        lastEdited: DateTime.now(),
        status: BookStatus.drafting,
        tags: ['Gótico'],
        synopsis: 'Una historia de misterio.',
      );

      final docxBytes = ExportService.generateDocx(book);
      expect(docxBytes, isNotEmpty);
      // Verify ZIP magic header: PK (0x50, 0x4B)
      expect(docxBytes.sublist(0, 2), equals([0x50, 0x4B]));

      // Decode OpenXML zip package
      final decodedArchive = ZipDecoder().decodeBytes(docxBytes);
      final fileNames = decodedArchive.map((f) => f.name).toList();

      expect(fileNames.contains('[Content_Types].xml'), isTrue);
      expect(fileNames.contains('_rels/.rels'), isTrue);
      expect(fileNames.contains('word/_rels/document.xml.rels'), isTrue);
      expect(fileNames.contains('word/styles.xml'), isTrue);
      expect(fileNames.contains('word/document.xml'), isTrue);

      final docFile = decodedArchive.firstWhere((f) => f.name == 'word/document.xml');
      final docXmlContent = utf8.decode(docFile.content as List<int>);
      expect(docXmlContent.contains('Misterio en el Valle'), isTrue);
      expect(docXmlContent.contains('Capítulo 1: El Amanecer'), isTrue);
      expect(docXmlContent.contains('El sol iluminaba las montañas'), isTrue);
    });

    test('Export with characters and codex entries creates complete editorial manuscript', () async {
      final ch = ChapterModel(
        id: 'c1',
        bookId: 'b1',
        chapterNumber: 1,
        title: 'El Amanecer',
        content: 'Silas esperó en el muelle… «Todo ha terminado», murmuró.',
        lastEdited: DateTime.now(),
      );
      final book = BookModel(
        id: 'b1',
        title: 'Misterio en el Valle',
        subtitle: 'Novela gótica',
        genre: 'Misterio',
        coverEmoji: '🧭',
        coverColorHex: 0,
        targetWordCount: 50000,
        chapters: [ch],
        lastEdited: DateTime.now(),
        status: BookStatus.drafting,
        tags: ['Gótico'],
        synopsis: 'Una historia de misterio.',
      );
      final character = CharacterModel(
        id: 'char1',
        bookId: 'b1',
        name: 'Silas Thorne',
        role: 'Protagonista',
        archetype: 'El Detective Renuente',
        traits: ['Astuto', 'Solitario'],
        motivation: 'Descubrir la verdad.',
        writtenBiography: 'Silas nació en un pequeño pueblo costero.',
        avatarEmoji: '🕵️‍♂️',
      );
      final codex = CodexEntryModel(
        id: 'cod1',
        bookId: 'b1',
        name: 'El Faro Olvidado',
        type: CodexType.location,
        role: 'Lugar antiguo',
        description: 'Un faro abandonado en los acantilados del norte.',
        traits: ['Peligroso'],
        secrets: 'Oculta una cripta.',
        avatarEmoji: '🏰',
        createdAt: DateTime.now(),
      );

      // Markdown test with characters & codex
      final md = ExportService.exportToMarkdown(book, characters: [character], codexEntries: [codex]);
      expect(md.contains('Dramatis Personae (Personajes)'), isTrue);
      expect(md.contains('Silas Thorne'), isTrue);
      expect(md.contains('Apéndice del Códice'), isTrue);
      expect(md.contains('El Faro Olvidado'), isTrue);

      // PDF export test with ellipsis '…' and emojis (safely sanitized)
      final pdfBytes = await ExportService.generatePdf(book, characters: [character], codexEntries: [codex]);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.sublist(0, 5), equals([0x25, 0x50, 0x44, 0x46, 0x2D]));

      // DOCX export test with characters & codex
      final docxBytes = ExportService.generateDocx(book, characters: [character], codexEntries: [codex]);
      expect(docxBytes, isNotEmpty);
      final decodedArchive = ZipDecoder().decodeBytes(docxBytes);
      final docFile = decodedArchive.firstWhere((f) => f.name == 'word/document.xml');
      final docXmlContent = utf8.decode(docFile.content as List<int>);
      expect(docXmlContent.contains('Dramatis Personae (Personajes)'), isTrue);
      expect(docXmlContent.contains('Silas Thorne'), isTrue);
      expect(docXmlContent.contains('Apéndice del Códice'), isTrue);
      expect(docXmlContent.contains('El Faro Olvidado'), isTrue);
    });
  });

  group('SprintController Tests', () {
    test('Sprint lifecycle and word tracking', () {
      final sprint = SprintController();
      expect(sprint.isSprintActive, isFalse);

      sprint.startSprint(
        durationMinutes: 15,
        targetWords: 100,
        currentContent: 'Cinco palabras para empezar ahora',
      );

      expect(sprint.isSprintActive, isTrue);
      expect(sprint.secondsRemaining, equals(15 * 60));

      // User writes 10 more words
      sprint.onTextUpdated('Cinco palabras para empezar ahora y diez palabras adicionales añadidas por el autor hoy');
      expect(sprint.activeSprint?.wordsWritten, greaterThan(0));

      sprint.stopSprint();
      expect(sprint.isSprintActive, isFalse);
    });
  });

  group('MindMapNodeModel Chapter Linking Tests', () {
    test('MindMapNodeModel links to chapter and serializes correctly', () {
      final node = MindMapNodeModel(
        id: 'node_1',
        bookId: 'b_1',
        title: 'El Descubrimiento',
        description: 'Descripción del punto de giro',
        act: PlotAct.act1Exposition,
        type: PlotNodeType.turningPoint,
        dx: 100,
        dy: 150,
        connectedToIds: [],
        colorHex: 0xFF18181B,
        iconEmoji: '🗺️',
        linkedChapterId: 'ch_101',
      );

      expect(node.linkedChapterId, equals('ch_101'));

      final map = node.toMap();
      expect(map['linkedChapterId'], equals('ch_101'));

      final restored = MindMapNodeModel.fromMap(map);
      expect(restored.linkedChapterId, equals('ch_101'));

      // Test copyWith modifying chapter
      final updated = restored.copyWith(linkedChapterId: 'ch_102');
      expect(updated.linkedChapterId, equals('ch_102'));

      // Test copyWith clearing chapter
      final cleared = updated.copyWith(clearLinkedChapter: true);
      expect(cleared.linkedChapterId, isNull);
    });
  });

  group('Chapter Split and Merge Tests', () {
    test('splitChapter divides content into two chapters preserving numbering', () {
      final controller = EditorController();
      final originalChapterCount = controller.activeBook.chapters.length;
      final activeChapter = controller.activeChapter;
      expect(activeChapter, isNotNull);

      // Set content on active chapter
      controller.textEditingController.text = 'Primera parte del texto.\n\nSegunda parte del texto.';
      controller.saveCurrentSession();

      final splitIndex = 'Primera parte del texto.\n\n'.length;
      final originalId = activeChapter.id;

      controller.splitChapter(originalId, splitIndex, newChapterTitle: 'Parte Dos');

      expect(controller.activeBook.chapters.length, equals(originalChapterCount + 1));

      final firstPart = controller.activeBook.chapters.firstWhere((c) => c.id == originalId);
      expect(firstPart.content.trim(), equals('Primera parte del texto.'));

      final secondPart = controller.activeBook.chapters.firstWhere((c) => c.title == 'Parte Dos');
      expect(secondPart.content.trim(), equals('Segunda parte del texto.'));
      expect(secondPart.chapterNumber, equals(firstPart.chapterNumber + 1));
    });

    test('mergeChapterWithNext combines contents and decrements chapter count', () {
      final controller = EditorController();
      if (controller.activeBook.chapters.length < 2) {
        controller.addNewChapter('Capítulo Adicional');
      }
      final initialCount = controller.activeBook.chapters.length;
      final ch1 = controller.activeBook.chapters[0];
      final ch2 = controller.activeBook.chapters[1];

      final expectedMergedContent = '${ch1.content}\n\n${ch2.content}'.trim();

      controller.mergeChapterWithNext(ch1.id);

      expect(controller.activeBook.chapters.length, equals(initialCount - 1));
      final mergedChapter = controller.activeBook.chapters.firstWhere((c) => c.id == ch1.id);
      expect(mergedChapter.content.trim(), equals(expectedMergedContent));
      expect(controller.activeBook.chapters.any((c) => c.id == ch2.id), isFalse);
    });
  });

  group('Typography and Typewriter Mode Tests', () {
    test('EditorController updates and exposes typography and typewriter settings', () {
      final controller = EditorController();
      expect(controller.fontSize, equals(16.5));
      expect(controller.lineHeight, equals(1.65));
      expect(controller.maxEditorWidth, equals(720.0));
      expect(controller.isTypewriterMode, isFalse);

      controller.setFontSize(22.0);
      expect(controller.fontSize, equals(22.0));

      controller.setLineHeight(2.0);
      expect(controller.lineHeight, equals(2.0));

      controller.setMaxEditorWidth(900.0);
      expect(controller.maxEditorWidth, equals(900.0));

      controller.toggleTypewriterMode();
      expect(controller.isTypewriterMode, isTrue);
    });
  });

  group('EPUB Ebook Generator Tests', () {
    test('generateEpub creates a valid EPUB archive structure conforming to standard', () {
      final ch1 = ChapterModel(
        id: 'ch1',
        bookId: 'b_epub',
        chapterNumber: 1,
        title: 'El Comienzo',
        content: '# El Comienzo\n\nEra una noche oscura y tempestuosa.',
        lastEdited: DateTime.now(),
      );
      final ch2 = ChapterModel(
        id: 'ch2',
        bookId: 'b_epub',
        chapterNumber: 2,
        title: 'La Travesía',
        content: 'El barco zarpó a medianoche rumbo a las islas lejanas.',
        lastEdited: DateTime.now(),
      );
      final book = BookModel(
        id: 'b_epub',
        title: 'Crónicas del Mar',
        subtitle: 'Una odisea literaria',
        genre: 'Aventura',
        coverEmoji: '⛵',
        coverColorHex: 0,
        targetWordCount: 40000,
        chapters: [ch1, ch2],
        lastEdited: DateTime.now(),
        status: BookStatus.drafting,
        tags: ['Aventura', 'Mar'],
        synopsis: 'Una odisea en alta mar.',
      );
      final character = CharacterModel(
        id: 'char_epub',
        bookId: 'b_epub',
        name: 'Capitán Morgan',
        role: 'Protagonista',
      );
      final codex = CodexEntryModel(
        id: 'cod_epub',
        bookId: 'b_epub',
        name: 'El Kraken',
        type: CodexType.lore,
        role: 'Criatura Mítica',
        description: 'Monstruo legendario de las profundidades.',
        traits: ['Gigantesco', 'Hostil'],
        secrets: 'Habita en la Fosa del Abismo.',
        avatarEmoji: '🦑',
        createdAt: DateTime.now(),
      );

      final epubBytes = ExportService.generateEpub(
        book,
        characters: [character],
        codexEntries: [codex],
      );

      expect(epubBytes, isNotEmpty);

      // Verify ZIP package
      final archive = ZipDecoder().decodeBytes(epubBytes);
      final filenames = archive.map((f) => f.name).toList();

      // 1. mimetype must be the very first file and uncompressed
      expect(filenames.first, equals('mimetype'));
      final mimeFile = archive.first;
      expect(mimeFile.compression, equals(CompressionType.none));
      expect(utf8.decode(mimeFile.content as List<int>), equals('application/epub+zip'));

      // 2. META-INF/container.xml
      expect(filenames.contains('META-INF/container.xml'), isTrue);

      // 3. OEBPS content files
      expect(filenames.contains('OEBPS/content.opf'), isTrue);
      expect(filenames.contains('OEBPS/toc.ncx'), isTrue);
      expect(filenames.contains('OEBPS/nav.xhtml'), isTrue);
      expect(filenames.contains('OEBPS/style.css'), isTrue);
      expect(filenames.contains('OEBPS/titlepage.xhtml'), isTrue);
      expect(filenames.contains('OEBPS/chapter_1.xhtml'), isTrue);
      expect(filenames.contains('OEBPS/chapter_2.xhtml'), isTrue);
      expect(filenames.contains('OEBPS/characters.xhtml'), isTrue);
      expect(filenames.contains('OEBPS/codex.xhtml'), isTrue);

      // 4. Inspect content of OPF and chapter
      final opfFile = archive.firstWhere((f) => f.name == 'OEBPS/content.opf');
      final opfText = utf8.decode(opfFile.content as List<int>);
      expect(opfText.contains('Crónicas del Mar'), isTrue);
      expect(opfText.contains('chapter_1.xhtml'), isTrue);
      expect(opfText.contains('characters.xhtml'), isTrue);

      final ch1File = archive.firstWhere((f) => f.name == 'OEBPS/chapter_1.xhtml');
      final ch1Text = utf8.decode(ch1File.content as List<int>);
      expect(ch1Text.contains('El Comienzo'), isTrue);
      expect(ch1Text.contains('Era una noche oscura y tempestuosa.'), isTrue);
    });
  });

  group('Backup and Restore (.inkwright) Tests', () {
    test('generateBackupJson and parseBackupJson round-trip successfully', () {
      final book = BookModel(
        id: 'b_backup_1',
        title: 'La Ciudad Sumergida',
        subtitle: 'Crónica arqueológica',
        genre: 'Ciencia Ficción',
        coverEmoji: '🏛️',
        coverColorHex: 0,
        targetWordCount: 80000,
        chapters: [
          ChapterModel(
            id: 'ch_b1',
            bookId: 'b_backup_1',
            chapterNumber: 1,
            title: 'El Abismo',
            content: 'La sonda descendió a diez mil metros.',
            lastEdited: DateTime.now(),
          ),
        ],
        lastEdited: DateTime.now(),
        status: BookStatus.drafting,
        tags: ['Sci-Fi', 'Misterio'],
        synopsis: 'Una expedición arqueológica submarina.',
      );

      final character = CharacterModel(
        id: 'char_b1',
        bookId: 'b_backup_1',
        name: 'Dra. Aris',
        role: 'Científica en jefe',
      );

      final node = MindMapNodeModel(
        id: 'node_b1',
        bookId: 'b_backup_1',
        title: 'Descenso Inicial',
        description: 'La expedición submarina comienza.',
        act: PlotAct.act1Exposition,
        type: PlotNodeType.turningPoint,
        dx: 50,
        dy: 80,
        connectedToIds: [],
        colorHex: 0xFF18181B,
        iconEmoji: '🌊',
        linkedChapterId: 'ch_b1',
      );

      final codex = CodexEntryModel(
        id: 'cod_b1',
        bookId: 'b_backup_1',
        name: 'Reliquia de Cristal',
        type: CodexType.artifact,
        role: 'Artefacto Alienígena',
        description: 'Estructura cristalina resonante.',
        traits: ['Brillante', 'Resonante'],
        secrets: 'Contiene datos milenarios.',
        avatarEmoji: '🔮',
        createdAt: DateTime.now(),
      );

      final idea = IdeaSnippetModel(
        id: 'idea_b1',
        title: 'Idea de Cristales',
        content: 'Quizá los cristales son una red de comunicación orgánica.',
        category: IdeaCategory.general,
        colorHex: 0xFF18181B,
        createdAt: DateTime.now(),
        tags: ['Misterio'],
      );

      final stats = WriterStatsModel(
        dailyGoalWords: 1000,
        wordsToday: 350,
        streakDays: 5,
        totalWordsWritten: 12000,
        writingTimeTodayMinutes: 45,
        weeklyProgress: {'Lun': 350},
        wordsPerMinuteAvg: 42,
        focusScore: 90,
      );

      final persistence = PersistenceService();
      final jsonString = persistence.generateBackupJson(
        books: [book],
        characters: [character],
        mindMapNodes: [node],
        codexEntries: [codex],
        ideas: [idea],
        writerStats: stats,
        activeBookId: book.id,
        activeChapterId: 'ch_b1',
        isDarkMode: true,
        typewriterMode: true,
      );

      expect(jsonString, isNotEmpty);
      final parsedMap = json.decode(jsonString) as Map<String, dynamic>;
      expect(parsedMap['format'], equals('inkwright_backup'));
      expect(parsedMap['version'], equals('2.0.0'));
      expect(parsedMap.containsKey('books'), isTrue);

      final restoredData = persistence.parseBackupJson(jsonString);
      expect(restoredData, isNotNull);
      final restoredBooks = restoredData!['books'] as List<BookModel>;
      expect(restoredBooks.length, equals(1));
      expect(restoredBooks.first.title, equals('La Ciudad Sumergida'));
      final restoredCharacters = restoredData['characters'] as List<CharacterModel>;
      expect(restoredCharacters.length, equals(1));
      expect(restoredCharacters.first.name, equals('Dra. Aris'));
      final restoredNodes = restoredData['mindMap'] as List<MindMapNodeModel>;
      expect(restoredNodes.length, equals(1));
      expect(restoredNodes.first.linkedChapterId, equals('ch_b1'));
      final restoredCodex = restoredData['codex'] as List<CodexEntryModel>;
      expect(restoredCodex.length, equals(1));
      final restoredIdeas = restoredData['ideas'] as List<IdeaSnippetModel>;
      expect(restoredIdeas.length, equals(1));
      final restoredPrefs = restoredData['preferences'] as Map<String, dynamic>;
      expect(restoredPrefs['typewriterMode'], isTrue);
    });

    test('EditorController export and restore integration', () {
      final controller = EditorController();
      final originalBookTitle = controller.activeBook.title;

      // Export current state
      final exportedJson = controller.exportBackupJson();
      expect(exportedJson.contains(originalBookTitle), isTrue);

      // Mutate controller state
      controller.createNewBook('Mundo Alterno Temporal', 'Fantasía', 50000);
      expect(controller.activeBook.title, equals('Mundo Alterno Temporal'));

      // Restore from original backup JSON
      final restoreSuccess = controller.restoreFromBackupJson(exportedJson);
      expect(restoreSuccess, isTrue);

      // Active state should have reverted
      expect(controller.activeBook.title, equals(originalBookTitle));
    });
  });

  group('Chapter Version History and Snapshots Tests', () {
    test('ChapterSnapshotModel serialization and deserialization', () {
      final now = DateTime.now();
      final snapshot = ChapterSnapshotModel(
        id: 'snap_1',
        chapterId: 'ch_1',
        label: 'Borrador inicial',
        content: 'Había una vez en un reino muy lejano...',
        createdAt: now,
        wordCount: 7,
      );

      final map = snapshot.toMap();
      final restored = ChapterSnapshotModel.fromMap(map);

      expect(restored.id, equals('snap_1'));
      expect(restored.chapterId, equals('ch_1'));
      expect(restored.label, equals('Borrador inicial'));
      expect(restored.content, equals('Había una vez en un reino muy lejano...'));
      expect(restored.wordCount, equals(7));
      expect(restored.createdAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
    });

    test('ChapterModel includes snapshots in serialization', () {
      final snapshot = ChapterSnapshotModel(
        id: 'snap_test',
        chapterId: 'ch_test',
        label: 'Versión 1',
        content: 'Texto congelado',
        createdAt: DateTime.now(),
        wordCount: 2,
      );

      final chapter = ChapterModel(
        id: 'ch_test',
        bookId: 'b_test',
        chapterNumber: 1,
        title: 'Capítulo con Instantáneas',
        content: 'Texto actual en progreso',
        lastEdited: DateTime.now(),
        snapshots: [snapshot],
      );

      final map = chapter.toMap();
      expect(map.containsKey('snapshots'), isTrue);

      final restored = ChapterModel.fromMap(map);
      expect(restored.snapshots.length, equals(1));
      expect(restored.snapshots.first.id, equals('snap_test'));
      expect(restored.snapshots.first.label, equals('Versión 1'));
      expect(restored.snapshots.first.content, equals('Texto congelado'));
    });

    test('EditorController creates chapter snapshot', () {
      final controller = EditorController();
      final activeChapter = controller.activeChapter;
      expect(activeChapter.snapshots, isEmpty);

      controller.textEditingController.text = 'Este es el texto para la instantánea.';
      controller.createChapterSnapshot(activeChapter.id, label: 'Instantánea de prueba');

      expect(controller.activeChapter.snapshots.length, equals(1));
      final created = controller.activeChapter.snapshots.first;
      expect(created.label, equals('Instantánea de prueba'));
      expect(created.content, equals('Este es el texto para la instantánea.'));
      expect(created.wordCount, equals(7));
    });

    test('EditorController restores snapshot with automatic safety backup', () {
      final controller = EditorController();
      final activeChapter = controller.activeChapter;

      // 1. Create a baseline snapshot
      controller.textEditingController.text = 'Texto original v1 antes de cambios.';
      controller.createChapterSnapshot(activeChapter.id, label: 'Versión 1 Original');
      final v1Snapshot = controller.activeChapter.snapshots.first;

      // 2. Modify editor text heavily
      controller.textEditingController.text = 'Texto nuevo y modificado que no queremos perder.';

      // 3. Restore snapshot v1
      controller.restoreChapterSnapshot(activeChapter.id, v1Snapshot.id);

      // Verify active editor content restored to v1
      expect(controller.textEditingController.text, equals('Texto original v1 antes de cambios.'));
      expect(controller.activeChapter.content, equals('Texto original v1 antes de cambios.'));

      // Verify automatic safety backup was generated
      expect(controller.activeChapter.snapshots.length, equals(2));
      final safetyBackup = controller.activeChapter.snapshots.firstWhere(
        (s) => s.label.startsWith('Respaldo previo a restaurar:'),
      );
      expect(safetyBackup.content, equals('Texto nuevo y modificado que no queremos perder.'));
    });

    test('EditorController deletes snapshot', () {
      final controller = EditorController();
      final activeChapter = controller.activeChapter;

      controller.createChapterSnapshot(activeChapter.id, label: 'Instantánea para borrar');
      expect(controller.activeChapter.snapshots.length, equals(1));
      final snapId = controller.activeChapter.snapshots.first.id;

      controller.deleteChapterSnapshot(activeChapter.id, snapId);
      expect(controller.activeChapter.snapshots, isEmpty);
    });

    test('Full persistence backup preserves chapter snapshots', () {
      final controller = EditorController();
      final activeChapter = controller.activeChapter;
      controller.createChapterSnapshot(activeChapter.id, label: 'Instantánea Persistente');

      final exportedJson = controller.exportBackupJson();
      expect(exportedJson.contains('Instantánea Persistente'), isTrue);

      final persistence = PersistenceService();
      final restored = persistence.parseBackupJson(exportedJson);
      expect(restored, isNotNull);
      final books = restored!['books'] as List<BookModel>;
      final ch = books.first.chapters.firstWhere((c) => c.id == activeChapter.id);
      expect(ch.snapshots.length, equals(1));
      expect(ch.snapshots.first.label, equals('Instantánea Persistente'));
    });

    test('EditorController updates daily goal words', () {
      final controller = EditorController();
      expect(controller.writerStats.dailyGoalWords, equals(2000));
      controller.updateDailyGoal(2500);
      expect(controller.writerStats.dailyGoalWords, equals(2500));
    });
  });
}
