import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesUtils {
  static const String _sizeKey = "captionSize";
  static const String _textColorKey = "captionTextColor";
  static const String _backgroundColorKey = "captionBackgroundColor";

  static Future<void> storeCaptionSize(double size) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_sizeKey, size);
  }

  static Future<double> getCaptionSize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_sizeKey) ?? 50.0;
  }

  static Future<void> storeCaptionTextColor(Color color) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int colorInt = (color.a.toInt() << 24) |
                   (color.r.toInt() << 16) |
                   (color.g.toInt() << 8) |
                   color.b.toInt();
    await prefs.setInt(_textColorKey, colorInt);
  }

  static Future<Color> getCaptionTextColor() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int colorInt = prefs.getInt(_textColorKey) ?? 
    ((Colors.black.a.toInt() << 24) |
     (Colors.black.r.toInt() << 16) |
     (Colors.black.g.toInt() << 8) |
     Colors.black.b.toInt());
    return Color.fromARGB(
      (colorInt >> 24) & 0xFF,  // Alpha
      (colorInt >> 16) & 0xFF,  // Red
      (colorInt >> 8) & 0xFF,   // Green
      colorInt & 0xFF           // Blue
    );
  }

  static Future<void> storeCaptionBackgroundColor(Color color) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int colorInt = (color.a.toInt() << 24) |
                   (color.r.toInt() << 16) |
                   (color.g.toInt() << 8) |
                   color.b.toInt();
    await prefs.setInt(_backgroundColorKey, colorInt);
  }

  static Future<Color> getCaptionBackgroundColor() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int colorInt = prefs.getInt(_backgroundColorKey) ?? 
    ((Colors.white.a.toInt() << 24) |
     (Colors.white.r.toInt() << 16) |
     (Colors.white.g.toInt() << 8) |
     Colors.white.b.toInt());
    return Color.fromARGB(
      (colorInt >> 24) & 0xFF,  // Alpha
      (colorInt >> 16) & 0xFF,  // Red
      (colorInt >> 8) & 0xFF,   // Green
      colorInt & 0xFF           // Blue
    );
  }

  static Future<void> storeTheme(String theme) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
  }

  static Future<String> getTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme') ?? 'Light';
  }

  static const String _languageKey = "selectedLanguage";

  static Future<void> storeLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'English';
  }

  static Future<void> storeWalkthrough(bool walkthrough) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isWalkthrough', walkthrough);
  }

  static Future<bool> getWalkthrough() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isWalkthrough') ?? false;
  }

  static Future<String> getThemeAndWalkthrough() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme').toString();
  }

}
