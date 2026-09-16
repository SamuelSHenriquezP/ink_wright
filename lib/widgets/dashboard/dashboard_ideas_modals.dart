import 'package:flutter/material.dart';
import '../../controllers/editor_controller.dart';
import '../../models/idea_snippet_model.dart';
import '../../screens/zen_editor_screen.dart';
import '../../theme/app_theme.dart';

class DashboardIdeasModals {
  static void showAddIdeaDialog(BuildContext context, EditorController controller, bool isDark) {
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

  static void showIdeaDetailModal(BuildContext context, EditorController controller, IdeaSnippetModel idea, bool isDark) {
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
}

