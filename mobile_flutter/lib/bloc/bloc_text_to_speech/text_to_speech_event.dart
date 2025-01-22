abstract class TextToSpeechEvent {}

class TextToSpeechLoadingEvent extends TextToSpeechEvent {}

class CreateTextToSpeechEvent extends TextToSpeechEvent {
  final String text;

  CreateTextToSpeechEvent({required this.text});
}
