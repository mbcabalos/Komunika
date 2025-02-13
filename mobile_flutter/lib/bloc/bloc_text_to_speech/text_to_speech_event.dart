import 'dart:ffi';

abstract class TextToSpeechEvent {}

class TextToSpeechLoadingEvent extends TextToSpeechEvent {}

class CreateTextToSpeechEvent extends TextToSpeechEvent {
  final String text;
  final String title;
  final bool save;

  CreateTextToSpeechEvent(
      {required this.text, required this.title, required this.save});
}

class FetchAudioEvent extends TextToSpeechEvent {}

class PlayAudioEvent extends TextToSpeechEvent {
  final String audioName;

  PlayAudioEvent({required this.audioName});
}

class AddToFavorite extends TextToSpeechEvent {
  final String audioName;

  AddToFavorite({required this.audioName});
}

class RemoveFromFavorite extends TextToSpeechEvent {
  final String audioName;

  RemoveFromFavorite({required this.audioName});
}

class DeleteQuickSpeech extends TextToSpeechEvent {
  final int audioId;

  DeleteQuickSpeech({required this.audioId});
}
