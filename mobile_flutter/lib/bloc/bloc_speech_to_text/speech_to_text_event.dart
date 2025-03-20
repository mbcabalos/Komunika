part of 'speech_to_text_bloc.dart';

abstract class SpeechToTextEvent {}

class SpeechToTextLoadingEvent extends SpeechToTextEvent {}

class CreateSpeechToTextEvent extends SpeechToTextEvent {
  final String audioData; // Base64-encoded audio data
  CreateSpeechToTextEvent(this.audioData);
}

class RequestPermissionEvent extends SpeechToTextEvent {}

class StartRecordingEvent extends SpeechToTextEvent {}

class StopRecordingEvent extends SpeechToTextEvent {}

class StartTapRecordingEvent extends SpeechToTextEvent {}

class StopTapRecordingEvent extends SpeechToTextEvent {}

class StartListeningEventEvent extends SpeechToTextEvent {}

class NewTranscriptionEvent extends SpeechToTextEvent {
  final String text;

  NewTranscriptionEvent(this.text);

  List<Object> get props => [text];
}

class ClearTextEvent extends SpeechToTextEvent {}

class LivePreviewTranscriptionEvent extends SpeechToTextEvent {
  final String text;

  LivePreviewTranscriptionEvent(this.text);

  List<Object> get props => [text];
}
