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

  SpeexDSP({
    this.frameSize = 240,
    this.sampleRate = 16000,
    int noiseSuppressDb = -25,
    double agcLevel = 12000.0,
  }) {
    _state = speexPreprocessInit(frameSize, sampleRate);
    if (_state == nullptr) {
      throw Exception("Failed to initialize speex_preprocess_state");
    }

    // default settings
    _setCtlInt(SPEEX_PREPROCESS_SET_DENOISE, 0);
    _setCtlInt(SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, noiseSuppressDb);
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC, 0);
    _setCtlFloat(SPEEX_PREPROCESS_SET_AGC_LEVEL, agcLevel);
    _setCtlInt(SPEEX_PREPROCESS_SET_VAD, 0);
  }

  void enableNoiseSuppress() {
    _noiseSuppressEnabled = true;
    _setCtlInt(SPEEX_PREPROCESS_SET_DENOISE, 1);
  }

  void disableNoiseSuppress() {
    _noiseSuppressEnabled = false;
    _setCtlInt(SPEEX_PREPROCESS_SET_DENOISE, 0);
  }

  void enableAgc({double targetDb = 12000.0}) {
    _agcEnabled = true;
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC, 1);

    final double linearRms = 12000.0;
    _setCtlFloat(SPEEX_PREPROCESS_SET_AGC_LEVEL, targetDb);

    print("✅ AGC enabled with target: $targetDb dB (~$linearRms linear RMS)");
  }

  void disableAgc() {
    _agcEnabled = false;
    _setCtlInt(SPEEX_PREPROCESS_SET_AGC, 0);
  }

  List<int> processFrame(List<int> input) {
    if (input.length != frameSize) {
      throw ArgumentError("Expected $frameSize samples, got ${input.length}");
    }

    // final preRmsDb = rmsDb(input);

    final ptr = calloc<Int16>(frameSize);
    final typedList = ptr.asTypedList(frameSize)..setAll(0, input);

    if (_noiseSuppressEnabled) {
      _setCtlInt(SPEEX_PREPROCESS_SET_DENOISE, 1);
    }

    if (_noiseSuppressEnabled || _agcEnabled) {
      speexPreprocessRun(_state, ptr);
    }

    for (int i = 0; i < typedList.length; i++) {
      if (typedList[i] > 32767) typedList[i] = 32767;
      if (typedList[i] < -32768) typedList[i] = -32768;
    }

    final result = List<int>.from(typedList);
    calloc.free(ptr);

    // Logging
    final postRmsDb = rmsDb(result);
    // print("🎤 RMS before AGC/NS: ${preRmsDb.toStringAsFixed(2)} dB");
    // print("🔊 RMS after AGC/NS: ${postRmsDb.toStringAsFixed(2)} dB");
    // print("🔺 Peak after AGC/NS: ${peak(result)}");

    return result;
  }

  int peak(List<int> samples) {
    if (samples.isEmpty) return 0;
    return samples.map((s) => s.abs()).reduce((a, b) => a > b ? a : b);
  }

  double computeRms(List<int> samples) {
    if (samples.isEmpty) return 0.0;
    double sumSquares = 0.0;
    for (var s in samples) {
      sumSquares += s * s;
    }
    return sqrt(sumSquares / samples.length); // RMS amplitude
  }

// Convert RMS to dBFS (decibels full scale)
  double rmsDb(List<int> samples) {
    final rms = computeRms(samples);
    if (rms == 0) return -double.infinity; // avoid log(0)
    return 20 * log(rms / 32768.0) / ln10; // ln10 converts natural log to log10
  }

  void dispose() {
    speexPreprocessDestroy(_state);
  }

  // Internal helpers
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
