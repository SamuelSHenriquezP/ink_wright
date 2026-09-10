import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ink_wright/controllers/editor_controller.dart';
import 'package:ink_wright/controllers/theme_controller.dart';
import 'package:ink_wright/controllers/sprint_controller.dart';
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

  test('Smoke test ThemeController and SprintController', () {
    final theme = ThemeController();
    expect(theme.isDarkMode, isFalse);
    expect(theme.isZenMode, isFalse);

    final sprint = SprintController();
    expect(sprint.isSprintActive, isFalse);
  });

  testWidgets('App opens last written text directly on launch and navigates back to Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const InkWrightApp());
    await tester.pumpAndSettle();

    // Directly opens editor with the active manuscript and chapter
    expect(find.text('Manual del Escritor — Guía de Ink & Wright'), findsOneWidget);
    expect(find.text('Capítulo 1: Bienvenido a tu Estudio & Markdown en Vivo'), findsOneWidget);

    // Tapping options and 'Volver al Inicio' returns to Dashboard
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();

    final backOption = find.text('Volver al Inicio');
    await tester.ensureVisible(backOption);
    await tester.pumpAndSettle();

    await tester.tap(backOption);
    await tester.pumpAndSettle();
    expect(find.text('InkWright Studio'), findsOneWidget);
  });

  testWidgets('Navigation to chapter metrics screen via swipe gesture and back to editor', (WidgetTester tester) async {
    await tester.pumpWidget(const InkWrightApp());
    await tester.pumpAndSettle();

    // Editor is active initially
    expect(find.text('Capítulo 1: Bienvenido a tu Estudio & Markdown en Vivo'), findsOneWidget);

    // 1. Swipe to the right (drag finger right) to open Metrics
    await tester.flingFrom(const Offset(200, 40), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();

    // Metrics view is displayed
    expect(find.text('Métricas del Capítulo'), findsOneWidget);
    expect(find.text('Palabras Totales'), findsOneWidget);
    expect(find.text('Tiempo de Lectura'), findsOneWidget);

    var returnBtn = find.text('Volver al Editor a Escribir');
    await tester.ensureVisible(returnBtn);
    await tester.pumpAndSettle();
    await tester.tap(returnBtn);
    await tester.pumpAndSettle();

    // Returns back to editor
    expect(find.text('Capítulo 1: Bienvenido a tu Estudio & Markdown en Vivo'), findsOneWidget);

    // 2. Swipe to the left (drag finger left) to open Metrics
    await tester.flingFrom(const Offset(300, 40), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    // Metrics view is displayed
    expect(find.text('Métricas del Capítulo'), findsOneWidget);
    expect(find.text('Palabras Totales'), findsOneWidget);
    expect(find.text('Tiempo de Lectura'), findsOneWidget);

    returnBtn = find.text('Volver al Editor a Escribir');
    await tester.ensureVisible(returnBtn);
    await tester.pumpAndSettle();
    await tester.tap(returnBtn);
    await tester.pumpAndSettle();

    // Returns back to editor
    expect(find.text('Capítulo 1: Bienvenido a tu Estudio & Markdown en Vivo'), findsOneWidget);
  });
}
