import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class EditorOptionsMenuSheet extends StatelessWidget {
  final bool isDark;
  final String chapterTitle;
  final String chapterContent;
  final bool isReadOnly;
  final bool isTypewriter;
  final bool hideMarkdownSymbols;
  final VoidCallback onToggleReadOnly;
  final VoidCallback onToggleTypewriter;
  final VoidCallback onToggleHideMarkdown;
  final VoidCallback onFindReplace;
  final VoidCallback onExport;
  final VoidCallback onHistory;
  final VoidCallback onTypography;
  final VoidCallback onStats;
  final VoidCallback onGoToDashboard;
  final VoidCallback? onNextChapter;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNewChapter;
  final VoidCallback? onWritingSprint;
  final VoidCallback? onMuseAssistant;
  final bool hasNextChapter;
  final bool hasPreviousChapter;

  const EditorOptionsMenuSheet({
    super.key,
    required this.isDark,
    required this.chapterTitle,
    required this.chapterContent,
    required this.isReadOnly,
    required this.isTypewriter,
    required this.hideMarkdownSymbols,
    required this.onToggleReadOnly,
    required this.onToggleTypewriter,
    required this.onToggleHideMarkdown,
    required this.onFindReplace,
    required this.onExport,
    required this.onHistory,
    required this.onTypography,
    required this.onStats,
    required this.onGoToDashboard,
    this.onNextChapter,
    this.onPreviousChapter,
    this.onNewChapter,
    this.onWritingSprint,
    this.onMuseAssistant,
    this.hasNextChapter = false,
    this.hasPreviousChapter = false,
  });

  static void show({
    required BuildContext context,
    required bool isDark,
    required String chapterTitle,
    required String chapterContent,
    required bool isReadOnly,
    required bool isTypewriter,
    required bool hideMarkdownSymbols,
    required VoidCallback onToggleReadOnly,
    required VoidCallback onToggleTypewriter,
    required VoidCallback onToggleHideMarkdown,
    required VoidCallback onFindReplace,
    required VoidCallback onExport,
    required VoidCallback onHistory,
    required VoidCallback onTypography,
    required VoidCallback onStats,
    required VoidCallback onGoToDashboard,
    VoidCallback? onNextChapter,
    VoidCallback? onPreviousChapter,
    VoidCallback? onNewChapter,
    VoidCallback? onWritingSprint,
    VoidCallback? onMuseAssistant,
    bool hasNextChapter = false,
    bool hasPreviousChapter = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditorOptionsMenuSheet(
        isDark: isDark,
        chapterTitle: chapterTitle,
        chapterContent: chapterContent,
        isReadOnly: isReadOnly,
        isTypewriter: isTypewriter,
        hideMarkdownSymbols: hideMarkdownSymbols,
        onToggleReadOnly: onToggleReadOnly,
        onToggleTypewriter: onToggleTypewriter,
        onToggleHideMarkdown: onToggleHideMarkdown,
        onFindReplace: onFindReplace,
        onExport: onExport,
        onHistory: onHistory,
        onTypography: onTypography,
        onStats: onStats,
        onGoToDashboard: onGoToDashboard,
        onNextChapter: onNextChapter,
        onPreviousChapter: onPreviousChapter,
        onNewChapter: onNewChapter,
        onWritingSprint: onWritingSprint,
        onMuseAssistant: onMuseAssistant,
        hasNextChapter: hasNextChapter,
        hasPreviousChapter: hasPreviousChapter,
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado al portapapeles'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgCard = isDark ? const Color(0xFF1E1E20) : Colors.white;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final itemBg = isDark ? const Color(0xFF26262A) : const Color(0xFFF7F7F8);

    final List<_MenuItem> items = [
      if (onNewChapter != null)
        _MenuItem(
          icon: Icons.add_circle_outline_rounded,
          title: 'Nuevo Capítulo',
          subtitle: 'Añadir nueva entrega',
          onTap: () {
            Navigator.of(context).pop();
            onNewChapter!();
          },
        ),
      if (hasNextChapter && onNextChapter != null)
        _MenuItem(
          icon: Icons.arrow_forward_rounded,
          title: 'Siguiente Capítulo',
          subtitle: 'Avanzar en el manuscrito',
          onTap: () {
            Navigator.of(context).pop();
            onNextChapter!();
          },
        ),
      if (hasPreviousChapter && onPreviousChapter != null)
        _MenuItem(
          icon: Icons.arrow_back_rounded,
          title: 'Capítulo Anterior',
          subtitle: 'Retroceder al previo',
          onTap: () {
            Navigator.of(context).pop();
            onPreviousChapter!();
          },
        ),
      if (onWritingSprint != null)
        _MenuItem(
          icon: Icons.timer_outlined,
          title: 'Sprint de Escritura',
          subtitle: 'Cronómetro y meta',
          onTap: () {
            Navigator.of(context).pop();
            onWritingSprint!();
          },
        ),
      if (onMuseAssistant != null)
        _MenuItem(
          icon: Icons.auto_awesome_outlined,
          title: 'Musa Creativa',
          subtitle: 'Ideas y giros narrativos',
          onTap: () {
            Navigator.of(context).pop();
            onMuseAssistant!();
          },
        ),
      _MenuItem(
        icon: Icons.title_rounded,
        title: 'Copiar Título',
        subtitle: 'Solo el título del capítulo',
        onTap: () => _copyToClipboard(context, chapterTitle, 'Título'),
      ),
      _MenuItem(
        icon: Icons.copy_rounded,
        title: 'Copiar Contenido',
        subtitle: 'Cuerpo del manuscrito',
        onTap: () => _copyToClipboard(context, chapterContent, 'Contenido'),
      ),
      _MenuItem(
        icon: Icons.content_copy_rounded,
        title: 'Copiar Todo',
        subtitle: 'Título y texto completo',
        onTap: () => _copyToClipboard(context, '# $chapterTitle\n\n$chapterContent', 'Capítulo completo'),
      ),
      _MenuItem(
        icon: Icons.search_rounded,
        title: 'Buscar y Reemplazar',
        subtitle: 'Buscar palabras en el texto',
        onTap: () {
          Navigator.of(context).pop();
          onFindReplace();
        },
      ),
      _MenuItem(
        icon: Icons.ios_share_rounded,
        title: 'Exportar Manuscrito',
        subtitle: 'PDF, EPUB, TXT o Markdown',
        onTap: () {
          Navigator.of(context).pop();
          onExport();
        },
      ),
      _MenuItem(
        icon: Icons.history_rounded,
        title: 'Historial de Versiones',
        subtitle: 'Instantáneas y respaldos',
        onTap: () {
          Navigator.of(context).pop();
          onHistory();
        },
      ),
      _MenuItem(
        icon: isReadOnly ? Icons.visibility_rounded : Icons.edit_note_rounded,
        title: 'Modo Solo Lectura',
        subtitle: isReadOnly ? 'Activado (bloqueado)' : 'Desactivado (editable)',
        isActive: isReadOnly,
        onTap: () {
          Navigator.of(context).pop();
          onToggleReadOnly();
        },
      ),
      _MenuItem(
        icon: Icons.keyboard_outlined,
        title: 'Máquina de Escribir',
        subtitle: isTypewriter ? 'Cursor centrado' : 'Desactivado',
        isActive: isTypewriter,
        onTap: () {
          Navigator.of(context).pop();
          onToggleTypewriter();
        },
      ),
      _MenuItem(
        icon: Icons.format_size_rounded,
        title: 'Tipografía y Diseño',
        subtitle: 'Fuente, interlineado y ancho',
        onTap: () {
          Navigator.of(context).pop();
          onTypography();
        },
      ),
      _MenuItem(
        icon: Icons.auto_stories_outlined,
        title: 'Símbolos Markdown',
        subtitle: hideMarkdownSymbols ? 'Ocultos (Modo limpio)' : 'Visibles (#, **, *)',
        isActive: hideMarkdownSymbols,
        onTap: () {
          Navigator.of(context).pop();
          onToggleHideMarkdown();
        },
      ),
      _MenuItem(
        icon: Icons.analytics_outlined,
        title: 'Estadísticas',
        subtitle: 'Métricas de lectura y palabras',
        onTap: () {
          Navigator.of(context).pop();
          onStats();
        },
      ),
      _MenuItem(
        icon: Icons.dashboard_rounded,
        title: 'Volver al Inicio',
        subtitle: 'Biblioteca y proyectos',
        onTap: () {
          Navigator.of(context).pop();
          onGoToDashboard();
        },
      ),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 20, left: 16, right: 16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Center drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

            // Header title
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Opciones del Editor',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        chapterTitle,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2-Column Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.35,
              ),
              itemBuilder: (ctx, index) {
                final item = items[index];
                final isItemActive = item.isActive;
                return Material(
                  color: isItemActive
                      ? (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08))
                      : itemBg,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isItemActive
                              ? (isDark ? Colors.white38 : Colors.black45)
                              : borderSubtle,
                          width: isItemActive ? 1.4 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.icon,
                              size: 18,
                              color: isItemActive
                                  ? (isDark ? Colors.white : Colors.black)
                                  : textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isActive;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isActive = false,
  });
}
