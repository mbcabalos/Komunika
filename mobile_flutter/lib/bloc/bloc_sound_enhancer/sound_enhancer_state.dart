part of 'sound_enhancer_bloc.dart';

abstract class SoundEnhancerState extends Equatable {
  const SoundEnhancerState();
  @override
  List<Object?> get props => [];
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

class SoundEnhancerSpectrumState extends SoundEnhancerState {
  final List<double> spectrum;
  final double decibel;

  SoundEnhancerSpectrumState(this.spectrum, {required this.decibel});

  @override
  List<Object?> get props => [spectrum, decibel];
}
