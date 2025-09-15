import 'package:shared_preferences/shared_preferences.dart';

class PreferencesUtils {
  // ================== Walkthrough / Tutorial ==================
  static const String _walkthroughDoneKey = 'walkthroughDone';

  static Future<void> storeWalkthroughDone(bool isDone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_walkthroughDoneKey, isDone);
  }

  static Future<bool> getWalkthroughDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_walkthroughDoneKey) ?? false;
  }

  static Future<void> resetWalkthrough() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_walkthroughDoneKey);
  }

  static Future<void> storeWalkthrough(bool walkthrough) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isWalkthrough', walkthrough);
  }

  static Future<bool> getWalkthrough() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isWalkthrough') ?? false;
  }

  // ================== Settings Screen ==================
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

  static Future<String> getThemeAndWalkthrough() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme').toString();
  }

  // ================== Sound Enhancer Screen ==================
  static Future<void> storeNoiseReductionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isNoiseReductionEnabled", enabled);
  }

  static Future<bool> getNoiseReductionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("isNoiseReductionEnabled") ?? false;
  }

  static Future<void> storeAGCEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isAGCEnabled", enabled);
  }

  static Future<bool> getAGCEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("isAGCEnabled") ?? false;
  }

  static Future<void> storeAmplifierVolume(double volume) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('isAmplifierVolume', volume);
  }

  static Future<double> getAmplifierVolume() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('isAmplifierVolume') ?? 1.0;
  }

  static Future<void> storeAudioBalanceLevel(double balance) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('isAudioBalanceLevel', balance);
  }

  static Future<double> getAudioBalanceLevel() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('isAudioBalanceLevel') ?? 0.0;
  }

  // ================== Text to Speech (TTS) Screen ==================
  static Future<void> storeTTSVoice(String voice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("TTS_selectedVoice", voice);
  }

  static Future<String> getTTSVoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("TTS_selectedVoice") ?? "fil-ph-x-fie-local";
  }

  static Future<void> storeTTSRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("TTS_selectedRate", rate);
  }

  static Future<double> getTTSRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble("TTS_selectedRate") ?? 0.5;
  }

  static Future<void> storeTTSSettings(String language, String voice) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("TTS_language", language);
    await prefs.setString("TTS_voice", voice);
  }

  static Future<Map<String, String>> getTTSSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? language = prefs.getString("TTS_language");
    final String? voice = prefs.getString("TTS_voice");

    return {
      "language": language ?? "en-US",
      "voice": voice ?? "fil-ph-x-fie-local",
    };
  }
}
