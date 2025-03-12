part of 'auto_caption_bloc.dart';

abstract class AutoCaptionEvent {}

class AutoCaptionLoadingEvent extends AutoCaptionEvent {}

class RequestPermissionEvent extends AutoCaptionEvent {}

class StartAutoCaptionEvent extends AutoCaptionEvent {}

class StopAutoCaptionEvent extends AutoCaptionEvent {}

class ToggleAutoCaptionEvent extends AutoCaptionEvent {
  final bool isEnabled;
  ToggleAutoCaptionEvent(this.isEnabled);
}

class CaptionResultEvent extends AutoCaptionEvent {
  final String text;

  CaptionResultEvent(this.text);
}
