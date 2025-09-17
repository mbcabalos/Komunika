import 'package:image_picker/image_picker.dart';

abstract class TextToSpeechEvent {}

class TextToSpeechLoadingEvent extends TextToSpeechEvent {}

class FlutterTTSEvent extends TextToSpeechEvent {
  final String text;
  final String language;
  final String voice;

  FlutterTTSEvent(
      {required this.text, required this.language, required this.voice});
}

class FetchAudioEvent extends TextToSpeechEvent {}

class CaptureImageEvent extends TextToSpeechEvent {
  final ImageSource source;

  CaptureImageEvent({required this.source});
}

class CropAndPreviewImageEvent extends TextToSpeechEvent {
  final XFile image;

  CropAndPreviewImageEvent({required this.image});
}

class ExtractTextFromImageEvent extends TextToSpeechEvent {
  final String imagePath;
  ExtractTextFromImageEvent({required this.imagePath});
}

class BatchExtractTextEvent extends TextToSpeechEvent {
  final List<String> imagePaths;
  BatchExtractTextEvent({required this.imagePaths});
}
