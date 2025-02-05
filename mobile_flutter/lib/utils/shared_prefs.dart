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

  static Future<void> storeWalkthorugh(bool walkthough) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isWalkthrough', walkthough);
  }

  static Future<String> getWalkthrough() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('isWalkthough').toString();
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
