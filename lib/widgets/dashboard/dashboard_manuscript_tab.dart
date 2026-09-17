import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../screens/plot_mind_map_screen.dart';
import '../../screens/zen_editor_screen.dart';
import '../../screens/manuscript_reader_screen.dart';
import '../../screens/corkboard_screen.dart';
import '../../theme/app_theme.dart';
import '../chapters/new_chapter_modal.dart';

class DashboardManuscriptTab extends StatelessWidget {
  final EditorController controller;
  final bool isDark;
  final VoidCallback onGoToCharacters;
  final VoidCallback onChangeBook;

  const DashboardManuscriptTab({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onGoToCharacters,
    required this.onChangeBook,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta Principal de Escritura (Hero Writing Card)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: borderSubtle, width: 1.0),
                boxShadow: AppTheme.getSoftShadow(isDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          controller.activeBook.coverEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.activeBook.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${controller.activeBook.chapters.length} capítulos • ${controller.activeBook.currentWordCount} palabras',
                              style: TextStyle(fontSize: 12.5, color: textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Barra de Progreso del Objetivo de Palabras
                  Builder(
                    builder: (context) {
                      final targetWords = controller.activeBook.targetWordCount;
                      final currentWords = controller.activeBook.currentWordCount;
                      final ratio = targetWords > 0 ? (currentWords / targetWords).clamp(0.0, 1.0) : 0.0;
                      final percent = (ratio * 100).toInt();

                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progreso del Libro',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                              ),
                              Text(
                                '$percent% ($currentWords / $targetWords pal.)',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 5,
                              backgroundColor: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07),
                              valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : Colors.black),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // Botón Principal "Continuar Escribiendo"
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: const Text(
                      'Continuar Escribiendo',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Fila de 3 Acciones Secundarias
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderSubtle),
                            minimumSize: const Size(0, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 17),
                          label: const Text(
                            'Capítulo',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            NewChapterModal.show(
                              context,
                              isDark: isDark,
                              onChapterCreated: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderSubtle),
                            minimumSize: const Size(0, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          icon: const Icon(Icons.hub_outlined, size: 16),
                          label: const Text(
                            'Mapa Mental',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PlotMindMapScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderSubtle),
                            minimumSize: const Size(0, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          icon: const Icon(Icons.person_search_rounded, size: 16),
                          label: const Text(
                            'Personajes',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          onPressed: onGoToCharacters,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: const Text(
                        'Cambiar de Libro',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      onPressed: onChangeBook,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Lista de Capítulos del Manuscrito Activo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Capítulos del Manuscrito',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      icon: const Icon(Icons.dashboard_customize_outlined, size: 15),
                      label: const Text(
                        'Corcho',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CorkboardScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      icon: const Icon(Icons.auto_stories_outlined, size: 15),
                      label: const Text(
                        'Lectura',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ManuscriptReaderScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...controller.activeBook.chapters.map((chapter) {
              final isSelected = chapter.id == controller.activeChapter.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  boxShadow: AppTheme.getSoftShadow(isDark),
                ),
                child: Material(
                  color: bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    side: BorderSide(
                      color: isSelected ? (isDark ? Colors.white : Colors.black) : borderSubtle,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${chapter.chapterNumber}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    title: Text(
                      chapter.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${chapter.wordCount} palabras • ${chapter.readingTimeMinutes} min lectura',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: textSecondary),
                    onTap: () {
                      controller.selectChapter(chapter);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                      );
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

