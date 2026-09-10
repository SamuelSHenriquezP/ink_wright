import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../controllers/editor_controller.dart';
import '../widgets/idea_chip_card.dart';
import '../widgets/codex_card.dart';
import '../widgets/muse_assistant_sheet.dart';
import '../widgets/writing_sprint_dialog.dart';
import '../widgets/export_manuscript_dialog.dart';
import '../models/idea_snippet_model.dart';
import '../models/codex_entry_model.dart';
import '../models/book_model.dart';
import '../controllers/theme_controller.dart';
import '../formatters/writer_text_formatter.dart';
import '../widgets/progress_ring_card.dart';
import 'zen_editor_screen.dart';
import 'plot_mind_map_screen.dart';
import 'characters_screen.dart';

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

  void _showEditDailyGoalModal(BuildContext context, EditorController controller, bool isDark) {
    final currentGoal = controller.writerStats.dailyGoalWords;
    int selectedWords = currentGoal;
    final customCtrl = TextEditingController(text: currentGoal.toString());
    final presets = [500, 1000, 1500, 2000, 3000];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bgCard = isDark ? const Color(0xFF1E1E22) : Colors.white;
            final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
            final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
            final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: AppTheme.getSoftShadow(isDark),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.flag_rounded, color: textPrimary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Meta Diaria de Escritura',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ajusta tu objetivo diario de palabras',
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'PRESETS RÁPIDOS (PALABRAS)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.map((p) {
                        final isSelected = selectedWords == p;
                        return ChoiceChip(
                          label: Text(
                            '$p',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? (isDark ? Colors.black : Colors.white) : textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: isDark ? Colors.white : Colors.black,
                          backgroundColor: isDark ? const Color(0xFF252525) : const Color(0xFFF4F3EF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: isSelected ? Colors.transparent : borderSubtle),
                          ),
                          showCheckmark: false,
                          onSelected: (sel) {
                            if (sel) {
                              setModalState(() {
                                selectedWords = p;
                                customCtrl.text = p.toString();
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'O INGRESA UN VALOR PERSONALIZADO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'ej: 1200',
                        suffixText: 'palabras / día',
                        suffixStyle: TextStyle(color: textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF18181A) : const Color(0xFFF9F9FB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: textPrimary, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val.trim());
                        if (parsed != null && parsed > 0) {
                          setModalState(() {
                            selectedWords = parsed;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text(
                          'Guardar Meta Diaria',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        onPressed: () {
                          final parsed = int.tryParse(customCtrl.text.trim()) ?? selectedWords;
                          if (parsed > 0) {
                            controller.updateDailyGoal(parsed);
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Meta diaria establecida en $parsed palabras'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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

  void _showRestoreDialog(BuildContext context, EditorController controller, bool isDark) {
    final textController = TextEditingController();
    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              side: BorderSide(color: borderSubtle),
            ),
            title: Row(
              children: [
                Icon(Icons.settings_backup_restore_rounded, color: textPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Restaurar Biblioteca',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pega el contenido de tu archivo de respaldo (.inkwright o JSON) a continuación. Esta acción reemplazará los libros, códice, ideas y trama actuales.',
                      style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(color: borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.paste_rounded, size: 16),
                      label: const Text('Pegar desde Portapapeles'),
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null && data!.text!.isNotEmpty) {
                          setDialogState(() {
                            textController.text = data.text!;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textController,
                      maxLines: 6,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Pega aquí el JSON del respaldo...',
                        hintStyle: TextStyle(fontSize: 12, color: textSecondary.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderSubtle),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text('Cancelar', style: TextStyle(color: textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final rawJson = textController.text.trim();
                  if (rawJson.isEmpty) return;

                  final ok = controller.restoreFromBackupJson(rawJson);
                  if (!dialogCtx.mounted) return;
                  Navigator.of(dialogCtx).pop();

                  if (context.mounted) {
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('¡Biblioteca restaurada con éxito!'),
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Error: El formato de respaldo no es válido.'),
                          backgroundColor: Colors.red.shade700,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Restaurar Ahora'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openTutorialSheet(BuildContext context, bool isDark, EditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
        final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
        final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
        final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
            border: Border.all(color: borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('🖋️', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guía de Inicio — Ink & Wright',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Tu estudio minimalista de narrativa y planificación',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: borderSubtle),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTutorialItem(
                        icon: Icons.edit_note_rounded,
                        title: '1. Editor con Markdown en Vivo',
                        description:
                            'Escribe con total fluidez. Tus títulos (#), negritas (**texto**), cursivas (*texto*), citas (>), rayas de diálogo (—) y tareas (- [ ]) se renderizan en tiempo real mientras tecleas.',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 12),
                      _buildTutorialItem(
                        icon: Icons.person_search_rounded,
                        title: '2. Fichas de Personajes Narrativos',
                        description:
                            'Cada libro cuenta con su propia sección de Personajes. Define su psicología, motivaciones, debilidades y redacta su biografía escrita para insertarla en tu manuscrito.',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 12),
                      _buildTutorialItem(
                        icon: Icons.hub_outlined,
                        title: '3. Mapa Mental Individual por Libro',
                        description:
                            'Un lienzo visual exclusivo para cada proyecto. Conecta causas y consecuencias, arrastra ideas por el espacio infinito y auto-organiza tu trama en columnas por actos narrativos.',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 12),
                      _buildTutorialItem(
                        icon: Icons.fullscreen_rounded,
                        title: '4. Modo Pantalla Completa & Concentración',
                        description:
                            'Toca el botón de pantalla completa para ocultar barras y controles. Activa paisajes sonoros (lluvia, fuego, café) y sprints cronometrados para mantener tu ritmo.',
                        isDark: isDark,
                        borderSubtle: borderSubtle,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.auto_stories_rounded, size: 20),
                  label: const Text(
                    'Abrir el Manual del Escritor',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  onPressed: () {
                    final tutBook = controller.allBooks.firstWhere(
                      (b) => b.id == 'b_tutorial',
                      orElse: () => controller.allBooks.first,
                    );
                    controller.selectBook(tutBook);
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
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

  Widget _buildTutorialItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
    required Color borderSubtle,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
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
                  setState(() {
                    _isInsideBookView = true;
                    _selectedFilterIndex = 0;
                  });
                }
              },
              child: const Text('Crear Libro'),
            ),
          ],
        );
      },
    );
  }

  void _showBookOptions(BuildContext context, EditorController controller, BookModel book, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.sheetRadius)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('Exportar Manuscrito', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.of(ctx).pop();
                controller.switchBook(book.id);
                _openExportDialog(context, isDark);
              },
            ),
            if (controller.allBooks.length > 1)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Eliminar Libro', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                subtitle: const Text('Se borrarán sus capítulos, personajes y trama'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDeleteBook(context, controller, book);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBook(BuildContext context, EditorController controller, BookModel book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar libro?'),
        content: Text('Se eliminará permanentemente "${book.title}" con todos sus capítulos, mapa de trama y personajes asociados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              controller.deleteBook(book.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAddIdeaDialog(BuildContext context, EditorController controller, bool isDark) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    IdeaCategory selectedCategory = IdeaCategory.general;

    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: AppTheme.getSoftShadow(isDark),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: textSecondary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.lightbulb_outline_rounded, color: textPrimary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nuevo Fragmento o Idea',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Para: ${controller.activeBook.title}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Category Selector Chips
                      Text(
                        'CATEGORÍA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: IdeaCategory.values.map((cat) {
                            final isSelected = selectedCategory == cat;
                            final tempSnippet = IdeaSnippetModel(
                              id: '',
                              bookId: controller.activeBook.id,
                              title: '',
                              content: '',
                              category: cat,
                              colorHex: 0,
                              createdAt: DateTime.now(),
                              tags: const [],
                            );
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(tempSnippet.categoryIcon, style: const TextStyle(fontSize: 13)),
                                    const SizedBox(width: 6),
                                    Text(
                                      tempSnippet.categoryLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? (isDark ? Colors.black : Colors.white) : textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                selected: isSelected,
                                selectedColor: isDark ? Colors.white : Colors.black,
                                backgroundColor: isDark ? const Color(0xFF252525) : const Color(0xFFF4F3EF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                    color: isSelected ? Colors.transparent : borderSubtle,
                                  ),
                                ),
                                showCheckmark: false,
                                onSelected: (selected) {
                                  if (selected) setState(() => selectedCategory = cat);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title Field
                      TextField(
                        controller: titleCtrl,
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'Título del fragmento',
                          hintText: 'ej: Diálogo revelador en el puerto',
                          labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF18181A) : const Color(0xFFF9F9FB),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: textPrimary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Content Field
                      TextField(
                        controller: contentCtrl,
                        maxLines: 4,
                        style: TextStyle(color: textPrimary, fontSize: 14, height: 1.4),
                        decoration: InputDecoration(
                          labelText: 'Contenido o borrador de la idea',
                          hintText: 'Escribe tu pensamiento, diálogo o escena suelta...',
                          alignLabelWithHint: true,
                          labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF18181A) : const Color(0xFFF9F9FB),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: textPrimary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tags Field
                      TextField(
                        controller: tagsCtrl,
                        style: TextStyle(color: textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Etiquetas (opcionales)',
                          hintText: 'Separadas por comas: Clímax, Secreto, Misterio',
                          labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF18181A) : const Color(0xFFF9F9FB),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: textPrimary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textSecondary,
                                side: BorderSide(color: borderSubtle),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : Colors.black,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('Guardar Fragmento', style: TextStyle(fontWeight: FontWeight.w700)),
                              onPressed: () {
                                final title = titleCtrl.text.trim();
                                if (title.isEmpty) return;

                                final rawTags = tagsCtrl.text.split(',');
                                final tagsList = rawTags
                                    .map((t) => t.trim())
                                    .where((t) => t.isNotEmpty)
                                    .toList();
                                if (tagsList.isEmpty) tagsList.add('Nota');

                                final newIdea = IdeaSnippetModel(
                                  id: 'idea_${DateTime.now().millisecondsSinceEpoch}',
                                  bookId: controller.activeBook.id,
                                  title: title,
                                  content: contentCtrl.text.trim(),
                                  category: selectedCategory,
                                  colorHex: 0xFF18181B,
                                  createdAt: DateTime.now(),
                                  tags: tagsList,
                                );
                                controller.addIdea(newIdea);
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Fragmento guardado en este libro'), behavior: SnackBarBehavior.floating),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddCodexDialog(BuildContext context, EditorController controller, bool isDark) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final traitsCtrl = TextEditingController();
    CodexType category = CodexType.character;

    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            String defaultEmojiForCategory(CodexType c) {
              switch (c) {
                case CodexType.character:
                  return '🧙‍♂️';
                case CodexType.location:
                  return '🏰';
                case CodexType.artifact:
                  return '🗝️';
                case CodexType.lore:
                  return '📜';
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: AppTheme.getSoftShadow(isDark),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: textSecondary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.auto_stories_outlined, color: textPrimary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nueva Entrada al Códice',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Para: ${controller.activeBook.title}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Category Selector Chips
                      Text(
                        'TIPO DE ELEMENTO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: CodexType.values.map((c) {
                            final isSelected = category == c;
                            final emoji = defaultEmojiForCategory(c);
                            String label;
                            switch (c) {
                              case CodexType.character:
                                label = 'Personaje';
                                break;
                              case CodexType.location:
                                label = 'Lugar';
                                break;
                              case CodexType.artifact:
                                label = 'Objeto / Reliquia';
                                break;
                              case CodexType.lore:
                                label = 'Códice / Lore';
                                break;
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(emoji, style: const TextStyle(fontSize: 13)),
                                    const SizedBox(width: 6),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? (isDark ? Colors.black : Colors.white) : textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                selected: isSelected,
                                selectedColor: isDark ? Colors.white : Colors.black,
                                backgroundColor: isDark ? const Color(0xFF252525) : const Color(0xFFF4F3EF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                    color: isSelected ? Colors.transparent : borderSubtle,
                                  ),
                                ),
                                showCheckmark: false,
                                onSelected: (selected) {
                                  if (selected) setState(() => category = c);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name Field
                      TextField(
                        controller: titleCtrl,
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'Nombre del elemento',
                          hintText: 'ej: Ciudad de Niebla o Lord Malakor',
                          labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF18181A) : const Color(0xFFF9F9FB),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: textPrimary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Role / Classification Field
                      TextField(
                        controller: roleCtrl,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Rol o Clasificación',
                          hintText: 'ej: Santuario Antiguo, Antagonista Principal',
                          labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF18181A) : const Color(0xFFF9F9FB),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: textPrimary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Description Field
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        style: TextStyle(color: textPrimary, fontSize: 14, height: 1.4),
                        decoration: InputDecoration(
                          labelText: 'Descripción / Lore del mundo',
                          hintText: 'Detalles, secretos, atmósfera o importancia narrativa...',
                          alignLabelWithHint: true,
                          labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF18181A) : const Color(0xFFF9F9FB),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: textPrimary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Traits Field
                      TextField(
                        controller: traitsCtrl,
                        style: TextStyle(color: textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Rasgos distintivos (opcionales)',
                          hintText: 'Separados por comas: Antiguo, Prohibido, Místico',
                          labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4), fontSize: 13),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF18181A) : const Color(0xFFF9F9FB),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: textPrimary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textSecondary,
                                side: BorderSide(color: borderSubtle),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : Colors.black,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('Guardar en el Códice', style: TextStyle(fontWeight: FontWeight.w700)),
                              onPressed: () {
                                final title = titleCtrl.text.trim();
                                if (title.isEmpty) return;

                                final rawTraits = traitsCtrl.text.split(',');
                                final traitsList = rawTraits
                                    .map((t) => t.trim())
                                    .where((t) => t.isNotEmpty)
                                    .toList();
                                if (traitsList.isEmpty) traitsList.add('Lore');

                                final role = roleCtrl.text.trim().isNotEmpty
                                    ? roleCtrl.text.trim()
                                    : 'Elemento de ${category.name}';

                                final newEntry = CodexEntryModel(
                                  id: 'codex_${DateTime.now().millisecondsSinceEpoch}',
                                  bookId: controller.activeBook.id,
                                  name: title,
                                  type: category,
                                  role: role,
                                  description: descCtrl.text.trim(),
                                  traits: traitsList,
                                  secrets: '',
                                  avatarEmoji: defaultEmojiForCategory(category),
                                  createdAt: DateTime.now(),
                                );
                                controller.addCodexEntry(newEntry);
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Entrada guardada en el códice del libro'), behavior: SnackBarBehavior.floating),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCodexDetailModal(BuildContext context, EditorController controller, CodexEntryModel entry, bool isDark) {
    final titleCtrl = TextEditingController(text: entry.name);
    final descCtrl = TextEditingController(text: entry.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bgCard = isDark ? const Color(0xFF1E1E22) : Colors.white;
        final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
        final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(entry.avatarEmoji, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              entry.type.name.toUpperCase(),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        tooltip: 'Eliminar entrada',
                        onPressed: () {
                          controller.deleteCodexEntry(entry.id);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Entrada eliminada'), behavior: SnackBarBehavior.floating),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'Título / Nombre',
                      labelStyle: TextStyle(color: textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 4,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Descripción / Lore',
                      labelStyle: TextStyle(color: textSecondary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Guardar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            final updated = entry.copyWith(
                              name: titleCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                            );
                            controller.updateCodexEntry(updated);
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Entrada actualizada'), behavior: SnackBarBehavior.floating),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Insertar en Editor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          controller.insertTextToEditor(
                            '\n/* Referencia Códice: ${entry.name} */\n${entry.description}\n',
                          );
                          Navigator.of(ctx).pop();
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
        );
      },
    );
  }

  void _showIdeaDetailModal(BuildContext context, EditorController controller, IdeaSnippetModel idea, bool isDark) {
    final titleCtrl = TextEditingController(text: idea.title);
    final contentCtrl = TextEditingController(text: idea.content);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bgCard = isDark ? const Color(0xFF1E1E22) : Colors.white;
        final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
        final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.lightbulb_outline_rounded, color: textPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          idea.title,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          idea.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                          color: idea.isPinned ? (isDark ? Colors.white : Colors.black) : textSecondary,
                        ),
                        tooltip: 'Fijar nota',
                        onPressed: () {
                          controller.toggleIdeaPin(idea.id);
                          Navigator.of(ctx).pop();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        tooltip: 'Eliminar nota',
                        onPressed: () {
                          controller.deleteIdea(idea.id);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nota eliminada'), behavior: SnackBarBehavior.floating),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'Título de la Nota',
                      labelStyle: TextStyle(color: textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Contenido / Fragmento',
                      labelStyle: TextStyle(color: textSecondary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Guardar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            final updated = idea.copyWith(
                              title: titleCtrl.text.trim(),
                              content: contentCtrl.text.trim(),
                            );
                            controller.updateIdea(updated);
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nota actualizada'), behavior: SnackBarBehavior.floating),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Insertar en Editor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          controller.insertIdeaToEditor(idea);
                          Navigator.of(ctx).pop();
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
        );
      },
    );
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

    final todayFormatted = WriterTextFormatter.formatSpanishDate(DateTime.now());

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (!_isInsideBookView) ...[
              // --- VISTA BIBLIOTECA (SELECCIÓN DE LIBRO) ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            todayFormatted.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'InkWright Studio',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Biblioteca de Manuscritos',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        ],
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
                )
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: -0.06, end: 0, curve: Curves.easeOutQuad),
              ),

              // Cabecera de Libros y Acción Nuevo Libro
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tus Libros (${controller.allBooks.length})',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Nuevo Libro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        onPressed: () => _showCreateBookDialog(context, controller),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideX(begin: -0.03, end: 0, curve: Curves.easeOutQuad),
              ),

              // Cuadrícula de Libros de la Biblioteca (Estilo MoonReader)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.67,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == controller.allBooks.length) {
                        // Tarjeta "Nuevo Libro" al final de la estantería
                        return InkWell(
                          onTap: () => _showCreateBookDialog(context, controller),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderSubtle,
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(Icons.add_rounded, size: 24, color: textPrimary),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Nuevo Libro',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                            .animate(delay: (index * 60).ms)
                            .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
                            .scale(
                              begin: const Offset(0.96, 0.96),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutCubic,
                            );
                      }

                      final book = controller.allBooks[index];
                      final isActive = book.id == controller.activeBook.id;
                      final targetWords = book.targetWordCount;
                      final currentWords = book.currentWordCount;
                      final ratio = targetWords > 0 ? (currentWords / targetWords).clamp(0.0, 1.0) : 0.0;
                      final percent = (ratio * 100).toInt();

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            controller.switchBook(book.id);
                            setState(() {
                              _isInsideBookView = true;
                              _selectedFilterIndex = 0;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive
                                    ? (isDark ? Colors.white38 : Colors.black38)
                                    : borderSubtle,
                                width: isActive ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                                  offset: const Offset(0, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Barra superior: Etiqueta y Opciones
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'LIBRO ACTIVO',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                            color: textPrimary,
                                          ),
                                        ),
                                      )
                                    else
                                      Text(
                                        'LIBRO',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: textSecondary.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    if (controller.allBooks.length > 1)
                                      InkWell(
                                        onTap: () => _showBookOptions(context, controller, book, isDark),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(2),
                                          child: Icon(Icons.more_vert_rounded, size: 16, color: textSecondary),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Portada / Emoji Central
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    book.coverEmoji,
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Título del libro
                                Text(
                                  book.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    letterSpacing: -0.2,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 3),

                                // Metadatos (capítulos y palabras)
                                Text(
                                  '${book.chapters.length} cap. • ${book.currentWordCount} pal.',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                ),

                                const Spacer(),

                                // Barra de Progreso
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progreso',
                                      style: TextStyle(fontSize: 9.5, color: textSecondary, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '$percent%',
                                      style: TextStyle(fontSize: 9.5, color: textPrimary, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 4,
                                    backgroundColor: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07),
                                    valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Botones de Acción (Abrir Estudio y Escribir)
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: textPrimary,
                                          side: BorderSide(color: borderSubtle),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(vertical: 5),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () {
                                          controller.switchBook(book.id);
                                          setState(() {
                                            _isInsideBookView = true;
                                            _selectedFilterIndex = 0;
                                          });
                                        },
                                        child: const Text(
                                          'Abrir Estudio',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark ? Colors.white : Colors.black,
                                        foregroundColor: isDark ? Colors.black : Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        controller.switchBook(book.id);
                                        setState(() {
                                          _isInsideBookView = true;
                                          _selectedFilterIndex = 0;
                                        });
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                                        );
                                      },
                                      child: const Text(
                                        'Escribir',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                          .animate(delay: (index * 60).ms)
                          .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
                          .scale(
                            begin: const Offset(0.96, 0.96),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutCubic,
                          );
                    },
                    childCount: controller.allBooks.length + 1,
                  ),
                ),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                              _bookFilters[index],
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

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // SECCIÓN 0: MANUSCRITO ACTIVO Y ESCRITURA DIRECTA
            if (_selectedFilterIndex == 0) ...[
              // Tarjeta Principal de Escritura (Hero Writing Card)
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
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                controller.activeBook.coverEmoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.activeBook.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${controller.activeBook.chapters.length} capítulos • ${controller.activeBook.currentWordCount} palabras',
                                    style: TextStyle(fontSize: 12.5, color: textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Barra de Progreso del Objetivo de Palabras
                        Builder(
                          builder: (context) {
                            final targetWords = controller.activeBook.targetWordCount;
                            final currentWords = controller.activeBook.currentWordCount;
                            final ratio = targetWords > 0 ? (currentWords / targetWords).clamp(0.0, 1.0) : 0.0;
                            final percent = (ratio * 100).toInt();

                            return Column(
                              children: [
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progreso del Libro',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                                    ),
                                    Text(
                                      '$percent% ($currentWords / $targetWords pal.)',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 5,
                                    backgroundColor: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07),
                                    valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : Colors.black),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 18),

                        // Botón Principal "Continuar Escribiendo"
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                          label: const Text(
                            'Continuar Escribiendo',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        // Fila de 3 Acciones Secundarias (Nombres concisos y legibles completos)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(color: borderSubtle),
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 17),
                                label: const Text(
                                  'Capítulo',
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                onPressed: () {
                                  controller.addNewChapter('Nuevo Capítulo');
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ZenEditorScreen()),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(color: borderSubtle),
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                icon: const Icon(Icons.hub_outlined, size: 16),
                                label: const Text(
                                  'Mapa Mental',
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const PlotMindMapScreen()),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(color: borderSubtle),
                                  minimumSize: const Size(0, 42),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                icon: const Icon(Icons.person_search_rounded, size: 16),
                                label: const Text(
                                  'Personajes',
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedFilterIndex = 1; // Personajes
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Center(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: textSecondary,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                            label: const Text(
                              'Cambiar de Libro',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              setState(() {
                                _isInsideBookView = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

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
                          fontSize: 18,
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
                            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                            boxShadow: AppTheme.getSoftShadow(isDark),
                          ),
                          child: Material(
                            color: bgCard,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
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
                                  borderRadius: BorderRadius.circular(10),
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
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${chapter.wordCount} palabras • ${chapter.readingTimeMinutes} min lectura',
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: textSecondary),
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

            // SECCIÓN 1: PERSONAJES DE LA HISTORIA
            if (_selectedFilterIndex == 1) ...[
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: const CharactersScreen(isEmbedded: true),
                ),
              ),
            ],

            // SECCIÓN 2: MAPA DE TRAMA BANNER
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                            onPressed: () => _showAddCodexDialog(context, controller, isDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (controller.codexEntries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
                            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                            border: Border.all(color: borderSubtle),
                            boxShadow: AppTheme.getSoftShadow(isDark),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.auto_stories_outlined, size: 36, color: textSecondary.withValues(alpha: 0.5)),
                              const SizedBox(height: 10),
                              Text(
                                'Sin entradas en el códice para este libro',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Registra personajes, lugares, reliquias y conceptos exclusivos de "${controller.activeBook.title}".',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(color: borderSubtle),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Crear Primera Entrada'),
                                onPressed: () => _showAddCodexDialog(context, controller, isDark),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
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
                              onTap: () => _showCodexDetailModal(context, controller, entry, isDark),
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
                            onPressed: () => _showAddIdeaDialog(context, controller, isDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (controller.ideas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
                            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                            border: Border.all(color: borderSubtle),
                            boxShadow: AppTheme.getSoftShadow(isDark),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.lightbulb_outline_rounded, size: 36, color: textSecondary.withValues(alpha: 0.5)),
                              const SizedBox(height: 10),
                              Text(
                                'Sin fragmentos ni notas para este libro',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Apunta diálogos, giros y notas rápidas exclusivas de "${controller.activeBook.title}".',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(color: borderSubtle),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Crear Primer Fragmento'),
                                onPressed: () => _showAddIdeaDialog(context, controller, isDark),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
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
                              onTap: () => _showIdeaDetailModal(context, controller, idea, isDark),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // SECCIÓN 5: MÉTRICAS & ESTADÍSTICAS
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

            // SECCIÓN 6: HERRAMIENTAS & PRODUCTIVIDAD
            if (_selectedFilterIndex == 6) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de Meta Diaria de Escritura (Configurable con respiro visual amplio)
                      Container(
                        width: double.infinity,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.flag_rounded, size: 20, color: textPrimary),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Meta Diaria de Escritura',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${controller.writerStats.wordsToday} de ${controller.writerStats.dailyGoalWords} palabras hoy',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Porcentaje separado con respiro visual amplio
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    '${controller.writerStats.dailyPercentage}%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: controller.writerStats.dailyGoalRatio,
                                minHeight: 6,
                                backgroundColor: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                                valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : Colors.black),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(color: borderSubtle),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                ),
                                icon: const Icon(Icons.tune_rounded, size: 17),
                                label: const Text(
                                  'Ajustar Meta Diaria',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                                onPressed: () => _showEditDailyGoalModal(context, controller, isDark),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        'Herramientas y Productividad',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Utilidades para inspirarte, estructurar y gestionar tu obra',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textPrimary,
                                side: BorderSide(color: borderSubtle),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                              ),
                              icon: const Icon(Icons.auto_awesome_outlined, size: 17),
                              label: const Text('Asistente Muse', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                              onPressed: () => _openMuseStudio(context, isDark),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textPrimary,
                                side: BorderSide(color: borderSubtle),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                              ),
                              icon: const Icon(Icons.menu_book_rounded, size: 17),
                              label: const Text('Guía y Tutorial', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                              onPressed: () => _openTutorialSheet(context, isDark, controller),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textPrimary,
                                side: BorderSide(color: borderSubtle),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                              ),
                              icon: const Icon(Icons.timer_outlined, size: 17),
                              label: const Text('Sprint de Escritura', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                              onPressed: () => _openSprintDialog(context, isDark),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textPrimary,
                                side: BorderSide(color: borderSubtle),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                              ),
                              icon: const Icon(Icons.ios_share_rounded, size: 17),
                              label: const Text('Exportar Libro', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                              onPressed: () => _openExportDialog(context, isDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Card de Copia de Seguridad Integral (.inkwright)
                      Container(
                        width: double.infinity,
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
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.shield_outlined,
                                    size: 20,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Copia de Seguridad Integral',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Exporta o restaura toda tu biblioteca (.inkwright)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Guarda una copia completa en archivo local de tus novelas, capítulos, personajes, códice, notas y mapas de trama para no perder nunca tu trabajo o transferirlo a otro dispositivo.',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? Colors.white : Colors.black,
                                      foregroundColor: isDark ? Colors.black : Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.download_rounded, size: 17),
                                    label: const Text('Exportar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    onPressed: () => _handleExportBackup(context, controller, isDark),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: textPrimary,
                                      side: BorderSide(color: borderSubtle),
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                    ),
                                    icon: const Icon(Icons.settings_backup_restore_rounded, size: 17),
                                    label: const Text('Restaurar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    onPressed: () => _showRestoreDialog(context, controller, isDark),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
            _showCreateBookDialog(context, controller);
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
