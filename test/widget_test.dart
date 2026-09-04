import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ink_wright/controllers/editor_controller.dart';
import 'package:ink_wright/main.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_ES', null);
  });

  test('Smoke test controller initialization', () {
    final controller = EditorController();
    expect(controller.activeBook.chapters.length, equals(3));
  });

  testWidgets('App renders Dashboard without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const InkWrightApp());
    await tester.pumpAndSettle();
    expect(find.text('InkWright Studio'), findsOneWidget);
  });
}
