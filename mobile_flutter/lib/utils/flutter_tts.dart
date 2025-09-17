import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';

class TtsHelper {
  final FlutterTts flutterTts = FlutterTts();

  bool isPlaying = false;

  void setupHandlers(VoidCallback onStart, VoidCallback onComplete, VoidCallback onCancel, Function(String) onError) {
    flutterTts.setStartHandler(onStart);
    flutterTts.setCompletionHandler(onComplete);
    flutterTts.setCancelHandler(onCancel);
  }

  Future<void> speak({
    required String text,
    required String? language,
    required String? voice,
    double rate = 0.5,
    double pitch = 1.0,
    double volume = 1.0,
  }) async {
    await flutterTts.setEngine("com.google.android.tts");
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (language != null) {
      await flutterTts.setLanguage(language);
    }
    if (voice != null && language != null) {
      await flutterTts.setVoice({"name": voice, "locale": language});
    }
    await flutterTts.speak(text);
  }

  Future<void> stop() async {
    await flutterTts.stop();
  }

  Future<void> pause() async {
    await flutterTts.pause();
  }
}