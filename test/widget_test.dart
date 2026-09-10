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

  testWidgets('Navigation to chapters (swipe right) and chapter metrics (swipe left)', (WidgetTester tester) async {
    await tester.pumpWidget(const InkWrightApp());
    await tester.pumpAndSettle();

    // Editor is active initially
    expect(find.text('Capítulo 1: Bienvenido a tu Estudio & Markdown en Vivo'), findsOneWidget);

    // 1. Swipe to the right (drag finger right) to open Chapter Drawer (Page 0)
    await tester.flingFrom(const Offset(200, 40), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();

    // ChapterDrawer view is displayed (same view as 3-bars menu)
    expect(find.text('Nuevo Capítulo'), findsOneWidget);
    expect(find.text('Capítulo 2: El Arte de Crear Personajes'), findsOneWidget);

    // Tap a chapter to switch to it and return to editor
    await tester.tap(find.text('Capítulo 2: El Arte de Crear Personajes'));
    await tester.pumpAndSettle();

    // Returns back to editor with the selected chapter
    expect(find.text('Capítulo 2: El Arte de Crear Personajes'), findsOneWidget);

    // 2. Swipe to the left (drag finger left) to open Metrics (Page 2)
    await tester.flingFrom(const Offset(300, 40), const Offset(-400, 0), 1000);
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
    expect(find.text('Capítulo 2: El Arte de Crear Personajes'), findsOneWidget);

    // 3. Tap the 3-bars hamburger menu at the top left to verify it opens the same ChapterDrawer
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo Capítulo'), findsOneWidget);
    expect(find.text('Capítulo 1: Bienvenido a tu Estudio & Markdown en Vivo'), findsOneWidget);

    // Close drawer
    await tester.tap(find.text('Capítulo 1: Bienvenido a tu Estudio & Markdown en Vivo'));
    await tester.pumpAndSettle();
    expect(find.text('Capítulo 1: Bienvenido a tu Estudio & Markdown en Vivo'), findsOneWidget);
  });

  testWidgets('Floating + button opens popup options: Nuevo Capitulo, Nuevo Libro, Mapa Mental, Exportar', (WidgetTester tester) async {
    await tester.pumpWidget(const InkWrightApp());
    await tester.pumpAndSettle();

    // Verify "Fin del Capítulo" is no longer displayed
    expect(find.textContaining('Fin del Capítulo'), findsNothing);

    // Tap the floating '+' options button
    final fab = find.byTooltip('Acciones Rápidas (+)');
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Verify the 4 floating speed dial options are present
    expect(find.text('Nuevo Capítulo'), findsOneWidget);
    expect(find.text('Nuevo Libro'), findsOneWidget);
    expect(find.text('Mapa Mental'), findsOneWidget);
    expect(find.text('Exportar'), findsOneWidget);

    // Tap "Nuevo Capítulo" option
    await tester.tap(find.text('Nuevo Capítulo'));
    await tester.pumpAndSettle();

    // Dialog pops up
    expect(find.text('Título del capítulo'), findsOneWidget);
    expect(find.text('Crear Capítulo'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });

  testWidgets('Export modal opens as scrollable bottom sheet and can be scrolled and dismissed', (WidgetTester tester) async {
    await tester.pumpWidget(const InkWrightApp());
    await tester.pumpAndSettle();

    // Tap the floating '+' options button
    final fab = find.byTooltip('Acciones Rápidas (+)');
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Tap "Exportar"
    await tester.tap(find.text('Exportar'));
    await tester.pumpAndSettle();

    // Verify Export sheet is opened
    expect(find.text('Exportar Manuscrito'), findsOneWidget);
    expect(find.text('Seleccionar Formato de Exportación'), findsOneWidget);
    expect(find.text('Tipografía Editorial'), findsOneWidget);
    expect(find.text('Contenido Adicional'), findsOneWidget);

    // Verify SingleChildScrollView exists and is scrollable
    expect(find.byType(SingleChildScrollView), findsWidgets);

    // Select Word export format
    await tester.tap(find.text('Microsoft Word (.docx)'));
    await tester.pumpAndSettle();

    // Verify button updates
    expect(find.text('Exportar a Microsoft Word (.docx)'), findsOneWidget);

    // Tap outside / close sheet
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Sheet dismissed
    expect(find.text('Exportar Manuscrito'), findsNothing);
  });

  testWidgets('Dashboard two-level Library view and Book Study view navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const InkWrightApp());
    await tester.pumpAndSettle();

    // Navigate back to Dashboard
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    final backOption = find.text('Volver al Inicio');
    await tester.ensureVisible(backOption);
    await tester.pumpAndSettle();
    await tester.tap(backOption);
    await tester.pumpAndSettle();

    // 1. Initial view in Dashboard is the Library view
    expect(find.text('InkWright Studio'), findsOneWidget);
    expect(find.text('Biblioteca de Manuscritos'), findsOneWidget);
    expect(find.textContaining('Tus Libros'), findsOneWidget);
    expect(find.text('Abrir Estudio'), findsWidgets);

    // 2. Tap 'Abrir Estudio' to enter Book Study view
    await tester.tap(find.text('Abrir Estudio').first);
    await tester.pumpAndSettle();

    // Verify Book Study view is active
    expect(find.text('Biblioteca'), findsOneWidget); // Strategic back button
    expect(find.text('Manuscrito'), findsOneWidget);
    expect(find.text('Personajes'), findsWidgets);
    expect(find.text('Mapa de Trama'), findsOneWidget);
    expect(find.text('Cambiar de Libro'), findsOneWidget);

    // 3. Tap 'Biblioteca' strategic button to return to Library view
    await tester.tap(find.text('Biblioteca'));
    await tester.pumpAndSettle();

    expect(find.text('Biblioteca de Manuscritos'), findsOneWidget);
    expect(find.textContaining('Tus Libros'), findsOneWidget);
  });

  testWidgets('Herramientas tab shows dedicated Meta Diaria card and adjustment modal', (WidgetTester tester) async {
    await tester.pumpWidget(const InkWrightApp());
    await tester.pumpAndSettle();

    // Navigate back to Dashboard
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    final backOption = find.text('Volver al Inicio');
    await tester.ensureVisible(backOption);
    await tester.pumpAndSettle();
    await tester.tap(backOption);
    await tester.pumpAndSettle();

    // Enter book study
    await tester.tap(find.text('Abrir Estudio').first);
    await tester.pumpAndSettle();

    // Scroll horizontal filter pills to bring Herramientas into view
    await tester.drag(find.byType(ListView).first, const Offset(-700, 0));
    await tester.pumpAndSettle();

    // Tap Herramientas tab
    final herramientasTab = find.text('Herramientas');
    expect(herramientasTab, findsOneWidget);
    await tester.tap(herramientasTab);
    await tester.pumpAndSettle();

    // Verify dedicated Meta Diaria card is present in Herramientas
    expect(find.text('Meta Diaria de Escritura'), findsOneWidget);
    expect(find.text('Ajustar Meta Diaria'), findsOneWidget);
    // Verify symmetrical backup export button
    expect(find.text('Exportar'), findsOneWidget);
    expect(find.text('Restaurar'), findsOneWidget);

    // Tap 'Ajustar Meta Diaria'
    await tester.tap(find.text('Ajustar Meta Diaria'));
    await tester.pumpAndSettle();

    // Verify modal options and presets
    expect(find.text('PRESETS RÁPIDOS (PALABRAS)'), findsOneWidget);
    expect(find.text('1500'), findsOneWidget);
    expect(find.text('Guardar Meta Diaria'), findsOneWidget);

    // Select 1500 preset and save
    await tester.tap(find.text('1500'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar Meta Diaria'));
    await tester.pumpAndSettle();

    // Verify updated goal
    expect(find.textContaining('1500 palabras hoy'), findsOneWidget);
  });
}
