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
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC, 0); // Disable AGC
    _setCtlInt(SPEEX_PREPROCESS_SET_VAD, 0); // Disable VAD
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
