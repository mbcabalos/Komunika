import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DatabaseHelper _databaseHelper;
  HomeBloc(this._databaseHelper) : super(HomeLoadingState()) {
    on<HomeLoadingEvent>(homeLoadingEvent);
    on<RequestPermissionEvent>(requestPermissionEvent);
    on<FetchAudioEvent>(fetchAudioEvent);
    on<PlayAudioEvent>(playAudioEvent);
  }

  /// Helper function to fetch audio items and emit state
  Future<void> _fetchAndEmitAudioItems(Emitter<HomeState> emit) async {
    try {
      List<Map<String, dynamic>> audioItems =
          await _databaseHelper.fetchAllFavorites();
      emit(HomeSuccessLoadedState(audioItems: audioItems));
    } catch (e) {
      emit(HomeErrorState(message: '$e'));
    }
  }

  FutureOr<void> homeLoadingEvent(
      HomeLoadingEvent event, Emitter<HomeState> emit) async {
    await _fetchAndEmitAudioItems(emit);
  }

  FutureOr<void> requestPermissionEvent(
      RequestPermissionEvent event, Emitter<HomeState> emit) async {
    try {
      var status = await Permission.microphone.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        print("Microphone permission is required!");
        // Optionally, guide the user to the app settings to enable it
        openAppSettings();
      }
      await _fetchAndEmitAudioItems(emit);
    } catch (e) {
      emit(HomeErrorState(message: "$e"));
    }
  }

  FutureOr<void> fetchAudioEvent(
      FetchAudioEvent event, Emitter<HomeState> emit) async {
    try {
      List<Map<String, dynamic>> data =
          await DatabaseHelper().fetchAllFavorites();
      emit(HomeSuccessLoadedState(audioItems: data));
    } catch (e) {
      emit(HomeErrorState(message: "$e"));
    }
  }

  FutureOr<void> playAudioEvent(
      PlayAudioEvent event, Emitter<HomeState> emit) async {
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
      emit(HomeErrorState(message: "$e"));
    }
  }
}
