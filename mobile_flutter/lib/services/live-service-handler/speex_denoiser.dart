import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'speexdsp_ffi.dart';

class SpeexDenoiser {
  final int frameSize;
  final int sampleRate;
  late final Pointer<Void> _state;

  SpeexDenoiser({
    this.frameSize = 160,
    this.sampleRate = 16000,
    int noiseSuppressDb = -25,
  }) {
    _state = speexPreprocessInit(frameSize, sampleRate);
    if (_state == nullptr) {
      throw Exception("Failed to initialize speex_preprocess_state");
    }

    _setCtlInt(SPEEX_PREPROCESS_SET_DENOISE, 1); // enable denoise
    _setCtlInt(SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, noiseSuppressDb);
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC, 0); // AGC off by default
    _setCtlFloat(SPEEX_PREPROCESS_SET_AGC_LEVEL, 30.0); // default target 30 dB
    _setCtlInt(SPEEX_PREPROCESS_SET_VAD, 0); // disable VAD
  }

  /// Update noise suppression in dB (-10 … -50)
  void setNoiseSuppressDb(int dbLevel) {
    if (dbLevel > -10 || dbLevel < -50) {
      throw ArgumentError("Noise suppression must be between -10 and -50 dB.");
    }
    _setCtlInt(SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, dbLevel);
    print("✅ Noise suppression updated to $dbLevel dB");
  }

  /// Enable AGC with a target RMS level in dB (typical 15–45)
  void enableAgc({double agcLevel = 30.0}) {
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC, 1);
    _setCtlFloat(SPEEX_PREPROCESS_SET_AGC_LEVEL, agcLevel);
    print("✅ AGC enabled with level: $agcLevel dB");
  }

  void disableAgc() {
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC, 0);
    print("✅ AGC disabled");
  }

  void setAgcLevel(double agcLevel) {
    //accepts 15.0 - 45.0 float value
    if (agcLevel <= 0) {
      throw ArgumentError("AGC level must be positive (dB).");
    }
    _setCtlFloat(SPEEX_PREPROCESS_SET_AGC_LEVEL, agcLevel);
    print("✅ AGC level updated to: $agcLevel dB");
  }

  void _setCtlInt(int request, int value) {
    final ptr = calloc<Int32>()..value = value;
    speexPreprocessCtl(_state, request, ptr.cast());
    calloc.free(ptr);
  }

  void _setCtlFloat(int request, double value) {
    final ptr = calloc<Float>()..value = value;
    speexPreprocessCtl(_state, request, ptr.cast());
    calloc.free(ptr);
  }

  List<int> denoise(List<int> input) {
    if (input.length != frameSize) {
      throw ArgumentError("Expected $frameSize samples, got ${input.length}");
    }
    final ptr = calloc<Int16>(frameSize);
    final typedList = ptr.asTypedList(frameSize)..setAll(0, input);

    speexPreprocessRun(_state, ptr);

    final result = List<int>.from(typedList);
    calloc.free(ptr);
    return result;
  }

  void dispose() {
    speexPreprocessDestroy(_state);
  }
}
