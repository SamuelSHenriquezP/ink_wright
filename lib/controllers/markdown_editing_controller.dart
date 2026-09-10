import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../formatters/writer_text_formatter.dart';

/// A high-performance [TextEditingController] that dynamically renders
/// Markdown styling (headers, bold, italics, blockquotes, code, checklists,
/// dialogue dashes, and guillemets) in real-time while the author writes.
///
/// Crucially, all syntax tokens are preserved character-for-character so that
/// the cursor position, IME composing, and selection are never disrupted.
class MarkdownEditingController extends TextEditingController {
  bool isLiveMarkdownEnabled;
  bool isDarkMode;
  bool hideMarkdownSymbols;

  // Performance Cache: Prevents re-running full markdown regex parsing during idle cursor blinking / non-mutating layout passes
  String? _cachedText;
  TextStyle? _cachedStyle;
  bool? _cachedDarkMode;
  bool? _cachedLiveMarkdown;
  bool? _cachedHideMarkdownSymbols;
  bool? _cachedWithComposing;
  TextSpan? _cachedSpan;

  static final String? _monoFontFamily = GoogleFonts.jetBrainsMono().fontFamily;

  MarkdownEditingController({
    super.text,
    this.isLiveMarkdownEnabled = true,
    this.isDarkMode = false,
    this.hideMarkdownSymbols = true,
  });

  void toggleHideMarkdownSymbols() {
    hideMarkdownSymbols = !hideMarkdownSymbols;
    _cachedSpan = null;
    notifyListeners();
  }

  // Quick formatting actions
  void formatBold() => WriterTextFormatter.toggleFormat(this, '**');
  void formatItalic() => WriterTextFormatter.toggleFormat(this, '*');
  void formatStrikethrough() => WriterTextFormatter.toggleFormat(this, '~~');
  void formatHeading(int level) => WriterTextFormatter.toggleLinePrefix(this, '${"#" * level} ');
  void formatBlockquote() => WriterTextFormatter.toggleLinePrefix(this, '> ');
  void formatBulletList() => WriterTextFormatter.toggleLinePrefix(this, '- ');
  void formatCheckboxList() => WriterTextFormatter.insertCheckboxList(this);
  void insertDialogueDash() => WriterTextFormatter.insertEmDash(this);
  void insertSpanishQuotes() => WriterTextFormatter.insertSpanishQuotes(this);

  // Matches inline Markdown patterns within a single line
  static final RegExp _inlineRegex = RegExp(
    r'(\*\*\*(?!\s)[^\*\n]+?(?<!\s)\*\*\*)|' // bold italic ***
    r'(___(?!\s)[^_\n]+?(?<!\s)___)|'       // bold italic ___
    r'(\*\*(?!\s)[^\*\n]+?(?<!\s)\*\*)|'     // bold **
    r'(__(?!\s)[^_\n]+?(?<!\s)__)|'         // bold __
    r'(\*(?!\s)[^\*\n]+?(?<!\s)\*)|'         // italic *
    r'(_(?!\s)[^_\n]+?(?<!\s)_)|'            // italic _
    r'(~~(?!\s)[^~\n]+?(?<!\s)~~)|'          // strikethrough ~~
    r'(`[^`\n]+?`)|'                         // inline code `
    r'(==(?!\s)[^=\n]+?(?<!\s)==)|'          // highlight ==
    r'(«[^»\n]+?»)',                         // guillemets «»
    dotAll: false,
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!isLiveMarkdownEnabled || text.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    if (_cachedSpan != null &&
        _cachedText == text &&
        _cachedStyle == style &&
        _cachedDarkMode == isDarkMode &&
        _cachedLiveMarkdown == isLiveMarkdownEnabled &&
        _cachedHideMarkdownSymbols == hideMarkdownSymbols &&
        _cachedWithComposing == withComposing) {
      return _cachedSpan!;
    }

    final baseStyle = style ??
        TextStyle(
          color: isDarkMode ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          fontSize: 16.5,
          height: 1.65,
        );

    final lines = text.split('\n');
    final List<InlineSpan> spans = [];

    final markerColor = (baseStyle.color ?? (isDarkMode ? Colors.white : Colors.black))
        .withValues(alpha: 0.35);

    final hiddenMarkerStyle = const TextStyle(
      fontSize: 0.001,
      height: 0.001,
      color: Colors.transparent,
      letterSpacing: -1.0,
    );

    bool inCodeBlock = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Check multi-line code block fences
      if (line.trim().startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        spans.add(_buildCodeBlockFenceSpan(line, baseStyle, markerColor));
      } else if (inCodeBlock) {
        spans.add(_buildCodeContentSpan(line, baseStyle));
      } else {
        _parseLine(line, spans, baseStyle, markerColor, hiddenMarkerStyle);
      }

      if (i < lines.length - 1) {
        spans.add(TextSpan(text: '\n', style: baseStyle));
      }
    }

    final result = TextSpan(children: spans, style: baseStyle);
    _cachedText = text;
    _cachedStyle = style;
    _cachedDarkMode = isDarkMode;
    _cachedLiveMarkdown = isLiveMarkdownEnabled;
    _cachedHideMarkdownSymbols = hideMarkdownSymbols;
    _cachedWithComposing = withComposing;
    _cachedSpan = result;
    return result;
  }

  void _parseLine(
    String line,
    List<InlineSpan> spans,
    TextStyle baseStyle,
    Color markerColor,
    TextStyle hiddenMarkerStyle,
  ) {
    if (line.isEmpty) {
      return;
    }

    final lineMarkerStyle = hideMarkdownSymbols
        ? hiddenMarkerStyle
        : baseStyle.copyWith(color: markerColor, fontWeight: FontWeight.normal);

    // 1. Headers
    if (line.startsWith('# ')) {
      final h1Style = baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 16.5) * 1.55,
        fontWeight: FontWeight.bold,
        height: 1.35,
        letterSpacing: -0.4,
      );
      spans.add(TextSpan(
        text: '# ',
        style: lineMarkerStyle,
      ));
      _parseInline(line.substring(2), spans, h1Style, markerColor, hiddenMarkerStyle);
      return;
    }

    if (line.startsWith('## ')) {
      final h2Style = baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 16.5) * 1.32,
        fontWeight: FontWeight.bold,
        height: 1.35,
        letterSpacing: -0.2,
      );
      spans.add(TextSpan(
        text: '## ',
        style: lineMarkerStyle,
      ));
      _parseInline(line.substring(3), spans, h2Style, markerColor, hiddenMarkerStyle);
      return;
    }

    if (line.startsWith('### ')) {
      final h3Style = baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 16.5) * 1.16,
        fontWeight: FontWeight.w700,
        height: 1.35,
      );
      spans.add(TextSpan(
        text: '### ',
        style: lineMarkerStyle,
      ));
      _parseInline(line.substring(4), spans, h3Style, markerColor, hiddenMarkerStyle);
      return;
    }

    if (line.startsWith('#### ')) {
      final h4Style = baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 16.5) * 1.05,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );
      spans.add(TextSpan(
        text: '#### ',
        style: lineMarkerStyle,
      ));
      _parseInline(line.substring(5), spans, h4Style, markerColor, hiddenMarkerStyle);
      return;
    }

    // 2. Blockquotes
    if (line.startsWith('> ') || line == '>') {
      final quoteMarker = line == '>' ? '>' : '> ';
      final quoteStyle = baseStyle.copyWith(
        fontStyle: FontStyle.italic,
        color: (baseStyle.color ?? (isDarkMode ? Colors.white : Colors.black))
            .withValues(alpha: 0.8),
      );
      spans.add(TextSpan(
        text: quoteMarker,
        style: lineMarkerStyle,
      ));
      if (line.length > quoteMarker.length) {
        _parseInline(line.substring(quoteMarker.length), spans, quoteStyle, markerColor, hiddenMarkerStyle);
      }
      return;
    }

    // 3. Task / Checklists
    if (line.startsWith('- [ ] ') || line.startsWith('* [ ] ')) {
      spans.add(TextSpan(
        text: line.substring(0, 6),
        style: baseStyle.copyWith(
          color: markerColor,
          fontWeight: FontWeight.w600,
        ),
      ));
      _parseInline(line.substring(6), spans, baseStyle, markerColor, hiddenMarkerStyle);
      return;
    }

    if (line.startsWith('- [x] ') ||
        line.startsWith('- [X] ') ||
        line.startsWith('* [x] ') ||
        line.startsWith('* [X] ')) {
      final checkedStyle = baseStyle.copyWith(
        decoration: TextDecoration.lineThrough,
        decorationColor: markerColor,
        color: (baseStyle.color ?? (isDarkMode ? Colors.white : Colors.black))
            .withValues(alpha: 0.45),
      );
      spans.add(TextSpan(
        text: line.substring(0, 6),
        style: baseStyle.copyWith(color: markerColor, fontWeight: FontWeight.bold),
      ));
      _parseInline(line.substring(6), spans, checkedStyle, markerColor, hiddenMarkerStyle);
      return;
    }

    // 4. Bullet lists
    if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('+ ')) {
      spans.add(TextSpan(
        text: line.substring(0, 2),
        style: baseStyle.copyWith(color: markerColor, fontWeight: FontWeight.bold),
      ));
      _parseInline(line.substring(2), spans, baseStyle, markerColor, hiddenMarkerStyle);
      return;
    }

    // 5. Numbered lists
    final numMatch = RegExp(r'^(\d+\.\s)').firstMatch(line);
    if (numMatch != null) {
      final prefix = numMatch.group(1)!;
      spans.add(TextSpan(
        text: prefix,
        style: baseStyle.copyWith(color: markerColor, fontWeight: FontWeight.w700),
      ));
      _parseInline(line.substring(prefix.length), spans, baseStyle, markerColor, hiddenMarkerStyle);
      return;
    }

    // 6. Dialogue Dash (Spanish / Literary em-dash)
    if (line.startsWith('— ')) {
      spans.add(TextSpan(
        text: '— ',
        style: baseStyle.copyWith(
          color: baseStyle.color,
          fontWeight: FontWeight.bold,
        ),
      ));
      _parseInline(line.substring(2), spans, baseStyle, markerColor, hiddenMarkerStyle);
      return;
    }

    if (line.startsWith('-- ')) {
      spans.add(TextSpan(
        text: '-- ',
        style: baseStyle.copyWith(color: markerColor, fontWeight: FontWeight.bold),
      ));
      _parseInline(line.substring(3), spans, baseStyle, markerColor, hiddenMarkerStyle);
      return;
    }

    // 7. Scene Break / Separator
    final trimmed = line.trim();
    if (trimmed == '***' || trimmed == '---' || trimmed == '___') {
      spans.add(TextSpan(
        text: line,
        style: baseStyle.copyWith(
          letterSpacing: 6.0,
          color: markerColor,
          fontWeight: FontWeight.bold,
        ),
      ));
      return;
    }

    // 8. Normal line with inline tokens
    _parseInline(line, spans, baseStyle, markerColor, hiddenMarkerStyle);
  }

  void _parseInline(
    String text,
    List<InlineSpan> spans,
    TextStyle currentStyle,
    Color markerColor,
    TextStyle hiddenMarkerStyle,
  ) {
    if (text.isEmpty) return;

    final matches = _inlineRegex.allMatches(text);
    if (matches.isEmpty) {
      spans.add(TextSpan(text: text, style: currentStyle));
      return;
    }

    int lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: currentStyle,
        ));
      }

      final fullMatch = match.group(0)!;
      _formatMatchedToken(fullMatch, spans, currentStyle, markerColor, hiddenMarkerStyle);
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: currentStyle,
      ));
    }
  }

  void _formatMatchedToken(
    String token,
    List<InlineSpan> spans,
    TextStyle currentStyle,
    Color markerColor,
    TextStyle hiddenMarkerStyle,
  ) {
    final markerStyle = hideMarkdownSymbols
        ? hiddenMarkerStyle
        : currentStyle.copyWith(
            color: markerColor,
            fontWeight: FontWeight.normal,
            fontStyle: FontStyle.normal,
            decoration: TextDecoration.none,
          );

    // 1. Bold Italic (***text*** or ___text___)
    if ((token.startsWith('***') && token.endsWith('***')) ||
        (token.startsWith('___') && token.endsWith('___'))) {
      if (token.length >= 6) {
        spans.add(TextSpan(text: token.substring(0, 3), style: markerStyle));
        spans.add(TextSpan(
          text: token.substring(3, token.length - 3),
          style: currentStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ));
        spans.add(TextSpan(text: token.substring(token.length - 3), style: markerStyle));
        return;
      }
    }

    // 2. Bold (**text** or __text__)
    if ((token.startsWith('**') && token.endsWith('**')) ||
        (token.startsWith('__') && token.endsWith('__'))) {
      if (token.length >= 4) {
        spans.add(TextSpan(text: token.substring(0, 2), style: markerStyle));
        spans.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: currentStyle.copyWith(fontWeight: FontWeight.bold),
        ));
        spans.add(TextSpan(text: token.substring(token.length - 2), style: markerStyle));
        return;
      }
    }

    // 3. Italic (*text* or _text_)
    if ((token.startsWith('*') && token.endsWith('*')) ||
        (token.startsWith('_') && token.endsWith('_'))) {
      if (token.length >= 2) {
        spans.add(TextSpan(text: token.substring(0, 1), style: markerStyle));
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: currentStyle.copyWith(fontStyle: FontStyle.italic),
        ));
        spans.add(TextSpan(text: token.substring(token.length - 1), style: markerStyle));
        return;
      }
    }

    // 4. Strikethrough (~~text~~)
    if (token.startsWith('~~') && token.endsWith('~~')) {
      if (token.length >= 4) {
        spans.add(TextSpan(text: '~~', style: markerStyle));
        spans.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: currentStyle.copyWith(
            decoration: TextDecoration.lineThrough,
            decorationColor: markerColor,
          ),
        ));
        spans.add(TextSpan(text: '~~', style: markerStyle));
        return;
      }
    }

    // 5. Inline code (`text`)
    if (token.startsWith('`') && token.endsWith('`')) {
      if (token.length >= 2) {
        final codeStyle = TextStyle(
          fontFamily: _monoFontFamily,
          fontSize: (currentStyle.fontSize ?? 16.0) * 0.88,
          backgroundColor: isDarkMode ? const Color(0xFF262628) : const Color(0xFFEBE8E3),
          color: isDarkMode ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
        );
        spans.add(TextSpan(text: '`', style: markerStyle));
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: codeStyle,
        ));
        spans.add(TextSpan(text: '`', style: markerStyle));
        return;
      }
    }

    // 6. Highlight (==text==)
    if (token.startsWith('==') && token.endsWith('==')) {
      if (token.length >= 4) {
        final highlightStyle = currentStyle.copyWith(
          backgroundColor: isDarkMode ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
        );
        spans.add(TextSpan(text: '==', style: markerStyle));
        spans.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: highlightStyle,
        ));
        spans.add(TextSpan(text: '==', style: markerStyle));
        return;
      }
    }

    // 7. Guillemets («text»)
    if (token.startsWith('«') && token.endsWith('»')) {
      if (token.length >= 2) {
        final quoteCharStyle = currentStyle.copyWith(
          color: markerColor,
          fontWeight: FontWeight.bold,
        );
        spans.add(TextSpan(text: '«', style: quoteCharStyle));
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: currentStyle.copyWith(fontStyle: FontStyle.italic),
        ));
        spans.add(TextSpan(text: '»', style: quoteCharStyle));
        return;
      }
    }

    // Fallback: raw token
    spans.add(TextSpan(text: token, style: currentStyle));
  }

  InlineSpan _buildCodeBlockFenceSpan(String line, TextStyle baseStyle, Color markerColor) {
    return TextSpan(
      text: line,
      style: TextStyle(
        fontFamily: _monoFontFamily,
        fontSize: (baseStyle.fontSize ?? 16.0) * 0.86,
        color: markerColor,
        backgroundColor: isDarkMode ? const Color(0xFF1F1F21) : const Color(0xFFF0EDE6),
      ),
    );
  }

  InlineSpan _buildCodeContentSpan(String line, TextStyle baseStyle) {
    return TextSpan(
      text: line,
      style: TextStyle(
        fontFamily: _monoFontFamily,
        fontSize: (baseStyle.fontSize ?? 16.0) * 0.88,
        color: isDarkMode ? const Color(0xFFE4E4E7) : const Color(0xFF27272A),
        backgroundColor: isDarkMode ? const Color(0xFF1F1F21) : const Color(0xFFF0EDE6),
      ),
    );
  }
}
