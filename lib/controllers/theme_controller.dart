import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _prefKeyDarkMode = 'ink_wright_dark_mode';

  bool _isDarkMode = false;
  bool _isZenMode = false;

  bool get isDarkMode => _isDarkMode;
  bool get isZenMode => _isZenMode;

  ThemeController() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_prefKeyDarkMode) ?? false;
      _updateSystemOverlay();
      notifyListeners();
    } catch (_) {}
  }

  void toggleThemeMode() {
    _isDarkMode = !_isDarkMode;
    _updateSystemOverlay();
    _saveThemePreference();
    notifyListeners();
  }

  void toggleZenMode() {
    _isZenMode = !_isZenMode;
    notifyListeners();
  }

  void setZenMode(bool enabled) {
    if (_isZenMode != enabled) {
      _isZenMode = enabled;
      notifyListeners();
    }
  }

  void _updateSystemOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: _isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyDarkMode, _isDarkMode);
    } catch (_) {}
  }
}

