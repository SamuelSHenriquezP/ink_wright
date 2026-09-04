import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../widgets/progress_ring_card.dart';
import '../widgets/book_card.dart';
import '../widgets/idea_chip_card.dart';
import '../widgets/codex_card.dart';
import '../widgets/soundscape_bar.dart';
import '../widgets/muse_assistant_sheet.dart';
import '../widgets/writing_sprint_dialog.dart';
import '../widgets/export_manuscript_dialog.dart';
import '../models/idea_snippet_model.dart';
import '../models/codex_entry_model.dart';
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
    'All Manuscripts',
    'Story Plot Map',
    'World Codex',
    'Ideas & Scraps',
    'Soundscapes & Sprints',
    'Stats & Goals',
  ];

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

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final isDark = controller.isDarkMode;

    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentMint = isDark ? AppTheme.darkAccentMint : AppTheme.lightAccentMint;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;

    final todayFormatted = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                            color: accentMint,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'InkWright Studio',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    // Top Action Controls (The Muse Spark, Theme Switcher & Avatar)
                    Row(
                      children: [
                        // The Muse Studio Button
                        Container(
                          decoration: BoxDecoration(
                            color: bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderSubtle),
                            boxShadow: AppTheme.getSoftShadow(isDark),
                          ),
                          child: IconButton(
                            icon: const Text('✨', style: TextStyle(fontSize: 18)),
                            onPressed: () => _openMuseStudio(context, isDark),
                            tooltip: 'The Muse Studio',
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Story Plot Mind Map Button
                        Container(
                          decoration: BoxDecoration(
                            color: bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderSubtle),
                            boxShadow: AppTheme.getSoftShadow(isDark),
                          ),
                          child: IconButton(
                            icon: const Text('🗺️', style: TextStyle(fontSize: 18)),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PlotMindMapScreen()),
                              );
                            },
                            tooltip: 'Story Plot Mind Map Canvas',
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Export Studio Button
                        Container(
                          decoration: BoxDecoration(
                            color: bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderSubtle),
                            boxShadow: AppTheme.getSoftShadow(isDark),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.ios_share_rounded, size: 18, color: textPrimary),
                            onPressed: () => _openExportDialog(context, isDark),
                            tooltip: 'Publish & Export Manuscript',
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Theme Mode Switcher Button
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
                            tooltip: 'Toggle Theme',
                          ),
                        ),
                        const SizedBox(width: 8),

                        CircleAvatar(
                          radius: 18,
                          backgroundColor: accentMint.withValues(alpha: 0.2),
                          child: const Text('✍️', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Monochromatic Pill Navigation Filter
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
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
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.white : AppTheme.lightTextPrimary)
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

            // DYNAMIC SECTION BASED ON SELECTED FILTER INDEX
            if (_selectedFilterIndex == 0 || _selectedFilterIndex == 4) ...[
              // SECTION 1: Daily Progress Ring Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ProgressRingCard(
                    stats: controller.writerStats,
                    isDark: isDark,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            if (_selectedFilterIndex == 0) ...[
              // SECTION 2: Active Manuscripts Carousel
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Active Manuscripts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentMint.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${controller.allBooks.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: accentMint,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline_rounded, color: accentMint),
                            onPressed: () => _showCreateBookDialog(context, controller),
                            tooltip: 'Create New Manuscript',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 205,
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
                              controller.selectBook(book);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ZenEditorScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            if (_selectedFilterIndex == 1) ...[
              // SECTION: Interactive Story Plot Map Banner Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderSubtle),
                      boxShadow: AppTheme.getSoftShadow(isDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('🗺️', style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Story Arc & Plot Mind Map',
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
                                  ),
                                  Text(
                                    'Interactive canvas for plot nodes, acts & subplots',
                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${controller.mindMapNodes.length} Plot Nodes configured for "${controller.activeBook.title}"',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accentMint),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentMint,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.hub_rounded),
                          label: const Text('Open Interactive Mind Map Canvas', style: TextStyle(fontWeight: FontWeight.w700)),
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
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) ...[
              // SECTION 3: Worldbuilding Codex Bible Carousel
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Worldbuilding Codex',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentMint.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${controller.codexEntries.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: accentMint,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: accentMint,
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Entry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            onPressed: () => _showAddCodexDialog(context, controller),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
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
                            onPinTap: () => controller.toggleCodexPin(entry.id),
                            onTap: () {
                              controller.insertTextToEditor(
                                '\n\n/* Codex Note: ${entry.name} */\n${entry.description}\n\n',
                              );
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ZenEditorScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            if (_selectedFilterIndex == 0 || _selectedFilterIndex == 3) ...[
              // SECTION 4: Quick Ideas & Character Scraps
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ideas & Scraps',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: accentMint,
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('New Scrap', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
                                MaterialPageRoute(
                                  builder: (_) => const ZenEditorScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            if (_selectedFilterIndex == 4) ...[
              // SECTION 5: Soundscapes & Writing Sprints Dedicated View
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SoundscapeBar(isDark: isDark),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderSubtle),
                          boxShadow: AppTheme.getSoftShadow(isDark),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Timed Writing Sprint',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Boost your output with Pomodoro focus',
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentMint,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              icon: const Icon(Icons.timer_rounded, size: 18),
                              label: const Text('Start Sprint'),
                              onPressed: () => _openSprintDialog(context, isDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            // SECTION 6: Recent Chapters List
            if (_selectedFilterIndex == 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Chapters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...controller.activeBook.chapters.map((chapter) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderSubtle),
                            boxShadow: AppTheme.getSoftShadow(isDark),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: accentMint.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${chapter.chapterNumber}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: accentMint,
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
                              '${chapter.wordCount} words • ${chapter.readingTimeMinutes} min read',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textSecondary),
                            onTap: () {
                              controller.selectChapter(chapter);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ZenEditorScreen(),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      // FAB for quick creation
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accentMint,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text(
          'Open Zen Editor',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ZenEditorScreen(),
            ),
          );
        },
      ),
    );
  }

  void _showCreateBookDialog(BuildContext context, EditorController controller) {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final genreCtrl = TextEditingController(text: 'Fiction');
    final targetCtrl = TextEditingController(text: '50000');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Manuscript'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: subtitleCtrl,
                  decoration: const InputDecoration(labelText: 'Subtitle / Tagline'),
                ),
                TextField(
                  controller: genreCtrl,
                  decoration: const InputDecoration(labelText: 'Genre'),
                ),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Target Word Count'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                final subtitle = subtitleCtrl.text.trim();
                final genre = genreCtrl.text.trim();
                final target = int.tryParse(targetCtrl.text) ?? 50000;

                if (title.isNotEmpty) {
                  controller.createNewBook(
                    title: title,
                    subtitle: subtitle,
                    genre: genre,
                    targetWordCount: target,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create Project'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCodexDialog(BuildContext context, EditorController controller) {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final secretsCtrl = TextEditingController();
    final emojiCtrl = TextEditingController(text: '🧙‍♂️');
    CodexType selectedType = CodexType.character;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Codex Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<CodexType>(
                      value: selectedType,
                      isExpanded: true,
                      items: CodexType.values.map((type) {
                        final dummy = CodexEntryModel(
                          id: '',
                          bookId: '',
                          name: '',
                          type: type,
                          role: '',
                          description: '',
                          traits: [],
                          secrets: '',
                          avatarEmoji: '',
                          createdAt: DateTime.now(),
                        );
                        return DropdownMenuItem(
                          value: type,
                          child: Text('${dummy.defaultEmoji} ${dummy.typeLabel}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedType = val;
                            switch (val) {
                              case CodexType.character:
                                emojiCtrl.text = '🧙‍♂️';
                                break;
                              case CodexType.location:
                                emojiCtrl.text = '🏰';
                                break;
                              case CodexType.artifact:
                                emojiCtrl.text = '🗝️';
                                break;
                              case CodexType.lore:
                                emojiCtrl.text = '📜';
                                break;
                            }
                          });
                        }
                      },
                    ),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name / Title'),
                    ),
                    TextField(
                      controller: roleCtrl,
                      decoration: const InputDecoration(labelText: 'Role / Archetype'),
                    ),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    TextField(
                      controller: secretsCtrl,
                      decoration: const InputDecoration(labelText: 'Hidden Secret / Key Lore'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isNotEmpty) {
                      final entry = CodexEntryModel(
                        id: 'codex_${DateTime.now().millisecondsSinceEpoch}',
                        bookId: controller.activeBook.id,
                        name: name,
                        type: selectedType,
                        role: roleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        traits: ['Key Entry'],
                        secrets: secretsCtrl.text.trim(),
                        avatarEmoji: emojiCtrl.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      controller.addCodexEntry(entry);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save Entry'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddIdeaDialog(BuildContext context, EditorController controller) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    IdeaCategory selectedCategory = IdeaCategory.character;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Idea Scrap'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<IdeaCategory>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: IdeaCategory.values.map((cat) {
                        final dummy = IdeaSnippetModel(
                          id: '',
                          title: '',
                          content: '',
                          category: cat,
                          colorHex: 0,
                          createdAt: DateTime.now(),
                          tags: [],
                        );
                        return DropdownMenuItem(
                          value: cat,
                          child: Text('${dummy.categoryIcon} ${dummy.categoryLabel}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedCategory = val);
                        }
                      },
                    ),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: contentCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Snippet / Details'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    final contentText = contentCtrl.text.trim();

                    if (title.isNotEmpty) {
                      final newIdea = IdeaSnippetModel(
                        id: 'idea_${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        content: contentText,
                        category: selectedCategory,
                        colorHex: 0xFF38C793,
                        createdAt: DateTime.now(),
                        tags: ['Note'],
                      );
                      controller.addIdea(newIdea);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save Idea'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
