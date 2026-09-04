import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WriterTextFormatter {
  /// Counts the total number of words in a text snippet
  static int countWords(String text) {
    if (text.trim().isEmpty) return 0;
    final cleanText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleanText.split(' ').length;
  }

  /// Counts characters with or without whitespace
  static int countCharacters(String text, {bool includeSpaces = true}) {
    if (includeSpaces) {
      return text.length;
    }
    return text.replaceAll(RegExp(r'\s+'), '').length;
  }

  /// Counts non-empty paragraphs
  static int countParagraphs(String text) {
    if (text.trim().isEmpty) return 0;
    final lines = text.split('\n');
    return lines.where((line) => line.trim().isNotEmpty).length;
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

  /// Inserts a line prefix like '# ', '## ', '> ', '• ' at current line start
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
