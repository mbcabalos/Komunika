import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:permission_handler/permission_handler.dart';

part 'sound_enhancer_event.dart';
part 'sound_enhancer_state.dart';

class SoundEnhancerBloc extends Bloc<SoundEnhancerEvent, SoundEnhancerState> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  StreamController<Uint8List>? _audioStreamController;
  final StreamController<String> _transcriptionController =
      StreamController<String>();
  final SocketService socketService;

  bool recording = false;
  bool _transcribing = false;
  double _currentGain = 1.0;

  SoundEnhancerBloc(this.socketService) : super(SoundEnhancerLoadingState()) {
    _player.openPlayer();

    // Event handlers
    on<SoundEnhancerLoadingEvent>(_onLoadingEvent);
    on<RequestPermissionEvent>(_onRequestPermission);
    on<StartRecordingEvent>(_onStartRecording);
    on<StopRecordingEvent>(_onStopRecording);
    on<StartTranscriptionEvent>(_onStartTranscription);
    on<StopTranscriptionEvent>(_onStopTranscription);
    on<SetAmplificationEvent>(_onSetAmplification);
    on<NewTranscriptionEvent>(_onNewTranscription);
    on<LivePreviewTranscriptionEvent>(_onLivePreview);
    on<ClearTextEvent>(_onClearText);

    // Socket listeners
    _setupSocketListeners();
  }

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

  Uint8List _processAudioChunk(Uint8List chunk) {
    var processed = _amplifyPCM(chunk, _currentGain);

    // Optional: Add other processing here (noise reduction, etc.)
    return processed;
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
      // Initialize with saved gain
      _currentGain = await PreferencesUtils.getAmplifierVolume();

      _startNewStream();
      await _recorder.openRecorder();

      await _recorder.startRecorder(
        toStream: _audioStreamController!.sink,
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 1,
      );

      await _player.startPlayerFromStream(
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 1,
      );

      _audioStreamController!.stream.listen(
        (Uint8List buffer) {
          final processed = _processAudioChunk(buffer);
          _handleAudioChunk(buffer);
          _player.foodSink?.add(FoodData(processed));
        },
        onError: (e) => developer.log("Audio stream error: $e"),
      );

      recording = true;
      developer.log("Tap recording started with gain: $_currentGain");
    } catch (e) {
      emit(SoundEnhancerErrorState(message: "Tap recording failed: $e"));
    }
  }

  Future<void> _onStopRecording(
      StopRecordingEvent event, Emitter<SoundEnhancerState> emit) async {
    try {
      await _recorder.stopRecorder();
      await _player.stopPlayer();
      await _audioStreamController?.close();
      recording = false;
      developer.log("Tap recording stopped");
    } catch (e) {
      emit(SoundEnhancerErrorState(message: "Stop recording failed: $e"));
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
