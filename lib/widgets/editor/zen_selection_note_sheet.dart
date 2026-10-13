import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../models/idea_snippet_model.dart';
import '../../models/codex_entry_model.dart';
import '../../theme/app_theme.dart';
import 'synonyms_sheet.dart';

class ZenSelectionNoteSheet {
  static void show({
    required BuildContext context,
    required EditorController controller,
    required bool isDark,
    required String selectedText,
    required TextSelection selection,
    required String fullText,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bgCard = isDark ? const Color(0xFF1E1E22) : Colors.white;
        final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
        final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anotar Selección',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '«$selectedText»',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.bookmark_add_outlined),
                  title: Text('Fijar Marcapáginas aquí', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('Guarda este punto para volver a él con 1 toque más adelante', style: TextStyle(color: textSecondary, fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    controller.addBookmark(
                      controller.activeChapter.id,
                      charOffset: selection.start,
                      previewText: selectedText,
                      label: selectedText.length > 25 ? '${selectedText.substring(0, 25)}...' : selectedText,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Marcapáginas fijado en esta posición.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded),
                  title: Text('Buscar Sinónimos Literarios', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('Encuentra alternativas estilísticas y matices para esta palabra', style: TextStyle(color: textSecondary, fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    SynonymsSheet.show(
                      context: context,
                      initialWord: selectedText,
                      isDark: isDark,
                      onReplaceWord: (replacement) {
                        final newText = fullText.replaceRange(selection.start, selection.end, replacement);
                        controller.textEditingController.value = TextEditingValue(
                          text: newText,
                          selection: TextSelection.collapsed(offset: selection.start + replacement.length),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Reemplazado por «$replacement».'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lightbulb_outline_rounded),
                  title: Text('Guardar como Idea / Nota', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('Añade este fragmento al banco de ideas del proyecto', style: TextStyle(color: textSecondary, fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    controller.addIdea(IdeaSnippetModel(
                      id: 'idea_${DateTime.now().millisecondsSinceEpoch}',
                      title: selectedText.length > 30 ? '${selectedText.substring(0, 30)}...' : selectedText,
                      content: selectedText,
                      category: IdeaCategory.general,
                      colorHex: 0xFF18181B,
                      createdAt: DateTime.now(),
                      tags: ['Idea', 'Nota'],
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Guardado en Ideas con éxito.'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.auto_stories_outlined),
                  title: Text('Guardar en Códice del Mundo (Lore)', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('Registra este concepto en la enciclopedia de la historia', style: TextStyle(color: textSecondary, fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showAddCodexDialog(context, controller, isDark, selectedText);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.comment_outlined),
                  title: Text('Insertar como Nota de Autor', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('Envuelve el texto entre marcas Markdown <!-- [Nota]: ... -->', style: TextStyle(color: textSecondary, fontSize: 12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    final wrapped = '<!-- [Nota]: $selectedText -->';
                    final newText = fullText.replaceRange(selection.start, selection.end, wrapped);
                    controller.textEditingController.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: selection.start + wrapped.length),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showAddCodexDialog(BuildContext context, EditorController controller, bool isDark, String initialContent) {
    final titleCtrl = TextEditingController(
      text: initialContent.length > 30 ? '${initialContent.substring(0, 30)}...' : initialContent,
    );
    String selectedCategory = 'Lore';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
          title: Text(
            'Nueva Entrada del Códice',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Título del concepto / entrada',
                  labelStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                dropdownColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard,
                style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  labelStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
                items: ['Lore', 'Ubicaciones', 'Objetos', 'Magia / Leyes', 'Facciones']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDlgState(() => selectedCategory = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancelar', style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isNotEmpty) {
                  CodexType codexType = CodexType.lore;
                  if (selectedCategory == 'Ubicaciones') codexType = CodexType.location;
                  if (selectedCategory == 'Objetos') codexType = CodexType.artifact;

                  controller.addCodexEntry(CodexEntryModel(
                    id: 'codex_${DateTime.now().millisecondsSinceEpoch}',
                    bookId: controller.activeBook.id,
                    name: title,
                    type: codexType,
                    role: selectedCategory,
                    description: initialContent,
                    traits: [selectedCategory],
                    secrets: '',
                    avatarEmoji: codexType == CodexType.location
                        ? '🏰'
                        : (codexType == CodexType.artifact ? '🗝️' : '📜'),
                    createdAt: DateTime.now(),
                  ));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Entrada añadida al Códice con éxito.'), behavior: SnackBarBehavior.floating),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

