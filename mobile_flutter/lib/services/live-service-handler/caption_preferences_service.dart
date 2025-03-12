import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class CaptionPreferencesService {
  static const MethodChannel _platform = MethodChannel('com.example.komunika/recorder');

  Future<void> saveCaptionPreferences(double textSize, Color textColor, Color bgColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("captionTextSize", textSize);
    await prefs.setInt("captionTextColor", textColor.value);
    await prefs.setInt("captionBackgroundColor", bgColor.value);

    // Send the updated settings to the native side
    await _platform.invokeMethod('updateCaptionStyle', {
      "textSize": textSize,
      "textColor": textColor,
      "bgColor": bgColor,
    });
  }

  Future<Map<String, dynamic>> getCaptionPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "textSize": prefs.getDouble("captionTextSize") ?? 16.0,
      "textColor": Color(prefs.getInt("captionTextColor") ?? Colors.white.value),
      "bgColor": Color(prefs.getInt("captionBackgroundColor") ?? Colors.black.value),
    };
  }
}
