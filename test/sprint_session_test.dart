import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ink_wright/controllers/editor_controller.dart';
import 'package:ink_wright/controllers/sprint_controller.dart';
import 'package:ink_wright/controllers/sprint_session.dart';
import 'package:ink_wright/main.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EditorController editor;
  late SprintController sprint;
  late SprintSession session;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 11, 20, 10);
    editor = EditorController();
    await editor.ready;
    editor.textEditingController.text = 'Una frase inicial';
    sprint = SprintController(now: () => now);
    session = SprintSession(editor: editor, sprint: sprint);
  });

  tearDown(() async {
    session.dispose();
    sprint.dispose();
    await editor.flushAndBackup();
    editor.dispose();
  });

  void start() => sprint.startSprint(
    durationMinutes: 1,
    targetWords: 5,
    currentContent: editor.textEditingController.text,
  );

  test('editor changes update sprint progress without opening its dialog', () {
    start();
    editor.textEditingController.text = 'Una frase inicial con dos';
    expect(sprint.activeSprint!.wordsWritten, 2);
    expect(sprint.activeSprint!.progress, 0.4);
    editor.textEditingController.text = 'Una';
    expect(sprint.activeSprint!.wordsWritten, 0);
    sprint.stopSprint();
    sprint.stopSprint();
    expect(editor.sprintHistory.length, 1);
    expect(editor.sprintHistory.single.completed, isFalse);
  });

  test('resume completes overdue sprint and records it exactly once', () {
    start();
    editor.textEditingController.text = 'Una frase inicial con dos';
    now = now.add(const Duration(seconds: 61));
    sprint.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(sprint.secondsRemaining, 0);
    expect(sprint.activeSprint!.isCompleted, isTrue);
    expect(editor.sprintHistory.single.wordsWritten, 2);
    expect(editor.sprintHistory.single.completed, isTrue);
    sprint.didChangeAppLifecycleState(AppLifecycleState.resumed);
    sprint.stopSprint();
    expect(editor.sprintHistory.length, 1);
  });

  test('changing chapters ends sprint against its original chapter', () {
    final original = editor.activeChapter;
    start();
    editor.textEditingController.text = 'Una frase inicial con dos';
    editor.selectChapter(editor.activeBook.chapters[1]);
    expect(sprint.isSprintActive, isFalse);
    expect(editor.sprintHistory.single.chapterId, original.id);
    expect(editor.sprintHistory.single.wordsWritten, 2);
  });

  test('invalid sprint does not replace an active session', () {
    start();
    final original = sprint.activeSprint;
    sprint.startSprint(durationMinutes: 0, targetWords: 5, currentContent: '');
    sprint.startSprint(durationMinutes: 5, targetWords: -1, currentContent: '');
    expect(sprint.activeSprint, same(original));
  });

  testWidgets('legacy PIN preferences do not block launch or resume', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'ink_wright_pin_enabled': true,
      'ink_wright_pin_hash': 'old-hash',
      'ink_wright_pin_salt': 'old-salt',
      'ink_wright_pin_length': 4,
      'ink_wright_sprint_audio_enabled': true,
    });
    await initializeDateFormatting('es_ES', null);
    await tester.pumpWidget(const InkWrightApp());
    await tester.pumpAndSettle();
    expect(find.byType(EditableText), findsWidgets);
    expect(find.textContaining('Ingresa tu PIN'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byType(EditableText), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
    'switching chapters immediately preserves unflushed text and snapshots',
    () async {
      final firstId = editor.activeChapter.id;
      editor.textEditingController.text =
          'Texto escrito justo antes de cambiar';
      editor.selectChapter(editor.activeBook.chapters[1]);
      final saved = editor.activeBook.chapters.firstWhere(
        (c) => c.id == firstId,
      );
      expect(saved.content, 'Texto escrito justo antes de cambiar');
      expect(saved.snapshots, isNotEmpty);
      await editor.flushAndBackup();
      final reopened = EditorController();
      await reopened.ready;
      expect(
        reopened.activeBook.chapters.firstWhere((c) => c.id == firstId).content,
        'Texto escrito justo antes de cambiar',
      );
      reopened.dispose();
    },
  );
}
