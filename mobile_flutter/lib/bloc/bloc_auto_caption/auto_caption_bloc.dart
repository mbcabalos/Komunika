import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
part 'auto_caption_event.dart';
part 'auto_caption_state.dart';

class AutoCaptionBloc extends Bloc<AutoCaptionEvent, AutoCaptionState> {
  static const platform = MethodChannel('com.example.komunika/recorder');

  final socketService = SocketService();

  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>.broadcast();

  AutoCaptionBloc() : super(AutoCaptionLoadingState()) {
    on<AutoCaptionLoadingEvent>(autoCaptionLoadingEvent);
    on<ToggleAutoCaptionEvent>(_onToggleAutoCaption);
    on<StartAutoCaption>(_startAudioCaption);
    on<StopAutoCaption>(_stopAutoCaption);

    void emitTextToFloatingWindow(String text) {
      platform.invokeMethod('updateText', {'updatedText': text});
    }

    socketService.socket?.on("caption_result", (data) {
      if (data != null && data["text"] != null) {
        final text = data["text"] as String;
        // Trigger an event to BLoC
        emitTextToFloatingWindow(text);
      }
    });

    platform.setMethodCallHandler((call) async {
      if (call.method == 'onAudioData') {
        final List<int> audioData = List<int>.from(call.arguments);
        _audioStreamController.add(Uint8List.fromList(audioData));
      }
    });
  }

  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  FutureOr<void> autoCaptionLoadingEvent(
      AutoCaptionLoadingEvent event, Emitter<AutoCaptionState> emit) async {
    emit(AutoCaptionLoadedSuccessState(isEnabled: false));
  }

  Future<void> listenForAutoCaptionToggle() async {
    platform.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'toggleAutoCaption') {
        bool isEnabled = call.arguments ?? false;
        // Trigger the auto-caption toggle event
        if (isEnabled) {
          add(StartAutoCaption());
        } else {
          add(StopAutoCaption());
        }
      }
    });
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
      // await platform.invokeMethod('startRecording');
      emit(AutoCaptionLoadedSuccessState(isEnabled: true));

      audioStream.listen((audioData) {
        socketService.sendCaptionAudio(audioData);
      });
    } on PlatformException catch (e) {
      emit(AutoCaptionErrorState(
          message: 'Failed to start recording: ${e.message}'));
    }
  }

  Future<void> _stopAutoCaption(
    StopAutoCaption event,
    Emitter<AutoCaptionState> emit,
  ) async {
    print("called");

    try {
      await platform.invokeMethod('stopForegroundService');
      emit(AutoCaptionLoadedSuccessState(isEnabled: false));
      print("called");
    } on PlatformException catch (e) {
      emit(AutoCaptionErrorState(
          message: 'Failed to stop recording: ${e.message}'));
    }
  }
}
