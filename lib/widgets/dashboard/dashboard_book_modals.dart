import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/editor_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/book_model.dart';
import '../../theme/app_theme.dart';
import '../export_manuscript_dialog.dart';
import '../import_manuscript_dialog.dart';

class DashboardBookModals {
  static void showCreateBookDialog(
    BuildContext context,
    EditorController controller, {
    VoidCallback? onBookCreated,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _CreateBookDialog(
        controller: controller,
        onBookCreated: onBookCreated,
      ),
    );
  }

  static void showBookOptions(
    BuildContext context,
    EditorController controller,
    BookModel book,
    bool isDark,
  ) {
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
                ExportManuscriptDialog.show(context, isDark: isDark);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Importar Capítulos a este Libro', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Añadir contenido desde .docx, .epub, .md o .txt'),
              onTap: () {
                Navigator.of(ctx).pop();
                ImportManuscriptDialog.show(
                  context,
                  isDark: isDark,
                  targetBookId: book.id,
                  forceChaptersMode: true,
                );
              },
            ),
            if (controller.allBooks.length > 1)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Eliminar Libro', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                subtitle: const Text('Se borrarán sus capítulos, personajes y trama'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  confirmDeleteBook(context, controller, book);
                },
              ),
          ],
        ),
      ),
    );
  }

  static void confirmDeleteBook(
    BuildContext context,
    EditorController controller,
    BookModel book,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('¿Eliminar libro?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Se eliminará permanentemente "${book.title}" con todos sus capítulos, mapa de trama y personajes asociados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
}

class _CreateBookDialog extends StatefulWidget {
  final EditorController controller;
  final VoidCallback? onBookCreated;

  const _CreateBookDialog({
    required this.controller,
    this.onBookCreated,
  });

  @override
  State<_CreateBookDialog> createState() => _CreateBookDialogState();
}

class _CreateBookDialogState extends State<_CreateBookDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subCtrl;
  late final TextEditingController _targetCtrl;

  String _selectedEmoji = '📖';
  String _selectedGenre = 'Ficción';
  bool _titleHasError = false;

  static const List<String> _emojis = [
    '📖', '🖋️', '📜', '🌑', '⚔️', '🕯️', '🗝️', '🌿', '🎭', '🌌', '👁️', '👑',
  ];

  static const List<String> _genres = [
    'Ficción',
    'Fantasía',
    'Ciencia Ficción',
    'Misterio',
    'Terror',
    'No Ficción',
    'Romance',
    'Aventura',
  ];

  static const List<int> _wordPresets = [25000, 50000, 80000, 100000];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _subCtrl = TextEditingController();
    _targetCtrl = TextEditingController(text: '80000');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleHasError = true;
      });
      return;
    }

    final target = int.tryParse(_targetCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 80000;
    widget.controller.createNewBook(
      title,
      _subCtrl.text.trim(),
      target,
      genre: _selectedGenre,
      coverEmoji: _selectedEmoji,
    );

    Navigator.of(context).pop();
    widget.onBookCreated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDark = themeController.isDarkMode;

    final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderSubtle = isDark ? AppTheme.darkBorderSubtle : AppTheme.lightBorderSubtle;
    final accentBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04);

    return Dialog(
      backgroundColor: bgCard,
      elevation: 6,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderSubtle, width: 1.2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderSubtle),
                    ),
                    alignment: Alignment.center,
                    child: Text(_selectedEmoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nuevo Manuscrito',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Ficha inicial y configuración de tu obra',
                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderSubtle),

            // Formulario Scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector de Emoji / Portada
                    Text(
                      'SÍMBOLO DE PORTADA',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _emojis.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final emoji = _emojis[i];
                          final isSelected = emoji == _selectedEmoji;
                          return InkWell(
                            onTap: () => setState(() => _selectedEmoji = emoji),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? Colors.white : Colors.black)
                                    : accentBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark ? Colors.white : Colors.black)
                                      : borderSubtle,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                emoji,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: isSelected
                                      ? (isDark ? Colors.black : Colors.white)
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Título del Libro
                    Text(
                      'TÍTULO DEL LIBRO *',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleCtrl,
                      autofocus: true,
                      style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Ej. El Resplandor de las Cenizas',
                        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: accentBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        errorText: _titleHasError ? 'El título no puede estar vacío' : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: textPrimary, width: 1.2),
                        ),
                      ),
                      onChanged: (_) {
                        if (_titleHasError) {
                          setState(() => _titleHasError = false);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Subtítulo / Premisa
                    Text(
                      'SUBTÍTULO / PREMISA BREVE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _subCtrl,
                      style: TextStyle(color: textPrimary, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Ej. Libro I de la Saga del Horizonte',
                        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: accentBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: textPrimary, width: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Género Literario
                    Text(
                      'GÉNERO PRINCIPAL',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _genres.map((genre) {
                        final isSelected = genre == _selectedGenre;
                        return InkWell(
                          onTap: () => setState(() => _selectedGenre = genre),
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? Colors.white : Colors.black)
                                  : accentBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? (isDark ? Colors.white : Colors.black)
                                    : borderSubtle,
                              ),
                            ),
                            child: Text(
                              genre,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? (isDark ? Colors.black : Colors.white)
                                    : textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Meta de Palabras
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'OBJETIVO DE PALABRAS',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Meta total de la obra',
                          style: TextStyle(fontSize: 10.5, color: textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _targetCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.flag_outlined, size: 18, color: textSecondary),
                        hintText: '80000',
                        filled: true,
                        fillColor: accentBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: textPrimary, width: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Chips de metas rápidas
                    Row(
                      children: _wordPresets.map((words) {
                        final currentVal = int.tryParse(_targetCtrl.text) ?? 0;
                        final isSelected = currentVal == words;
                        final label = words >= 1000 ? '${words ~/ 1000}k' : '$words';
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5),
                            child: InkWell(
                              onTap: () => setState(() => _targetCtrl.text = words.toString()),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08))
                                      : accentBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? textPrimary : borderSubtle,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? textPrimary : textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Opción Importar archivo existente
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        ImportManuscriptDialog.show(context, isDark: isDark);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: accentBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.file_download_outlined, size: 18, color: textPrimary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¿Ya tienes un borrador escrito?',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                                  ),
                                  Text(
                                    'Importar desde archivo (.docx, .epub, .md, .txt)',
                                    style: TextStyle(fontSize: 10.5, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 18, color: textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: borderSubtle),

            // Botones de acción inferiores
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          side: BorderSide(color: borderSubtle),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _submit,
                        child: const Text('Crear Libro', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
