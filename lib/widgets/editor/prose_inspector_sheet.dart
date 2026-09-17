import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../controllers/editor_controller.dart';
import '../../services/prose_style_analyzer_service.dart';

/// Modal bottom sheet that presents a Hemingway-style prose critique for the active chapter.
class ProseInspectorSheet extends StatefulWidget {
  final EditorController controller;
  final bool isDark;
  final void Function(int start, int end) onJumpToIssue;

  const ProseInspectorSheet({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onJumpToIssue,
  });

  static void show({
    required BuildContext context,
    required EditorController controller,
    required bool isDark,
    required void Function(int start, int end) onJumpToIssue,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProseInspectorSheet(
        controller: controller,
        isDark: isDark,
        onJumpToIssue: onJumpToIssue,
      ),
    );
  }

  @override
  State<ProseInspectorSheet> createState() => _ProseInspectorSheetState();
}

class _ProseInspectorSheetState extends State<ProseInspectorSheet> {
  late ProseAnalysisResult _result;
  ProseIssueType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _reanalyze();
  }

  void _reanalyze() {
    final text = widget.controller.textEditingController.text;
    setState(() {
      _result = ProseStyleAnalyzerService.analyze(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final bgSurface = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    final filteredIssues = _selectedFilter == null
        ? _result.issues
        : _result.issues.where((i) => i.type == _selectedFilter).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderSubtle, width: 1),
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.auto_awesome_rounded, size: 20, color: textPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inspector de Prosa y Estilo',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Análisis literario de cadencia y pulido narrativo',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      tooltip: 'Reanalizar texto actual',
                      onPressed: _reanalyze,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: borderSubtle),

              // Metrics Carousel / Summary
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Row(
                  children: [
                    // Readability Card
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Legibilidad', style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.bold)),
                                Text('${_result.readabilityScore.toInt()}/100', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _result.readabilityLabel,
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_result.averageWordsPerSentence} pal/oración',
                              style: TextStyle(fontSize: 10.5, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Quick Counts
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          _buildMetricPill(
                            context: context,
                            label: 'Adverbios',
                            count: _result.adverbsCount,
                            type: ProseIssueType.adverb,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildMetricPill(
                            context: context,
                            label: 'Densas',
                            count: _result.longSentencesCount,
                            type: ProseIssueType.longSentence,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildMetricPill(
                            context: context,
                            label: 'Ecos',
                            count: _result.echoesCount,
                            type: ProseIssueType.echo,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Row(
                  children: [
                    FilterChip(
                      selected: _selectedFilter == null,
                      label: Text('Todos (${_result.issues.length})'),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _selectedFilter == null ? FontWeight.bold : FontWeight.w500,
                        color: _selectedFilter == null ? (isDark ? Colors.black : Colors.white) : textSecondary,
                      ),
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      selectedColor: isDark ? Colors.white : Colors.black,
                      checkmarkColor: isDark ? Colors.black : Colors.white,
                      onSelected: (_) => setState(() => _selectedFilter = null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _selectedFilter == ProseIssueType.adverb,
                      label: Text('Adverbios -mente (${_result.adverbsCount})'),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _selectedFilter == ProseIssueType.adverb ? FontWeight.bold : FontWeight.w500,
                        color: _selectedFilter == ProseIssueType.adverb ? (isDark ? Colors.black : Colors.white) : textSecondary,
                      ),
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      selectedColor: isDark ? Colors.white : Colors.black,
                      checkmarkColor: isDark ? Colors.black : Colors.white,
                      onSelected: (_) => setState(() => _selectedFilter = ProseIssueType.adverb),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _selectedFilter == ProseIssueType.longSentence,
                      label: Text('Oraciones densas (${_result.longSentencesCount})'),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _selectedFilter == ProseIssueType.longSentence ? FontWeight.bold : FontWeight.w500,
                        color: _selectedFilter == ProseIssueType.longSentence ? (isDark ? Colors.black : Colors.white) : textSecondary,
                      ),
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      selectedColor: isDark ? Colors.white : Colors.black,
                      checkmarkColor: isDark ? Colors.black : Colors.white,
                      onSelected: (_) => setState(() => _selectedFilter = ProseIssueType.longSentence),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _selectedFilter == ProseIssueType.echo,
                      label: Text('Ecos y repeticiones (${_result.echoesCount})'),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _selectedFilter == ProseIssueType.echo ? FontWeight.bold : FontWeight.w500,
                        color: _selectedFilter == ProseIssueType.echo ? (isDark ? Colors.black : Colors.white) : textSecondary,
                      ),
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      selectedColor: isDark ? Colors.white : Colors.black,
                      checkmarkColor: isDark ? Colors.black : Colors.white,
                      onSelected: (_) => setState(() => _selectedFilter = ProseIssueType.echo),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Issues List
              Expanded(
                child: filteredIssues.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 40, color: textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              '¡Prosa limpia y equilibrada!',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No se detectaron observaciones en este filtro.',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                        itemCount: filteredIssues.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final issue = filteredIssues[index];
                          return _buildIssueCard(issue, isDark, textPrimary, textSecondary, borderSubtle);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricPill({
    required BuildContext context,
    required String label,
    required int count,
    required ProseIssueType type,
    required bool isDark,
  }) {
    final isSelected = _selectedFilter == type;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = isSelected ? null : type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08))
                : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.white38 : Colors.black26)
                  : (isDark ? Colors.white10 : Colors.black12),
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIssueCard(
    ProseIssue issue,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderSubtle,
  ) {
    IconData icon;
    switch (issue.type) {
      case ProseIssueType.adverb:
        icon = Icons.bolt_outlined;
        break;
      case ProseIssueType.longSentence:
        icon = Icons.straighten_rounded;
        break;
      case ProseIssueType.echo:
        icon = Icons.repeat_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBgPrimary : AppTheme.lightBgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: textSecondary),
              const SizedBox(width: 6),
              Text(
                issue.typeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: const Size(0, 28),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 13),
                label: const Text('Ir al texto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onJumpToIssue(issue.startIndex, issue.endIndex);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '«${issue.matchedText}»',
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            issue.message,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            issue.suggestion,
            style: TextStyle(fontSize: 11.5, color: textSecondary),
          ),
        ],
      ),
    );
  }
}

