import '../models/chapter_model.dart';
import '../models/chapter_snapshot_model.dart';
import '../formatters/writer_text_formatter.dart';

/// Result returned when a chapter is successfully split.
class SplitChapterResult {
  final List<ChapterModel> updatedChapters;
  final ChapterModel updatedOriginal;
  final ChapterModel newChapter;
  final int originalIndex;

  const SplitChapterResult({
    required this.updatedChapters,
    required this.updatedOriginal,
    required this.newChapter,
    required this.originalIndex,
  });
}

/// Result returned when two consecutive chapters are merged.
class MergeChapterResult {
  final List<ChapterModel> updatedChapters;
  final ChapterModel mergedChapter;
  final String mergedContent;
  final String deletedChapterId;
  final int mergedIndex;

  const MergeChapterResult({
    required this.updatedChapters,
    required this.mergedChapter,
    required this.mergedContent,
    required this.deletedChapterId,
    required this.mergedIndex,
  });
}

/// Result returned when a snapshot is restored.
class RestoreSnapshotResult {
  final List<ChapterModel> updatedChapters;
  final ChapterModel restoredChapter;
  final ChapterSnapshotModel safetySnapshot;
  final int chapterIndex;

  const RestoreSnapshotResult({
    required this.updatedChapters,
    required this.restoredChapter,
    required this.safetySnapshot,
    required this.chapterIndex,
  });
}

/// Service that handles non-destructive chapter calculations, splits, merges, reorders, and snapshots.
class ChapterOperationsService {
  const ChapterOperationsService._();

  /// Moves a chapter from [oldIndex] to [newIndex] and returns a reindexed list of chapters.
  static List<ChapterModel> moveChapter(
    List<ChapterModel> chapters,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex == newIndex || oldIndex < 0 || oldIndex >= chapters.length) {
      return chapters;
    }
    final List<ChapterModel> reordered = List.from(chapters);
    final ChapterModel moved = reordered.removeAt(oldIndex);
    final targetIndex = newIndex.clamp(0, reordered.length);
    reordered.insert(targetIndex, moved);

    return _reindex(reordered);
  }

  /// Removes [chapterId] and reindexes remaining chapters sequentially.
  static List<ChapterModel> removeAndReindex(
    List<ChapterModel> chapters,
    String chapterId,
  ) {
    final updated = chapters.where((ch) => ch.id != chapterId).toList();
    return _reindex(updated);
  }

  /// Splits [chapterId] at [splitPosition] into two chapters.
  static SplitChapterResult? splitChapter({
    required List<ChapterModel> chapters,
    required String bookId,
    required String chapterId,
    required int splitPosition,
    required String currentContent,
    String? newChapterTitle,
  }) {
    final chapterIndex = chapters.indexWhere((ch) => ch.id == chapterId);
    if (chapterIndex == -1) return null;

    final targetChapter = chapters[chapterIndex];
    final clampedPos = splitPosition.clamp(0, currentContent.length);
    final part1 = currentContent.substring(0, clampedPos).trimRight();
    final part2 = currentContent.substring(clampedPos).trimLeft();

    final now = DateTime.now();
    final updatedOriginal = targetChapter.copyWith(
      content: part1,
      lastEdited: now,
    );

    final newChapterNum = chapterIndex + 2;
    final fallbackTitle = '${targetChapter.title} (Parte 2)';
    final newChapter = ChapterModel(
      id: 'ch_${now.millisecondsSinceEpoch}',
      bookId: bookId,
      chapterNumber: newChapterNum,
      title: (newChapterTitle != null && newChapterTitle.trim().isNotEmpty)
          ? newChapterTitle.trim()
          : fallbackTitle,
      content: part2,
      lastEdited: now,
      notes: '',
      povCharacter: targetChapter.povCharacter,
    );

    final updatedChapters = List<ChapterModel>.from(chapters);
    updatedChapters[chapterIndex] = updatedOriginal;
    updatedChapters.insert(chapterIndex + 1, newChapter);

    final reindexed = _reindex(updatedChapters);

    return SplitChapterResult(
      updatedChapters: reindexed,
      updatedOriginal: reindexed[chapterIndex],
      newChapter: reindexed[chapterIndex + 1],
      originalIndex: chapterIndex,
    );
  }

  /// Merges [chapterId] with the subsequent chapter in [chapters].
  static MergeChapterResult? mergeChapterWithNext({
    required List<ChapterModel> chapters,
    required String chapterId,
    required String currentChapterContent,
    required String nextChapterContent,
  }) {
    final chapterIndex = chapters.indexWhere((ch) => ch.id == chapterId);
    if (chapterIndex == -1 || chapterIndex >= chapters.length - 1) {
      return null;
    }

    final current = chapters[chapterIndex];
    final next = chapters[chapterIndex + 1];

    final separator = (currentChapterContent.isEmpty || nextChapterContent.isEmpty) ? '' : '\n\n';
    final mergedContent = '$currentChapterContent$separator$nextChapterContent';

    final mergedChapter = current.copyWith(
      content: mergedContent,
      lastEdited: DateTime.now(),
    );

    final updatedChapters = List<ChapterModel>.from(chapters);
    updatedChapters[chapterIndex] = mergedChapter;
    updatedChapters.removeAt(chapterIndex + 1);

    final reindexed = _reindex(updatedChapters);

    return MergeChapterResult(
      updatedChapters: reindexed,
      mergedChapter: reindexed[chapterIndex],
      mergedContent: mergedContent,
      deletedChapterId: next.id,
      mergedIndex: chapterIndex,
    );
  }

  /// Creates a new snapshot for [targetChapter].
  static ChapterSnapshotModel createSnapshot({
    required ChapterModel targetChapter,
    required String content,
    String? label,
  }) {
    final now = DateTime.now();
    final defaultLabel = 'Versión del ${WriterTextFormatter.formatSpanishDate(now)}';
    return ChapterSnapshotModel(
      id: 'snap_${now.millisecondsSinceEpoch}',
      chapterId: targetChapter.id,
      label: (label != null && label.trim().isNotEmpty) ? label.trim() : defaultLabel,
      content: content,
      createdAt: now,
      wordCount: WriterTextFormatter.countWords(content),
    );
  }

  /// Restores a snapshot and generates an automatic safety snapshot of [currentContent].
  static RestoreSnapshotResult? restoreSnapshot({
    required List<ChapterModel> chapters,
    required String chapterId,
    required String snapshotId,
    required String currentContent,
  }) {
    final index = chapters.indexWhere((c) => c.id == chapterId);
    if (index == -1) return null;

    final targetChapter = chapters[index];
    final snapshotIndex = targetChapter.snapshots.indexWhere((s) => s.id == snapshotId);
    if (snapshotIndex == -1) return null;

    final targetSnapshot = targetChapter.snapshots[snapshotIndex];
    final now = DateTime.now();
    final safetyLabel = 'Respaldo previo a restaurar: ${targetSnapshot.label}';
    final safetySnapshot = ChapterSnapshotModel(
      id: 'snap_auto_${now.millisecondsSinceEpoch}',
      chapterId: chapterId,
      label: safetyLabel,
      content: currentContent,
      createdAt: now,
      wordCount: WriterTextFormatter.countWords(currentContent),
    );

    final updatedSnapshots = List<ChapterSnapshotModel>.from(targetChapter.snapshots)
      ..insert(0, safetySnapshot);

    final restoredChapter = targetChapter.copyWith(
      content: targetSnapshot.content,
      lastEdited: now,
      snapshots: updatedSnapshots,
    );

    final updatedChapters = List<ChapterModel>.from(chapters);
    updatedChapters[index] = restoredChapter;

    return RestoreSnapshotResult(
      updatedChapters: updatedChapters,
      restoredChapter: restoredChapter,
      safetySnapshot: safetySnapshot,
      chapterIndex: index,
    );
  }

  /// Deletes a snapshot from a chapter's list of snapshots.
  static List<ChapterSnapshotModel> deleteSnapshot({
    required ChapterModel chapter,
    required String snapshotId,
  }) {
    return chapter.snapshots.where((s) => s.id != snapshotId).toList();
  }

  static List<ChapterModel> _reindex(List<ChapterModel> list) {
    final reindexed = <ChapterModel>[];
    for (int i = 0; i < list.length; i++) {
      reindexed.add(list[i].copyWith(chapterNumber: i + 1));
    }
    return reindexed;
  }
}

