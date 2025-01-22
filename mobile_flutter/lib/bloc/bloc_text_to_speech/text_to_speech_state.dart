abstract class TextToSpeechState {}

class TextToSpeechLoadingState extends TextToSpeechState {}

class TextToSpeechLoadedSuccessState extends TextToSpeechState {}

class TextToSpeechErrorState extends TextToSpeechState {
  final String message;

  TextToSpeechErrorState({required this.message});
}
