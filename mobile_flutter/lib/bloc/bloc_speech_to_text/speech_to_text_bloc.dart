import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:path_provider/path_provider.dart';

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
    on<CreateSpeechToTextEvent>(createSpeechToTextLoadingEvent);
    on<StartRecording>(_startRecording);
    on<StopRecording>(_stopRecording);
    on<StartTapRecording>(_startTapRecording);
    on<StopTapRecording>(_stopTapRecording);

    socketService.socket?.on("transcription_result", (data) {
      if (data != null && data["text"] != null) {
        _transcriptionController.add(data["text"]);
        add(NewTranscriptionEvent(data["text"]));
      }
    });

    on<NewTranscriptionEvent>((event, emit) {
      final currentText = state is TranscriptionUpdated
          ? (state as TranscriptionUpdated).text
          : '';
      final updatedText = "${event.text}\n";
      emit(TranscriptionUpdated(updatedText));
    });
  }

  FutureOr<void> speechToTextLoadingEvent(
      SpeechToTextLoadingEvent event, Emitter<SpeechToTextState> emit) async {
    emit(SpeechToTextLoadedSuccessState());
  }

  FutureOr<void> createSpeechToTextLoadingEvent(
      CreateSpeechToTextEvent event, Emitter<SpeechToTextState> emit) async {}

  // Start recording with stream controller setup
  Future<void> _startRecording(
      StartRecording event, Emitter<SpeechToTextState> emit) async {
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

  Future<void> _startTapRecording(
      StartTapRecording event, Emitter<SpeechToTextState> emit) async {
    _startNewStream();
    await _recorder.openRecorder();
    await _recorder.startRecorder(
      toStream: _audioStreamController?.sink,
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
    );
    _audioStreamController?.stream.listen(
      (Uint8List buffer) {
        socketService.sendAudio(buffer);
      },
    );
    recording = true;
  }

  // Stop recording and send audio to the backend
  Future<void> _stopRecording(
      StopRecording event, Emitter<SpeechToTextState> emit) async {
    if (!recording) return;
    recording = false;
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();
    print("🛑 Recording stopped.");
    if (_recordedFile != null) {
      sendAudioToBackend(_recordedFile!);
    }
  }

  Future<void> _stopTapRecording(
      StopTapRecording event, Emitter<SpeechToTextState> emit) async {
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
    _audioStreamController = StreamController<Uint8List>(); // Create a new one
  }

  @override
  Future<void> close() {
    _recorder.closeRecorder();
    _audioStreamController?.close(); // Close the stream controller
    return super.close();
  }
}
