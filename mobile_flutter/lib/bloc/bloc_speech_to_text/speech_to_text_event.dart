part of 'speech_to_text_bloc.dart';

abstract class SpeechToTextEvent {}

class SpeechToTextLoadingEvent extends SpeechToTextEvent {}

class CreateSpeechToTextEvent extends SpeechToTextEvent {
  final String audioData; // Base64-encoded audio data
  CreateSpeechToTextEvent(this.audioData);
}

class StartRecording extends SpeechToTextEvent {}

class StopRecording extends SpeechToTextEvent {}

class AudioDataReceived extends SpeechToTextEvent {
  final String transcript;
  AudioDataReceived(this.transcript);

  @override
  List<Object> get props => [transcript];
}
