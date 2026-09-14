import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../screens/zen_editor_screen.dart';

class GlobalSearchSheet extends StatefulWidget {
  const GlobalSearchSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GlobalSearchSheet(),
    );
  }

  @override
  State<GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _SearchResultItem {
  final String category;
  final String title;
  final String subtitle;
  final String snippet;
  final IconData icon;
  final VoidCallback onTap;

  _SearchResultItem({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.snippet,
    required this.icon,
    required this.onTap,
  });
}

class _GlobalSearchSheetState extends State<GlobalSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SearchResultItem> _performSearch(EditorController controller, BuildContext context) {
    if (_query.trim().isEmpty) return [];

    final q = _query.toLowerCase().trim();
    final List<_SearchResultItem> results = [];

    // 1. Capítulos
    for (final book in controller.allBooks) {
      for (final chapter in book.chapters) {
        final titleMatch = chapter.title.toLowerCase().contains(q);
        final contentMatch = chapter.content.toLowerCase().contains(q);

        if (titleMatch || contentMatch) {
          String snippet = '';
          if (contentMatch) {
            final idx = chapter.content.toLowerCase().indexOf(q);
            final start = (idx - 30).clamp(0, chapter.content.length);
            final end = (idx + q.length + 50).clamp(0, chapter.content.length);
            snippet = '...${chapter.content.substring(start, end).replaceAll('\n', ' ')}...';
          }

          results.add(
            _SearchResultItem(
              category: 'Capítulos',
              title: chapter.title,
              subtitle: 'Libro: ${book.title}',
              snippet: snippet,
              icon: Icons.menu_book_rounded,
              onTap: () {
                controller.switchBook(book.id);
                controller.selectChapter(chapter);
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                );
              },
            ),
          );
        }
      }
    }

    // 2. Personajes
    for (final char in controller.allCharacters) {
      final nameMatch = char.name.toLowerCase().contains(q);
      final roleMatch = char.role.toLowerCase().contains(q);
      final bioMatch = char.writtenBiography.toLowerCase().contains(q);
      final motivationMatch = char.motivation.toLowerCase().contains(q);

      if (nameMatch || roleMatch || bioMatch || motivationMatch) {
        String snippet = char.motivation.isNotEmpty ? char.motivation : char.writtenBiography;
        if (snippet.length > 80) snippet = '${snippet.substring(0, 80)}...';

        results.add(
          _SearchResultItem(
            category: 'Personajes',
            title: '${char.avatarEmoji} ${char.name}',
            subtitle: '${char.role} ${char.archetype.isNotEmpty ? "• ${char.archetype}" : ""}',
            snippet: snippet,
            icon: Icons.person_rounded,
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        );
      }
    }

    // 3. Códice de Mundo
    for (final entry in controller.allCodexEntries) {
      final nameMatch = entry.name.toLowerCase().contains(q);
      final descMatch = entry.description.toLowerCase().contains(q);
      final roleMatch = entry.role.toLowerCase().contains(q);

      if (nameMatch || descMatch || roleMatch) {
        String snippet = entry.description;
        if (snippet.length > 80) snippet = '${snippet.substring(0, 80)}...';

        results.add(
          _SearchResultItem(
            category: 'Códice',
            title: '${entry.avatarEmoji} ${entry.name}',
            subtitle: '${entry.typeLabel} • ${entry.role}',
            snippet: snippet,
            icon: Icons.auto_stories_rounded,
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        );
      }
    }

    // 4. Ideas & Notas
    for (final idea in controller.allIdeas) {
      final titleMatch = idea.title.toLowerCase().contains(q);
      final contentMatch = idea.content.toLowerCase().contains(q);

      if (titleMatch || contentMatch) {
        String snippet = idea.content;
        if (snippet.length > 80) snippet = '${snippet.substring(0, 80)}...';

        results.add(
          _SearchResultItem(
            category: 'Notas & Ideas',
            title: '${idea.categoryIcon} ${idea.title}',
            subtitle: idea.categoryLabel,
            snippet: snippet,
            icon: Icons.lightbulb_outline_rounded,
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        );
      }
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context);
    final isDark = controller.isDarkMode;
    final bgCard = isDark ? const Color(0xFF1E1E22) : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderColor = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    final results = _performSearch(controller, context);

    // Group results by category
    final Map<String, List<_SearchResultItem>> grouped = {};
    for (final r in results) {
      grouped.putIfAbsent(r.category, () => []).add(r);
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: AppTheme.getSoftShadow(isDark),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header & Search TextField
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Búsqueda Global',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: textSecondary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: TextStyle(color: textPrimary, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Buscar en capítulos, personajes, códice, ideas...',
                              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _query = val;
                              });
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear_rounded, size: 18, color: textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Results List or Empty State
            Expanded(
              child: _query.trim().isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.manage_search_rounded,
                            size: 64,
                            color: textSecondary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Escribe para buscar en todo tu universo creativo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Capítulos, diálogos, biografías de personajes, códice e ideas',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 54,
                                color: textSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No se encontraron coincidencias para "$_query"',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Prueba con otra palabra clave o término más general',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${results.length} ${results.length == 1 ? "resultado encontrado" : "resultados encontrados"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            for (final entry in grouped.entries) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 10, bottom: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white70 : Colors.black87,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      entry.key.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: textSecondary,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${entry.value.length})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondary.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...entry.value.map((item) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFF9F9FB),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(color: borderColor),
                                  ),
                                  child: InkWell(
                                    onTap: item.onTap,
                                    borderRadius: BorderRadius.circular(14),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(item.icon, size: 18, color: textPrimary),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.title,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  item.subtitle,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textSecondary,
                                                  ),
                                                ),
                                                if (item.snippet.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    item.snippet,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: textSecondary.withValues(alpha: 0.85),
                                                      fontStyle: FontStyle.italic,
                                                      height: 1.3,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 14,
                                            color: textSecondary.withValues(alpha: 0.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                            const SizedBox(height: 20),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

