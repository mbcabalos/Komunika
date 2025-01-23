import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:komunika/services/api/global_repository_impl.dart';
import 'package:meta/meta.dart';

part 'speech_to_text_event.dart';
part 'speech_to_text_state.dart';

class SpeechToTextBloc extends Bloc<SpeechToTextEvent, SpeechToTextState> {
  final GlobalRepositoryImpl globalRepositoryImpl;
  SpeechToTextBloc(this.globalRepositoryImpl)
      : super(SpeechToTextLoadingState()) {
    on<SpeechToTextLoadingEvent>(speechToTextLoadingEvent);
    on<CreateSpeechToTextEvent>(createSpeechToTextLoadingEvent);
  }

  FutureOr<void> speechToTextLoadingEvent(
      SpeechToTextLoadingEvent event, Emitter<SpeechToTextState> emit) async {
    try {
      emit(SpeechToTextLoadedSuccessState());
    } catch (e) {
      emit(SpeechToTextErrorState(message: '$e'));
    }
  }

  FutureOr<void> createSpeechToTextLoadingEvent(
      CreateSpeechToTextEvent event, Emitter<SpeechToTextState> emit) async {
    try {
      await globalRepositoryImpl.startLiveTranscription();
      emit(SpeechToTextLoadedSuccessState());
    } catch (e) {
      emit(SpeechToTextErrorState(message: '$e'));
    }
  }
}
