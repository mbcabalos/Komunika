import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/services/api/global_repository_impl.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';

class TextToSpeechBloc extends Bloc<TextToSpeechEvent, TextToSpeechState> {
  final GlobalRepositoryImpl _globalService;
  final DatabaseHelper _databaseHelper;
  final FlutterTts flutterTts = FlutterTts();
  final ImagePicker _imagePicker = ImagePicker();

  TextToSpeechBloc(this._globalService, this._databaseHelper)
      : super(TextToSpeechLoadingState()) {
    on<TextToSpeechLoadingEvent>(textToSpeechLoadingEvent);
    on<CreateTextToSpeechEvent>(createTextToSpeechEvent);
    on<FlutterTTSEvent>(flutterTTSEvent);
    on<PlayAudioEvent>(playAudioEvent);
    on<AddToFavoriteEvent>(addToFavoriteEvent);
    on<RemoveFromFavoriteEvent>(removeFromFavoriteEvent);
    on<DeleteQuickSpeechEvent>(deleteQuickspeechEvent);
    on<CaptureImageEvent>(captureImageEvent);
    on<CropAndPreviewImageEvent>(cropAndPreviewImageEvent);
    on<ExtractTextFromImageEvent>(_extractTextFromImageEvent);
    on<BatchExtractTextEvent>(_batchExtractTextEvent);
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

  Future<void> flutterTTSEvent(
      FlutterTTSEvent event, Emitter<TextToSpeechState> emit) async {
    try {
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.speak(event.text);
      await _fetchAndEmitAudioItems(emit);
      emit(AudioPlaybackCompletedState());
    } catch (e) {
      emit(TextToSpeechErrorState(message: "$e"));
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

  FutureOr<void> captureImageEvent(
      CaptureImageEvent event, Emitter<TextToSpeechState> emit) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: event.source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 70,
      );

      if (image != null) {
        add(CropAndPreviewImageEvent(image: image));
      }
    } catch (e) {
      emit(TextToSpeechErrorState(message: '$e'));
    }
  }

  FutureOr<void> cropAndPreviewImageEvent(
      CropAndPreviewImageEvent event, Emitter<TextToSpeechState> emit) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: event.image.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle:
                "\n Crop Image", 
            toolbarColor: ColorsPalette.accent, 
            toolbarWidgetColor: ColorsPalette.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
            activeControlsWidgetColor: ColorsPalette.accent,
          ),
          IOSUiSettings(
            title: "\n Crop Image",
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        emit(ImageCroppedState(croppedImagePath: croppedFile.path));
      }
    } catch (e) {
      emit(TextToSpeechErrorState(
          message: "Error cropping image: ${e.toString()}"));
    }
  }

  Future<void> _extractTextFromImageEvent(
      ExtractTextFromImageEvent event, Emitter<TextToSpeechState> emit) async {
    emit(TextExtractionInProgressState(current: 1, total: 1));
    try {
      final inputImage = InputImage.fromFilePath(event.imagePath);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      textRecognizer.close();
      emit(TextExtractionSuccessState(extractedText: recognizedText.text));
    } catch (e) {
      emit(TextToSpeechErrorState(message: "OCR Error: $e"));
    }
  }

  Future<void> _batchExtractTextEvent(
      BatchExtractTextEvent event, Emitter<TextToSpeechState> emit) async {
    String combinedText = '';
    final total = event.imagePaths.length;

    for (int i = 0; i < total; i++) {
      emit(TextExtractionInProgressState(current: i + 1, total: total));
      try {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: event.imagePaths[i],
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: "Processing image ${i + 1} of $total",
              toolbarColor: ColorsPalette.accent,
              toolbarWidgetColor: ColorsPalette.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
          ],
        );

        if (croppedFile != null) {
          final inputImage = InputImage.fromFilePath(croppedFile.path);
          final textRecognizer = TextRecognizer();
          final RecognizedText recognizedText =
              await textRecognizer.processImage(inputImage);
          textRecognizer.close();

          if (recognizedText.text.isNotEmpty) {
            combinedText = combinedText.isEmpty
                ? recognizedText.text
                : '$combinedText\n\n${recognizedText.text}';
          }
        }
      } catch (e) {
        // Optionally emit an error or continue
      }
    }

    emit(TextExtractionSuccessState(extractedText: combinedText));
  }
}
