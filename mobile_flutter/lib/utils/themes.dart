import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart'; // Your ColorsPalette

class ThemeProvider extends ChangeNotifier {
  // Default theme (Light)
  String _selectedTheme = 'Light';
  String get selectedTheme => _selectedTheme;

  // Set the theme
  void setTheme(String theme) {
    _selectedTheme = theme;
    notifyListeners(); // Notify listeners to update the theme
  }

  // Theme function to return ThemeData based on selected theme
  ThemeData get themeData {
    switch (_selectedTheme) {
      case 'Dark':
        return _buildDarkTheme();
      default:
        return _buildLightTheme();
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
          bodyLarge: TextStyle(color: ColorsPalette.black),
          bodyMedium: TextStyle(color: ColorsPalette.black),
          bodySmall: TextStyle(color: ColorsPalette.white)),
      iconTheme: const IconThemeData(color: ColorsPalette.black),
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
          bodySmall: TextStyle(color: DarkModeColors.textPrimary)),
      iconTheme: const IconThemeData(color: DarkModeColors.textPrimary),
    );
  }
}
