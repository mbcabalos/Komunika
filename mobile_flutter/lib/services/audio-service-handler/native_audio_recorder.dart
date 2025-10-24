import 'dart:typed_data';
import 'package:flutter/services.dart';

class NativeAudioRecorder {
  static const MethodChannel _method =
      MethodChannel('com.komunika.app/recorder');
  static const EventChannel _event = EventChannel('native_audio_stream');

  static Future<void> start() async {
    await _method.invokeMethod('startRecording');
  }

  static Future<void> stop() async {
    await _method.invokeMethod('stopRecording');
  }

  static Future<void> startNoiseSupressor() async {
    print("NoiseSupressor start 2");

    await _method.invokeMethod('enableNoiseSuppressor');
  }

  static Future<void> stopNoiseSupressor() async {
    await _method.invokeMethod('disableNoiseSuppressor');
  }

  static Stream<Uint8List> get audioStream {
    return _event.receiveBroadcastStream().cast<Uint8List>();
  }
}
