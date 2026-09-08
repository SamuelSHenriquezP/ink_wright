import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../formatters/writer_text_formatter.dart';
import 'muse_assistant_sheet.dart';
import 'writing_sprint_dialog.dart';

class KeyboardAccessoryBar extends StatelessWidget {
  final TextEditingController textController;
  final bool isDark;
  final VoidCallback onToggleZenMode;
  final VoidCallback onOpenIdeas;
  final VoidCallback onOpenContextDrawer;
  final int wordCount;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  const KeyboardAccessoryBar({
    super.key,
    required this.textController,
    required this.isDark,
    required this.onToggleZenMode,
    required this.onOpenIdeas,
    required this.onOpenContextDrawer,
    required this.wordCount,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
  });

  void _openMuseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MuseAssistantSheet(isDark: isDark),
    );
  }

  void _openSprintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => WritingSprintDialog(isDark: isDark),
    );
  }

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
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: borderSubtle, width: 1),
        boxShadow: AppTheme.getSoftShadow(isDark),
      ),
      child: Row(
        children: [
          // Word count pill badge
          GestureDetector(
            onTap: onOpenContextDrawer,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded, size: 16, color: textPrimary),
                  const SizedBox(width: 4),
                  Text(
                    '$wordCount p',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Undo / Redo buttons
          IconButton(
            icon: Icon(
              Icons.undo_rounded,
              size: 18,
              color: canUndo ? textPrimary : textSecondary.withValues(alpha: 0.3),
            ),
            tooltip: 'Deshacer',
            onPressed: canUndo ? onUndo : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          IconButton(
            icon: Icon(
              Icons.redo_rounded,
              size: 18,
              color: canRedo ? textPrimary : textSecondary.withValues(alpha: 0.3),
            ),
            tooltip: 'Rehacer',
            onPressed: canRedo ? onRedo : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),

          Container(height: 20, width: 1, color: borderSubtle),

          // Scrollable Quick Toolbar
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  _buildToolButton(
                    iconText: 'B',
                    tooltip: 'Negrita',
                    onTap: () => WriterTextFormatter.toggleFormat(textController, '**'),
                    textPrimary: textPrimary,
                    isBold: true,
                  ),
                  _buildToolButton(
                    iconText: 'I',
                    tooltip: 'Cursiva',
                    onTap: () => WriterTextFormatter.toggleFormat(textController, '*'),
                    textPrimary: textPrimary,
                    isItalic: true,
                  ),
                  _buildToolButton(
                    iconText: 'S',
                    tooltip: 'Tachado',
                    onTap: () => WriterTextFormatter.toggleFormat(textController, '~~'),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: 'H1',
                    tooltip: 'Título 1',
                    onTap: () => WriterTextFormatter.insertLinePrefix(textController, '# '),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: 'H2',
                    tooltip: 'Título 2',
                    onTap: () => WriterTextFormatter.insertLinePrefix(textController, '## '),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: 'H3',
                    tooltip: 'Título 3',
                    onTap: () => WriterTextFormatter.insertLinePrefix(textController, '### '),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: '•',
                    tooltip: 'Lista con viñetas',
                    onTap: () => WriterTextFormatter.insertLinePrefix(textController, '- '),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: '1.',
                    tooltip: 'Lista numerada',
                    onTap: () => WriterTextFormatter.insertNumberedList(textController),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: '☑',
                    tooltip: 'Lista de verificación / tareas',
                    onTap: () => WriterTextFormatter.insertCheckboxList(textController),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: '“ ”',
                    tooltip: 'Cita textual',
                    onTap: () => WriterTextFormatter.insertLinePrefix(textController, '> '),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: '* * *',
                    tooltip: 'Salto / Separador de escena',
                    onTap: () => WriterTextFormatter.insertSceneBreak(textController),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: '</>',
                    tooltip: 'Código / Texto fijo',
                    onTap: () => WriterTextFormatter.toggleFormat(textController, '`'),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: '—',
                    tooltip: 'Raya de diálogo',
                    onTap: () => WriterTextFormatter.insertAtCursor(textController, '— '),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: '«»',
                    tooltip: 'Comillas españolas',
                    onTap: _insertSpanishQuotes,
                    textPrimary: textPrimary,
                  ),
                ],
              ),
            ),
          ),

          Container(height: 20, width: 1, color: borderSubtle),

          // Quick Action Buttons (Writing Tools + Writing Sprint + Zen Focus)
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
            tooltip: 'Herramientas de Escritura',
            onPressed: () => _openMuseSheet(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

          IconButton(
            icon: Icon(Icons.timer_outlined, size: 18, color: textSecondary),
            tooltip: 'Sprint de Escritura',
            onPressed: () => _openSprintDialog(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

          IconButton(
            icon: Icon(Icons.fullscreen_rounded, size: 22, color: textPrimary),
            tooltip: 'Pantalla Completa',
            onPressed: onToggleZenMode,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildToolButton({
    required String iconText,
    required String tooltip,
    required VoidCallback onTap,
    required Color textPrimary,
    bool isBold = false,
    bool isItalic = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          child: Text(
            iconText,
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ),
    );
  }
}
