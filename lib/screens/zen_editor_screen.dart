import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../widgets/keyboard_accessory_bar.dart';
import '../widgets/context_drawer_sheet.dart';
import '../widgets/export_manuscript_dialog.dart';
import '../widgets/soundscape_bar.dart';
import '../formatters/writer_text_formatter.dart';

class ZenEditorScreen extends StatefulWidget {
  const ZenEditorScreen({super.key});

  @override
  State<ZenEditorScreen> createState() => _ZenEditorScreenState();
}

class _ZenEditorScreenState extends State<ZenEditorScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showSoundscapeOverlay = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openContextDrawer(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContextDrawerSheet(isDark: isDark),
    );
  }

  void _openExportDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => ExportManuscriptDialog(isDark: isDark),
    );
  }

  TextStyle _getEditorFontTextStyle(String fontName, bool isDark) {
    final color = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    switch (fontName) {
      case 'Merriweather':
        return GoogleFonts.merriweather(fontSize: 16.5, height: 1.65, color: color);
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(fontSize: 17.5, height: 1.6, color: color);
      case 'JetBrains Mono':
        return GoogleFonts.jetBrainsMono(fontSize: 15.0, height: 1.6, color: color);
      case 'Lora':
      default:
        return GoogleFonts.lora(fontSize: 16.5, height: 1.65, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final isDark = controller.isDarkMode;
    final isZen = controller.isZenMode;

    final bgPrimary = isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final accentMint = isDark ? AppTheme.darkAccentMint : AppTheme.lightAccentMint;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    final activeChapter = controller.activeChapter;
    final activeBook = controller.activeBook;
    final content = controller.textEditingController.text;
    final wordCount = WriterTextFormatter.countWords(content);

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Text Editor Canvas
            Positioned.fill(
              child: Column(
                children: [
                  // App Bar (Animated out when Zen mode active)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isZen ? 0 : 64,
                    curve: Curves.easeInOut,
                    child: isZen
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                // Back to Dashboard Button
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                                  onPressed: () => Navigator.of(context).pop(),
                                  tooltip: 'Return to Dashboard',
                                ),
                                const SizedBox(width: 8),

                                // Book & Chapter Title Button (Opens Context Drawer)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _openContextDrawer(context, isDark),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              activeBook.title,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: textSecondary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: textSecondary),
                                          ],
                                        ),
                                        Text(
                                          activeChapter.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: textPrimary,
                                            letterSpacing: -0.2,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Live Word Counter Badge Pill
                                GestureDetector(
                                  onTap: () => _openContextDrawer(context, isDark),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: accentMint.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: accentMint.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      '$wordCount words',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: accentMint,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 4),

                                // Soundscape Toggle Button
                                IconButton(
                                  icon: Icon(
                                    controller.isPlayingAmbience ? Icons.graphic_eq_rounded : Icons.headset_outlined,
                                    size: 20,
                                    color: controller.isPlayingAmbience ? accentMint : textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showSoundscapeOverlay = !_showSoundscapeOverlay;
                                    });
                                  },
                                  tooltip: 'Ambient Soundscapes',
                                ),

                                // Export Manuscript Button
                                IconButton(
                                  icon: Icon(Icons.ios_share_rounded, size: 20, color: textSecondary),
                                  onPressed: () => _openExportDialog(context, isDark),
                                  tooltip: 'Export & Publish Manuscript',
                                ),

                                // Zen Mode Toggle Button
                                IconButton(
                                  icon: Icon(
                                    Icons.self_improvement_rounded,
                                    color: isZen ? accentMint : textSecondary,
                                  ),
                                  onPressed: () => controller.toggleZenMode(),
                                  tooltip: 'Toggle Zen Mode',
                                ),
                              ],
                            ),
                          ),
                  ),

                  if (!isZen) Divider(height: 1, color: borderSubtle),

                  // Soundscape Quick Bar Banner (if toggled)
                  if (_showSoundscapeOverlay && !isZen)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SoundscapeBar(isDark: isDark),
                    ).animate().fadeIn(duration: 200.ms),

                  // Zen Canvas Paper Text Area
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 720),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: TextField(
                          controller: controller.textEditingController,
                          focusNode: controller.focusNode,
                          scrollController: _scrollController,
                          maxLines: null,
                          expands: true,
                          keyboardType: TextInputType.multiline,
                          cursorColor: accentMint,
                          cursorWidth: 2.5,
                          cursorRadius: const Radius.circular(2),
                          style: _getEditorFontTextStyle(controller.selectedFontFamily, isDark),
                          decoration: InputDecoration(
                            hintText: 'Begin writing your story here...',
                            hintStyle: _getEditorFontTextStyle(controller.selectedFontFamily, isDark).copyWith(
                              color: textSecondary.withValues(alpha: 0.4),
                              fontStyle: FontStyle.italic,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Zen Mode Float Restorer (Tap anywhere top corner to restore UI)
            if (isZen)
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.small(
                  backgroundColor: accentMint,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.close_fullscreen_rounded, size: 18),
                  onPressed: () => controller.toggleZenMode(),
                ),
              ).animate().fadeIn(duration: 200.ms),

            // Keyboard Accessory Toolbar (Bottom)
            if (!isZen)
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).viewInsets.bottom,
                child: KeyboardAccessoryBar(
                  textController: controller.textEditingController,
                  isDark: isDark,
                  onToggleZenMode: () => controller.toggleZenMode(),
                  onOpenIdeas: () => _openContextDrawer(context, isDark),
                  onOpenContextDrawer: () => _openContextDrawer(context, isDark),
                  wordCount: wordCount,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
