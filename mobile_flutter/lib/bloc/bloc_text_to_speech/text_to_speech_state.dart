abstract class TextToSpeechState {}

class TextToSpeechLoadingState extends TextToSpeechState {}

class TextToSpeechLoadedSuccessState extends TextToSpeechState {
  final List<Map<String, dynamic>> audioItems;

  TextToSpeechLoadedSuccessState({required this.audioItems});
}

class TextToSpeechErrorState extends TextToSpeechState {
  final String message;

  TextToSpeechErrorState({required this.message});
}

class AudioPlaybackCompletedState extends TextToSpeechState {}

