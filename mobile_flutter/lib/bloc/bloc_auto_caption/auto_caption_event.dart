part of 'auto_caption_bloc.dart';

abstract class AutoCaptionEvent {}

class AutoCaptionLoadingEvent extends AutoCaptionEvent {}

class StartAutoCaption extends AutoCaptionEvent {}

class StopAutoCaption extends AutoCaptionEvent {}

class ToggleAutoCaptionEvent extends AutoCaptionEvent {
  final bool isEnabled;
  ToggleAutoCaptionEvent(this.isEnabled);
}

