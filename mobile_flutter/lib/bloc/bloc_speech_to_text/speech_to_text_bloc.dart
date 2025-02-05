import 'dart:async';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';

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

  SpeechToTextBloc(this.socketService) : super(SpeechToTextLoadingState()) {
    on<SpeechToTextLoadingEvent>(speechToTextLoadingEvent);
    on<CreateSpeechToTextEvent>(createSpeechToTextLoadingEvent);
    on<StartRecording>(_startRecording);

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
      final updatedText = event.text;
      emit(TranscriptionUpdated(updatedText));
    });
  }

  FutureOr<void> speechToTextLoadingEvent(
      SpeechToTextLoadingEvent event, Emitter<SpeechToTextState> emit) async {
    emit(SpeechToTextLoadedSuccessState());
  }

  FutureOr<void> createSpeechToTextLoadingEvent(
      CreateSpeechToTextEvent event, Emitter<SpeechToTextState> emit) async {}

  Future<void> _startRecording(
      StartRecording event, Emitter<SpeechToTextState> emit) async {
    await _recorder.openRecorder();
    await _recorder.startRecorder(
      toStream: _audioStreamController.sink,
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
    );

    _audioStreamController.stream.listen(
      (Uint8List buffer) {
        socketService.sendAudio(buffer);
      },
      onDone: () {
        _restartRecorder();
      },
    );

    isRecording = true;
  }

  Future<void> _restartRecorder() async {
    add(StartRecording()); // Restart
  }

  @override
  Future<void> close() {
    _recorder.closeRecorder();
    return super.close();
  }
}
