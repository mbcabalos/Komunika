import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:permission_handler/permission_handler.dart';
part 'auto_caption_event.dart';
part 'auto_caption_state.dart';

class AutoCaptionBloc extends Bloc<AutoCaptionEvent, AutoCaptionState> {
  bool isInitialized = false;
  static const platform = MethodChannel('com.example.komunika/recorder');

  final socketService = SocketService();
  final dbHelper = DatabaseHelper();
  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>.broadcast();
  String capturedText = "";

  AutoCaptionBloc() : super(AutoCaptionLoadingState()) {
    on<AutoCaptionLoadingEvent>(autoCaptionLoadingEvent);
    on<RequestPermissionEvent>(requestPermissionEvent);
    on<ToggleAutoCaptionEvent>(toggleAutoCaptionEvent);
    on<StartAutoCaptionEvent>(startAudioCaptionEvent);
    on<StopAutoCaptionEvent>(stopAutoCaptionEvent);

    void emitTextToFloatingWindow(String text) {
      platform.invokeMethod('updateText', {'updatedText': text});
    }

    socketService.socket?.on("caption_result", (data) {
      if (data != null && data["text"] != null) {
        final text = data["text"] as String;
        capturedText += "$text "; // Append text to retain history
        emitTextToFloatingWindow(capturedText);
      }
    });

    platform.setMethodCallHandler((call) async {
      if (call.method == 'toggleAutoCaption') {
        bool state = call.arguments ?? false;
        add(ToggleAutoCaptionEvent(state));
      }
      if (call.method == 'onAudioData') {
        final List<int> audioData = List<int>.from(call.arguments);
        _audioStreamController.add(Uint8List.fromList(audioData));
      }
    });
  }

  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  FutureOr<void> autoCaptionLoadingEvent(
      AutoCaptionLoadingEvent event, Emitter<AutoCaptionState> emit) async {
    isInitialized = true;
    emit(AutoCaptionLoadedSuccessState(isEnabled: false));
  }

  FutureOr<void> requestPermissionEvent(
      RequestPermissionEvent event, Emitter<AutoCaptionState> emit) async {
    try {
      Future<void> requestPermission(Permission permission) async {
        var status = await permission.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          await permission.request();
        }
      }

      // Request permissions
      await requestPermission(Permission.notification);
      await requestPermission(Permission.systemAlertWindow);
    } catch (e) {
      emit(AutoCaptionErrorState(message: "$e"));
    }
  }

  Future<void> listenForAutoCaptionToggle() async {
    platform.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'toggleAutoCaption') {
        bool isEnabled = call.arguments ?? false;
        if (isEnabled) {
          add(StartAutoCaptionEvent());
        } else {
          add(StopAutoCaptionEvent());
        }
      }
    });
  }

  Future<void> toggleAutoCaptionEvent(
    ToggleAutoCaptionEvent event,
    Emitter<AutoCaptionState> emit,
  ) async {
    try {
      emit(AutoCaptionLoadedSuccessState(isEnabled: event.isEnabled));
      if (event.isEnabled) {
        add(StartAutoCaptionEvent());
      } else {
        add(StopAutoCaptionEvent());
      }
    } catch (e) {
      emit(AutoCaptionErrorState(message: '$e'));
    }
  }

  Future<void> startAudioCaptionEvent(
    StartAutoCaptionEvent event,
    Emitter<AutoCaptionState> emit,
  ) async {
    try {
      await platform.invokeMethod('startRecording');
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

  Future<void> stopAutoCaptionEvent(
    StopAutoCaptionEvent event,
    Emitter<AutoCaptionState> emit,
  ) async {
    try {
      dbHelper.saveAutoCaptionHistory(capturedText);
      await platform.invokeMethod('stopForegroundService');
      emit(AutoCaptionLoadedSuccessState(isEnabled: false));
    } on PlatformException catch (e) {
      emit(AutoCaptionErrorState(
          message: 'Failed to stop recording: ${e.message}'));
    }
  }
}
