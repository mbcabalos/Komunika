part of 'sign_transcriber_bloc.dart';

abstract class SignTranscriberEvent extends Equatable {
  const SignTranscriberEvent();
  @override
  List<Object> get props => [];
}

class InitializeCamera extends SignTranscriberEvent {}

class SignTranscriberLoadingEvent extends SignTranscriberEvent {}

class SwitchCamera extends SignTranscriberEvent {}

class StartImageStream extends SignTranscriberEvent {}

class StartTranslation extends SignTranscriberEvent {}

class StopTranslation extends SignTranscriberEvent {}
