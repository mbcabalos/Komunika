abstract class TextToSpeechState {}

class TextToSpeechLoadingState extends TextToSpeechState {}

class TextToSpeechLoadedSuccessState extends TextToSpeechState {}

class TextToSpeechErrorState extends TextToSpeechState {
  final String message;

  TextToSpeechErrorState({required this.message});
}

class TextExtractionInProgressState extends TextToSpeechState {
  final int current;
  final int total;
  TextExtractionInProgressState({required this.current, required this.total});
}

class TextExtractionSuccessState extends TextToSpeechState {
  final String extractedText;
  TextExtractionSuccessState({required this.extractedText});
}

class ImageCroppedState extends TextToSpeechState {
  final String croppedImagePath;
  ImageCroppedState({required this.croppedImagePath});
}
