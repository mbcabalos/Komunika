part of 'sign_transcriber_bloc.dart';

abstract class SignTranscriberState extends Equatable {
  SignTranscriberState();

  @override
  List<Object> get props => [];
}

class SignTranscriberInitial extends SignTranscriberState {}

class SignTranscriberErrorState extends SignTranscriberState {
  final String message;
  SignTranscriberErrorState({required this.message});
}

class SignTranscriberLoadingState extends SignTranscriberState {}

class SignTranscriberLoadedState extends SignTranscriberState {
  final CameraController cameraController;
  SignTranscriberLoadedState(this.cameraController);

  @override
  List<Object> get props => [cameraController];
}

class TranscriptionInProgress extends SignTranscriberState {
  final String message;
  TranscriptionInProgress(this.message);

  @override
  List<Object> get props => [message];
}

class TranscriptionCompleted extends SignTranscriberState {
  final String result;
  TranscriptionCompleted(this.result);

  @override
  List<Object> get props => [result];
}
