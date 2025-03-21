abstract class TextToSpeechEvent {}

class TextToSpeechLoadingEvent extends TextToSpeechEvent {}

class CreateTextToSpeechEvent extends TextToSpeechEvent {
  final String text;
  final String title;
  final bool save;

  CreateTextToSpeechEvent(
      {required this.text, required this.title, required this.save});
}

class FlutterTTSEvent extends TextToSpeechEvent {
  final String text;
  final String language;
  final String voice;

  FlutterTTSEvent(
      {required this.text, required this.language, required this.voice});
}

class FetchAudioEvent extends TextToSpeechEvent {}

class PlayAudioEvent extends TextToSpeechEvent {
  final String audioName;

  PlayAudioEvent({required this.audioName});
}

class AddToFavoriteEvent extends TextToSpeechEvent {
  final String audioName;

  AddToFavoriteEvent({required this.audioName});
}

class RemoveFromFavoriteEvent extends TextToSpeechEvent {
  final String audioName;

  RemoveFromFavoriteEvent({required this.audioName});
}

class DeleteQuickSpeechEvent extends TextToSpeechEvent {
  final int audioId;

  DeleteQuickSpeechEvent({required this.audioId});
}
