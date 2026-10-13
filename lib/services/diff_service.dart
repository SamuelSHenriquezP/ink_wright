/// Types of diff segment
enum DiffType {
  same,
  added,
  deleted,
}

/// A segment in the diff comparison
class DiffSegment {
  final DiffType type;
  final String text;

  const DiffSegment({required this.type, required this.text});

  bool get isSame => type == DiffType.same;
  bool get isAdded => type == DiffType.added;
  bool get isDeleted => type == DiffType.deleted;
}

/// Summary stats of a diff comparison
class DiffStats {
  final int wordsAdded;
  final int wordsDeleted;
  final int wordsUnchanged;
  final int originalWordCount;
  final int currentWordCount;

  const DiffStats({
    required this.wordsAdded,
    required this.wordsDeleted,
    required this.wordsUnchanged,
    required this.originalWordCount,
    required this.currentWordCount,
  });

  int get wordNetDelta => currentWordCount - originalWordCount;
}

/// High-performance text diff service using tokenized LCS algorithm
class DiffService {
  const DiffService._();

  /// Computes a word-level diff between [oldText] and [newText]
  static List<DiffSegment> computeWordDiff(String oldText, String newText) {
    if (oldText == newText) {
      return [DiffSegment(type: DiffType.same, text: oldText)];
    }
    if (oldText.isEmpty) {
      return [DiffSegment(type: DiffType.added, text: newText)];
    }
    if (newText.isEmpty) {
      return [DiffSegment(type: DiffType.deleted, text: oldText)];
    }

    final oldTokens = _tokenize(oldText);
    final newTokens = _tokenize(newText);

    final lcsMatrix = _computeLcsTable(oldTokens, newTokens);
    final List<DiffSegment> rawSegments = [];

    int i = oldTokens.length;
    int j = newTokens.length;

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && oldTokens[i - 1] == newTokens[j - 1]) {
        rawSegments.add(DiffSegment(type: DiffType.same, text: oldTokens[i - 1]));
        i--;
        j--;
      } else if (j > 0 && (i == 0 || lcsMatrix[i][j - 1] >= lcsMatrix[i - 1][j])) {
        rawSegments.add(DiffSegment(type: DiffType.added, text: newTokens[j - 1]));
        j--;
      } else if (i > 0 && (j == 0 || lcsMatrix[i][j - 1] < lcsMatrix[i - 1][j])) {
        rawSegments.add(DiffSegment(type: DiffType.deleted, text: oldTokens[i - 1]));
        i--;
      }
    }

    final reversed = rawSegments.reversed.toList();
    return _collapseSegments(reversed);
  }

  /// Calculates diff summary metrics
  static DiffStats computeStats(List<DiffSegment> segments, int originalWords, int currentWords) {
    int added = 0;
    int deleted = 0;
    int same = 0;

    for (final seg in segments) {
      final count = _countWords(seg.text);
      switch (seg.type) {
        case DiffType.added:
          added += count;
          break;
        case DiffType.deleted:
          deleted += count;
          break;
        case DiffType.same:
          same += count;
          break;
      }
    }

    return DiffStats(
      wordsAdded: added,
      wordsDeleted: deleted,
      wordsUnchanged: same,
      originalWordCount: originalWords,
      currentWordCount: currentWords,
    );
  }

  static List<String> _tokenize(String text) {
    final List<String> tokens = [];
    final pattern = RegExp(r'(\s+|[^\s\w]+|\w+)');
    for (final match in pattern.allMatches(text)) {
      tokens.add(match.group(0)!);
    }
    return tokens;
  }

  static List<List<int>> _computeLcsTable(List<String> a, List<String> b) {
    final int m = a.length;
    final int n = b.length;

    // Allocate 2D matrix
    final table = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          table[i][j] = table[i - 1][j - 1] + 1;
        } else {
          final top = table[i - 1][j];
          final left = table[i][j - 1];
          table[i][j] = top > left ? top : left;
        }
      }
    }
    return table;
  }

  static List<DiffSegment> _collapseSegments(List<DiffSegment> segments) {
    if (segments.isEmpty) return [];

    final List<DiffSegment> collapsed = [];
    DiffType currentType = segments.first.type;
    final buffer = StringBuffer(segments.first.text);

    for (int i = 1; i < segments.length; i++) {
      final seg = segments[i];
      if (seg.type == currentType) {
        buffer.write(seg.text);
      } else {
        collapsed.add(DiffSegment(type: currentType, text: buffer.toString()));
        currentType = seg.type;
        buffer.clear();
        buffer.write(seg.text);
      }
    }

    if (buffer.isNotEmpty) {
      collapsed.add(DiffSegment(type: currentType, text: buffer.toString()));
    }

    return collapsed;
  }

  static int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }
}

