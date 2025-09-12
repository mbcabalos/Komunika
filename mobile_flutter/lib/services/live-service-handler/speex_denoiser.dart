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
    int noiseSuppressDb = -50,
  }) {
    _state = speexPreprocessInit(frameSize, sampleRate);
    if (_state == nullptr) {
      throw Exception("Failed to initialize speex_preprocess_state");
    }

    _setCtlInt(SPEEX_PREPROCESS_SET_DENOISE, 1); // ✅ Enable denoise
    _setCtlInt(
        SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, noiseSuppressDb); // Set level
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC, 1); // Disable AGC
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC_LEVEL, 12000);
    _setCtlInt(SPEEX_PREPROCESS_SET_VAD, 0); // Disable VAD
  }

  void setNoiseSuppressDb(int dbLevel) {
    if (dbLevel > -10 || dbLevel < -50) {
      throw ArgumentError(
          "Noise suppression level must be between -10 and -50 dB.");
    }
    final ptr = calloc<Int32>()..value = dbLevel;
    final result = speexPreprocessCtl(
        _state, SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, ptr.cast());
    calloc.free(ptr);

    if (result != 0) {
      print("⚠️ speexPreprocessCtl returned error code: $result");
    } else {
      print("✅ Noise suppression updated to $dbLevel dB");
    }
  }

  void enableAgc({int agcLevel = 8000}) {
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC, 1);
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC_LEVEL, agcLevel);
    print("✅ AGC enabled with level: $agcLevel");
  }

  void disableAgc() {
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC, 0);
    print("✅ AGC disabled");
  }

  void setAgcLevel(int agcLevel) {
    if (agcLevel <= 0) {
      throw ArgumentError("AGC level must be a positive integer");
    }
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC_LEVEL, agcLevel);
    print("✅ AGC level updated to: $agcLevel");
  }

  void _setCtlInt(int request, int value) {
    final ptr = calloc<Int32>()..value = value;
    speexPreprocessCtl(_state, request, ptr.cast());
    calloc.free(ptr);
  }

  List<int> denoise(List<int> input) {
    if (input.length != frameSize) {
      throw ArgumentError("Expected $frameSize samples, got ${input.length}");
    }

    final ptr = calloc<Int16>(frameSize);
    final typedList = ptr.asTypedList(frameSize);
    typedList.setAll(0, input);

    speexPreprocessRun(_state, ptr);

    final result = List<int>.from(typedList);
    calloc.free(ptr);
    return result;
  }

  void dispose() {
    speexPreprocessDestroy(_state);
  }
}
