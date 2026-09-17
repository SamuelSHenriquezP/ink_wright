import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../controllers/editor_controller.dart';
import '../controllers/theme_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard/dashboard_book_modals.dart';
import '../widgets/dashboard/dashboard_codex_tab.dart';
import '../widgets/dashboard/dashboard_ideas_tab.dart';
import '../widgets/dashboard/dashboard_library_shelf.dart';
import '../widgets/dashboard/dashboard_manuscript_tab.dart';
import '../widgets/dashboard/dashboard_metrics_tab.dart';
import '../widgets/dashboard/dashboard_tools_tab.dart';
import '../widgets/export_manuscript_dialog.dart';
import '../widgets/global_search_sheet.dart';
import '../widgets/muse_assistant_sheet.dart';
import '../widgets/writing_sprint_dialog.dart';
import 'characters_screen.dart';
import 'plot_mind_map_screen.dart';
import 'zen_editor_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedFilterIndex = 0;
  bool _hasAutoOpenedLastText = false;
  bool _isInsideBookView = false;

  final List<String> _bookFilters = [
    'Manuscrito',
    'Personajes',
    'Mapa de Trama',
    'Códice de Mundo',
    'Notas & Ideas',
    'Métricas',
    'Herramientas',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasAutoOpenedLastText && mounted) {
        _hasAutoOpenedLastText = true;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
        );
      }
    });
  }

  void _openMuseStudio(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MuseAssistantSheet(isDark: isDark),
    );
  }

  void _openSprintDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => WritingSprintDialog(isDark: isDark),
    );
  }

  void _openExportDialog(BuildContext context, bool isDark) {
    ExportManuscriptDialog.show(context, isDark: isDark);
  }

  Future<void> _handleExportBackup(BuildContext context, EditorController controller, bool isDark) async {
    try {
      final backupJson = controller.exportBackupJson();
      final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final filename = 'inkwright_backup_$dateStr.inkwright';

      await Clipboard.setData(ClipboardData(text: backupJson));

      await Printing.sharePdf(
        bytes: Uint8List.fromList(utf8.encode(backupJson)),
        filename: filename,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Respaldo exportado exitosamente ($filename) y copiado al portapapeles.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar respaldo: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final themeController = Provider.of<ThemeController>(context);
    final isDark = themeController.isDarkMode;

    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final bgPrimary = isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary;

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (!_isInsideBookView) ...[
              DashboardLibraryShelf(
                controller: controller,
                themeController: themeController,
                isDark: isDark,
                onOpenBook: () {
                  setState(() {
                    _isInsideBookView = true;
                    _selectedFilterIndex = 0;
                  });
                },
                onCreateBook: () {
                  DashboardBookModals.showCreateBookDialog(
                    context,
                    controller,
                    onBookCreated: () {
                      setState(() {
                        _isInsideBookView = true;
                        _selectedFilterIndex = 0;
                      });
                    },
                  );
                },
              ),
            ] else ...[
              // --- VISTA ESTUDIO DEL LIBRO SELECCIONADO ---
              // Barra de Navegación Estratégica Superior
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      // Botón Estratégico para volver a la biblioteca
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          side: BorderSide(color: borderSubtle),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text(
                          'Biblioteca',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          setState(() {
                            _isInsideBookView = false;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.activeBook.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'InkWright Studio',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
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
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.04, end: 0, curve: Curves.easeOutQuad),
              ),

              // Barra de Filtros Monocromática estilo Píldora
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _bookFilters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedFilterIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark ? Colors.white12 : Colors.black12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _bookFilters[index],
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected
                                    ? (isDark ? Colors.black : Colors.white)
                                    : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 0: MANUSCRITO
              if (_selectedFilterIndex == 0) ...[
                DashboardManuscriptTab(
                  controller: controller,
                  isDark: isDark,
                  onGoToCharacters: () {
                    setState(() {
                      _selectedFilterIndex = 1;
                    });
                  },
                  onChangeBook: () {
                    setState(() {
                      _isInsideBookView = false;
                    });
                  },
                ),
              ],

              // 1: PERSONAJES
              if (_selectedFilterIndex == 1) ...[
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.72,
                    child: const CharactersScreen(isEmbedded: true),
                  ),
                ),
              ],

              // 2: MAPA DE TRAMA
              if (_selectedFilterIndex == 2) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
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
                              const Text('🗺️', style: TextStyle(fontSize: 26)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mapa Mental de Trama',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.3),
                                    ),
                                    Text(
                                      'Lienzo interactivo de nodos, actos y subtramas',
                                      style: TextStyle(fontSize: 12.5, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${controller.mindMapNodes.length} Puntos de Trama configurados para "${controller.activeBook.title}"',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.hub_rounded),
                            label: const Text('Abrir Lienzo del Mapa Mental', style: TextStyle(fontWeight: FontWeight.w700)),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PlotMindMapScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // 3: CÓDICE DE MUNDO
              if (_selectedFilterIndex == 3) ...[
                DashboardCodexTab(
                  controller: controller,
                  isDark: isDark,
                ),
              ],

              // 4: NOTAS & IDEAS
              if (_selectedFilterIndex == 4) ...[
                DashboardIdeasTab(
                  controller: controller,
                  isDark: isDark,
                ),
              ],

              // 5: MÉTRICAS & ESTADÍSTICAS
              if (_selectedFilterIndex == 5) ...[
                DashboardMetricsTab(
                  controller: controller,
                  isDark: isDark,
                ),
              ],

              // 6: HERRAMIENTAS & PRODUCTIVIDAD
              if (_selectedFilterIndex == 6) ...[
                DashboardToolsTab(
                  controller: controller,
                  isDark: isDark,
                  onOpenMuse: () => _openMuseStudio(context, isDark),
                  onOpenSprint: () => _openSprintDialog(context, isDark),
                  onOpenExport: () => _openExportDialog(context, isDark),
                  onExportBackup: () => _handleExportBackup(context, controller, isDark),
                ),
              ],
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      // FAB adaptativo según vista (Biblioteca o Estudio del Manuscrito)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: Icon(!_isInsideBookView ? Icons.add_rounded : Icons.edit_note_rounded),
        label: Text(
          !_isInsideBookView ? 'Nuevo Libro' : 'Escribir',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          if (!_isInsideBookView) {
            DashboardBookModals.showCreateBookDialog(
              context,
              controller,
              onBookCreated: () {
                setState(() {
                  _isInsideBookView = true;
                  _selectedFilterIndex = 0;
                });
              },
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
            );
          }
        },
      ),
    );
  }
}
