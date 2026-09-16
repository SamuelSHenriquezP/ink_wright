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
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    final isDark = Provider.of<ThemeController>(context, listen: false).isDarkMode;
                    ImportManuscriptDialog.show(context, isDark: isDark);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.file_download_outlined, size: 16, color: Colors.blueAccent),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'O importar desde archivo (.docx, .epub, .md, .txt)',
                            style: TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  onBookCreated?.call();
                }
              },
              child: const Text('Crear Libro'),
            ),
          ],
        );
      },
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
}
