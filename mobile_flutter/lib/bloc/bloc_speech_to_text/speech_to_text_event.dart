part of 'speech_to_text_bloc.dart';

abstract class SpeechToTextEvent {}

class SpeechToTextLoadingEvent extends SpeechToTextEvent {}

class CreateSpeechToTextEvent extends SpeechToTextEvent {
  final String audioData; // Base64-encoded audio data
  CreateSpeechToTextEvent(this.audioData);
}

class StartRecording extends SpeechToTextEvent {}

class StopRecording extends SpeechToTextEvent {}

class StartTapRecording extends SpeechToTextEvent {}

class StopTapRecording extends SpeechToTextEvent {}

class StartListeningEvent extends SpeechToTextEvent {}

class NewTranscriptionEvent extends SpeechToTextEvent {
  final String text;

  NewTranscriptionEvent(this.text);

  @override
  List<Object> get props => [text];
}
