import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:path_provider/path_provider.dart';
part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeLoadingState()) {
    on<HomeLoadingEvent>(homeLoadingEvent);
    on<FetchAudioEvent>(fetchAudioEvent);
    on<PlayAudioEvent>(playAudioEvent);
  }

  FutureOr<void> homeLoadingEvent(
      HomeLoadingEvent event, Emitter<HomeState> emit) async {
    try {
      List<Map<String, dynamic>> data =
          await DatabaseHelper().fetchAllAudioItems();
      emit(HomeSuccessLoadedState(audioItems: data));
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
      await player.setFilePath(filePath); // Set file path (local file or URL)
      await player.play(); // Play the audio
      List<Map<String, dynamic>> data =
          await DatabaseHelper().fetchAllAudioItems();
      emit(HomeSuccessLoadedState(audioItems: data));
    } catch (e) {
      emit(HomeErrorState(message: "$e"));
    }
  }
}
