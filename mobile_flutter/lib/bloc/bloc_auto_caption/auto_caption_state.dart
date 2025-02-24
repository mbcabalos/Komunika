part of 'auto_caption_bloc.dart';

abstract class AutoCaptionState {}

final class AutoCaptionLoadingState extends AutoCaptionState {}

final class AutoCaptionLoadedSuccessState extends AutoCaptionState {
  final bool isEnabled;
  AutoCaptionLoadedSuccessState({required this.isEnabled});
}

final class AutoCaptionErrorState extends AutoCaptionState {
  final String message;
  AutoCaptionErrorState({required this.message});
}
