abstract class TextToSpeechEvent {}

class TextToSpeechLoadingEvent extends TextToSpeechEvent {}

class CreateTextToSpeechEvent extends TextToSpeechEvent {
  final String text;
  final String title;
  final bool save;

  CreateTextToSpeechEvent({required this.text, required this.title, required this.save});
}
