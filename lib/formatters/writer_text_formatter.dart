import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WriterTextFormatter {
  /// Counts the total number of words in a text snippet in a single zero-allocation pass
  static int countWords(String text) {
    if (text.isEmpty) return 0;
    int count = 0;
    bool inWord = false;
    final len = text.length;
    for (int i = 0; i < len; i++) {
      final code = text.codeUnitAt(i);
      // Fast check for whitespace: space (32), tab (9), newline (10), CR (13), non-breaking space (0xA0)
      if (code <= 32 || code == 0x00A0) {
        inWord = false;
      } else if (!inWord) {
        inWord = true;
        count++;
      }
    }
    return count;
  }

  /// Counts characters with or without whitespace in a single zero-allocation pass
  static int countCharacters(String text, {bool includeSpaces = true}) {
    if (includeSpaces) {
      return text.length;
    }
    int count = 0;
    final len = text.length;
    for (int i = 0; i < len; i++) {
      final code = text.codeUnitAt(i);
      if (code > 32 && code != 0x00A0) {
        count++;
      }
    }
    return count;
  }

  /// Counts non-empty paragraphs separated by one or more blank lines.
  /// Consecutive lines without a blank line are considered part of the same paragraph.
  static int countParagraphs(String text) {
    if (text.trim().isEmpty) return 0;
    final blocks = text.split(RegExp(r'\n\s*\n+'));
    return blocks.where((block) => block.trim().isNotEmpty).length;
  }

  /// Estimates reading time in minutes (assuming 200 WPM)
  static int estimateReadingTime(String text) {
    final words = countWords(text);
    if (words == 0) return 0;
    final minutes = (words / 200).ceil();
    return minutes;
  }

  /// Formats time in minutes into "Xh Ym" or "X mins"
  static String formatReadingTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min${minutes == 1 ? '' : 's'} read';
    }
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    return '${hours}h ${remainingMins}m read';
  }

  /// Estimates reading time aloud in minutes (assuming 130 WPM)
  static int estimateReadingTimeAloud(String text) {
    final words = countWords(text);
    if (words == 0) return 0;
    return (words / 130).ceil();
  }

  /// Counts non-empty sentences using common punctuation marks (. ! ?)
  static int countSentences(String text) {
    if (text.trim().isEmpty) return 0;
    final matches = RegExp(r'[^.!?]+[.!?]+(\s|$)').allMatches(text);
    final count = matches.length;
    return count > 0 ? count : 1;
  }

  /// Calculates percentage of dialogue vs narrative text based on dialogue lines and quotes
  static Map<String, double> analyzeDialogueVsNarrative(String text) {
    if (text.trim().isEmpty) return {'dialogue': 0.0, 'narrative': 1.0};
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return {'dialogue': 0.0, 'narrative': 1.0};

    int dialogueLines = 0;
    for (final line in lines) {
      if (line.startsWith('—') ||
          line.startsWith('-') ||
          line.startsWith('«') ||
          line.startsWith('"') ||
          line.startsWith('“')) {
        dialogueLines++;
      }
    }
    final ratio = (dialogueLines / lines.length).clamp(0.0, 1.0);
    return {
      'dialogue': ratio,
      'narrative': (1.0 - ratio).clamp(0.0, 1.0),
    };
  }

  /// Analyzes vocabulary richness (ratio of unique words to total words, 0.0 to 1.0)
  static double analyzeVocabularyRichness(String text) {
    if (text.trim().isEmpty) return 0.0;
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();
    if (words.isEmpty) return 0.0;
    final uniqueWords = words.toSet();
    return (uniqueWords.length / words.length).clamp(0.0, 1.0);
  }

  /// Extracts the most frequent meaningful words (filtering common Spanish stopwords)
  static List<MapEntry<String, int>> getTopFrequentWords(String text, {int limit = 8}) {
    if (text.trim().isEmpty) return [];
    const stopWords = {
      'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
      'de', 'del', 'a', 'al', 'en', 'con', 'por', 'para', 'sin', 'sobre',
      'que', 'qué', 'como', 'cómo', 'cual', 'cuál', 'donde', 'dónde',
      'cuando', 'cuándo', 'quien', 'quién', 'y', 'e', 'o', 'u', 'pero',
      'mas', 'más', 'sino', 'aunque', 'porque', 'se', 'me', 'te', 'nos',
      'le', 'les', 'lo', 'su', 'sus', 'mi', 'mis', 'tu', 'tus',
      'este', 'esta', 'estos', 'estas', 'ese', 'esa', 'esos', 'esas',
      'aquel', 'aquella', 'aquello', 'ya', 'no', 'si', 'sí', 'fue', 'era',
      'ha', 'han', 'hay', 'es', 'son', 'ser', 'estar', 'estaba', 'muy',
      'todo', 'toda', 'todos', 'todas', 'cada', 'otro', 'otra', 'otros', 'otras',
    };

    final rawWords = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 3 && !stopWords.contains(w));

    final freqMap = <String, int>{};
    for (final word in rawWords) {
      freqMap[word] = (freqMap[word] ?? 0) + 1;
    }

    final sorted = freqMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Surrounds selected text with bold, italic, etc., or inserts tags
  static void toggleFormat(
    TextEditingController controller,
    String prefix, [
    String? suffix,
  ]) {
    final s = suffix ?? prefix;
    final selection = controller.selection;
    final text = controller.text;

    if (!selection.isValid) {
      // Append at end if selection invalid
      final newText = '$text$prefix$s';
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length - s.length),
      );
      return;
    }

    final start = selection.start;
    final end = selection.end;

    if (start == end) {
      // Insert placeholder
      final newText = text.replaceRange(start, end, '$prefix$s');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + prefix.length),
      );
    } else {
      final selectedText = text.substring(start, end);
      // Check if already formatted
      if (selectedText.startsWith(prefix) && selectedText.endsWith(s) && selectedText.length >= prefix.length + s.length) {
        final unformatted = selectedText.substring(prefix.length, selectedText.length - s.length);
        final newText = text.replaceRange(start, end, unformatted);
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection(
            baseOffset: start,
            extentOffset: start + unformatted.length,
          ),
        );
      } else {
        final formatted = '$prefix$selectedText$s';
        final newText = text.replaceRange(start, end, formatted);
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection(
            baseOffset: start,
            extentOffset: start + formatted.length,
          ),
        );
      }
    }
  }

  /// Inserts or toggles a line prefix like '# ', '## ', '> ', '• ' at current line start
  static void insertLinePrefix(TextEditingController controller, String prefix) {
    final selection = controller.selection;
    final text = controller.text;

    int cursor = selection.isValid ? selection.start : text.length;

    // Find the start of the line
    int lineStart = text.lastIndexOf('\n', cursor > 0 ? cursor - 1 : 0);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;

    final currentLine = text.substring(lineStart, cursor);

    if (currentLine.startsWith(prefix)) {
      // Remove prefix
      final newText = text.replaceRange(lineStart, lineStart + prefix.length, '');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: (cursor - prefix.length).clamp(0, newText.length)),
      );
    } else {
      // Insert prefix
      final newText = text.replaceRange(lineStart, lineStart, prefix);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + prefix.length),
      );
    }
  }

  /// Alias for insertLinePrefix that indicates toggle behavior
  static void toggleLinePrefix(TextEditingController controller, String prefix) =>
      insertLinePrefix(controller, prefix);

  /// Inserts a dialogue em-dash at cursor
  static void insertEmDash(TextEditingController controller) =>
      insertAtCursor(controller, '— ');

  /// Inserts Spanish / literary guillemets « » around selection or at cursor
  static void insertSpanishQuotes(TextEditingController controller) {
    final selection = controller.selection;
    final text = controller.text;
    int start = selection.isValid ? selection.start : text.length;
    int end = selection.isValid ? selection.end : text.length;

    if (start != end) {
      final selected = text.substring(start, end);
      final newText = text.replaceRange(start, end, '« $selected »');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(baseOffset: start + 2, extentOffset: start + 2 + selected.length),
      );
    } else {
      final newText = text.replaceRange(start, end, '«  »');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + 2),
      );
    }
  }

  /// Quick insert raw string at cursor
  static void insertAtCursor(TextEditingController controller, String insertText) {
    final selection = controller.selection;
    final text = controller.text;

    int start = selection.isValid ? selection.start : text.length;
    int end = selection.isValid ? selection.end : text.length;

    final newText = text.replaceRange(start, end, insertText);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + insertText.length),
    );
  }

  /// Inserts or toggles numbered lists (1. , 2. etc.)
  static void insertNumberedList(TextEditingController controller) {
    final selection = controller.selection;
    final text = controller.text;

    if (!selection.isValid) {
      controller.text = '$text\n1. ';
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
      return;
    }

    // If multi-line selection, number all selected lines
    if (selection.start != selection.end && text.substring(selection.start, selection.end).contains('\n')) {
      final selected = text.substring(selection.start, selection.end);
      final lines = selected.split('\n');
      int counter = 1;
      final numberedLines = lines.map((line) {
        final clean = line.replaceFirst(RegExp(r'^\d+\.\s*'), '').replaceFirst(RegExp(r'^-\s*'), '');
        return '${counter++}. $clean';
      }).join('\n');

      final newText = text.replaceRange(selection.start, selection.end, numberedLines);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + numberedLines.length,
        ),
      );
      return;
    }

    // Single line / cursor position
    int cursor = selection.start;
    int lineStart = text.lastIndexOf('\n', cursor > 0 ? cursor - 1 : 0);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;
    final currentLine = text.substring(lineStart, cursor);

    // If already numbered, remove the number
    final numberMatch = RegExp(r'^\d+\.\s*').firstMatch(currentLine);
    if (numberMatch != null) {
      final prefixLen = numberMatch.group(0)!.length;
      final newText = text.replaceRange(lineStart, lineStart + prefixLen, '');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: (cursor - prefixLen).clamp(0, newText.length)),
      );
      return;
    }

    // Determine number by checking previous line
    int nextNumber = 1;
    if (lineStart > 1) {
      final prevLineStart = text.lastIndexOf('\n', lineStart - 2);
      final prevLine = text.substring(prevLineStart == -1 ? 0 : prevLineStart + 1, lineStart - 1);
      final prevMatch = RegExp(r'^(\d+)\.\s*').firstMatch(prevLine);
      if (prevMatch != null) {
        nextNumber = (int.tryParse(prevMatch.group(1)!) ?? 0) + 1;
      }
    }

    final prefix = '$nextNumber. ';
    final newText = text.replaceRange(lineStart, lineStart, prefix);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + prefix.length),
    );
  }

  /// Inserts or toggles checklist / task items (- [ ] )
  static void insertCheckboxList(TextEditingController controller) {
    final selection = controller.selection;
    final text = controller.text;
    int cursor = selection.isValid ? selection.start : text.length;

    int lineStart = text.lastIndexOf('\n', cursor > 0 ? cursor - 1 : 0);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;
    final currentLine = text.substring(lineStart, cursor);

    if (currentLine.startsWith('- [ ] ')) {
      // Toggle to checked
      final newText = text.replaceRange(lineStart, lineStart + 6, '- [x] ');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor),
      );
    } else if (currentLine.startsWith('- [x] ')) {
      // Remove
      final newText = text.replaceRange(lineStart, lineStart + 6, '');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: (cursor - 6).clamp(0, newText.length)),
      );
    } else {
      // Insert
      const prefix = '- [ ] ';
      final newText = text.replaceRange(lineStart, lineStart, prefix);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + prefix.length),
      );
    }
  }

  /// Inserts a scene break / separator line (* * *)
  static void insertSceneBreak(TextEditingController controller) {
    insertAtCursor(controller, '\n\n* * *\n\n');
  }

  /// Formats date in Spanish with safe fallback
  static String formatSpanishDate(DateTime date, {String format = 'EEEE, d MMMM'}) {
    try {
      return DateFormat(format, 'es_ES').format(date);
    } catch (_) {
      final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
      final months = [
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
      ];
      if (format == 'd MMM') {
        final shortMonths = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
        return '${date.day} ${shortMonths[date.month - 1]}';
      }
      return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
    }
  }
}
