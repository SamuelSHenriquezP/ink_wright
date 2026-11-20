import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/editor_controller.dart';
import '../theme/app_theme.dart';

enum BackupShareState { prepared, shared, cancelled, unavailable, failed }

class CloudBackupStatus {
  final DateTime? preparedAt;
  final DateTime? sharedAt;
  final BackupShareState? lastState;

  const CloudBackupStatus({this.preparedAt, this.sharedAt, this.lastState});

  // A share-sheet result never confirms an upload to a cloud provider.
  bool get cloudUploadConfirmed => false;
}

/// Prepares a backup and hands it to another app, without asserting an upload.
class CloudBackupService {
  const CloudBackupService._();

  static const String _keyPrepared = 'ink_backup_prepared_at';
  static const String _keyShared = 'ink_backup_shared_at';
  static const String _keyState = 'ink_backup_share_state';
  static final ValueNotifier<int> statusRevision = ValueNotifier(0);
  static bool _isSharing = false;

  static Future<CloudBackupStatus> getBackupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final rawState = prefs.getString(_keyState);
    BackupShareState? state;
    for (final value in BackupShareState.values) {
      if (value.name == rawState) state = value;
    }
    return CloudBackupStatus(
      preparedAt: DateTime.tryParse(prefs.getString(_keyPrepared) ?? ''),
      sharedAt: DateTime.tryParse(prefs.getString(_keyShared) ?? ''),
      lastState: state,
    );
  }

  static String formatBackupTime(DateTime? dt) {
    if (dt == null) return 'Sin registro';
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

  static String shareMessage(BackupShareState state) => switch (state) {
    BackupShareState.prepared => 'Archivo preparado para compartir.',
    BackupShareState.shared => 'Archivo compartido con otra aplicación. La subida a la nube no está confirmada.',
    BackupShareState.cancelled => 'Envío cancelado. No se confirmó ninguna subida a la nube.',
    BackupShareState.unavailable => 'Archivo preparado. No se pudo confirmar si se compartió ni si se subió a la nube.',
    BackupShareState.failed => 'No se pudo compartir el respaldo. No se confirmó ninguna subida a la nube.',
  };

  static Future<BackupShareState> shareBackupFile(
    BuildContext context,
    EditorController controller, {
    bool silent = false,
    Future<ShareResult> Function(ShareParams)? share,
  }) async {
    if (_isSharing) return BackupShareState.prepared;
    _isSharing = true;
    var state = BackupShareState.failed;
    SharedPreferences? prefs;
    try {
      await controller.ready;
      await controller.flushAndBackup();
      final backupJson = controller.exportBackupJson();
      final preparedAt = DateTime.now();
      final stamp = preparedAt.toIso8601String().replaceAll(':', '-');
      final filename = 'InkWright_$stamp.inkwright';
      prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPrepared, preparedAt.toIso8601String());
      await prefs.setString(_keyState, BackupShareState.prepared.name);
      statusRevision.value++;
      if (!context.mounted) {
        state = BackupShareState.cancelled;
      } else {
        final renderObject = context.findRenderObject();
        final result = await (share ?? SharePlus.instance.share)(ShareParams(
          files: [XFile.fromData(Uint8List.fromList(utf8.encode(backupJson)), name: filename, mimeType: 'application/json')],
          fileNameOverrides: [filename],
          subject: 'Respaldo de InkWright',
          sharePositionOrigin: renderObject is RenderBox && renderObject.hasSize
              ? renderObject.localToGlobal(Offset.zero) & renderObject.size : null,
        ));
        state = switch (result.status) {
          ShareResultStatus.success => BackupShareState.shared,
          ShareResultStatus.dismissed => BackupShareState.cancelled,
          ShareResultStatus.unavailable => BackupShareState.unavailable,
        };
        if (state == BackupShareState.shared) {
          await prefs.setString(_keyShared, DateTime.now().toIso8601String());
        }
      }
    } catch (error) {
      debugPrint('Error al preparar o compartir respaldo: $error');
      state = BackupShareState.failed;
    } finally {
      try {
        prefs ??= await SharedPreferences.getInstance();
        await prefs.setString(_keyState, state.name);
      } catch (error) {
        debugPrint('Error al registrar estado del respaldo: $error');
      } finally {
        _isSharing = false;
        statusRevision.value++;
      }
    }
    if (!silent && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(shareMessage(state)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ));
    }
    return state;
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
                    '¿Restaurar este archivo?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                  ),
                ),
              ],
            ),
            content: Text(
              'Se restaurará el archivo "$fileName". Esta acción reemplazará tu biblioteca con los datos del archivo seleccionado.\n\nSe recomienda tener un respaldo reciente antes de continuar.',
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
                    child: Text('¡Biblioteca restaurada desde el archivo seleccionado!'),
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
            content: Text('Error al restaurar el archivo: $e'),
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
      final lastTime = (await getBackupStatus()).sharedAt;
      // Si nunca ha respaldado o pasaron más de 8 horas
      final shouldRemind = lastTime == null || DateTime.now().difference(lastTime).inHours >= 8;
      if (!shouldRemind || !context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Manuscrito guardado. ¿Compartir un respaldo?'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Compartir',
            textColor: Colors.amberAccent,
            onPressed: () {
              shareBackupFile(context, controller);
            },
          ),
        ),
      );
    } catch (_) {}
  }
}
