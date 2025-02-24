import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';

part 'auto_caption_event.dart';
part 'auto_caption_state.dart';

class AutoCaptionBloc extends Bloc<AutoCaptionEvent, AutoCaptionState> {
  static const platform = MethodChannel('com.example.komunika/recorder');
  final socketService = SocketService();

  AutoCaptionBloc() : super(AutoCaptionLoadingState()) {
    on<AutoCaptionLoadingEvent>(autoCaptionLoadingEvent);
    on<ToggleAutoCaptionEvent>(_onToggleAutoCaption);
    on<StartAutoCaption>(_startAudioCaption);
    on<StopAutoCaption>(_stopAutoCaption);
  }

  FutureOr<void> autoCaptionLoadingEvent(
      AutoCaptionLoadingEvent event, Emitter<AutoCaptionState> emit) async {
    emit(AutoCaptionLoadedSuccessState(isEnabled: false));
  }

  Future<void> _onToggleAutoCaption(
    ToggleAutoCaptionEvent event,
    Emitter<AutoCaptionState> emit,
  ) async {
    try {
      emit(AutoCaptionLoadedSuccessState(isEnabled: event.isEnabled));
      if (event.isEnabled) {
        add(StartAutoCaption());
      } else {
        add(StopAutoCaption());
      }
    } catch (e) {
      emit(AutoCaptionErrorState(message: '${e}'));
    }
  }

  Future<void> _startAudioCaption(
    StartAutoCaption event,
    Emitter<AutoCaptionState> emit,
  ) async {
    try {
      await platform.invokeMethod('startForegroundService');
      await platform.invokeMethod('startRecording');
      emit(AutoCaptionLoadedSuccessState(isEnabled: true));
    } on PlatformException catch (e) {
      emit(AutoCaptionErrorState(
          message: 'Failed to start recording: ${e.message}'));
    }
  }

  Future<void> _stopAutoCaption(
    StopAutoCaption event,
    Emitter<AutoCaptionState> emit,
  ) async {
    try {
      // Stop recording
      await platform.invokeMethod('stopRecording');

      // Stop the foreground service
      await platform.invokeMethod('stopForegroundService');
      emit(AutoCaptionLoadedSuccessState(isEnabled: false));
    } on PlatformException catch (e) {
      emit(AutoCaptionErrorState(
          message: 'Failed to stop recording: ${e.message}'));
    }
  }
}
