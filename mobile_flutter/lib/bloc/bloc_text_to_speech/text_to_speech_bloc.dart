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
    on<CreateTextToSpeechEvent>(createTextToSpeechEvent);
    on<PlayAudioEvent>(playAudioEvent);
    on<AddToFavoriteEvent>(addToFavoriteEvent);
    on<RemoveFromFavoriteEvent>(removeFromFavoriteEvent);
    on<DeleteQuickSpeechEvent>(deleteQuickspeechEvent);
  }

  /// Helper function to fetch audio items and emit state
  Future<void> _fetchAndEmitAudioItems(Emitter<TextToSpeechState> emit) async {
    try {
      List<Map<String, dynamic>> audioItems =
          await _databaseHelper.fetchAllAudioItems();
      emit(TextToSpeechLoadedSuccessState(audioItems: audioItems));
    } catch (e) {
      emit(TextToSpeechErrorState(message: '$e'));
    }
  }

  FutureOr<void> textToSpeechLoadingEvent(
      TextToSpeechLoadingEvent event, Emitter<TextToSpeechState> emit) async {
    await _fetchAndEmitAudioItems(emit);
  }

  FutureOr<void> createTextToSpeechEvent(
      CreateTextToSpeechEvent event, Emitter<TextToSpeechState> emit) async {
    try {
      await _globalService.sendTextToSpeech(
          event.text, event.title, event.save);
      await _fetchAndEmitAudioItems(emit);
      emit(AudioPlaybackCompletedState());
    } catch (e) {
      emit(TextToSpeechErrorState(message: '$e'));
    }
  }

  FutureOr<void> addToFavoriteEvent(
      AddToFavoriteEvent event, Emitter<TextToSpeechState> emit) async {
    try {
      await _databaseHelper.favorite(event.audioName);
      await _fetchAndEmitAudioItems(emit);
    } catch (e) {
      emit(TextToSpeechErrorState(message: '$e'));
    }
  }

  FutureOr<void> removeFromFavoriteEvent(
      RemoveFromFavoriteEvent event, Emitter<TextToSpeechState> emit) async {
    try {
      await _databaseHelper.removeFavorite(event.audioName);
      await _fetchAndEmitAudioItems(emit);
    } catch (e) {
      emit(TextToSpeechErrorState(message: '$e'));
    }
  }

  FutureOr<void> deleteQuickspeechEvent(
      DeleteQuickSpeechEvent event, Emitter<TextToSpeechState> emit) async {
    try {
      await _databaseHelper.deleteAudioItem(event.audioId);
      await _fetchAndEmitAudioItems(emit);
    } catch (e) {
      emit(TextToSpeechErrorState(message: '$e'));
    }
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

      // ✅ Correctly await the stream using `await for`
      await for (final playerState in player.playerStateStream) {
        if (playerState.processingState == ProcessingState.completed) {
          emit(AudioPlaybackCompletedState());
          break; // Stop listening after emitting the state
        }
      }
      await _fetchAndEmitAudioItems(emit);
    } catch (e) {
      emit(TextToSpeechErrorState(message: '$e'));
    }
  }
}
