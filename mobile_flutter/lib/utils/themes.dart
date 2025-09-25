import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  String _selectedTheme = 'Light';
  String get selectedTheme => _selectedTheme;

  ThemeProvider() {
    loadTheme();
    WidgetsBinding.instance.addObserver(this); // 👀 Listen for system changes
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Called when system brightness changes
  @override
  void didChangePlatformBrightness() {
    if (_selectedTheme == 'System') {
      notifyListeners(); // 🔥 Refresh UI
    }
  }

  void setTheme(String theme) async {
    _selectedTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('theme', theme);
    notifyListeners();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedTheme = prefs.getString('theme') ?? 'Light';
    notifyListeners();
  }

  ThemeMode get themeMode {
    switch (_selectedTheme) {
      case 'Dark':
        return ThemeMode.dark;
      case 'Light':
        return ThemeMode.light;
      case 'System':
      default:
        return ThemeMode.system;
    }
  }

  ThemeData get themeData {
    switch (_selectedTheme) {
      case 'Dark':
        return _buildDarkTheme();
      case 'Light':
        return _buildLightTheme();
      default:
        // When System → detect current device brightness
        final brightness = WidgetsBinding.instance.window.platformBrightness;
        return brightness == Brightness.dark
            ? _buildDarkTheme()
            : _buildLightTheme();
    }
  }

  // Light Theme
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: ColorsPalette.accent,
      scaffoldBackgroundColor: ColorsPalette.background,
      cardColor: ColorsPalette.card,
      appBarTheme: const AppBarTheme(
        color: ColorsPalette.accent,
        iconTheme: IconThemeData(color: ColorsPalette.white),
        titleTextStyle: TextStyle(
          fontFamily: Fonts.main,
          fontWeight: FontWeight.bold,
          color: ColorsPalette.white,
          letterSpacing: 5,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: ColorsPalette.white),
        bodyMedium: TextStyle(color: ColorsPalette.black),
        bodySmall: TextStyle(color: ColorsPalette.white),
      ),
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }

  // Dark Theme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: DarkModeColors.accent,
      scaffoldBackgroundColor: DarkModeColors.background,
      cardColor: DarkModeColors.card,
      appBarTheme: const AppBarTheme(
        color: DarkModeColors.accent,
        iconTheme: IconThemeData(color: DarkModeColors.textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: Fonts.main,
          fontWeight: FontWeight.bold,
          color: DarkModeColors.textPrimary,
          letterSpacing: 5,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: DarkModeColors.textPrimary),
        bodyMedium: TextStyle(color: DarkModeColors.textPrimary),
        bodySmall: TextStyle(color: DarkModeColors.textPrimary),
      ),
      iconTheme: const IconThemeData(color: DarkModeColors.textPrimary),
    );
  }
}
