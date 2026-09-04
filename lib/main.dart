import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'controllers/editor_controller.dart';
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

class InkWrightApp extends StatelessWidget {
  const InkWrightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditorController>(
      create: (_) => EditorController(),
      child: Consumer<EditorController>(
        builder: (context, controller, _) {
          return MaterialApp(
            title: 'InkWright Sanctuary',
            debugShowCheckedModeBanner: false,
            themeMode: controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}
