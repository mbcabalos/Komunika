import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:komunika/bloc/externals/image_processing.dart';

part 'sign_transcriber_event.dart';
part 'sign_transcriber_state.dart';

class SignTranscriberBloc
    extends Bloc<SignTranscriberEvent, SignTranscriberState> {
  final socketService = SocketService();
  final StreamController<String> _transcriptionController =
      StreamController<String>();

  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  int currentCameraIndex = 0;
  int frameCount = 0;
  DateTime lastFrameTime = DateTime.now();
  static const int targetFPS = 15;
  static const int targetFrameDurationMs = 1000;

  SignTranscriberBloc() : super(SignTranscriberInitial()) {
    on<SignTranscriberLoadingEvent>(signTranscriberLoadingEvent);
    on<RequestPermissionEvent>(requestPermissionEvent);
    on<StopTranslationEvent>(stopTranslationEvent);
    on<SwitchCameraEvent>(switchCameraEvent);

    socketService.socket?.on("translationupdate", (data) {
      if (data != null && data["translation"] != null) {
        if (state is SignTranscriberLoadedState ||
            state is TranslationUpdatedState) {
          _transcriptionController.add(data["translation"]);
          add(NewTranscriptEvent(data["translation"]));
          print(data["translation"]);
        } else {
          print("Camera is still initializing, skipping text append.");
        }
      }
    });

    on<NewTranscriptEvent>((event, emit) {
      if (state is SignTranscriberLoadedState) {
        final currentState = state as SignTranscriberLoadedState;

        if (currentState.translationText == event.text) return;

        print("✅ Updating translation text: ${event.text}");
        emit(currentState.copyWith(translationText: event.text));
      }
    });
  }

  Future<void> signTranscriberLoadingEvent(SignTranscriberLoadingEvent event,
      Emitter<SignTranscriberState> emit) async {
    emit(SignTranscriberLoadingState());

    if (cameraController != null && cameraController!.value.isInitialized) {
      emit(SignTranscriberLoadedState(cameraController: cameraController!));
      return;
    }

    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        emit(SignTranscriberErrorState(message: "No cameras found"));
        return;
      }

      final camera = cameras[currentCameraIndex];
      cameraController = CameraController(camera, ResolutionPreset.veryHigh);
      await cameraController!.initialize();

      emit(SignTranscriberLoadedState(cameraController: cameraController!));
      _startImageStream();
    } catch (e) {
      emit(SignTranscriberErrorState(
          message: "Failed to initialize the camera: $e"));
    }
  }

  Future<void> requestPermissionEvent(
      RequestPermissionEvent event, Emitter<SignTranscriberState> emit) async {
    try {
      PermissionStatus status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        await Permission.camera.request();
      }
    } catch (e) {
      emit(SignTranscriberErrorState(message: "$e"));
    }
  }

  Future<void> switchCameraEvent(
      SwitchCameraEvent event, Emitter<SignTranscriberState> emit) async {
    _stopImageStream();

    if (state is SignTranscriberLoadedState) {
      final currentState = state as SignTranscriberLoadedState;
      final newCamera =
          await _getNewCamera(currentState.cameraController.description);
      final newController = CameraController(newCamera, ResolutionPreset.low);
      await newController.initialize();

      emit(SignTranscriberLoadedState(cameraController: newController));
      _startImageStream();
    }
  }

  Future<CameraDescription> _getNewCamera(
      CameraDescription currentCamera) async {
    final cameras = await availableCameras();
    if (currentCamera.lensDirection == CameraLensDirection.back) {
      return cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front);
    } else {
      return cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back);
    }
  }

  void _startImageStream() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    cameraController!.startImageStream((CameraImage image) async {
      final DateTime now = DateTime.now();
      final int frameDuration = now.difference(lastFrameTime).inMilliseconds;

      if (frameDuration >= targetFrameDurationMs) {
        final frame = await _convertCameraImageToBytes(image);
        if (frame != null) {
          frameCount++;
          print("Sending frame...");
          socketService.sendFrame(frame);
        } else {
          print("No frame generated.");
        }

        // Update lastFrameTime to current time after processing the frame
        lastFrameTime = now;
      } else {
        print("Skipping frame (rate-limited).");
      }
    });
  }

  Future<Uint8List?> _convertCameraImageToBytes(CameraImage image) async {
    try {
      print("Starting image conversion...");
      final frame = await processImageInIsolate(image);
      if (frame == null) {
        print("Frame conversion failed.");
        return null;
      }
      print("Frame conversion successful.");
      return frame;
    } catch (e) {
      print("Error during image conversion: $e");
      return null;
    }
  }

  Future<Uint8List?> processImageInIsolate(CameraImage image) async {
    try {
      final yPlane = image.planes[0].bytes;
      final uPlane = image.planes[1].bytes;
      final vPlane = image.planes[2].bytes;

      final receivePort = ReceivePort();
      final isolate =
          await Isolate.spawn(imageProcessingIsolate, receivePort.sendPort);
      final sendPort = await receivePort.first;
      final result = ReceivePort();
      sendPort.send({
        'yPlane': yPlane,
        'uPlane': uPlane,
        'vPlane': vPlane,
        'width': image.width,
        'height': image.height,
        'result': result.sendPort,
      });

      final response = await result.first;
      isolate.kill(priority: Isolate.immediate);
      return response['frame'];
    } catch (e) {
      print("Error in processImageInIsolate: $e");
      return null;
    }
  }

  void stopTranslationEvent(
      StopTranslationEvent event, Emitter<SignTranscriberState> emit) {
    _stopImageStream();

    cameraController?.dispose();
    cameraController = null;

    emit(SignTranscriberInitial());
  }

  Future<void> _stopImageStream() async {
    await cameraController?.stopImageStream();
  }

  @override
  Future<void> close() async {
    await cameraController?.dispose();
    _stopImageStream();
    super.close();
  }
}
