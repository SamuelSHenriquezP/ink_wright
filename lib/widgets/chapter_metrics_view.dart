import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../formatters/writer_text_formatter.dart';
import 'chapter_history_sheet.dart';
import 'export_manuscript_dialog.dart';

class ChapterMetricsView extends StatelessWidget {
  final EditorController controller;
  final bool isDark;
  final VoidCallback onBackToEditor;

  const ChapterMetricsView({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onBackToEditor,
  });

  @override
  Widget build(BuildContext context) {
    final bgPrimary = isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentColor = isDark ? Colors.white : Colors.black;

    final activeChapter = controller.activeChapter;
    final activeBook = controller.activeBook;
    final content = controller.textEditingController.text;

    // Metrics calculations
    final words = WriterTextFormatter.countWords(content);
    final charsWithSpaces = content.length;
    final charsNoSpaces = WriterTextFormatter.countCharacters(content, includeSpaces: false);
    final paragraphs = WriterTextFormatter.countParagraphs(content);
    final sentences = WriterTextFormatter.countSentences(content);
    final readingTimeSilent = WriterTextFormatter.estimateReadingTime(content);
    final readingTimeAloud = WriterTextFormatter.estimateReadingTimeAloud(content);
    final dialogueMap = WriterTextFormatter.analyzeDialogueVsNarrative(content);
    final dialoguePct = (dialogueMap['dialogue'] ?? 0.0) * 100;
    final narrativePct = (dialogueMap['narrative'] ?? 1.0) * 100;
    final vocabRichness = WriterTextFormatter.analyzeVocabularyRichness(content);
    final topWords = WriterTextFormatter.getTopFrequentWords(content, limit: 8);

    final wordsPerParagraph = paragraphs > 0 ? (words / paragraphs).round() : 0;
    final wordsPerSentence = sentences > 0 ? (words / sentences).round() : 0;

    // Target goal
    final chapterTarget = 2000;
    final progress = (words / chapterTarget).clamp(0.0, 1.0);

    return ColoredBox(
      color: bgPrimary,
      child: Column(
        children: [
          // Top Bar
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderSubtle)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 22),
                  tooltip: 'Volver al Editor',
                  onPressed: onBackToEditor,
                ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Métricas del Capítulo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          '${activeBook.title} • Capítulo ${controller.activeChapterIndex + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '$words pal.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Chapter Title Banner
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'CAPÍTULO ${controller.activeChapterIndex + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: textSecondary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: activeChapter.isCompleted
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  activeChapter.isCompleted ? 'Completado' : 'En progreso',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: activeChapter.isCompleted
                                        ? Colors.green
                                        : textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            activeChapter.title,
                            style: GoogleFonts.lora(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Progress Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Meta de palabras: $words / $chapterTarget',
                                style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2x2 Metric Cards Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.article_outlined,
                            label: 'Palabras Totales',
                            value: '$words',
                            subtitle: '$wordsPerParagraph pal./párrafo',
                            isDark: isDark,
                            bgCard: bgCard,
                            borderSubtle: borderSubtle,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.timer_outlined,
                            label: 'Tiempo de Lectura',
                            value: '$readingTimeSilent min',
                            subtitle: '$readingTimeAloud min en voz alta',
                            isDark: isDark,
                            bgCard: bgCard,
                            borderSubtle: borderSubtle,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.segment_rounded,
                            label: 'Estructura',
                            value: '$paragraphs párrafos',
                            subtitle: '$sentences oraciones ($wordsPerSentence pal./oración)',
                            isDark: isDark,
                            bgCard: bgCard,
                            borderSubtle: borderSubtle,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.text_fields_rounded,
                            label: 'Caracteres',
                            value: '$charsNoSpaces',
                            subtitle: '$charsWithSpaces con espacios',
                            isDark: isDark,
                            bgCard: bgCard,
                            borderSubtle: borderSubtle,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Dialogue vs Narrative Balance
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Equilibrio Diálogo vs Narración',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Icon(Icons.forum_outlined, size: 18, color: textSecondary),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                flex: (dialoguePct * 10).toInt().clamp(1, 1000),
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: (narrativePct * 10).toInt().clamp(1, 1000),
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white24 : Colors.black12,
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Diálogo: ${dialoguePct.toStringAsFixed(1)}%',
                                    style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Narración: ${narrativePct.toStringAsFixed(1)}%',
                                    style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Vocabulary Richness & Style
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Riqueza Léxica',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                '${(vocabRichness * 100).toStringAsFixed(1)}% única',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            vocabRichness > 0.65
                                ? 'Excelente variedad léxica: prosa fluida y rica en sinónimos.'
                                : 'Vocabulario reiterado: considera enriquecer con adjetivos y variantes.',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                          if (topWords.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              'Palabras clave más frecuentes:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: topWords.map((entry) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderSubtle),
                                  ),
                                  child: Text(
                                    '${entry.key} (${entry.value})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.edit_note_rounded, size: 20),
                        label: const Text('Volver al Editor a Escribir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        onPressed: onBackToEditor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textPrimary,
                              side: BorderSide(color: borderSubtle),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.history_rounded, size: 18),
                            label: const Text('Historial', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            onPressed: () {
                              ChapterHistorySheet.show(context, activeChapter, isDark);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textPrimary,
                              side: BorderSide(color: borderSubtle),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.ios_share_rounded, size: 18),
                            label: const Text('Exportar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            onPressed: () {
                              ExportManuscriptDialog.show(context, isDark: isDark);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required bool isDark,
    required Color bgCard,
    required Color borderSubtle,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
