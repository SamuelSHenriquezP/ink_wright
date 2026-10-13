import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../models/chapter_snapshot_model.dart';
import '../services/diff_service.dart';
import '../formatters/writer_text_formatter.dart';

class ChapterDiffViewerModal extends StatefulWidget {
  final ChapterSnapshotModel snapshot;
  final String currentText;
  final String chapterTitle;
  final String chapterId;
  final EditorController controller;
  final bool isDark;

  const ChapterDiffViewerModal({
    super.key,
    required this.snapshot,
    required this.currentText,
    required this.chapterTitle,
    required this.chapterId,
    required this.controller,
    required this.isDark,
  });

  static void show({
    required BuildContext context,
    required ChapterSnapshotModel snapshot,
    required String currentText,
    required String chapterTitle,
    required String chapterId,
    required EditorController controller,
    required bool isDark,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChapterDiffViewerModal(
        snapshot: snapshot,
        currentText: currentText,
        chapterTitle: chapterTitle,
        chapterId: chapterId,
        controller: controller,
        isDark: isDark,
      ),
    );
  }

  @override
  State<ChapterDiffViewerModal> createState() => _ChapterDiffViewerModalState();
}

class _ChapterDiffViewerModalState extends State<ChapterDiffViewerModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<DiffSegment> _segments;
  late DiffStats _stats;
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _computeDiff();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  void _computeDiff() {
    _segments = DiffService.computeWordDiff(
      widget.snapshot.content,
      widget.currentText,
    );
    _stats = DiffService.computeStats(
      _segments,
      widget.snapshot.wordCount,
      WriterTextFormatter.countWords(widget.currentText),
    );
  }

  void _confirmRestore(BuildContext context) {
    final isDark = widget.isDark;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(color: borderSubtle),
        ),
        title: Row(
          children: [
            const Icon(Icons.settings_backup_restore_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 10),
            Text(
              '¿Restaurar Versión?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El texto actual será sustituido por la versión «${widget.snapshot.label}».',
              style: TextStyle(fontSize: 13, color: textPrimary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Se creará un respaldo de seguridad automático de tu borrador actual antes de aplicar el cambio.',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              final ok = widget.controller.restoreChapterSnapshot(
                widget.chapterId,
                widget.snapshot.id,
              );
              Navigator.of(ctx).pop(); // Close confirmation dialog
              if (ok) {
                Navigator.of(context).pop(); // Close Diff Viewer
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Restaurado a «${widget.snapshot.label}». Se guardó respaldo preventivo.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Restaurar Ahora'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
        border: Border.all(color: borderSubtle),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 6),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.difference_outlined, size: 20, color: textPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comparador de Versiones (Diff)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '«${widget.snapshot.label}» vs Texto Actual',
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
                  tooltip: 'Cerrar',
                ),
              ],
            ),
          ),

          // Diff Stats Summary Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBadge(
                  icon: Icons.add_circle_outline_rounded,
                  label: '+${_stats.wordsAdded} añadidas',
                  color: isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32),
                ),
                Container(width: 1, height: 16, color: borderSubtle),
                _buildStatBadge(
                  icon: Icons.remove_circle_outline_rounded,
                  label: '-${_stats.wordsDeleted} eliminadas',
                  color: isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828),
                ),
                Container(width: 1, height: 16, color: borderSubtle),
                _buildStatBadge(
                  icon: Icons.swap_vert_rounded,
                  label: _stats.wordNetDelta >= 0
                      ? '+${_stats.wordNetDelta} neto'
                      : '${_stats.wordNetDelta} neto',
                  color: _stats.wordNetDelta >= 0
                      ? (isDark ? Colors.lightBlueAccent : Colors.blue.shade700)
                      : (isDark ? Colors.orangeAccent : Colors.orange.shade800),
                ),
              ],
            ),
          ),

          // Tabs: Unified vs Side-by-Side
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDark ? Colors.white24 : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: textPrimary,
                unselectedLabelColor: textSecondary,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                tabs: const [
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.view_stream_rounded, size: 15),
                        SizedBox(width: 6),
                        Text('Vista Unificada'),
                      ],
                    ),
                  ),
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.view_column_rounded, size: 15),
                        SizedBox(width: 6),
                        Text('Lado a Lado'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Divider(height: 1, color: borderSubtle),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUnifiedView(isDark, textPrimary, textSecondary, borderSubtle),
                _buildSideBySideView(isDark, textPrimary, textSecondary, borderSubtle),
              ],
            ),
          ),

          Divider(height: 1, color: borderSubtle),

          // Bottom Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderSubtle),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: const Text('Copiar Instantánea', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.snapshot.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Texto histórico copiado al portapapeles.')),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.settings_backup_restore_rounded, size: 16),
                    label: const Text(
                      'Restaurar esta Versión',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _confirmRestore(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedView(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderSubtle,
  ) {
    if (_segments.isEmpty || (_segments.length == 1 && _segments.first.isSame)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 40, color: textSecondary),
              const SizedBox(height: 12),
              Text(
                'No hay diferencias',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Esta instantánea es idéntica al texto actual del capítulo.',
                style: TextStyle(fontSize: 12, color: textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Build rich text spans
    final spans = <TextSpan>[];
    final addBg = isDark
        ? const Color(0xFF1B5E20).withValues(alpha: 0.45)
        : const Color(0xFFA5D6A7).withValues(alpha: 0.55);
    final addFg = isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20);

    final delBg = isDark
        ? const Color(0xFFB71C1C).withValues(alpha: 0.45)
        : const Color(0xFFEF9A9A).withValues(alpha: 0.55);
    final delFg = isDark ? const Color(0xFFE57373) : const Color(0xFFB71C1C);

    for (final seg in _segments) {
      if (seg.isAdded) {
        spans.add(
          TextSpan(
            text: seg.text,
            style: TextStyle(
              backgroundColor: addBg,
              color: addFg,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      } else if (seg.isDeleted) {
        spans.add(
          TextSpan(
            text: seg.text,
            style: TextStyle(
              backgroundColor: delBg,
              color: delFg,
              decoration: TextDecoration.lineThrough,
              decorationColor: delFg,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: seg.text,
            style: TextStyle(color: textPrimary),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderSubtle),
      ),
      child: SingleChildScrollView(
        child: SelectableText.rich(
          TextSpan(
            children: spans,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.7,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideBySideView(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderSubtle,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Snapshot Text (Original)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_rounded, size: 14, color: textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Instantánea (${widget.snapshot.wordCount} pal.)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(height: 1, color: borderSubtle),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _leftScrollController,
                      child: SelectableText(
                        widget.snapshot.content.isEmpty
                            ? '(Versión vacía)'
                            : widget.snapshot.content,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.6,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Right: Current Text
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 15, color: textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Texto Actual (${WriterTextFormatter.countWords(widget.currentText)} pal.)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(height: 1, color: borderSubtle),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _rightScrollController,
                      child: SelectableText(
                        widget.currentText.isEmpty
                            ? '(Texto actual vacío)'
                            : widget.currentText,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.6,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

