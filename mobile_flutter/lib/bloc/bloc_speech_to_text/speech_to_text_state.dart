part of 'speech_to_text_bloc.dart';

abstract class SpeechToTextState extends Equatable {
  @override
  List<Object> get props => [];
}

final class SpeechToTextLoadingState extends SpeechToTextState {}

final class SpeechToTextLoadedSuccessState extends SpeechToTextState {}

final class SpeechToTextErrorState extends SpeechToTextState {
  final String message;

  SpeechToTextErrorState({required this.message});
}

class SpeechInitial extends SpeechToTextState {}

class SpeechRecording extends SpeechToTextState {}

class SpeechStopped extends SpeechToTextState {}

class SpeechTranscribed extends SpeechToTextState {
  final String text;
  SpeechTranscribed(this.text);

  @override
  List<Object> get props => [text];
}
