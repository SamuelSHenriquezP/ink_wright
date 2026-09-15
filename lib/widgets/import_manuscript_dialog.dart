import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/editor_controller.dart';
import '../services/import_service.dart';

enum ImportMode {
  newBook,
  intoCurrentBook,
}

class ImportManuscriptDialog extends StatefulWidget {
  final bool isDark;
  final String? targetBookId;
  final bool forceChaptersMode;

  const ImportManuscriptDialog({
    super.key,
    required this.isDark,
    this.targetBookId,
    this.forceChaptersMode = false,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isDark,
    String? targetBookId,
    bool forceChaptersMode = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ImportManuscriptDialog(
        isDark: isDark,
        targetBookId: targetBookId,
        forceChaptersMode: forceChaptersMode,
      ),
    );
  }

  @override
  State<ImportManuscriptDialog> createState() => _ImportManuscriptDialogState();
}

class _ImportManuscriptDialogState extends State<ImportManuscriptDialog> {
  bool _isProcessing = false;
  String? _selectedFileName;
  ImportedBookData? _parsedData;

  late ImportMode _importMode;
  late TextEditingController _titleController;
  late TextEditingController _genreController;
  late TextEditingController _targetWordsController;
  bool _isChaptersPreviewExpanded = false;

  @override
  void initState() {
    super.initState();
    _importMode = widget.forceChaptersMode ? ImportMode.intoCurrentBook : ImportMode.newBook;
    _titleController = TextEditingController();
    _genreController = TextEditingController(text: 'Ficción');
    _targetWordsController = TextEditingController(text: '80000');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _genreController.dispose();
    _targetWordsController.dispose();
    super.dispose();
  }

  Future<void> _pickAndParseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx', 'epub', 'md', 'markdown', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudieron leer los datos del archivo.')),
          );
        }
        return;
      }

      setState(() {
        _isProcessing = true;
        _selectedFileName = file.name;
      });

      final parsed = await ImportService.parseFile(Uint8List.fromList(bytes), file.name);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _parsedData = parsed;
        if (parsed != null) {
          _titleController.text = parsed.title;
          if (parsed.genre.isNotEmpty) {
            _genreController.text = parsed.genre;
          }
          final estimatedTarget = parsed.totalWords > 0 ? (parsed.totalWords * 1.25).round() : 80000;
          _targetWordsController.text = estimatedTarget.toString();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al analizar el archivo: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _executeImport(EditorController controller) {
    if (_parsedData == null) return;

    if (_importMode == ImportMode.newBook) {
      final target = int.tryParse(_targetWordsController.text) ?? 80000;
      final finalData = ImportedBookData(
        title: _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : _parsedData!.title,
        subtitle: _parsedData!.subtitle,
        author: _parsedData!.author,
        genre: _genreController.text.trim().isNotEmpty ? _genreController.text.trim() : 'Ficción',
        synopsis: _parsedData!.synopsis,
        targetWordCount: target,
        chapters: _parsedData!.chapters,
      );

      controller.importNewBook(finalData);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Libro "${finalData.title}" importado con éxito (${finalData.chapters.length} capítulos)!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Importar como capítulos en el libro actual o indicado
      if (widget.targetBookId != null && widget.targetBookId != controller.activeBook.id) {
        controller.switchBook(widget.targetBookId!);
      }

      controller.importChaptersIntoActiveBook(_parsedData!.chapters);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡${_parsedData!.chapters.length} capítulos añadidos a "${controller.activeBook.title}"!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EditorController>(context, listen: false);
    final isDark = widget.isDark;

    final bgCard = isDark ? const Color(0xFF18181B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF18181B);
    final textSecondary = isDark ? Colors.white60 : Colors.black54;
    final borderSubtle = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08);
    final accentBg = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de agarre superior
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Encabezado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.file_download_rounded, color: textPrimary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Importar Manuscrito',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Soporta Word (.docx), EPUB (.epub), Markdown y TXT',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Contenido deslizable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Si no se ha elegido archivo, mostrar botón principal de selección
                    if (_parsedData == null && !_isProcessing) ...[
                      _buildFilePickerArea(isDark, borderSubtle, textPrimary, textSecondary),
                    ],

                    if (_isProcessing) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: textPrimary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Analizando y extrayendo capítulos...',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedFileName ?? '',
                                style: TextStyle(color: textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Si ya se parseó el archivo
                    if (_parsedData != null && !_isProcessing) ...[
                      // Resumen del archivo analizado
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: accentBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.description_outlined, color: textPrimary, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFileName ?? 'Archivo cargado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_parsedData!.chapters.length} capítulos detectados • ${_parsedData!.totalWords} palabras',
                                    style: TextStyle(color: textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _pickAndParseFile,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Cambiar', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Selector de modo (si no está forzado a capítulos)
                      if (!widget.forceChaptersMode) ...[
                        Text(
                          'Destino de la importación',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModeOption(
                                title: 'Nuevo Libro',
                                subtitle: 'Crea una obra en la biblioteca',
                                isSelected: _importMode == ImportMode.newBook,
                                onTap: () => setState(() => _importMode = ImportMode.newBook),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildModeOption(
                                title: 'Al Libro Actual',
                                subtitle: 'Añade como capítulos',
                                isSelected: _importMode == ImportMode.intoCurrentBook,
                                onTap: () => setState(() => _importMode = ImportMode.intoCurrentBook),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Opciones para Nuevo Libro
                      if (_importMode == ImportMode.newBook) ...[
                        Text(
                          'Configuración del Libro',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _titleController,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Título del Libro',
                            labelStyle: TextStyle(color: textSecondary),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderSubtle),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderSubtle),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _genreController,
                                style: TextStyle(color: textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Género',
                                  labelStyle: TextStyle(color: textSecondary),
                                  filled: true,
                                  fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: borderSubtle),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: borderSubtle),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _targetWordsController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Meta Palabras',
                                  labelStyle: TextStyle(color: textSecondary),
                                  filled: true,
                                  fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: borderSubtle),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: borderSubtle),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Previsualización de capítulos detectados
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              dense: true,
                              title: Text(
                                'Capítulos Detectados (${_parsedData!.chapters.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Icon(
                                _isChaptersPreviewExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: textSecondary,
                              ),
                              onTap: () {
                                setState(() {
                                  _isChaptersPreviewExpanded = !_isChaptersPreviewExpanded;
                                });
                              },
                            ),
                            if (_isChaptersPreviewExpanded)
                              Container(
                                constraints: const BoxConstraints(maxHeight: 220),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                  itemCount: _parsedData!.chapters.length,
                                  separatorBuilder: (_, index) => Divider(color: borderSubtle, height: 1),
                                  itemBuilder: (context, idx) {
                                    final ch = _parsedData!.chapters[idx];
                                    final previewText = ch.content.length > 80
                                        ? '${ch.content.substring(0, 80).replaceAll('\n', ' ')}...'
                                        : ch.content.replaceAll('\n', ' ');

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: accentBg,
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${idx + 1}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: textPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  ch.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    color: textPrimary,
                                                  ),
                                                ),
                                                if (previewText.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    previewText,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${ch.wordCount} pal.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Botón de acción inferior
            if (_parsedData != null && !_isProcessing)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderSubtle)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancelar', style: TextStyle(color: textSecondary)),
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
                        label: Text(
                          _importMode == ImportMode.newBook ? 'Crear e Importar' : 'Agregar Capítulos',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => _executeImport(controller),
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

  Widget _buildFilePickerArea(
    bool isDark,
    Color borderSubtle,
    Color textPrimary,
    Color textSecondary,
  ) {
    return InkWell(
      onTap: _pickAndParseFile,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.015),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderSubtle, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.upload_file_rounded, size: 36, color: textPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              'Seleccionar archivo para importar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Elige un archivo Word (.docx), EPUB (.epub), Markdown (.md) o Texto (.txt)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: textSecondary),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildFormatBadge('DOCX', 'Word', isDark),
                _buildFormatBadge('EPUB', 'Ebook', isDark),
                _buildFormatBadge('MD', 'Markdown', isDark),
                _buildFormatBadge('TXT', 'Texto', isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatBadge(String ext, String desc, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ext,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            desc,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final border = isSelected
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08));

    final bg = isSelected
        ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04))
        : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: isSelected ? 1.8 : 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  size: 16,
                  color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
