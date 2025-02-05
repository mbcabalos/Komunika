import 'dart:async';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:komunika/services/api/global_repository_impl.dart';

part 'speech_to_text_event.dart';
part 'speech_to_text_state.dart';

class SpeechToTextBloc extends Bloc<SpeechToTextEvent, SpeechToTextState> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>();
  final GlobalRepositoryImpl globalRepositoryImpl;
  final socketService = SocketService();
  bool isRecording = false;

  SpeechToTextBloc(this.globalRepositoryImpl)
      : super(SpeechToTextLoadingState()) {
    on<SpeechToTextLoadingEvent>(speechToTextLoadingEvent);
    on<CreateSpeechToTextEvent>(createSpeechToTextLoadingEvent);
    on<StartRecording>(_startRecording);
    on<StopRecording>(_stopRecording);
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

    _audioStreamController.stream.listen((Uint8List buffer) {
      socketService.sendAudio(buffer);
    });

    await _recorder.startRecorder(
      toStream: _audioStreamController.sink,
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
    );

    isRecording = true;
  }

  Future<void> _stopRecording(
      StopRecording event, Emitter<SpeechToTextState> emit) async {
    await _recorder.stopRecorder();
    isRecording = false;
  }

  @override
  Future<void> close() {
    _recorder.closeRecorder();
    socketService.closeSocket();
    return super.close();
  }
}
