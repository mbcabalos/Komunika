import 'package:flutter/services.dart';

class SoundEnhancerService {
  static const _channel = MethodChannel('sound_enhancer_service');

  static Future<void> startService() async {
    try {
      await _channel.invokeMethod('startService');
      print("Foreground sound enhancer service started");
    } catch (e) {
      print("Failed to start service: $e");
    }
  }

  static Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
      print("Foreground sound enhancer service stopped");
    } catch (e) {
      print("Failed to stop service: $e");
    }
  }
}
