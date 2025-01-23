part of 'speech_to_text_bloc.dart';

@immutable
sealed class SpeechToTextState {}

final class SpeechToTextLoadingState extends SpeechToTextState {}

final class SpeechToTextLoadedSuccessState extends SpeechToTextState {}

final class SpeechToTextErrorState extends SpeechToTextState {
  final String message;

  SpeechToTextErrorState({required this.message});
}
