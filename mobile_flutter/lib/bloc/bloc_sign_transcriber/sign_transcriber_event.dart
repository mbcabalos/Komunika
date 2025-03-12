part of 'sign_transcriber_bloc.dart';

abstract class SignTranscriberEvent extends Equatable {
  const SignTranscriberEvent();
  @override
  List<Object> get props => [];
}

class SignTranscriberLoadingEvent extends SignTranscriberEvent {}

class InitializeCameraEvent extends SignTranscriberEvent {}

class RequestPermissionEvent extends SignTranscriberEvent {}

class SwitchCameraEvent extends SignTranscriberEvent {}

class StartImageStreamEvent extends SignTranscriberEvent {}

class StartTranslationEvent extends SignTranscriberEvent {}

class StopTranslationEvent extends SignTranscriberEvent {}

class NewTranscriptEvent extends SignTranscriberEvent {
  final String text;

  const NewTranscriptEvent(this.text);

  @override
  List<Object> get props => [text];
}
