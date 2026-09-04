import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ink_wright/controllers/editor_controller.dart';
import 'package:ink_wright/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('es_ES', null);
  });

  test('Smoke test controller initialization', () {
    final controller = EditorController();
    expect(controller.activeBook.chapters.length, equals(3));
  });

  testWidgets('App opens last written text directly on launch and navigates back to Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const InkWrightApp());
    await tester.pumpAndSettle();

    // Directly opens editor with the active manuscript and chapter
    expect(find.text('The Cipher of St. Jude'), findsOneWidget);
    expect(find.text('The Fog Across Blackwood'), findsOneWidget);

    // Tapping back returns to Dashboard
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('InkWright Studio'), findsOneWidget);
  });
}
