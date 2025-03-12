import 'dart:async';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart';
import 'package:equatable/equatable.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:permission_handler/permission_handler.dart';

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
  Timer? _captureTimer;
  DateTime? lastFrameSent;

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
      cameraController = CameraController(camera, ResolutionPreset.high);
      await cameraController!.initialize();

      emit(SignTranscriberLoadedState(cameraController: cameraController!));
      _startImageStream();
    } catch (e) {
      emit(SignTranscriberErrorState(
          message: "Failed to initialize the camera: $e"));
    }
  }

  FutureOr<void> requestPermissionEvent(
      RequestPermissionEvent event, Emitter<SignTranscriberState> emit) async {
    try {
      Future<void> requestPermission(Permission permission) async {
        var status = await permission.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          await permission.request();
        }
      }

      // Request permissions
      await requestPermission(Permission.camera);
    } catch (e) {
      emit(SignTranscriberErrorState(message: "$e"));
    }
  }

  Future<void> _startImageStream() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    int frameCount = 0;

    cameraController!.startImageStream((CameraImage image) async {
      frameCount++;

      if (frameCount % 30 == 0) {
        final frame = await _convertCameraImageToBytes(image);
        if (frame != null) {
          socketService.sendFrame(frame);
        }
      }
    });
  }

  Future<void> switchCameraEvent(
    SwitchCameraEvent event,
    Emitter<SignTranscriberState> emit,
  ) async {
    if (state is SignTranscriberLoadedState) {
      final currentState = state as SignTranscriberLoadedState;

      final cameras = await availableCameras();
      final currentCamera = currentState.cameraController.description;

      CameraDescription newCamera;
      if (currentCamera.lensDirection == CameraLensDirection.back) {
        newCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } else {
        newCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
        );
      }

      final newController = CameraController(
        newCamera,
        ResolutionPreset.high,
      );

      await newController.initialize();

      emit(SignTranscriberLoadedState(cameraController: newController));
    }
  }

  Future<Uint8List?> _convertCameraImageToBytes(CameraImage image) async {
    try {
      // Convert CameraImage to Image
      final img = _convertYUV420toImage(image);

      // Encode the image as JPEG (can be optimized further)
      final jpeg = encodeJpg(img);

      return Uint8List.fromList(jpeg);
    } catch (e) {
      print("Failed to convert CameraImage to bytes: $e");
      return null;
    }
  }

  Image _convertYUV420toImage(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yBuffer = image.planes[0].bytes;
    final uBuffer = image.planes[1].bytes;
    final vBuffer = image.planes[2].bytes;

    final img = Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yIndex = y * width + x;
        final uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

        final yValue = yBuffer[yIndex];
        final uValue = uBuffer[uvIndex];
        final vValue = vBuffer[uvIndex];

        final r = yValue + 1.402 * (vValue - 128);
        final g =
            yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128);
        final b = yValue + 1.772 * (uValue - 128);

        img.setPixelRgb(x, y, r.toInt(), g.toInt(), b.toInt());
      }
    }

    return img;
  }

  void stopTranslationEvent(
      StopTranslationEvent event, Emitter<SignTranscriberState> emit) {
    _captureTimer?.cancel();
    _stopImageStream();

    if (cameraController != null) {
      cameraController!.dispose();
      cameraController = null;
    }

    emit(SignTranscriberInitial());
  }

  Future<void> _stopImageStream() async {
    if (cameraController != null) {
      await cameraController!.stopImageStream();
    }
  }

  @override
  Future<void> close() async {
    await cameraController?.dispose();
    _stopImageStream();
    _captureTimer?.cancel();
    super.close();
  }
}
