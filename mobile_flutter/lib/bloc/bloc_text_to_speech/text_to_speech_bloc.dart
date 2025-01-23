import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/services/api/global_repository_impl.dart';

class TextToSpeechBloc extends Bloc<TextToSpeechEvent, TextToSpeechState> {
  final GlobalRepositoryImpl _globalService;

  TextToSpeechBloc(this._globalService) : super(TextToSpeechLoadingState()) {
    on<TextToSpeechLoadingEvent>(textToSpeechLoadingEvent);
    on<CreateTextToSpeechEvent>(createTextToSpeechLoadingEvent);
  }

  FutureOr<void> textToSpeechLoadingEvent(
      TextToSpeechLoadingEvent event, Emitter<TextToSpeechState> emit) async {
    try {
      emit(TextToSpeechLoadedSuccessState());
    } catch (e) {
      emit(TextToSpeechErrorState(message: '$e'));
    }
  }

  FutureOr<void> createTextToSpeechLoadingEvent(
      CreateTextToSpeechEvent event, Emitter<TextToSpeechState> emit) async {
    try {
      await _globalService.sendTextToSpeech(event.text, event.title, event.save);
      emit(TextToSpeechLoadedSuccessState());
    } catch (e) {
      emit(TextToSpeechErrorState(message: '$e'));
    }
  }
}
