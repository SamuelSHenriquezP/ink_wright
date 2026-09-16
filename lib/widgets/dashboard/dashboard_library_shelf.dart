import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controllers/editor_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../screens/zen_editor_screen.dart';
import '../../theme/app_theme.dart';
import '../../formatters/writer_text_formatter.dart';
import '../chapters/new_chapter_modal.dart';
import '../global_search_sheet.dart';
import '../import_manuscript_dialog.dart';
import 'dashboard_book_modals.dart';

class DashboardLibraryShelf extends StatelessWidget {
  final EditorController controller;
  final ThemeController themeController;
  final bool isDark;
  final VoidCallback onOpenBook;
  final VoidCallback onCreateBook;

  const DashboardLibraryShelf({
    super.key,
    required this.controller,
    required this.themeController,
    required this.isDark,
    required this.onOpenBook,
    required this.onCreateBook,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final todayFormatted = WriterTextFormatter.formatSpanishDate(DateTime.now());

    return SliverMainAxisGroup(
      slivers: [
        // Top Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayFormatted.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'InkWright Studio',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Biblioteca de Manuscritos',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: textSecondary,
                      ),
                      tooltip: 'Búsqueda Global',
                      onPressed: () => GlobalSearchSheet.show(context),
                    ),
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        size: 22,
                        color: textSecondary,
                      ),
                      tooltip: isDark ? 'Modo Claro' : 'Modo Oscuro',
                      onPressed: () {
                        themeController.toggleThemeMode();
                        controller.toggleThemeMode();
                      },
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: -0.06, end: 0, curve: Curves.easeOutQuad),
        ),

        // Cabecera de Libros y Acción Nuevo Libro
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tus Libros (${controller.allBooks.length})',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(color: borderSubtle),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      label: const Text('Importar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      onPressed: () => ImportManuscriptDialog.show(context, isDark: isDark),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nuevo Libro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      onPressed: onCreateBook,
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 350.ms)
              .slideX(begin: -0.03, end: 0, curve: Curves.easeOutQuad),
        ),

        // Cuadrícula de Libros de la Biblioteca (Estilo MoonReader)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 16,
              childAspectRatio: 0.67,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == controller.allBooks.length) {
                  // Tarjeta "Nuevo Libro" al final de la estantería
                  return InkWell(
                    onTap: onCreateBook,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderSubtle,
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(Icons.add_rounded, size: 24, color: textPrimary),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Nuevo Libro',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate(delay: (index * 60).ms)
                      .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
                      .scale(
                        begin: const Offset(0.96, 0.96),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutCubic,
                      );
                }

                final book = controller.allBooks[index];
                final isActive = book.id == controller.activeBook.id;
                final targetWords = book.targetWordCount;
                final currentWords = book.currentWordCount;
                final ratio = targetWords > 0 ? (currentWords / targetWords).clamp(0.0, 1.0) : 0.0;
                final percent = (ratio * 100).toInt();

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      controller.switchBook(book.id);
                      onOpenBook();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? (isDark ? Colors.white38 : Colors.black38)
                              : borderSubtle,
                          width: isActive ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Barra superior: Etiqueta y Opciones
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'LIBRO ACTIVO',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: textPrimary,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  'LIBRO',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: textSecondary.withValues(alpha: 0.6),
                                  ),
                                ),
                              if (controller.allBooks.length > 1)
                                InkWell(
                                  onTap: () => DashboardBookModals.showBookOptions(context, controller, book, isDark),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(Icons.more_vert_rounded, size: 16, color: textSecondary),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Portada / Emoji Central
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              book.coverEmoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Título del libro
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.2,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Metadatos (capítulos y palabras)
                          Text(
                            '${book.chapters.length} cap. • ${book.currentWordCount} pal.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),

                          const Spacer(),

                          // Barra de Progreso
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progreso',
                                style: TextStyle(fontSize: 9.5, color: textSecondary, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '$percent%',
                                style: TextStyle(fontSize: 9.5, color: textPrimary, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 4,
                              backgroundColor: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07),
                              valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : Colors.black),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Botones de Acción (Abrir Estudio y Escribir)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textPrimary,
                                    side: BorderSide(color: borderSubtle),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 5),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    controller.switchBook(book.id);
                                    onOpenBook();
                                  },
                                  child: const Text(
                                    'Abrir Estudio',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white : Colors.black,
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  controller.switchBook(book.id);
                                  onOpenBook();
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
                                child: const Text(
                                  'Escribir',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate(delay: (index * 60).ms)
                    .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
                    .scale(
                      begin: const Offset(0.96, 0.96),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutCubic,
                    );
              },
              childCount: controller.allBooks.length + 1,
            ),
          ),
        ),
      ],
    );
  }
}
