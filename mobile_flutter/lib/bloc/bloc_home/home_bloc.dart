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
  final AudioPlayer _player = AudioPlayer();
  HomeBloc(this._databaseHelper) : super(HomeLoadingState()) {
    on<HomeLoadingEvent>(homeLoadingEvent);
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
    PermissionStatus status = await Permission.storage.status;

    if (!status.isGranted) {
      PermissionStatus newStatus = await Permission.storage.request();
      if (!newStatus.isGranted) {
        emit(HomeErrorState(message: "Storage permission denied"));
        return; 
      }
    }

    // Proceed with your logic to fetch and emit audio items
    await _fetchAndEmitAudioItems(emit);
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

      // Set the audio file and play it
      await _player.setFilePath(filePath);
      await _player.play();

      // Listen for playback completion
      final completer = Completer<void>();
      final subscription = _player.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          completer.complete();
        }
      });

      await completer.future;
      emit(AudioPlaybackCompletedState());
      await _fetchAndEmitAudioItems(emit);

      subscription.cancel();
    } catch (e) {
      emit(HomeErrorState(message: "$e"));
    }
  }
}
