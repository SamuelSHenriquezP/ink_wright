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

  const KeyboardAccessoryBar({
    super.key,
    required this.textController,
    required this.isDark,
    required this.onToggleZenMode,
    required this.onOpenIdeas,
    required this.onOpenContextDrawer,
    required this.wordCount,
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

  @override
  Widget build(BuildContext context) {
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentMint = isDark ? AppTheme.darkAccentMint : AppTheme.lightAccentMint;

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(30.0), // Pill radius
        border: Border.all(color: borderSubtle, width: 1),
        boxShadow: AppTheme.getSoftShadow(isDark),
      ),
      child: Row(
        children: [
          // Word count pill badge
          GestureDetector(
            onTap: onOpenContextDrawer,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentMint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded, size: 16, color: accentMint),
                  const SizedBox(width: 6),
                  Text(
                    '$wordCount w',
                    style: TextStyle(
                      color: accentMint,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

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
                    tooltip: 'Bold',
                    onTap: () => WriterTextFormatter.toggleFormat(textController, '**'),
                    textPrimary: textPrimary,
                    isBold: true,
                  ),
                  _buildToolButton(
                    iconText: 'I',
                    tooltip: 'Italic',
                    onTap: () => WriterTextFormatter.toggleFormat(textController, '*'),
                    textPrimary: textPrimary,
                    isItalic: true,
                  ),
                  _buildToolButton(
                    iconText: 'H1',
                    tooltip: 'Heading 1',
                    onTap: () => WriterTextFormatter.insertLinePrefix(textController, '# '),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: 'H2',
                    tooltip: 'Heading 2',
                    onTap: () => WriterTextFormatter.insertLinePrefix(textController, '## '),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: '“ ”',
                    tooltip: 'Quote Block',
                    onTap: () => WriterTextFormatter.insertLinePrefix(textController, '> '),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: '•',
                    tooltip: 'Bullet List',
                    onTap: () => WriterTextFormatter.insertLinePrefix(textController, '- '),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: '—',
                    tooltip: 'Em Dash',
                    onTap: () => WriterTextFormatter.insertAtCursor(textController, '—'),
                    textPrimary: textPrimary,
                  ),
                  _buildToolButton(
                    iconText: '«»',
                    tooltip: 'Guillemets',
                    onTap: () => WriterTextFormatter.insertAtCursor(textController, '«  »'),
                    textPrimary: textPrimary,
                  ),
                ],
              ),
            ),
          ),

          Container(height: 20, width: 1, color: borderSubtle),

          // Quick Action Buttons (The Muse AI Spark + Writing Sprint + Zen Focus)
          IconButton(
            icon: const Text('✨', style: TextStyle(fontSize: 16)),
            tooltip: 'The Muse AI Assistant',
            onPressed: () => _openMuseSheet(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

          IconButton(
            icon: Icon(Icons.timer_outlined, size: 18, color: textSecondary),
            tooltip: 'Start Writing Sprint',
            onPressed: () => _openSprintDialog(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

          IconButton(
            icon: Icon(Icons.self_improvement_rounded, size: 20, color: accentMint),
            tooltip: 'Toggle Zen Focus Mode',
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
