part of 'sound_enhancer_bloc.dart';

abstract class SoundEnhancerState extends Equatable {
  @override
  List<Object> get props => [];
}

final class SoundEnhancerLoadingState extends SoundEnhancerState {}

final class SoundEnhancerLoadedSuccessState extends SoundEnhancerState {}

class SpeechRecordingState extends SoundEnhancerState {}

class SpeechStoppedState extends SoundEnhancerState {}

class TranscriptionUpdatedState extends SoundEnhancerState {
  final String text;

  TranscriptionUpdatedState(this.text);

  @override
  List<Object> get props => [text];
}

class LivePreviewTranscriptionState extends SoundEnhancerState {
  final String text;

  LivePreviewTranscriptionState(this.text);

  @override
  List<Object> get props => [text];
}

class SoundEnhancerErrorState extends SoundEnhancerState {
  final String message;

  SoundEnhancerErrorState({required this.message});
}
