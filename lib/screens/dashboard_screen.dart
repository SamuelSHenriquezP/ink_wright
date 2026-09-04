import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../widgets/book_card.dart';
import '../widgets/idea_chip_card.dart';
import '../widgets/codex_card.dart';
import '../widgets/soundscape_bar.dart';
import '../widgets/muse_assistant_sheet.dart';
import '../widgets/writing_sprint_dialog.dart';
import '../widgets/export_manuscript_dialog.dart';
import '../models/idea_snippet_model.dart';
import '../models/codex_entry_model.dart';
import '../formatters/writer_text_formatter.dart';
import '../widgets/progress_ring_card.dart';
import 'zen_editor_screen.dart';
import 'plot_mind_map_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    'Manuscrito Activo',
    'Tus Libros',
    'Mapa de Trama',
    'Códice de Mundo',
    'Notas & Ideas',
    'Métricas',
    'Herramientas',
  ];

  void _openMetricsSheet(BuildContext context, EditorController controller, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ProgressRingCard(stats: controller.writerStats, isDark: isDark),
            ],
          ),
        );
      },
    );
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
    showDialog(
      context: context,
      builder: (_) => ExportManuscriptDialog(isDark: isDark),
    );
  }

  void _showCreateBookDialog(BuildContext context, EditorController controller) {
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '80000');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nuevo Manuscrito', style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título del Libro'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subCtrl,
                  decoration: const InputDecoration(labelText: 'Subtítulo / Género'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Objetivo de Palabras'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isNotEmpty) {
                  final target = int.tryParse(targetCtrl.text) ?? 80000;
                  controller.createNewBook(title, subCtrl.text.trim(), target);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Crear Libro'),
            ),
          ],
        );
      },
    );
  }

  void _showAddIdeaDialog(BuildContext context, EditorController controller) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nueva Nota o Fragmento', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Título de la Nota'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Contenido del Fragmento'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isNotEmpty) {
                  final newIdea = IdeaSnippetModel(
                    id: 'idea_${DateTime.now().millisecondsSinceEpoch}',
                    title: title,
                    content: contentCtrl.text.trim(),
                    category: IdeaCategory.general,
                    colorHex: 0xFF18181B,
                    createdAt: DateTime.now(),
                    tags: ['Nota'],
                  );
                  controller.addIdea(newIdea);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Guardar Nota'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCodexDialog(BuildContext context, EditorController controller) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    CodexType category = CodexType.character;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Entrada al Códice de Mundo', style: TextStyle(fontWeight: FontWeight.w800)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre de Personaje / Lugar'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CodexType>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: CodexType.values.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Descripción / Biografía'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isNotEmpty) {
                      final newEntry = CodexEntryModel(
                        id: 'codex_${DateTime.now().millisecondsSinceEpoch}',
                        bookId: controller.activeBook.id,
                        name: title,
                        type: CodexType.character,
                        role: 'Personaje / Elemento',
                        description: descCtrl.text.trim(),
                        traits: ['Manuscrito'],
                        secrets: '',
                        avatarEmoji: '👤',
                        createdAt: DateTime.now(),
                      );
                      controller.addCodexEntry(newEntry);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final isDark = controller.isDarkMode;

    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final bgPrimary = isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary;

    final todayFormatted = WriterTextFormatter.formatSpanishDate(DateTime.now());

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header Minimalista Superior
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todayFormatted.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'InkWright Studio',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    // Iconos de Acceso Rápido
                    Row(
                      children: [
                        // Asistente Muse
                        Container(
                          decoration: BoxDecoration(
                            color: bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderSubtle),
                            boxShadow: AppTheme.getSoftShadow(isDark),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                            onPressed: () => _openMuseStudio(context, isDark),
                            tooltip: 'Herramientas de Escritura',
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Mapa de Trama
                        Container(
                          decoration: BoxDecoration(
                            color: bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderSubtle),
                            boxShadow: AppTheme.getSoftShadow(isDark),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.hub_outlined, size: 18),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PlotMindMapScreen()),
                              );
                            },
                            tooltip: 'Mapa Mental de Trama',
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Métricas y Estadísticas
                        Container(
                          decoration: BoxDecoration(
                            color: bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderSubtle),
                            boxShadow: AppTheme.getSoftShadow(isDark),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.insights_rounded, size: 18),
                            onPressed: () => _openMetricsSheet(context, controller, isDark),
                            tooltip: 'Métricas de Escritura',
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Modo Noche / Día
                        Container(
                          decoration: BoxDecoration(
                            color: bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderSubtle),
                            boxShadow: AppTheme.getSoftShadow(isDark),
                          ),
                          child: IconButton(
                            icon: Icon(
                              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              size: 18,
                              color: textPrimary,
                            ),
                            onPressed: () => controller.toggleThemeMode(),
                            tooltip: 'Cambiar Tema',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Barra de Filtros Monocromática estilo Píldora
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedFilterIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilterIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : bgCard,
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : borderSubtle,
                          ),
                          boxShadow: isSelected ? AppTheme.getSoftShadow(isDark) : null,
                        ),
                        child: Center(
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // SECCIÓN 0: MANUSCRITO ACTIVO Y ESCRITURA DIRECTA
            if (_selectedFilterIndex == 0) ...[
              // Tarjeta Principal de Escritura (Hero Writing Card)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderSubtle, width: 1.5),
                      boxShadow: AppTheme.getSoftShadow(isDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              controller.activeBook.coverEmoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.activeBook.title,
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${controller.activeBook.chapters.length} capítulos • ${controller.activeBook.currentWordCount} palabras totales',
                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Botón Prominente "Continuar Escribiendo"
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                          label: const Text(
                            'Continuar Escribiendo en Editor Zen',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderSubtle),
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Añadir Nuevo Capítulo'),
                          onPressed: () {
                            controller.addNewChapter('Nuevo Capítulo');
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Mini Tarjeta de Métrica Diaria (Opción menor y discreta)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openMetricsSheet(context, controller, isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderSubtle),
                        boxShadow: AppTheme.getSoftShadow(isDark),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.insights_rounded, size: 16, color: textPrimary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Meta diaria: ${controller.writerStats.wordsToday} / ${controller.writerStats.dailyGoalWords} pal.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${controller.writerStats.dailyPercentage}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: controller.writerStats.dailyGoalRatio,
                                    minHeight: 4,
                                    backgroundColor: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                                    valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 18)),

              // Lista de Capítulos del Manuscrito Activo
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capítulos del Manuscrito',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...controller.activeBook.chapters.map((chapter) {
                        final isSelected = chapter.id == controller.activeChapter.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppTheme.getSoftShadow(isDark),
                          ),
                          child: Material(
                            color: bgCard,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
                                shape: BoxShape.circle,
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
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${chapter.wordCount} palabras • ${chapter.readingTimeMinutes} min lectura',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textSecondary),
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
              ),
            ],

            // SECCIÓN 1: TUS LIBROS / PROYECTOS
            if (_selectedFilterIndex == 1) ...[
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tus Manuscritos y Libros',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded),
                            onPressed: () => _showCreateBookDialog(context, controller),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: controller.allBooks.length,
                        itemBuilder: (context, index) {
                          final book = controller.allBooks[index];
                          return BookCard(
                            book: book,
                            isDark: isDark,
                            onTap: () {
                              controller.switchBook(book.id);
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // SECCIÓN 2: MAPA DE TRAMA BANNER
            if (_selectedFilterIndex == 2) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderSubtle, width: 1.5),
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
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
                                  ),
                                  Text(
                                    'Lienzo interactivo de nodos, actos y subtramas',
                                    style: TextStyle(fontSize: 12, color: textSecondary),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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

            // SECCIÓN 3: CÓDICE DE MUNDO
            if (_selectedFilterIndex == 3) ...[
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Códice de Mundo',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: textPrimary),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Nueva Entrada'),
                            onPressed: () => _showAddCodexDialog(context, controller),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 190,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: controller.codexEntries.length,
                        itemBuilder: (context, index) {
                          final entry = controller.codexEntries[index];
                          return CodexCard(
                            entry: entry,
                            isDark: isDark,
                            onTap: () {
                              controller.insertTextToEditor(
                                '\n/* Referencia Códice: ${entry.name} */\n${entry.description}\n',
                              );
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // SECCIÓN 4: NOTAS & IDEAS
            if (_selectedFilterIndex == 4) ...[
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Notas & Fragmentos',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: textPrimary),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Nueva Nota'),
                            onPressed: () => _showAddIdeaDialog(context, controller),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 155,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: controller.ideas.length,
                        itemBuilder: (context, index) {
                          final idea = controller.ideas[index];
                          return IdeaChipCard(
                            idea: idea,
                            isDark: isDark,
                            onPinTap: () => controller.toggleIdeaPin(idea.id),
                            onTap: () {
                              controller.insertIdeaToEditor(idea);
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // SECCIÓN 5: MÉTRICAS & ESTADÍSTICAS (Opción menor)
            if (_selectedFilterIndex == 5) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Métricas y Estadísticas de Escritura',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Progreso diario, velocidad y constancia semanal',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ProgressRingCard(
                        stats: controller.writerStats,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // SECCIÓN 6: HERRAMIENTAS & AMBIENTE
            if (_selectedFilterIndex == 6) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SoundscapeBar(isDark: isDark),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textPrimary,
                                side: BorderSide(color: borderSubtle),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              icon: const Icon(Icons.timer_outlined, size: 18),
                              label: const Text('Sprint de Escritura'),
                              onPressed: () => _openSprintDialog(context, isDark),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textPrimary,
                                side: BorderSide(color: borderSubtle),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              icon: const Icon(Icons.ios_share_rounded, size: 18),
                              label: const Text('Exportar Libro'),
                              onPressed: () => _openExportDialog(context, isDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      // FAB para ir directo al Editor Zen
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text(
          'Editor Zen',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
          );
        },
      ),
    );
  }
}
