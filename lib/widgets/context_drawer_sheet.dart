import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../formatters/writer_text_formatter.dart';
import '../models/chapter_model.dart';
import 'muse_assistant_sheet.dart';

class ContextDrawerSheet extends StatefulWidget {
  final bool isDark;

  const ContextDrawerSheet({
    super.key,
    required this.isDark,
  });

  @override
  State<ContextDrawerSheet> createState() => _ContextDrawerSheetState();
}

class _ContextDrawerSheetState extends State<ContextDrawerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _newChapterTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newChapterTitleController.dispose();
    super.dispose();
  }

  void _openMuseStudio(BuildContext context) {
    Navigator.of(context).pop(); // pop context drawer
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MuseAssistantSheet(isDark: widget.isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final bgCard = widget.isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = widget.isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentMint = widget.isDark ? AppTheme.darkAccentMint : AppTheme.lightAccentMint;

    final activeChapter = controller.activeChapter;
    final activeBook = controller.activeBook;
    final content = controller.textEditingController.text;

    final wordCount = WriterTextFormatter.countWords(content);
    final charCount = WriterTextFormatter.countCharacters(content, includeSpaces: true);
    final charNoSpaces = WriterTextFormatter.countCharacters(content, includeSpaces: false);
    final paragraphCount = WriterTextFormatter.countParagraphs(content);
    final readingTime = WriterTextFormatter.estimateReadingTime(content);

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
        border: Border.all(color: borderSubtle, width: 1),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeBook.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Navegación del Manuscrito & Códice',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),

                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.auto_awesome_outlined, size: 20),
                      tooltip: 'Herramientas de Escritura',
                      onPressed: () => _openMuseStudio(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Custom Pill Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(26),
                boxShadow: AppTheme.getSoftShadow(widget.isDark),
              ),
              labelColor: textPrimary,
              unselectedLabelColor: textSecondary,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Capítulos'),
                Tab(text: 'Personajes & Códice'),
                Tab(text: 'Métricas'),
                Tab(text: 'Notas'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Chapters Outline
                _buildChaptersTab(controller, activeBook, activeChapter, textPrimary, textSecondary, accentMint, borderSubtle),

                // TAB 2: World Codex Bible
                _buildCodexTab(controller, textPrimary, textSecondary, accentMint, borderSubtle),

                // TAB 3: Text Metrics
                _buildMetricsTab(wordCount, charCount, charNoSpaces, paragraphCount, readingTime, activeChapter, textPrimary, textSecondary, accentMint, borderSubtle),

                // TAB 4: Ideas Drawer
                _buildIdeasTab(controller, textPrimary, textSecondary, accentMint, borderSubtle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChaptersTab(
    EditorController controller,
    dynamic activeBook,
    ChapterModel activeChapter,
    Color textPrimary,
    Color textSecondary,
    Color accentMint,
    Color borderSubtle,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: activeBook.chapters.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final chapter = activeBook.chapters[index];
              final isSelected = chapter.id == activeChapter.id;

              return Material(
                color: isSelected ? accentMint.withValues(alpha: 0.1) : (widget.isDark ? const Color(0xFF222222) : const Color(0xFFFAFAF8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSelected ? accentMint : borderSubtle,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: isSelected ? accentMint : borderSubtle,
                    child: Text(
                      '${chapter.chapterNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : textPrimary,
                      ),
                    ),
                  ),
                  title: Text(
                    chapter.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${chapter.wordCount} words • ${chapter.readingTimeMinutes} min read',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      chapter.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: chapter.isCompleted ? accentMint : textSecondary,
                    ),
                    onPressed: () => controller.toggleChapterCompletion(chapter.id),
                  ),
                  onTap: () {
                    controller.selectChapter(chapter);
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
          ),
        ),

        // Add Chapter Button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentMint,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add New Chapter', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () {
              _showAddChapterDialog(context, controller);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCodexTab(
    EditorController controller,
    Color textPrimary,
    Color textSecondary,
    Color accentMint,
    Color borderSubtle,
  ) {
    final characters = controller.characters;
    final codexList = controller.codexEntries;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Seccion Personajes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Personajes del Libro (${characters.length})',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (characters.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No hay personajes creados en este libro aún.',
              style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic),
            ),
          )
        else
          ...characters.map((char) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF222222) : const Color(0xFFFAFAF8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderSubtle),
              ),
              child: Row(
                children: [
                  Text(char.avatarEmoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          char.name,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${char.role} ${char.archetype.isNotEmpty ? '• ${char.archetype}' : ''}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentMint),
                        ),
                        if (char.writtenBiography.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            char.writtenBiography,
                            style: TextStyle(fontSize: 11, color: textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.post_add_rounded, size: 20, color: accentMint),
                    tooltip: 'Insertar Ficha en Manuscrito',
                    onPressed: () {
                      controller.insertCharacterToEditor(char);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 16),
        Divider(height: 1, color: borderSubtle),
        const SizedBox(height: 16),

        // Seccion Códice y Lore
        Text(
          'Códice de Mundo & Lugares (${codexList.length})',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary),
        ),
        const SizedBox(height: 10),
        ...codexList.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF222222) : const Color(0xFFFAFAF8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderSubtle),
            ),
            child: Row(
              children: [
                Text(entry.defaultEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.typeLabel} • ${entry.role}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentMint),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        entry.description,
                        style: TextStyle(fontSize: 11, color: textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_comment_rounded, size: 20, color: accentMint),
                  tooltip: 'Insertar Referencia',
                  onPressed: () {
                    controller.insertTextToEditor(
                      '\n\n/* Códice (${entry.typeLabel}): ${entry.name} */\n${entry.description}\n\n',
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMetricsTab(
    int wordCount,
    int charCount,
    int charNoSpaces,
    int paragraphCount,
    int readingTime,
    ChapterModel activeChapter,
    Color textPrimary,
    Color textSecondary,
    Color accentMint,
    Color borderSubtle,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildMetricRow('Total Words', '$wordCount words', textPrimary, textSecondary, borderSubtle),
        _buildMetricRow('Characters (with spaces)', '$charCount', textPrimary, textSecondary, borderSubtle),
        _buildMetricRow('Characters (without spaces)', '$charNoSpaces', textPrimary, textSecondary, borderSubtle),
        _buildMetricRow('Paragraphs', '$paragraphCount', textPrimary, textSecondary, borderSubtle),
        _buildMetricRow('Est. Reading Time', WriterTextFormatter.formatReadingTime(readingTime), textPrimary, textSecondary, borderSubtle),
        const SizedBox(height: 16),
        Text(
          'POV Character & Chapter Notes',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF222222) : const Color(0xFFFAFAF8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'POV: ${activeChapter.povCharacter.isEmpty ? 'Not specified' : activeChapter.povCharacter}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accentMint),
              ),
              const SizedBox(height: 6),
              Text(
                activeChapter.notes.isEmpty ? 'No chapter notes added yet.' : activeChapter.notes,
                style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, Color textPrimary, Color textSecondary, Color borderSubtle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: textSecondary)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
        ],
      ),
    );
  }

  Widget _buildIdeasTab(
    EditorController controller,
    Color textPrimary,
    Color textSecondary,
    Color accentMint,
    Color borderSubtle,
  ) {
    final ideas = controller.ideas;
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: ideas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final idea = ideas[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF222222) : const Color(0xFFFAFAF8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderSubtle),
          ),
          child: Row(
            children: [
              Text(idea.categoryIcon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.title,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      idea.content,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_comment_rounded, size: 20, color: accentMint),
                tooltip: 'Insert to Canvas',
                onPressed: () {
                  controller.insertIdeaToEditor(idea);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddChapterDialog(BuildContext context, EditorController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Chapter'),
          content: TextField(
            controller: _newChapterTitleController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter chapter title...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = _newChapterTitleController.text.trim();
                controller.addNewChapter(title);
                _newChapterTitleController.clear();
                Navigator.of(context).pop(); // pop dialog
                Navigator.of(context).pop(); // pop bottom sheet to open editor
              },
              child: const Text('Add Chapter'),
            ),
          ],
        );
      },
    );
  }
}
