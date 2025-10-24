import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:komunika/services/audio-service-handler/fft_helper.dart';
import 'package:komunika/services/audio-service-handler/native_audio_recorder.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:komunika/services/audio-service-handler/speexdsp_helper.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

part 'sound_enhancer_event.dart';
part 'sound_enhancer_state.dart';

class SoundEnhancerBloc extends Bloc<SoundEnhancerEvent, SoundEnhancerState> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  StreamController<Uint8List>? _audioStreamController;
  StreamController<String> _transcriptionController =
      StreamController<String>();
  final SocketService socketService;
  SpeexDSP? _denoiser;
  static const platform = MethodChannel('com.komunika.app/recorder');

  bool recording = false;
  bool _transcribing = false;
  bool _enableDenoise = false;
  double _currentGain = 1.0;
  double _balance = 0.5;
  double _smoothedDb = -90.0;
  double micCalibration = 60.0; // adjust per device
  List<int> _monitorBuffer = [];
  SoundEnhancerBloc(this.socketService, SpeexDSP speexDenoiser)
      : super(SoundEnhancerLoadingState()) {
    // Event handlers
    on<SoundEnhancerLoadingEvent>(_onLoadingEvent);
    // on<RequestPermissionEvent>(_onRequestPermission);
    on<StartRecordingEvent>(_onStartRecording);
    on<StopRecordingEvent>(_onStopRecording);
    on<StartTranscriptionEvent>(_onStartTranscription);
    on<StopTranscriptionEvent>(_onStopTranscription);
    on<SetAmplificationEvent>(_onSetAmplification);
    on<SetAudioBalanceLevel>(_onSetAudioBalance);
    on<StartNoiseSupressorEvent>(_onStartNoiseSupressor);
    on<StopNoiseSupressorEvent>(_onStopNoiseSupressor);
    on<StartVADEvent>(_onStartVAD);
    on<StopVADEvent>(_onStopVAD);
    on<StartAGCEvent>(_onStartAGC);
    on<StopAGCEvent>(_onStopAGC);
    on<NewTranscriptionEvent>(_onNewTranscription);
    on<LivePreviewTranscriptionEvent>(_onLivePreview);
    on<ClearTextEvent>(_onClearText);
    on<SoundBarsUpdatedEvent>((event, emit) {
      emit(SoundEnhancerSpectrumState(
        event.spectrum,
        decibel: event.decibel,
      ));
    });

    // Initializations
    _denoiser = SpeexDSP();
    _loadNoiseReductionPref();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    socketService.socket?.off("transcription_result");
    socketService.socket?.off("transcription_preview");

    socketService.socket?.on("transcription_result", (data) {
      if (data != null && data["text"] != null) {
        _transcriptionController.add(data["text"]);
        add(NewTranscriptionEvent(data["text"]));
      }
    });

    socketService.socket?.on("transcription_preview", (data) {
      if (data != null && data["live_text"] != null) {
        _transcriptionController.add(data["live_text"]);
        add(LivePreviewTranscriptionEvent(data["live_text"]));
      }
    });
  }

  // --- Event Handlers ---
  Future<void> _onLoadingEvent(
      SoundEnhancerLoadingEvent event, Emitter<SoundEnhancerState> emit) async {
    emit(SoundEnhancerLoadedSuccessState());
  }

  Future<void> _onRequestPermission(
      RequestPermissionEvent event, Emitter<SoundEnhancerState> emit) async {
    try {
      var status = await Permission.microphone.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        emit(SoundEnhancerErrorState(message: "Microphone permission denied"));
      }
    } catch (e) {
      emit(SoundEnhancerErrorState(message: "Permission error: $e"));
    }
  }

  Future<void> _onStartRecording(
      StartRecordingEvent event, Emitter<SoundEnhancerState> emit) async {
    if (recording) return;

    try {
      _currentGain = await PreferencesUtils.getAmplifierVolume();
      // await SoundEnhancerService.startService();
      await _player.openPlayer();
      await NativeAudioRecorder.start();
      await _player.startPlayerFromStream(
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 2,
      );

      NativeAudioRecorder.audioStream.listen((Uint8List buffer) {
        if (_denoiser == null) return;
        final pcm = Int16List.view(buffer.buffer);
        // 5️⃣ Update spectrum / processed audio
        final processedBytes = _processAudioChunk(buffer);
        final stereoBytes = _convertToStereo(processedBytes);
        _player.foodSink?.add(FoodData(stereoBytes));
        _handleAudioChunk(buffer);
        _updateAudio(
          processedBuffer: processedBytes,
          rawBuffer: buffer, // pass PCM16 for any additional processing
        );
      });
      await platform.invokeMethod('startService');

      recording = true;
      developer.log("Native recording started with gain: $_currentGain");
    } catch (e) {
      emit(SoundEnhancerErrorState(message: "Native recording failed: $e"));
    }
  }

  // --- Audio Processing Methods ---

  void _updateAudio({
    required Uint8List processedBuffer, // For spectrum visualization
    required Uint8List rawBuffer, // For noise meter
  }) {
    try {
      // --- Spectrum ---
      final barHeights = _updateSpectrum(processedBuffer);

      // --- Noise level in dB ---
      double db = computeDbSpl(rawBuffer);
      _smoothedDb = db;

      // --- Map to 0..1 for visualization ---
      double level = normalizeRms(db);

      // --- Emit event ---
      print("Normalized DB: $level");
      add(SoundBarsUpdatedEvent(barHeights, decibel: db));
    } catch (e) {
      developer.log("Audio processing error: $e");
    }
  }

  double computeDbSpl(Uint8List rawBytes, {double micCalibration = 0.0}) {
    final samples = Int16List.view(rawBytes.buffer);
    if (samples.isEmpty) return 0.0;

    // 🟢 Separate channels (interleaved stereo -> mono)
    final mono = <double>[];
    for (int i = 0; i < samples.length; i += 2) {
      // Average left/right to mono
      mono.add((samples[i] + samples[i + 1]) / 2.0);
    }

    // ✅ Remove DC bias
    final mean = mono.reduce((a, b) => a + b) / mono.length;
    final adjusted = mono.map((s) => s - mean).toList();

    // 1️⃣ RMS
    double sumSquares = 0.0;
    for (var s in adjusted) {
      sumSquares += s * s;
    }
    final rms = sqrt(sumSquares / adjusted.length);

    // 2️⃣ Normalize to [-1,1]
    final normRms = rms / 32768.0;

    // 3️⃣ Convert to dB SPL (ref = 20 µPa)
    final db = 20 * log(normRms / 0.00002) / ln10 + micCalibration;

    return db.clamp(0.0, 120.0);
  }

  double normalizeRms(double rms) {
    const minRms = 0.25;
    const maxRms = 1.0;
    final normalized = (rms - minRms) / (maxRms - minRms);
    return normalized.clamp(0.0, 1.0);
  }

  /// Computes spectrum bars from processed PCM
  List<double> _updateSpectrum(Uint8List pcmBytes) {
    try {
      if (pcmBytes.isEmpty) return List.filled(20, 0.0);

      List<double> samples = pcmToDouble(pcmBytes);

      // Ensure we have at least fftSize samples
      int fftSize = 1024;
      if (samples.length < fftSize) {
        samples = List<double>.from(samples)
          ..addAll(List.filled(fftSize - samples.length, 0.0));
      }

      List<double> fftInput = samples.sublist(0, fftSize);
      List<double> spectrum = computeFFT(fftInput);

      final barHeights = mapSpectrumToBars(spectrum, 20);
      return barHeights;
    } catch (e) {
      developer.log("FFT computation error: $e");
      return List.filled(20, 0.0);
    }
  }

  List<double> mapSpectrumToBars(List<double> spectrum, int numBars) {
    final barHeights = <double>[];
    final n = spectrum.length;

    // Ensure indices are within 0..n-1
    int lowEnd = max(0, (n * 0.04).toInt());
    int midStart = lowEnd + 1;
    int midEnd = max(midStart, (n * 0.25).toInt());
    int highStart = midEnd + 1;
    int highEnd = n - 1;

    barHeights.addAll(averageBins(spectrum, 0, lowEnd, 6));
    barHeights.addAll(averageBins(spectrum, midStart, midEnd, 8));
    barHeights.addAll(averageBins(spectrum, highStart, highEnd, 6));

    return barHeights;
  }

  /// Computes average amplitude for each chunk of bins
  List<double> averageBins(
      List<double> spectrum, int startBin, int endBin, int numBars) {
    final length = endBin - startBin + 1;
    final chunkSize = (length / numBars).ceil();
    final result = <double>[];

    for (int i = 0; i < numBars; i++) {
      final chunkStart = startBin + i * chunkSize;
      final chunkEnd = (chunkStart + chunkSize - 1).clamp(startBin, endBin);
      double sum = 0;
      for (int j = chunkStart; j <= chunkEnd; j++) {
        sum += spectrum[j].abs();
      }
      result.add(sum / (chunkEnd - chunkStart + 1));
    }

    return result;
  }

// Helper to convert PCM16 bytes to normalized doubles (-1.0 to 1.0)
  List<double> pcmToDouble(Uint8List buffer) {
    final byteData = ByteData.sublistView(buffer);
    return List<double>.generate(
      buffer.lengthInBytes ~/ 2,
      (i) => byteData.getInt16(i * 2, Endian.little) / 32768.0,
    );
  }

  Uint8List _amplifyPCM(Uint8List input, double gain) {
    final output = BytesBuilder();
    final byteData = ByteData.sublistView(input);

    for (int i = 0; i < byteData.lengthInBytes; i += 2) {
      int sample = byteData.getInt16(i, Endian.little);
      sample = (sample * gain).clamp(-32768, 32767).toInt();
      output.addByte(sample & 0xFF);
      output.addByte((sample >> 8) & 0xFF);
    }

    return output.toBytes();
  }

  Uint8List _convertToStereo(Uint8List monoBytes) {
    final monoBuffer = Int16List.view(monoBytes.buffer);
    final stereoBuffer = Int16List(monoBuffer.length * 2);
    _balance = _balance.clamp(0.0, 1.0);
    final leftGain = 1.0 - _balance;
    final rightGain = _balance;

    for (int i = 0; i < monoBuffer.length; i++) {
      final sample = monoBuffer[i];
      stereoBuffer[i * 2] = (sample * leftGain).toInt();
      stereoBuffer[i * 2 + 1] = (sample * rightGain).toInt();
    }

    return Uint8List.view(stereoBuffer.buffer);
  }

  Uint8List _processAudioChunk(Uint8List chunk) {
    if (_denoiser == null) {
      return _amplifyPCM(chunk, _currentGain);
    }

    if (chunk.isEmpty) return Uint8List(0);

    final frameSize = _denoiser!.frameSize;
    final byteData = ByteData.sublistView(chunk);
    final inputShorts = List<int>.generate(
      chunk.lengthInBytes ~/ 2,
      (i) => byteData.getInt16(i * 2, Endian.little),
    );

    _monitorBuffer.addAll(inputShorts);
    final outputSamples = <int>[];

    while (_monitorBuffer.length >= frameSize) {
      final frame = _monitorBuffer.sublist(0, frameSize);

      _monitorBuffer = _monitorBuffer.sublist(frameSize);

      final processedFrame = _denoiser!.processFrame(frame);

      for (final s in processedFrame) {
        outputSamples.add((s * _currentGain).clamp(-32768, 32767).toInt());
      }
    }

    // Convert back to bytes
    final out = BytesBuilder();
    for (final s in outputSamples) {
      out.addByte(s & 0xFF);
      out.addByte((s >> 8) & 0xFF);
    }

    return out.toBytes();
  }

  Future<void> _onStopRecording(
      StopRecordingEvent event, Emitter<SoundEnhancerState> emit) async {
    try {
      // ✅ Stop Android background service
      await NativeAudioRecorder.stop();
      await _player.stopPlayer();
      await _audioStreamController?.close();
      recording = false;
      await platform.invokeMethod('stopService');

      // Emit zero bars to reset visualizer
      emit(SoundEnhancerSpectrumState(
        List.filled(20, 0.0),
        decibel: 90,
      ));
    } catch (e) {
      emit(SoundEnhancerErrorState(message: "Stopping failed: $e"));
    }
  }

  FutureOr<void> _onStartTranscription(
      StartTranscriptionEvent event, Emitter<SoundEnhancerState> emit) async {
    _transcribing = true;
  }

  FutureOr<void> _onStopTranscription(
      StopTranscriptionEvent event, Emitter<SoundEnhancerState> emit) async {
    _transcribing = false;
  }

  Future<void> _onSetAmplification(
      SetAmplificationEvent event, Emitter<SoundEnhancerState> emit) async {
    try {
      // Clamp between 0.5 and 3.0 for reasonable amplification
      _currentGain = event.gain.clamp(0.5, 3.0);
      await PreferencesUtils.storeAmplifierVolume(_currentGain);
      developer.log("Amplification set to: $_currentGain");
    } catch (e) {
      emit(SoundEnhancerErrorState(message: "Failed to set amplification: $e"));
    }
  }

  Future<void> _onSetAudioBalance(
      SetAudioBalanceLevel event, Emitter<SoundEnhancerState> emit) async {
    try {
      // Clamp between 0.5 and 3.0 for reasonable amplification
      _balance = event.balance.clamp(0.0, 1.0);
      await PreferencesUtils.storeAudioBalanceLevel(_balance);
      developer.log("Amplification set to: $_balance");
    } catch (e) {
      emit(SoundEnhancerErrorState(message: "Failed to set amplification: $e"));
    }
  }

  Future<void> _onStartNoiseSupressor(
      StartNoiseSupressorEvent event, Emitter<SoundEnhancerState> emit) async {
    _enableDenoise = true;
    await PreferencesUtils.storeNoiseReductionEnabled(true);
    _denoiser?.enableNoiseSuppress();
  }

  Future<void> _onStopNoiseSupressor(
      StopNoiseSupressorEvent event, Emitter<SoundEnhancerState> emit) async {
    _enableDenoise = false;
    await PreferencesUtils.storeNoiseReductionEnabled(false);
    _denoiser?.disableNoiseSuppress();
  }

  Future<void> _onStartVAD(
      StartVADEvent event, Emitter<SoundEnhancerState> emit) async {
    _enableDenoise = true;
    await PreferencesUtils.storeVADEnabled(true);
    _denoiser?.enableVad();
  }

  Future<void> _onStopVAD(
      StopVADEvent event, Emitter<SoundEnhancerState> emit) async {
    _enableDenoise = false;
    await PreferencesUtils.storeVADEnabled(false);
    _denoiser?.disableVad();
  }

  Future<void> _onStartAGC(
      StartAGCEvent event, Emitter<SoundEnhancerState> emit) async {
    await PreferencesUtils.storeAGCEnabled(true);
    _denoiser?.enableAgc(); // just enable
  }

  Future<void> _onStopAGC(
      StopAGCEvent event, Emitter<SoundEnhancerState> emit) async {
    await PreferencesUtils.storeAGCEnabled(false);
    _denoiser?.disableAgc(); // just disable
  }

  Future<void> _loadNoiseReductionPref() async {
    _enableDenoise = await PreferencesUtils.getNoiseReductionEnabled();
  }

  List<int> _chunkBuffer = [];

  // Prevent concurrent uploads causing duplicate POSTs
  bool _isUploading = false;

  void _handleAudioChunk(Uint8List buffer) async {
    if (!_transcribing) return;

    // accumulate incoming pcm
    _chunkBuffer.addAll(buffer);

    // send when we have ~5 seconds (mono 16k,16-bit)
    const int threshold = 16000 * 2 * 5;
    if (_chunkBuffer.length >= threshold && !_isUploading) {
      _isUploading = true;

      // Snapshot buffer and clear quickly to avoid races
      final snapshot = Uint8List.fromList(_chunkBuffer);
      _chunkBuffer.clear();

      // Fire-and-wait upload (no concurrent uploads)
      try {
        await _sendBufferedAudioFromPcm(snapshot);
      } catch (e, st) {
        developer.log("Upload failed: $e\n$st");
      } finally {
        // small cooldown to avoid immediate retrigger from remaining events
        await Future.delayed(Duration(milliseconds: 200));
        _isUploading = false;
      }
    }
  }

  // New API: upload provided PCM snapshot (atomic from caller)
  Future<void> _sendBufferedAudioFromPcm(Uint8List pcm) async {
    try {
      if (pcm.isEmpty) return;

      // minimum length for Whisper / avoid "audio too short" errors
      const minBytes = 16000 * 2 ~/ 10; // ~0.1s
      if (pcm.length < minBytes) {
        developer.log(
            "Provided PCM too short (${pcm.length} bytes), skipping upload.");
        return;
      }

      final wavBytes =
          _pcm16ToWav(pcm, sampleRate: 16000, channels: 1, bytesPerSample: 2);

      // debug: write out a WAV file to inspect (remove in production)
      try {
        final tempDir = await getTemporaryDirectory();
        final ts = DateTime.now().millisecondsSinceEpoch;
        final path = '${tempDir.path}/komunika_chunk_$ts.wav';
        final f = File(path);
        await f.writeAsBytes(wavBytes, flush: true);
        developer
            .log('WAV written for inspection: $path  size=${wavBytes.length}');
      } catch (_) {}

      final uri = Uri.parse(
          "https://isomerically-concludable-iva.ngrok-free.dev/transcribe");
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        wavBytes,
        filename: 'audio.wav',
        contentType: MediaType('audio', 'wav'),
      ));

      final streamed = await request.send().timeout(Duration(seconds: 90));
      final resp = await http.Response.fromStream(streamed);
      developer.log('Whisper server HTTP ${resp.statusCode}');
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        developer.log('Whisper response: ${resp.body}');
        if (decoded["text"] != null && decoded["text"].isNotEmpty) {
          add(NewTranscriptionEvent(decoded["text"]));
        }
      } else {
        developer
            .log("Whisper server returned ${resp.statusCode}: ${resp.body}");
      }
    } catch (e, st) {
      developer.log("Buffered Whisper upload failed: $e\n$st");
      rethrow;
    }
  }

  // helper: build WAV RIFF header + pcm data (16-bit little-endian)
  Uint8List _pcm16ToWav(Uint8List pcmBytes,
      {required int sampleRate,
      required int channels,
      required int bytesPerSample}) {
    final int byteRate = sampleRate * channels * bytesPerSample;
    final int blockAlign = channels * bytesPerSample;
    final int subchunk2Size = pcmBytes.length;
    final int chunkSize = 36 + subchunk2Size;

    final out = BytesBuilder();

    // RIFF header
    out.add(ascii.encode('RIFF'));
    out.add(_intToBytesLE(chunkSize, 4));
    out.add(ascii.encode('WAVE'));

    // fmt subchunk
    out.add(ascii.encode('fmt '));
    out.add(_intToBytesLE(16, 4)); // subchunk1 size
    out.add(_intToBytesLE(1, 2)); // PCM format
    out.add(_intToBytesLE(channels, 2));
    out.add(_intToBytesLE(sampleRate, 4));
    out.add(_intToBytesLE(byteRate, 4));
    out.add(_intToBytesLE(blockAlign, 2));
    out.add(_intToBytesLE(bytesPerSample * 8, 2)); // bitsPerSample

    // data subchunk
    out.add(ascii.encode('data'));
    out.add(_intToBytesLE(subchunk2Size, 4));
    out.add(pcmBytes);

    return out.toBytes();
  }

  List<int> _intToBytesLE(int value, int byteCount) {
    final bytes = <int>[];
    for (int i = 0; i < byteCount; i++) {
      bytes.add((value >> (8 * i)) & 0xFF);
    }
    return bytes;
  }

  // Remove any PreferencesUtils.getWhisperServerUrl usage — fixed URL above
  // ...existing code...
  @override
  Future<void> close() async {
    await _recorder.closeRecorder();
    await _player.closePlayer();
    await _audioStreamController?.close();
    await _transcriptionController.close();
    return super.close();
  }

  // --- Transcription Handlers ---

  void _onNewTranscription(
      NewTranscriptionEvent event, Emitter<SoundEnhancerState> emit) {
    emit(TranscriptionUpdatedState("${event.text}\n"));
  }

  void _onLivePreview(
      LivePreviewTranscriptionEvent event, Emitter<SoundEnhancerState> emit) {
    emit(LivePreviewTranscriptionState(event.text));
  }

  void _onClearText(ClearTextEvent event, Emitter<SoundEnhancerState> emit) {
    socketService.socket?.off("transcription_result");
    socketService.socket?.off("transcription_preview");

    try {
      _transcriptionController.close();
    } catch (e) {
      developer.log("Error closing transcription controller: $e");
    }

    _transcriptionController = StreamController<String>.broadcast();

    _setupSocketListeners();

    emit(TranscriptionUpdatedState(""));
  }
}
