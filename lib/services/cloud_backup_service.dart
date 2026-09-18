import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/editor_controller.dart';
import '../theme/app_theme.dart';

/// Servicio de respaldo en la nube gratuito (Google Drive / Nube personal).
/// Permite exportar copias de seguridad .inkwright al Google Drive del usuario
/// y restaurarlas directamente desde el selector de la nube con 1 toque.
class CloudBackupService {
  const CloudBackupService._();

  static const String _keyLastCloudUpload = 'ink_last_cloud_backup_timestamp';

  /// Obtiene la fecha y hora de la última subida a la nube registrada.
  static Future<DateTime?> getLastCloudUploadTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyLastCloudUpload);
      if (str != null) return DateTime.tryParse(str);
    } catch (_) {}
    return null;
  }

  /// Formatea la fecha de la última subida para mostrarla en la interfaz.
  static String formatLastUploadText(DateTime? dt) {
    if (dt == null) return 'Pendiente (sin copia reciente)';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 2) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24 && dt.day == now.day) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return 'Hoy a las $hour:$minute';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  /// Genera el respaldo .inkwright y abre el menú nativo para guardarlo en Google Drive u otra nube.
  static Future<bool> uploadToCloudDrive(
    BuildContext context,
    EditorController controller, {
    bool silent = false,
  }) async {
    try {
      final backupJson = controller.exportBackupJson();
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final filename = 'InkWright_Nube_$dateStr.inkwright';

      // Guardar registro de la fecha en SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyLastCloudUpload, now.toIso8601String());
      } catch (_) {}

      // Copiar también al portapapeles como respaldo de seguridad adicional
      await Clipboard.setData(ClipboardData(text: backupJson));

      // Abrir el selector nativo de compartir para que el usuario elija "Guardar en Drive"
      await Printing.sharePdf(
        bytes: Uint8List.fromList(utf8.encode(backupJson)),
        filename: filename,
        subject: 'Copia de Seguridad Ink & Wright en Google Drive',
      );

      if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Respaldo listo ($filename). Selecciona "Guardar en Drive" para subirlo.'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return true;
    } catch (e) {
      if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al preparar copia para la nube: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  /// Permite elegir un archivo .inkwright desde Google Drive o almacenamiento local para restaurar la biblioteca.
  static Future<bool> restoreFromCloudDrive(
    BuildContext context,
    EditorController controller, {
    bool isDark = false,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['inkwright', 'json'],
        withData: true,
      );

      if (!context.mounted || result == null || result.files.single.bytes == null) {
        return false;
      }

      final file = result.files.single;
      final fileName = file.name;

      // Diálogo de confirmación para evitar sobreescritura involuntaria
      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final bgCard = isDark ? AppTheme.darkSurfaceCard : AppTheme.lightSurfaceCard;
          final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
          final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

          return AlertDialog(
            backgroundColor: bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
            title: Row(
              children: [
                const Icon(Icons.cloud_download_rounded, color: Colors.blueAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¿Restaurar desde la nube?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                  ),
                ),
              ],
            ),
            content: Text(
              'Se restaurará el archivo "$fileName". Esta acción sincronizará tus novelas, capítulos, notas y personajes con la copia de la nube.\n\nSe recomienda tener un respaldo reciente antes de continuar.',
              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.45),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Restaurar ahora'),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          );
        },
      );

      if (shouldRestore != true || !context.mounted) return false;

      final jsonStr = utf8.decode(file.bytes!);
      final success = controller.restoreFromBackupJson(jsonStr);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('¡Biblioteca restaurada con éxito desde la nube!'),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No se pudo procesar el archivo. Asegúrate de que sea un respaldo válido de Ink Wright.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return success;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al restaurar desde la nube: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  /// Muestra un recordatorio sutil de 1 toque al salir del editor si no se ha respaldado recientemente.
  static Future<void> promptCloudBackupReminder(
    BuildContext context,
    EditorController controller,
  ) async {
    try {
      final lastTime = await getLastCloudUploadTime();
      // Si nunca ha respaldado o pasaron más de 8 horas
      final shouldRemind = lastTime == null || DateTime.now().difference(lastTime).inHours >= 8;
      if (!shouldRemind || !context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('💾 Manuscrito guardado. ¿Deseas asegurar tu copia en Google Drive?'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Subir a Drive',
            textColor: Colors.amberAccent,
            onPressed: () {
              uploadToCloudDrive(context, controller);
            },
          ),
        ),
      );
    } catch (_) {}
  }
}
