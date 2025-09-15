part of 'sound_enhancer_bloc.dart';

abstract class SoundEnhancerEvent {}

class SoundEnhancerLoadingEvent extends SoundEnhancerEvent {}

class CreateSoundEnhancerEvent extends SoundEnhancerEvent {
  final String audioData; // Base64-encoded audio data
  CreateSoundEnhancerEvent(this.audioData);
}

class RequestPermissionEvent extends SoundEnhancerEvent {}

class StartRecordingEvent extends SoundEnhancerEvent {}

class StopRecordingEvent extends SoundEnhancerEvent {}

class StartTranscriptionEvent extends SoundEnhancerEvent {}

class StopTranscriptionEvent extends SoundEnhancerEvent {}

class NewTranscriptionEvent extends SoundEnhancerEvent {
  final String text;

  NewTranscriptionEvent(this.text);

  List<Object> get props => [text];
}

class ClearTextEvent extends SoundEnhancerEvent {}

class LivePreviewTranscriptionEvent extends SoundEnhancerEvent {
  final String text;

  LivePreviewTranscriptionEvent(this.text);

  List<Object> get props => [text];
}

class StartNoiseSupressorEvent extends SoundEnhancerEvent {}

class StopNoiseSupressorEvent extends SoundEnhancerEvent {}

class StartAGCEvent extends SoundEnhancerEvent {}

class StopAGCEvent extends SoundEnhancerEvent {}

class SetAmplificationEvent extends SoundEnhancerEvent {
  final double gain;
  SetAmplificationEvent(this.gain);

  List<Object?> get props => [gain];
}

class SetAudioBalanceLevel extends SoundEnhancerEvent {
  final double balance;
  SetAudioBalanceLevel(this.balance);

  List<Object?> get props => [balance];
}




