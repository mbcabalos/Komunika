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
  StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>();
  final StreamController<String> _transcriptionController =
      StreamController<String>();
  final SocketService socketService;
  bool isRecording = false;
  File? _recordedFile;

  SpeechToTextBloc(this.socketService) : super(SpeechToTextLoadingState()) {
    on<SpeechToTextLoadingEvent>(speechToTextLoadingEvent);
    on<CreateSpeechToTextEvent>(createSpeechToTextLoadingEvent);
    on<StartRecording>(_startRecording);
    on<StopRecording>(_stopRecording);

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

  // Future<void> _startRecording(
  //     StartRecording event, Emitter<SpeechToTextState> emit) async {
  //   _startNewStream();
  //   await _recorder.openRecorder();
  //   await _recorder.startRecorder(
  //     toStream: _audioStreamController.sink,
  //     codec: Codec.pcm16,
  //     sampleRate: 16000,
  //     numChannels: 1,
  //   );
  //   _audioStreamController.stream.listen(
  //     (Uint8List buffer) {
  //       socketService.sendAudio(buffer);
  //     },
  //   );
  //   isRecording = true;
  // }

  // Future<void> _stopRecording(
  //     StopRecording event, Emitter<SpeechToTextState> emit) async {
  //   await _recorder.stopRecorder();
  //   await Future.delayed(const Duration(seconds: 7));
  //   _audioStreamController.close();
  //   isRecording = false;
  // }

  // @override
  // Future<void> close() {
  //   _recorder.closeRecorder();
  //   return super.close();
  // }

  // void _startNewStream() {
  //   _audioStreamController?.close(); // Close if already open
  //   _audioStreamController = StreamController<Uint8List>(); // Create a new one
  // }

  Future<void> _startRecording(
      StartRecording event, Emitter<SpeechToTextState> emit) async {
    if (isRecording) return;

    isRecording = true;
    Directory tempDir = await getTemporaryDirectory();
    String filePath = '${tempDir.path}/recorded_audio.wav';
    _recordedFile = File(filePath);

    await _recorder.openRecorder();
    await _recorder.startRecorder(
      toFile: filePath, // Save the recording to a file
      codec: Codec.pcm16WAV,
      sampleRate: 16000,
    );

    print("🎙️ Recording started...");
  }

  Future<void> _stopRecording(
      StopRecording event, Emitter<SpeechToTextState> emit) async {
    if (!isRecording) return;

    isRecording = false;
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();

    print("🛑 Recording stopped.");

    if (_recordedFile != null) {
      sendAudioToBackend(_recordedFile!);
    }
  }

  void sendAudioToBackend(File audioFile) async {
    print("📤 Sending audio to backend...");
    List<int> audioBytes = await audioFile.readAsBytes();
    socketService.sendAudioFile(Uint8List.fromList(audioBytes));
    print("Socket called");
  }

  @override
  Future<void> close() {
    _recorder.closeRecorder();
    return super.close();
  }
}
