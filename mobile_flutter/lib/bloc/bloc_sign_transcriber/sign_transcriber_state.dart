part of 'sign_transcriber_bloc.dart';

abstract class SignTranscriberState extends Equatable {
  const SignTranscriberState();

  @override
  List<Object> get props => [];
}

class SignTranscriberInitial extends SignTranscriberState {}

class SignTranscriberLoadingState extends SignTranscriberState {}

class SignTranscriberLoadedState extends SignTranscriberState {
  final CameraController cameraController;
  final String translationText; 

  const SignTranscriberLoadedState({
    required this.cameraController,
    this.translationText = '',
  });

  @override
  List<Object> get props => [cameraController, translationText];

  SignTranscriberLoadedState copyWith({String? translationText}) {
    return SignTranscriberLoadedState(
      cameraController: cameraController,
      translationText: translationText ?? this.translationText,
    );
  }
}

class TranslationUpdatedState extends SignTranscriberState {
  final String text;

  const TranslationUpdatedState(this.text);
  @override
  List<Object> get props => [text];
}

class SignTranscriberErrorState extends SignTranscriberState {
  final String message;

  const SignTranscriberErrorState({required this.message});

  @override
  List<Object> get props => [message];
}
