import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/editor_controller.dart';
import '../../theme/app_theme.dart';

class DashboardRestoreDialog {
  static void show(BuildContext context, EditorController controller, bool isDark) {
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
                      'Carga tu archivo de respaldo (.inkwright o JSON) o pega su contenido. Esta acción sincronizará tus novelas, códice, ideas y trama.',
                      style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.cloud_download_outlined, size: 16),
                            label: const Text('Archivo / Drive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            onPressed: () async {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['inkwright', 'json'],
                                withData: true,
                              );
                              if (result != null && result.files.single.bytes != null) {
                                final text = utf8.decode(result.files.single.bytes!);
                                setDialogState(() {
                                  textController.text = text;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textPrimary,
                              side: BorderSide(color: borderSubtle),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.paste_rounded, size: 16),
                            label: const Text('Portapapeles', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            onPressed: () async {
                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                              if (data?.text != null && data!.text!.isNotEmpty) {
                                setDialogState(() {
                                  textController.text = data.text!;
                                });
                              }
                            },
                          ),
                        ),
                      ],
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
}

