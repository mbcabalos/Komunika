import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

part 'speech_to_text_event.dart';
part 'speech_to_text_state.dart';

class SpeechToTextBloc extends Bloc<SpeechToTextEvent, SpeechToTextState> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamController<Uint8List>? _audioStreamController;
  final StreamController<String> _transcriptionController =
      StreamController<String>();
  final SocketService socketService;
  bool recording = false;
  File? _recordedFile;

  SpeechToTextBloc(this.socketService) : super(SpeechToTextLoadingState()) {
    on<SpeechToTextLoadingEvent>(speechToTextLoadingEvent);
    on<RequestPermissionEvent>(requestPermissionEvent);
    on<CreateSpeechToTextEvent>(createSpeechToTextLoadingEvent);
    on<StartRecordingEvent>(startRecordingEvent);
    on<StopRecordingEvent>(stopRecordingEvent);
    on<StartTapRecordingEvent>(startTapRecordingEvent);
    on<StopTapRecordingEvent>(stopTapRecordingEvent);

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

    on<NewTranscriptionEvent>((event, emit) {
      final currentText = state is TranscriptionUpdatedState
          ? (state as TranscriptionUpdatedState).text
          : '';
      final updatedText = "${event.text}\n";
      emit(TranscriptionUpdatedState(updatedText));
    });

    on<LivePreviewTranscriptionEvent>((event, emit) {
      final currentText = state is LivePreviewTranscriptionState
          ? (state as LivePreviewTranscriptionState).text
          : '';
      final updatedText = "${event.text}\n";
      emit(LivePreviewTranscriptionState(updatedText));
    });
  }

  FutureOr<void> speechToTextLoadingEvent(
      SpeechToTextLoadingEvent event, Emitter<SpeechToTextState> emit) async {
    emit(SpeechToTextLoadedSuccessState());
  }

  FutureOr<void> requestPermissionEvent(
      RequestPermissionEvent event, Emitter<SpeechToTextState> emit) async {
    try {
      Future<void> requestPermission(Permission permission) async {
        var status = await permission.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          await permission.request();
        }
      }

      // Request permissions
      await requestPermission(Permission.microphone);
    } catch (e) {
      emit(SpeechToTextErrorState(message: "$e"));
    }
  }

  FutureOr<void> createSpeechToTextLoadingEvent(
      CreateSpeechToTextEvent event, Emitter<SpeechToTextState> emit) async {}

  // Start recording with stream controller setup
  Future<void> startRecordingEvent(
      StartRecordingEvent event, Emitter<SpeechToTextState> emit) async {
    if (recording) return;
    recording = true;
    Directory tempDir = await getTemporaryDirectory();
    String filePath = '${tempDir.path}/recorded_audio.wav';
    _recordedFile = File(filePath);
    await _recorder.openRecorder();
    await _recorder.startRecorder(
      toFile: filePath,
      codec: Codec.pcm16WAV,
      sampleRate: 16000,
    );
    print("🎙️ Recording started...");
  }

  Future<void> startTapRecordingEvent(
      StartTapRecordingEvent event, Emitter<SpeechToTextState> emit) async {
    _startNewStream();
    await _recorder.openRecorder();
    await _recorder.startRecorder(
      toStream: _audioStreamController!.sink, // ✅ Ensure non-null
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
    );

    _audioStreamController!.stream.listen(
      (Uint8List buffer) {
        _handleAudioChunk(buffer);
      },
      onError: (error) {
        print("Error with the audio stream: $error");
      },
      onDone: () {
        print("Audio stream finished.");
      },
    );

    recording = true;
  }

  void _handleAudioChunk(Uint8List buffer) async {
    try {
      // Directly send audio data to backend without excessive queuing
      if (socketService.isSocketInitialized) {
        socketService.sendAudio(buffer);
      } else {
        print("WebSocket not connected, attempting reconnect...");
        await socketService.reconnect();
        if (socketService.isSocketInitialized) {
          socketService.sendAudio(buffer);
        } else {
          print("Failed to reconnect WebSocket");
        }
      }
    } catch (e) {
      print("Error in handling audio chunk: $e");
    }
  }

  // Stop recording and send audio to the backend
  Future<void> stopRecordingEvent(
      StopRecordingEvent event, Emitter<SpeechToTextState> emit) async {
    emit(TranscriptionUpdatedState(""));
    if (!recording) return;
    recording = false;
    await _recorder.stopRecorder();
    print("🛑 Recording stopped.");
    if (_recordedFile != null) {
      sendAudioToBackend(_recordedFile!);
    }
  }

  Future<void> stopTapRecordingEvent(
      StopTapRecordingEvent event, Emitter<SpeechToTextState> emit) async {
    emit(TranscriptionUpdatedState(""));
    await _recorder.stopRecorder();
    await Future.delayed(const Duration(seconds: 7));
    _audioStreamController?.close();
    recording = false;
  }

  // Send recorded audio to the backend
  void sendAudioToBackend(File audioFile) async {
    print("📤 Sending audio to backend...");
    List<int> audioBytes = await audioFile.readAsBytes();
    socketService.sendAudioFile(Uint8List.fromList(audioBytes));
    await audioFile.delete();
    print("Socket called");
  }

  // Manage stream controller lifecycle
  void _startNewStream() {
    _audioStreamController?.close(); // Close any existing stream
    _audioStreamController = StreamController<Uint8List>.broadcast();
  }

  @override
  Future<void> close() {
    _recorder.closeRecorder();
    _audioStreamController?.close(); // Close the stream controller
    return super.close();
  }
}
