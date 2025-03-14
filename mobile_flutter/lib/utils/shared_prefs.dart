import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesUtils {
  static const String _sizeKey = "captionSize";
  static const String _textColorKey = "captionTextColor";
  static const String _backgroundColorKey = "captionBackgroundColor";
  static const String _captionEnableStateKey = 'captionEnableState';

  static Future<void> storeCaptionEnableState(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_captionEnableStateKey, isEnabled);
  }

  static Future<bool> getCaptionEnableState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_captionEnableStateKey) ?? false; // Default to false
  }

  static Future<void> storeCaptionSize(double size) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_sizeKey, size);
  }

  static Future<double> getCaptionSize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_sizeKey) ?? 50.0;
  }

  static Future<void> storeCaptionTextColor(String colorName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_textColorKey, colorName);
  }

  static Future<String> getCaptionTextColor() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_textColorKey) ?? "black";
  }

  static Future<void> storeCaptionBackgroundColor(String colorName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundColorKey, colorName);
  }

  static Future<String> getCaptionBackgroundColor() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backgroundColorKey) ?? "white";
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
