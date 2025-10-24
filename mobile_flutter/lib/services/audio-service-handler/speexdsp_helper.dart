import 'dart:ffi';
import 'dart:math';
import 'package:ffi/ffi.dart';
import 'speexdsp_ffi.dart';

class SpeexDSP {
  final int frameSize;
  final int sampleRate;
  late final Pointer<Void> _state;

  bool _noiseSuppressEnabled = false;
  bool _agcEnabled = false;
  bool _vadEnabled = false;
  bool get isNoiseSuppressionEnabled => _noiseSuppressEnabled;
  bool get isVadEnabled => _vadEnabled;
  SpeexDSP({
    this.frameSize = 240,
    this.sampleRate = 16000,
    int noiseSuppressDb = -50,
    double agcLevel = 12000.0,
  }) {
    _state = speexPreprocessInit(frameSize, sampleRate);
    if (_state == nullptr) {
      throw Exception("Failed to initialize speex_preprocess_state");
    }

    // Default settings
    _setCtlInt(SPEEX_PREPROCESS_SET_DENOISE, 0);
    _setCtlInt(SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, noiseSuppressDb);
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC, 0);
    _setCtlFloat(SPEEX_PREPROCESS_SET_AGC_LEVEL, agcLevel);
    _setCtlInt(SPEEX_PREPROCESS_SET_VAD, 0);
    _setCtlFloat(SPEEX_PREPROCESS_SET_PROB_START, 0.7);
    _setCtlFloat(SPEEX_PREPROCESS_SET_PROB_CONTINUE, 0.7);
  }

  // -------------------- Feature Toggles --------------------
  void enableNoiseSuppress() {
    _noiseSuppressEnabled = true;
    _setCtlInt(SPEEX_PREPROCESS_SET_DENOISE, 1);
    print("[DSP] Noise suppression enabled");
  }

  void disableNoiseSuppress() {
    _noiseSuppressEnabled = false;
    _setCtlInt(SPEEX_PREPROCESS_SET_DENOISE, 0);
    print("[DSP] Noise suppression disabled");
  }

  void enableAgc() {
    _agcEnabled = true;
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC, 1);
    print("[DSP] AGC enabled");
  }

  void disableAgc() {
    _agcEnabled = false;
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC, 0);
    print("[DSP] AGC disabled");
  }

  void enableVad() {
    if (!_noiseSuppressEnabled) {
      print("[DSP][WARN] Cannot enable VAD — noise suppression is OFF");
      _vadEnabled = false;
      return;
    }
    _vadEnabled = true;
    _setCtlInt(SPEEX_PREPROCESS_SET_VAD, 1);
    print("[DSP] VAD enabled");
  }

  void disableVad() {
    _vadEnabled = false;
    _setCtlInt(SPEEX_PREPROCESS_SET_VAD, 0);
    print("[DSP] VAD disabled");
  }

  // -------------------- Frame Processing --------------------
  List<int> processFrame(
    List<int> input, {
    bool? agc,
    bool? denoise,
    bool? vad,
  }) {
    if (input.length != frameSize) {
      throw ArgumentError("Expected $frameSize samples, got ${input.length}");
    }

    final ptr = calloc<Int16>(frameSize);
    final typedList = ptr.asTypedList(frameSize)..setAll(0, input);

    final applyAgc = agc ?? _agcEnabled;
    final applyDenoise = denoise ?? _noiseSuppressEnabled;
    final applyVad = vad ?? _vadEnabled;

    // ✅ Only enable VAD if Denoise is ON
    final effectiveVad = applyVad && applyDenoise;

    // 🟦 Debug info
    print(
        "[DSP] Processing frame | AGC: $applyAgc | Denoise: $applyDenoise | VAD: $applyVad (Effective: $effectiveVad)");

    _setCtlInt(SPEEX_PREPROCESS_SET_AGC, applyAgc ? 1 : 0);
    _setCtlInt(SPEEX_PREPROCESS_SET_DENOISE, applyDenoise ? 1 : 0);
    _setCtlInt(SPEEX_PREPROCESS_SET_VAD, effectiveVad ? 1 : 0);

    // 🔹 Run preprocessor
    final vadFlag = speexPreprocessRun(_state, ptr);
    final isSpeech = vadFlag != 0;

    if (effectiveVad) {
      if (isSpeech) {
        print("[DSP][VAD] Speech detected ✅");
      } else {
        print("[DSP][VAD] No speech detected — frame muted ❌");
      }
    } else if (applyVad && !applyDenoise) {
      print("[DSP][VAD] Skipped — Denoise is OFF (VAD requires it)");
    }

    if (effectiveVad && !isSpeech) {
      calloc.free(ptr);
      return List<int>.filled(frameSize, 0);
    }

    // Clamp PCM
    for (int i = 0; i < typedList.length; i++) {
      if (typedList[i] > 32767) typedList[i] = 32767;
      if (typedList[i] < -32768) typedList[i] = -32768;
    }

    final result = List<int>.from(typedList);
    calloc.free(ptr);
    return result;
  }

  // -------------------- VAD Check --------------------
  bool isSpeechFrame(List<int> frame) {
    if (!_noiseSuppressEnabled) return true;
    if (!_vadEnabled) return true;

    if (frame.length != frameSize) {
      throw ArgumentError("Expected $frameSize samples");
    }

    final ptr = calloc<Int16>(frameSize);
    final typedList = ptr.asTypedList(frameSize)..setAll(0, frame);

    _setCtlInt(SPEEX_PREPROCESS_SET_VAD, 1);
    final result = speexPreprocessRun(_state, ptr);

    calloc.free(ptr);
    return result != 0;
  }

  // -------------------- Utility --------------------
  int peak(List<int> samples) =>
      samples.isEmpty ? 0 : samples.map((s) => s.abs()).reduce(max);

  double computeRms(List<int> samples) {
    if (samples.isEmpty) return 0.0;
    double sumSquares = 0.0;
    for (var s in samples) sumSquares += s * s;
    return sqrt(sumSquares / samples.length);
  }

  double rmsDb(List<int> samples) {
    final rms = computeRms(samples);
    if (rms == 0) return -double.infinity;
    return 20 * log(rms / 32768.0) / ln10;
  }

  void dispose() {
    speexPreprocessDestroy(_state);
  }

  // -------------------- Internal helpers --------------------
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
}
