import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'controllers/theme_controller.dart';
import 'controllers/editor_controller.dart';
import 'controllers/sprint_controller.dart';
import 'controllers/sprint_session.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize locale data for date formatting in Spanish
  await initializeDateFormatting('es_ES', null);

  // Set transparent system overlay for modern edge-to-edge feel
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(const InkWrightApp());
}

class InkWrightApp extends StatefulWidget {
  const InkWrightApp({super.key});

  @override
  State<InkWrightApp> createState() => _InkWrightAppState();
}

class _InkWrightAppState extends State<InkWrightApp>
    with WidgetsBindingObserver {
  final EditorController _editor = EditorController();
  final SprintController _sprint = SprintController();
  late final SprintSession _sprintSession;

  @override
  void initState() {
    super.initState();
    _sprintSession = SprintSession(editor: _editor, sprint: _sprint);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _editor.flushAndBackup();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sprintSession.dispose();
    _sprint.dispose();
    _editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(),
        ),
        ChangeNotifierProvider<EditorController>.value(value: _editor),
        ChangeNotifierProvider<SprintController>.value(value: _sprint),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'InkWright Studio',
            debugShowCheckedModeBanner: false,
            themeMode: themeController.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}
