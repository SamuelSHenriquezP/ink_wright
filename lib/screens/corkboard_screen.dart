import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/editor_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/chapter_model.dart';
import '../theme/app_theme.dart';
import '../widgets/chapters/new_chapter_modal.dart';
import 'zen_editor_screen.dart';

/// Scrivener-style Corkboard view where chapters appear as index cards with synopses, POV, and word counts.
class CorkboardScreen extends StatefulWidget {
  const CorkboardScreen({super.key});

  @override
  State<CorkboardScreen> createState() => _CorkboardScreenState();
}

class _CorkboardScreenState extends State<CorkboardScreen> {
  String _statusFilter = 'all'; // 'all', 'draft', 'completed'
  String? _povFilter;

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDark = themeController.isDarkMode;
    final controller = Provider.of<EditorController>(context);

    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final bgScaffold = isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    final chapters = controller.activeBook.chapters;

    // Filtered chapters for display
    final displayedChapters = chapters.where((ch) {
      if (_statusFilter == 'draft' && ch.isCompleted) return false;
      if (_statusFilter == 'completed' && !ch.isCompleted) return false;
      if (_povFilter != null && _povFilter!.isNotEmpty && ch.povCharacter != _povFilter) {
        return false;
      }
      return true;
    }).toList();

    // Distinct POVs present in active book
    final distinctPovs = chapters
        .map((c) => c.povCharacter.trim())
        .where((pov) => pov.isNotEmpty)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: bgScaffold,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgScaffold,
        foregroundColor: textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tablón de Fichas (Corkboard)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${controller.activeBook.title} • ${chapters.length} capítulos',
              style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 22),
            tooltip: 'Nuevo Capítulo',
            onPressed: () {
              NewChapterModal.show(
                context,
                isDark: isDark,
                onChapterCreated: () => setState(() {}),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter and Controls Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: bgScaffold,
              border: Border(bottom: BorderSide(color: borderSubtle)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos (${chapters.length})', 'all', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Borradores (${chapters.where((c) => !c.isCompleted).length})',
                    'draft',
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Completados (${chapters.where((c) => c.isCompleted).length})',
                    'completed',
                    isDark,
                  ),
                  if (distinctPovs.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Container(height: 20, width: 1, color: borderSubtle),
                    const SizedBox(width: 12),
                    Text(
                      'POV:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary),
                    ),
                    const SizedBox(width: 6),
                    ...distinctPovs.map((pov) {
                      final isSelected = _povFilter == pov;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(pov),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? (isDark ? Colors.black : Colors.white) : textSecondary,
                          ),
                          backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                          selectedColor: isDark ? Colors.white : Colors.black,
                          checkmarkColor: isDark ? Colors.black : Colors.white,
                          onSelected: (val) {
                            setState(() {
                              _povFilter = val ? pov : null;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          // Cards Grid
          Expanded(
            child: displayedChapters.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard_customize_outlined, size: 48, color: textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No hay fichas para el filtro seleccionado',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // 1 column on very narrow, 2 on mobile/tablet portrait, 3 or 4 on desktop
                      final crossAxisCount = constraints.maxWidth > 900
                          ? 3
                          : constraints.maxWidth > 550
                              ? 2
                              : 1;

                      // If no filter is active, allow reordering via Drag & Drop ListView or ReorderableGrid
                      // When all chapters are shown, we display reorderable cards
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 260,
                        ),
                        itemCount: displayedChapters.length,
                        itemBuilder: (context, index) {
                          final chapter = displayedChapters[index];
                          final originalIndex = chapters.indexWhere((c) => c.id == chapter.id);
                          return _buildIndexCard(
                            context: context,
                            chapter: chapter,
                            originalIndex: originalIndex,
                            controller: controller,
                            isDark: isDark,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            borderSubtle: borderSubtle,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _statusFilter == value;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? (isDark ? Colors.black : Colors.white) : textSecondary,
      ),
      backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
      selectedColor: isDark ? Colors.white : Colors.black,
      checkmarkColor: isDark ? Colors.black : Colors.white,
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  Widget _buildIndexCard({
    required BuildContext context,
    required ChapterModel chapter,
    required int originalIndex,
    required EditorController controller,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderSubtle,
  }) {
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final isCompleted = chapter.isCompleted;

    // Synopsis preview: use chapter.notes if available, else first lines of content
    String synopsisText = chapter.notes.trim();
    final bool hasCustomNotes = synopsisText.isNotEmpty;
    if (!hasCustomNotes) {
      final cleanContent = chapter.content.replaceAll(RegExp(r'[#*`_]'), '').trim();
      synopsisText = cleanContent.isNotEmpty
          ? (cleanContent.length > 180 ? '${cleanContent.substring(0, 180)}...' : cleanContent)
          : 'Pulsa aquí para escribir la sinopsis o resumen de este capítulo.';
    }

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? (isDark ? Colors.white38 : Colors.black38)
              : borderSubtle,
          width: isCompleted ? 1.4 : 1.0,
        ),
        boxShadow: AppTheme.getSoftShadow(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openSynopsisEditor(context, chapter, controller, isDark),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Index + Status Pill + Reorder buttons
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Capítulo ${chapter.chapterNumber}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Reorder arrows
                    if (originalIndex > 0)
                      InkWell(
                        onTap: () => controller.moveChapter(originalIndex, originalIndex - 1),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: textSecondary),
                        ),
                      ),
                    if (originalIndex < controller.activeBook.chapters.length - 1)
                      InkWell(
                        onTap: () => controller.moveChapter(originalIndex, originalIndex + 1),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: textSecondary),
                        ),
                      ),

                    const SizedBox(width: 4),

                    // Status Check / Toggle
                    GestureDetector(
                      onTap: () {
                        controller.updateChapterDetails(
                          chapter.id,
                          isCompleted: !chapter.isCompleted,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isCompleted
                                ? (isDark ? Colors.white54 : Colors.black54)
                                : (isDark ? Colors.white24 : Colors.black26),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCompleted ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
                              size: 11,
                              color: isCompleted ? textPrimary : textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCompleted ? 'Listo' : 'Borrador',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? textPrimary : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Chapter Title
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chapter.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Editar título',
                      onPressed: () => _openTitleEditor(context, chapter, controller, isDark),
                    ),
                  ],
                ),

                // POV Badge (if set)
                if (chapter.povCharacter.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 12, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'POV: ${chapter.povCharacter}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 6),

                // Synopsis Text Canvas
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: Text(
                      synopsisText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: hasCustomNotes ? FontStyle.normal : FontStyle.italic,
                        height: 1.45,
                        color: hasCustomNotes
                            ? textPrimary
                            : textSecondary.withValues(alpha: 0.8),
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Card Footer: Words count + Write Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${chapter.wordCount} pal. • ${chapter.readingTimeMinutes} min',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(color: borderSubtle),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.edit_note_rounded, size: 14),
                      label: const Text('Escribir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        controller.selectChapter(chapter);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSynopsisEditor(
    BuildContext context,
    ChapterModel chapter,
    EditorController controller,
    bool isDark,
  ) {
    final textCtrl = TextEditingController(text: chapter.notes);
    final povCtrl = TextEditingController(text: chapter.povCharacter);
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ficha de Sinopsis: ${chapter.title}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Resume el conflicto, giro de trama o propósito de este capítulo.',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textCtrl,
                autofocus: true,
                maxLines: 5,
                style: TextStyle(fontSize: 13.5, color: textPrimary),
                decoration: InputDecoration(
                  hintText: '¿Qué ocurre en este capítulo? ¿Cuál es el cambio de estado del protagonista?',
                  hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: povCtrl,
                style: TextStyle(fontSize: 13, color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Personaje POV (Punto de vista)',
                  labelStyle: TextStyle(color: textSecondary),
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Cancelar', style: TextStyle(color: textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      controller.updateChapterDetails(
                        chapter.id,
                        notes: textCtrl.text.trim(),
                        povCharacter: povCtrl.text.trim(),
                      );
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Guardar Ficha', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTitleEditor(
    BuildContext context,
    ChapterModel chapter,
    EditorController controller,
    bool isDark,
  ) {
    final titleCtrl = TextEditingController(text: chapter.title);
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Renombrar Capítulo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          style: TextStyle(color: textPrimary),
          decoration: InputDecoration(
            labelText: 'Título del capítulo',
            labelStyle: TextStyle(color: textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () {
              final newTitle = titleCtrl.text.trim();
              if (newTitle.isNotEmpty) {
                controller.updateChapterDetails(chapter.id, title: newTitle);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

