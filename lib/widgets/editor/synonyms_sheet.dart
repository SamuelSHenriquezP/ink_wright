import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/synonyms_service.dart';

class SynonymsSheet extends StatefulWidget {
  final String? initialWord;
  final bool isDark;
  final void Function(String replacement)? onReplaceWord;

  const SynonymsSheet({
    super.key,
    this.initialWord,
    required this.isDark,
    this.onReplaceWord,
  });

  static void show({
    required BuildContext context,
    String? initialWord,
    required bool isDark,
    void Function(String replacement)? onReplaceWord,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SynonymsSheet(
        initialWord: initialWord,
        isDark: isDark,
        onReplaceWord: onReplaceWord,
      ),
    );
  }

  @override
  State<SynonymsSheet> createState() => _SynonymsSheetState();
}

class _SynonymsSheetState extends State<SynonymsSheet> {
  late TextEditingController _searchController;
  String? _selectedCategory;
  List<SynonymGroup> _results = [];
  String? _inspectedSynonym;
  String? _inspectedNuance;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialWord != null ? SynonymsService.normalizeWord(widget.initialWord!) : '';
    _searchController = TextEditingController(text: initial);
    _performSearch(initial);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _inspectedSynonym = null;
      _inspectedNuance = null;
      if (query.trim().isEmpty) {
        if (_selectedCategory != null) {
          _results = SynonymsService.allGroups
              .where((g) => g.category == _selectedCategory)
              .toList();
        } else {
          _results = SynonymsService.allGroups;
        }
      } else {
        var res = SynonymsService.lookup(query);
        if (_selectedCategory != null) {
          res = res.where((g) => g.category == _selectedCategory).toList();
        }
        _results = res;
      }
    });
  }

  void _selectSynonym(String syn, SynonymGroup group) {
    setState(() {
      _inspectedSynonym = syn;
      _inspectedNuance = group.nuances[syn];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgCard = isDark ? const Color(0xFF1E1E22) : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderSubtle),
            boxShadow: AppTheme.getSoftShadow(isDark),
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.menu_book_rounded, size: 20, color: textPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Diccionario de Sinónimos Literarios',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            widget.initialWord != null && widget.initialWord!.isNotEmpty
                                ? 'Buscando alternativas para «${widget.initialWord}»'
                                : 'Matices, dicción y riqueza expresiva en español',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  autofocus: widget.initialWord == null || widget.initialWord!.isEmpty,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Buscar palabra (ej. decir, miedo, oscuro, caminar)...',
                    hintStyle: TextStyle(fontSize: 13, color: textSecondary.withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white70 : Colors.black87,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (val) => _performSearch(val),
                ),
              ),

              // Category Filter Chips
              Container(
                height: 44,
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildCategoryChip(
                      label: 'Todos',
                      isSelected: _selectedCategory == null,
                      onTap: () {
                        setState(() => _selectedCategory = null);
                        _performSearch(_searchController.text);
                      },
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(width: 8),
                    ...SynonymsService.categories.map((cat) {
                      final isSel = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCategoryChip(
                          label: cat,
                          isSelected: isSel,
                          onTap: () {
                            setState(() => _selectedCategory = isSel ? null : cat);
                            _performSearch(_searchController.text);
                          },
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Selected synonym preview bar with action buttons
              if (_inspectedSynonym != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white30 : Colors.black26,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: isDark ? Colors.amberAccent : Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _inspectedSynonym!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          if (widget.onReplaceWord != null)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : Colors.black,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 14),
                              label: const Text('Reemplazar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                final chosen = _inspectedSynonym!;
                                Navigator.of(context).pop();
                                widget.onReplaceWord!(chosen);
                              },
                            ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Copiar al portapapeles',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _inspectedSynonym!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('«$_inspectedSynonym» copiado al portapapeles.'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      if (_inspectedNuance != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _inspectedNuance!,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              Divider(height: 1, color: borderSubtle),

              // Synonyms List
              Expanded(
                child: _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 44, color: textSecondary.withValues(alpha: 0.4)),
                              const SizedBox(height: 14),
                              Text(
                                'No se encontraron sinónimos',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Prueba buscar por verbo infinitivo («decir», «caminar») o explora las categorías temáticas.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final group = _results[index];
                          return _buildGroupCard(
                            group: group,
                            isDark: isDark,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            borderSubtle: borderSubtle,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.12))
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? (isDark ? Colors.white38 : Colors.black38) : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? textPrimary : textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard({
    required SynonymGroup group,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderSubtle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                group.headword.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  group.category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            group.description,
            style: TextStyle(fontSize: 11.5, color: textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.synonyms.map((syn) {
              final isInspected = _inspectedSynonym == syn;
              final hasNuance = group.nuances.containsKey(syn);

              return InkWell(
                onTap: () => _selectSynonym(syn, group),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isInspected
                        ? (isDark ? Colors.white24 : Colors.black12)
                        : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isInspected
                          ? (isDark ? Colors.white70 : Colors.black87)
                          : (hasNuance ? (isDark ? Colors.amber.withValues(alpha: 0.4) : Colors.amber.shade700.withValues(alpha: 0.4)) : Colors.transparent),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        syn,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isInspected ? FontWeight.bold : FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      if (hasNuance) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.info_outline_rounded,
                          size: 11,
                          color: isDark ? Colors.amberAccent : Colors.amber.shade800,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

