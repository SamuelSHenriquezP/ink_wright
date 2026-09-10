import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../formatters/writer_text_formatter.dart';

class KeyboardAccessoryBar extends StatelessWidget {
  final TextEditingController textController;
  final bool isDark;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback? onAnnotateSelection;
  final VoidCallback? onOpenOptionsSheet;
  final VoidCallback? onCloseKeyboard;

  // Optional legacy parameters for compatibility
  final VoidCallback? onToggleZenMode;
  final VoidCallback? onOpenIdeas;
  final VoidCallback? onOpenContextDrawer;
  final int wordCount;

  const KeyboardAccessoryBar({
    super.key,
    required this.textController,
    required this.isDark,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
    this.onAnnotateSelection,
    this.onOpenOptionsSheet,
    this.onCloseKeyboard,
    this.onToggleZenMode,
    this.onOpenIdeas,
    this.onOpenContextDrawer,
    this.wordCount = 0,
  });

  void _insertSpanishQuotes() {
    final selection = textController.selection;
    final text = textController.text;
    int start = selection.isValid ? selection.start : text.length;
    int end = selection.isValid ? selection.end : text.length;

    if (start != end) {
      final selected = text.substring(start, end);
      final newText = text.replaceRange(start, end, '« $selected »');
      textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(baseOffset: start + 2, extentOffset: start + 2 + selected.length),
      );
    } else {
      final newText = text.replaceRange(start, end, '«  »');
      textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgCard = isDark ? const Color(0xFF1E1E22) : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final keyBg = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bgCard,
        border: Border(
          top: BorderSide(color: borderSubtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Undo / Redo controls (compact)
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(
              Icons.undo_rounded,
              size: 15,
              color: canUndo ? textPrimary : textSecondary.withValues(alpha: 0.25),
            ),
            tooltip: 'Deshacer',
            onPressed: canUndo ? onUndo : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 28),
          ),
          IconButton(
            icon: Icon(
              Icons.redo_rounded,
              size: 15,
              color: canRedo ? textPrimary : textSecondary.withValues(alpha: 0.25),
            ),
            tooltip: 'Rehacer',
            onPressed: canRedo ? onRedo : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 28),
          ),

          Container(height: 20, width: 1, margin: const EdgeInsets.symmetric(horizontal: 4), color: borderSubtle),

          // Center: Rich, scrollable Markdown Formatting Shortcuts
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildKeyButton(
                    label: 'B',
                    tooltip: 'Negrita (**)',
                    onTap: () => WriterTextFormatter.toggleFormat(textController, '**'),
                    textPrimary: textPrimary,
                    keyBg: keyBg,
                    isBold: true,
                  ),
                  _buildKeyButton(
                    label: 'I',
                    tooltip: 'Cursiva (*)',
                    onTap: () => WriterTextFormatter.toggleFormat(textController, '*'),
                    textPrimary: textPrimary,
                    keyBg: keyBg,
                    isItalic: true,
                  ),
                  _buildKeyButton(
                    label: 'H1',
                    tooltip: 'Título 1 (#)',
                    onTap: () => WriterTextFormatter.insertLinePrefix(textController, '# '),
                    textPrimary: textPrimary,
                    keyBg: keyBg,
                    isBold: true,
                  ),
                  _buildKeyButton(
                    label: 'H2',
                    tooltip: 'Título 2 (##)',
                    onTap: () => WriterTextFormatter.insertLinePrefix(textController, '## '),
                    textPrimary: textPrimary,
                    keyBg: keyBg,
                    isBold: true,
                  ),
                  _buildKeyButton(
                    label: 'H3',
                    tooltip: 'Título 3 (###)',
                    onTap: () => WriterTextFormatter.insertLinePrefix(textController, '### '),
                    textPrimary: textPrimary,
                    keyBg: keyBg,
                  ),
                  _buildKeyButton(
                    label: '—',
                    tooltip: 'Raya de diálogo literaria',
                    onTap: () => WriterTextFormatter.insertAtCursor(textController, '— '),
                    textPrimary: textPrimary,
                    keyBg: keyBg,
                    isBold: true,
                  ),
                  _buildKeyButton(
                    label: '« »',
                    tooltip: 'Comillas latinas / españolas',
                    onTap: _insertSpanishQuotes,
                    textPrimary: textPrimary,
                    keyBg: keyBg,
                  ),
                  _buildKeyButton(
                    label: '•',
                    tooltip: 'Lista con viñetas',
                    onTap: () => WriterTextFormatter.insertLinePrefix(textController, '- '),
                    textPrimary: textPrimary,
                    keyBg: keyBg,
                    isBold: true,
                  ),
                  _buildKeyButton(
                    label: '1.',
                    tooltip: 'Lista numerada',
                    onTap: () => WriterTextFormatter.insertNumberedList(textController),
                    textPrimary: textPrimary,
                    keyBg: keyBg,
                  ),
                  _buildKeyButton(
                    label: '☑',
                    tooltip: 'Lista de tareas (- [ ])',
                    onTap: () => WriterTextFormatter.insertCheckboxList(textController),
                    textPrimary: textPrimary,
                    keyBg: keyBg,
                  ),
                  _buildKeyButton(
                    label: '“ ”',
                    tooltip: 'Cita en bloque (>)',
                    onTap: () => WriterTextFormatter.insertLinePrefix(textController, '> '),
                    textPrimary: textPrimary,
                    keyBg: keyBg,
                  ),
                  _buildKeyButton(
                    label: 'S',
                    tooltip: 'Tachado (~~)',
                    onTap: () => WriterTextFormatter.toggleFormat(textController, '~~'),
                    textPrimary: textPrimary,
                    keyBg: keyBg,
                  ),
                  _buildKeyButton(
                    label: '</>',
                    tooltip: 'Código inline (`)',
                    onTap: () => WriterTextFormatter.toggleFormat(textController, '`'),
                    textPrimary: textPrimary,
                    keyBg: keyBg,
                  ),
                  _buildKeyButton(
                    label: '* * *',
                    tooltip: 'Separador de escena',
                    onTap: () => WriterTextFormatter.insertSceneBreak(textController),
                    textPrimary: textPrimary,
                    keyBg: keyBg,
                  ),
                  if (onAnnotateSelection != null)
                    _buildIconKey(
                      icon: Icons.bookmark_add_outlined,
                      tooltip: 'Anotar en Ideas / Códice',
                      onTap: onAnnotateSelection!,
                      textPrimary: textPrimary,
                      keyBg: keyBg,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    ).animate().fadeIn(duration: 150.ms);
  }

  Widget _buildKeyButton({
    required String label,
    required String tooltip,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color keyBg,
    bool isBold = false,
    bool isItalic = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: keyBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: textPrimary,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconKey({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color keyBg,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: keyBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: textPrimary),
          ),
        ),
      ),
    );
  }
}
