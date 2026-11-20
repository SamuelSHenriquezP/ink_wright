import 'editor_controller.dart';
import 'sprint_controller.dart';

/// Keeps sprint progress and history connected while its dialog is closed.
class SprintSession {
  final EditorController editor;
  final SprintController sprint;
  DateTime? _startedAt;
  String? _bookId;
  String? _chapterId;
  String? _chapterTitle;

  SprintSession({required this.editor, required this.sprint}) {
    editor.textEditingController.addListener(_onEditorChanged);
    editor.addListener(_onEditorChanged);
    sprint.addListener(_onSprintChanged);
  }

  void _onEditorChanged() {
    if (!sprint.isSprintActive || _startedAt == null) return;
    if (editor.activeBook.id != _bookId ||
        editor.activeChapter.id != _chapterId) {
      sprint.stopSprint();
      return;
    }
    sprint.onTextUpdated(editor.textEditingController.text);
  }

  void _onSprintChanged() {
    final current = sprint.activeSprint;
    if (current == null) return;
    if (current.isActive && _startedAt != current.startTime) {
      _startedAt = current.startTime;
      _bookId = editor.activeBook.id;
      _chapterId = editor.activeChapter.id;
      _chapterTitle = editor.activeChapter.title;
    } else if (!current.isActive && _startedAt == current.startTime) {
      // Clear before notifying the editor, which can call back into this session.
      _startedAt = null;
      editor.recordSprintHistory(
        durationMinutes: current.durationMinutes,
        targetWords: current.targetWords,
        wordsWritten: current.wordsWritten,
        startTime: current.startTime,
        completed: current.isCompleted,
        bookId: _bookId,
        chapterId: _chapterId,
        chapterTitle: _chapterTitle,
      );
    }
  }

  void dispose() {
    editor.textEditingController.removeListener(_onEditorChanged);
    editor.removeListener(_onEditorChanged);
    sprint.removeListener(_onSprintChanged);
  }
}
