import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/utils/colors.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';

class TextToSpeechBloc extends Bloc<TextToSpeechEvent, TextToSpeechState> {
  final FlutterTts flutterTts = FlutterTts();
  final ImagePicker _imagePicker = ImagePicker();

  TextToSpeechBloc() : super(TextToSpeechLoadingState()) {
    on<TextToSpeechLoadingEvent>(textToSpeechLoadingEvent);
    on<CaptureImageEvent>(captureImageEvent);
    on<CropAndPreviewImageEvent>(cropAndPreviewImageEvent);
    on<ExtractTextFromImageEvent>(_extractTextFromImageEvent);
    on<BatchExtractTextEvent>(_batchExtractTextEvent);
  }

  FutureOr<void> textToSpeechLoadingEvent(
      TextToSpeechLoadingEvent event, Emitter<TextToSpeechState> emit) async {
    try {
      emit(TextToSpeechLoadedSuccessState());
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
            toolbarTitle: "Crop Image",
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
            title: "Crop Image",
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
