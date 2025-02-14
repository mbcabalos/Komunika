part of 'sign_transcriber_bloc.dart';

abstract class SignTranscriberState extends Equatable {
  const SignTranscriberState();

  @override
  List<Object> get props => [];
}

class SignTranscriberInitial extends SignTranscriberState {}

class CameraInitialized extends SignTranscriberState {
  final CameraController cameraController;
  const CameraInitialized(this.cameraController);

  @override
  List<Object> get props => [cameraController];
}

class CameraError extends SignTranscriberState {
  final String message;
  const CameraError(this.message);

  @override
  List<Object> get props => [message];
}

class TranscriptionInProgress extends SignTranscriberState {
  final String message;
  const TranscriptionInProgress(this.message);

  @override
  List<Object> get props => [message];
}

class TranscriptionCompleted extends SignTranscriberState {
  final String result;
  const TranscriptionCompleted(this.result);

  @override
  List<Object> get props => [result];
}
