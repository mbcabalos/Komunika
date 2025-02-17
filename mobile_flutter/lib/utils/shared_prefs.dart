import 'package:shared_preferences/shared_preferences.dart';

class PreferencesUtils {
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

  static Future<void> resetShowcaseFlags() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('pageOneDone'); // Remove specific flags
    await prefs.remove('pageTwoDone');
    await prefs.remove('pageThreeDone');
  }
}
