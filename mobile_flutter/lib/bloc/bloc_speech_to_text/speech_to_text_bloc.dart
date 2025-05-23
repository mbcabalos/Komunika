import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

part 'speech_to_text_event.dart';
part 'speech_to_text_state.dart';

class SpeechToTextBloc extends Bloc<SpeechToTextEvent, SpeechToTextState> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  
  StreamController<Uint8List>? _audioStreamController;
  final StreamController<String> _transcriptionController = StreamController<String>();
  final SocketService socketService;

  bool recording = false;
  File? _recordedFile;
  double _currentGain = 1.0; // Current amplification level

  SpeechToTextBloc(this.socketService) : super(SpeechToTextLoadingState()) {
    _player.openPlayer();

    // Event handlers
    on<SpeechToTextLoadingEvent>(_onLoadingEvent);
    on<RequestPermissionEvent>(_onRequestPermission);
    on<StartRecordingEvent>(_onStartRecording);
    on<StopRecordingEvent>(_onStopRecording);
    on<StartTapRecordingEvent>(_onStartTapRecording);
    on<StopTapRecordingEvent>(_onStopTapRecording);
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
    // Apply current gain
    var processed = _amplifyPCM(chunk, _currentGain);
    
    // Optional: Add other processing here (noise reduction, etc.)
    return processed;
  }

  // --- Event Handlers ---

  Future<void> _onLoadingEvent(
      SpeechToTextLoadingEvent event, Emitter<SpeechToTextState> emit) async {
    emit(SpeechToTextLoadedSuccessState());
  }

  Future<void> _onRequestPermission(
      RequestPermissionEvent event, Emitter<SpeechToTextState> emit) async {
    try {
      var status = await Permission.microphone.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        emit(SpeechToTextErrorState(message: "Microphone permission denied"));
      }
    } catch (e) {
      emit(SpeechToTextErrorState(message: "Permission error: $e"));
    }
  }

  Future<void> _onStartRecording(
      StartRecordingEvent event, Emitter<SpeechToTextState> emit) async {
    if (recording) return;
    
    try {
      Directory tempDir = await getTemporaryDirectory();
      String filePath = '${tempDir.path}/recorded_audio.wav';
      _recordedFile = File(filePath);
      
      await _recorder.openRecorder();
      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
      );
      
      recording = true;
      developer.log("Recording started");
    } catch (e) {
      emit(SpeechToTextErrorState(message: "Recording failed: $e"));
    }
  }

  Future<void> _onStartTapRecording(
      StartTapRecordingEvent event, Emitter<SpeechToTextState> emit) async {
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
      emit(SpeechToTextErrorState(message: "Tap recording failed: $e"));
    }
  }

  Future<void> _onStopRecording(
      StopRecordingEvent event, Emitter<SpeechToTextState> emit) async {
    if (!recording) return;
    
    try {
      await _recorder.stopRecorder();
      if (_recordedFile != null) {
        await sendAudioToBackend(_recordedFile!);
      }
      recording = false;
      developer.log("Recording stopped");
    } catch (e) {
      emit(SpeechToTextErrorState(message: "Stop recording failed: $e"));
    }
  }

  Future<void> _onStopTapRecording(
      StopTapRecordingEvent event, Emitter<SpeechToTextState> emit) async {
    try {
      await _recorder.stopRecorder();
      await _player.stopPlayer();
      await _audioStreamController?.close();
      recording = false;
      developer.log("Tap recording stopped");
    } catch (e) {
      emit(SpeechToTextErrorState(message: "Stop tap recording failed: $e"));
    }
  }

  Future<void> _onSetAmplification(
      SetAmplificationEvent event, Emitter<SpeechToTextState> emit) async {
    try {
      // Clamp between 0.5 and 3.0 for reasonable amplification
      _currentGain = event.gain.clamp(0.5, 3.0);
      await PreferencesUtils.storeAmplifierVolume(_currentGain);
      developer.log("Amplification set to: $_currentGain");
    } catch (e) {
      emit(SpeechToTextErrorState(message: "Failed to set amplification: $e"));
    }
  }

  // --- Helper Methods ---

  void _handleAudioChunk(Uint8List buffer) async {
    try {
      if (socketService.isSocketInitialized) {
        socketService.sendAudio(buffer);
      } else {
        developer.log("WebSocket not connected, attempting reconnect...");
        await socketService.reconnect();
        if (socketService.isSocketInitialized) {
          socketService.sendAudio(buffer);
        }
      }
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
  
  void _onNewTranscription(NewTranscriptionEvent event, Emitter<SpeechToTextState> emit) {
    emit(TranscriptionUpdatedState("${event.text}\n"));
  }

  void _onLivePreview(LivePreviewTranscriptionEvent event, Emitter<SpeechToTextState> emit) {
    emit(LivePreviewTranscriptionState(event.text));
  }

  void _onClearText(ClearTextEvent event, Emitter<SpeechToTextState> emit) {
    emit(TranscriptionUpdatedState(""));
  }
}