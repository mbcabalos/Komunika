import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:komunika/services/live-service-handler/speex_denoiser.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:komunika/services/live-service-handler/native_audio_recorder.dart';

part 'sound_enhancer_event.dart';
part 'sound_enhancer_state.dart';

class SoundEnhancerBloc extends Bloc<SoundEnhancerEvent, SoundEnhancerState> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  StreamController<Uint8List>? _audioStreamController;
  final StreamController<String> _transcriptionController =
      StreamController<String>();
  final SocketService socketService;
  SpeexDenoiser? _denoiser;

  bool recording = false;
  bool _transcribing = false;
  bool _enableDenoise = false;
  double _currentGain = 1.0;
  double _balance = 0.5;
  final int _denoiseLevel = -50;

  SoundEnhancerBloc(this.socketService, SpeexDenoiser speexDenoiser)
      : super(SoundEnhancerLoadingState()) {
    // Event handlers
    on<SoundEnhancerLoadingEvent>(_onLoadingEvent);
    on<RequestPermissionEvent>(_onRequestPermission);
    on<StartRecordingEvent>(_onStartRecording);
    on<StopRecordingEvent>(_onStopRecording);
    on<StartTranscriptionEvent>(_onStartTranscription);
    on<StopTranscriptionEvent>(_onStopTranscription);
    on<SetAmplificationEvent>(_onSetAmplification);
    on<SetAudioBalanceLevel>(_onSetAudioBalance);
    on<StartNoiseSupressor>(_onStartNoiseSupressor);
    on<StopNoiseSupressor>(_onStoptNoiseSupressor);
    _loadNoiseReductionPref();
    on<NewTranscriptionEvent>(_onNewTranscription);
    on<LivePreviewTranscriptionEvent>(_onLivePreview);
    on<ClearTextEvent>(_onClearText);

    // Socket listeners
    _setupSocketListeners();
  }

  List<int> _sampleBuffer = [];

  void _setupSocketListeners() {
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
      await _player.openPlayer();
      await NativeAudioRecorder.start();
      await _player.startPlayerFromStream(
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 2,
      );
      NativeAudioRecorder.audioStream.listen(
        (Uint8List buffer) {
          final amplified = _processAudioChunk(buffer);
          final stereo = _convertToStereo(amplified);
          // print("Audio chunk received, length: ${amplified.length}");
          _handleAudioChunk(stereo);

          _player.foodSink?.add(FoodData(stereo));
        },
        onError: (e) {
          developer.log("Native audio stream error: $e");
          emit(SoundEnhancerErrorState(message: "Native stream error: $e"));
        },
      );

      recording = true;
      developer.log("Native recording started with gain: $_currentGain");
    } catch (e) {
      emit(SoundEnhancerErrorState(message: "Native recording failed: $e"));
    }
  }

  // --- Audio Processing Methods ---

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

  // Uint8List _convertToStereo(Uint8List monoBytes) {
  //   final monoBuffer = Int16List.view(monoBytes.buffer);
  //   final stereoBuffer = Int16List(monoBuffer.length * 2);

  //   for (int i = 0; i < monoBuffer.length; i++) {
  //     final sample = monoBuffer[i];
  //     stereoBuffer[i * 2] = sample; // Left channel
  //     stereoBuffer[i * 2 + 1] = sample; // Right channel
  //   }

  //   return Uint8List.view(stereoBuffer.buffer);
  // }

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
    if (_enableDenoise && _denoiser != null) {
      final byteData = ByteData.sublistView(chunk);
      final inputShorts = List<int>.generate(
        chunk.lengthInBytes ~/ 2,
        (i) => byteData.getInt16(i * 2, Endian.little),
      );

      // Buffer for denoising
      _sampleBuffer.addAll(inputShorts);

      final outputSamples = <int>[];

      while (_sampleBuffer.length >= 160) {
        final frame = _sampleBuffer.sublist(0, 160);
        _sampleBuffer = _sampleBuffer.sublist(160);

        final denoised = _denoiser!.denoise(frame);

        for (final s in denoised) {
          final amplified = (s * _currentGain).clamp(-32768, 32767).toInt();
          // print("Amplifier gain: $_currentGain");
          outputSamples.add(amplified);
        }
      }

      // Convert to Uint8List using ByteData (ensures endian correctness)
      final outputBytes = BytesBuilder();
      for (final sample in outputSamples) {
        outputBytes.addByte(sample & 0xFF); // little endian low byte
        outputBytes.addByte((sample >> 8) & 0xFF); // high byte
      }

      return outputBytes.toBytes();
    }

    // If denoise disabled, fallback to old working amplifier
    return _amplifyPCM(chunk, _currentGain);
  }

  Future<void> _onStopRecording(
      StopRecordingEvent event, Emitter<SoundEnhancerState> emit) async {
    try {
      await NativeAudioRecorder.stop();
      await _player.stopPlayer();
      await _audioStreamController?.close();
      recording = false;
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
      StartNoiseSupressor event, Emitter<SoundEnhancerState> emit) async {
    _enableDenoise = true;
    await PreferencesUtils.storeNoiseReductionEnabled(true); 
    _denoiser ??= SpeexDenoiser(
      noiseSuppressDb: _denoiseLevel,
    );
    _denoiser ??= SpeexDenoiser(frameSize: 160, sampleRate: 16000);
  }

  Future<void> _onStoptNoiseSupressor(
      StopNoiseSupressor event, Emitter<SoundEnhancerState> emit) async {
    _enableDenoise = false;
    await PreferencesUtils.storeNoiseReductionEnabled(false); 
    _denoiser?.dispose();
    _denoiser = null;
  }

  Future<void> _loadNoiseReductionPref() async {
    _enableDenoise = await PreferencesUtils.getNoiseReductionEnabled();
  }

  // --- Helper Methods ---

  void _handleAudioChunk(Uint8List buffer) async {
    try {
      if (_transcribing) {
        if (socketService.isSocketInitialized) {
          socketService.sendAudio(buffer);
        } else {
          developer.log("WebSocket not connected, attempting reconnect...");
          await socketService.reconnect();
          if (socketService.isSocketInitialized) {
            socketService.sendAudio(buffer);
          }
        }
      }
      // If not transcribing, do nothing!
    } catch (e) {
      developer.log("Error handling audio chunk: $e");
    }
  }

  Future<void> sendAudioToBackend(File audioFile) async {
    try {
      List<int> audioBytes = await audioFile.readAsBytes();
      socketService.sendAudioFile(Uint8List.fromList(audioBytes));
      await audioFile.delete();
      developer.log("Audio sent to backend");
    } catch (e) {
      developer.log("Error sending audio to backend: $e");
    }
  }

  void _startNewStream() {
    _audioStreamController?.close();
    _audioStreamController = StreamController<Uint8List>.broadcast();
  }

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
    emit(TranscriptionUpdatedState(""));
  }
}
