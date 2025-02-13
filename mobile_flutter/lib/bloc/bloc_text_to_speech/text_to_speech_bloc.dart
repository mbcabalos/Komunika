import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/services/api/global_repository_impl.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:path_provider/path_provider.dart';

class TextToSpeechBloc extends Bloc<TextToSpeechEvent, TextToSpeechState> {
  final GlobalRepositoryImpl _globalService;
  final DatabaseHelper _databaseHelper;

  TextToSpeechBloc(this._globalService, this._databaseHelper)
      : super(TextToSpeechLoadingState()) {
    on<TextToSpeechLoadingEvent>(textToSpeechLoadingEvent);
    on<CreateTextToSpeechEvent>(createTextToSpeechLoadingEvent);
    on<PlayAudioEvent>(playAudioEvent);
    on<AddToFavorite>(addToFavorite);
    on<RemoveFromFavorite>(removeFromFavorite);
    on<DeleteQuickSpeech>(deleteQuickspeech);
  }

  FutureOr<void> textToSpeechLoadingEvent(
      TextToSpeechLoadingEvent event, Emitter<TextToSpeechState> emit) async {
    try {
      List<Map<String, dynamic>> data =
          await DatabaseHelper().fetchAllAudioItems();
      emit(TextToSpeechLoadedSuccessState(audioItems: data));
    } catch (e) {
      emit(TextToSpeechErrorState(message: '$e'));
    }
  }

  FutureOr<void> createTextToSpeechLoadingEvent(
      CreateTextToSpeechEvent event, Emitter<TextToSpeechState> emit) async {
    try {
      await _globalService.sendTextToSpeech(
          event.text, event.title, event.save);
      List<Map<String, dynamic>> data =
          await DatabaseHelper().fetchAllAudioItems();
      emit(TextToSpeechLoadedSuccessState(audioItems: data));
    } catch (e) {
      emit(TextToSpeechErrorState(message: '$e'));
    }
  }

  FutureOr<void> addToFavorite(
      AddToFavorite event, Emitter<TextToSpeechState> emit) async {
    try {
      _databaseHelper.favorite(event.audioName);
      List<Map<String, dynamic>> data =
          await DatabaseHelper().fetchAllAudioItems();
      emit(TextToSpeechLoadedSuccessState(audioItems: data));
    } catch (e) {}
  }

  FutureOr<void> removeFromFavorite(
      RemoveFromFavorite event, Emitter<TextToSpeechState> emit) async {
    try {
      _databaseHelper.removeFavorite(event.audioName);
      List<Map<String, dynamic>> data =
          await DatabaseHelper().fetchAllAudioItems();
      emit(TextToSpeechLoadedSuccessState(audioItems: data));
    } catch (e) {}
  }

  FutureOr<void> deleteQuickspeech(
      DeleteQuickSpeech event, Emitter<TextToSpeechState> emit) async {
    try {
      await DatabaseHelper().deleteAudioItem(event.audioId);
      List<Map<String, dynamic>> data =
          await DatabaseHelper().fetchAllAudioItems();
      emit(TextToSpeechLoadedSuccessState(audioItems: data));
    } catch (e) {}
  }

  FutureOr<void> playAudioEvent(
      PlayAudioEvent event, Emitter<TextToSpeechState> emit) async {
    try {
      String path = event.audioName;
      final directory = await getExternalStorageDirectory();
      final downloadDir = Directory('${directory?.parent.path}/files/audio');
      final filePath = '${downloadDir.path}/$path.mp3';
      final player = AudioPlayer();
      await player.setFilePath(filePath);
      await player.play(); 
      List<Map<String, dynamic>> data =
          await DatabaseHelper().fetchAllAudioItems();
      emit(TextToSpeechLoadedSuccessState(audioItems: data));
    } catch (e) {}
  }
}
