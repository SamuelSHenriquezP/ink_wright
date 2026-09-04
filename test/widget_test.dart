import 'package:flutter_test/flutter_test.dart';
import 'package:ink_wright/controllers/editor_controller.dart';

void main() {
  test('Smoke test controller initialization', () {
    final controller = EditorController();
    expect(controller.activeBook.chapters.length, equals(3));
  });
}
