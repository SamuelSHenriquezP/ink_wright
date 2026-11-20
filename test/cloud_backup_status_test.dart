import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ink_wright/controllers/editor_controller.dart';
import 'package:ink_wright/services/cloud_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'old upload timestamp is not treated as evidence of a cloud upload',
    () async {
      SharedPreferences.setMockInitialValues({
        'ink_last_cloud_backup_timestamp': '2026-11-20T10:00:00',
      });
      final status = await CloudBackupService.getBackupStatus();
      expect(status.preparedAt, isNull);
      expect(status.sharedAt, isNull);
      expect(status.cloudUploadConfirmed, isFalse);
    },
  );

  for (final state in [
    BackupShareState.shared,
    BackupShareState.cancelled,
    BackupShareState.unavailable,
    BackupShareState.failed,
  ]) {
    testWidgets(
      'backup distinguishes prepared file from $state without claiming upload',
      (tester) async {
        final editor = EditorController();
        await tester.runAsync(() => editor.ready);
        editor.textEditingController.text =
            'Texto pendiente que debe incluirse en el respaldo';
        late BuildContext context;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (value) {
                  context = value;
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        final result = await tester.runAsync(
          () => CloudBackupService.shareBackupFile(
            context,
            editor,
            silent: true,
            share: (params) async {
              final prepared = await CloudBackupService.getBackupStatus();
              expect(prepared.preparedAt, isNotNull);
              expect(prepared.lastState, BackupShareState.prepared);
              expect(prepared.sharedAt, isNull);
              final raw = utf8.decode(await params.files!.single.readAsBytes());
              expect(
                raw,
                contains('Texto pendiente que debe incluirse en el respaldo'),
              );
              if (state == BackupShareState.failed) {
                throw StateError('Share failed');
              }
              return ShareResult('target', switch (state) {
                BackupShareState.shared => ShareResultStatus.success,
                BackupShareState.cancelled => ShareResultStatus.dismissed,
                _ => ShareResultStatus.unavailable,
              });
            },
          ),
        );
        expect(result, state);
        final status = await tester.runAsync(
          CloudBackupService.getBackupStatus,
        );
        expect(status!.lastState, state);
        expect(status.sharedAt != null, state == BackupShareState.shared);
        expect(status.cloudUploadConfirmed, isFalse);
        expect(
          CloudBackupService.shareMessage(state).toLowerCase(),
          contains('no'),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        editor.dispose();
      },
    );
  }

  testWidgets(
    'cancelling a later attempt preserves the last genuine share date',
    (tester) async {
      final editor = EditorController();
      await tester.runAsync(() => editor.ready);
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (value) {
                context = value;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => CloudBackupService.shareBackupFile(
          context,
          editor,
          silent: true,
          share: (_) async =>
              const ShareResult('target', ShareResultStatus.success),
        ),
      );
      final first = await tester.runAsync(CloudBackupService.getBackupStatus);
      await tester.runAsync(
        () => CloudBackupService.shareBackupFile(
          context,
          editor,
          silent: true,
          share: (_) async =>
              const ShareResult('', ShareResultStatus.dismissed),
        ),
      );
      final cancelled = await tester.runAsync(
        CloudBackupService.getBackupStatus,
      );
      expect(cancelled!.sharedAt, first!.sharedAt);
      expect(cancelled.lastState, BackupShareState.cancelled);
      expect(cancelled.cloudUploadConfirmed, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      editor.dispose();
    },
  );
}
