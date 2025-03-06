import 'dart:async';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart'; // Image processing
import 'package:equatable/equatable.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';

part 'sign_transcriber_event.dart';
part 'sign_transcriber_state.dart';

class SignTranscriberBloc
    extends Bloc<SignTranscriberEvent, SignTranscriberState> {
  final socketService = SocketService();

  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  int currentCameraIndex = 0;
  Timer? _captureTimer;
  DateTime? lastFrameSent;

  SignTranscriberBloc() : super(SignTranscriberInitial()) {
    on<SignTranscriberLoadingEvent>(_initialize);
    on<StopTranslation>(_onStopTranslation);
  }

  Future<void> _initialize(SignTranscriberLoadingEvent event,
      Emitter<SignTranscriberState> emit) async {
    emit(SignTranscriberLoadingState());
    try {
      // Get available cameras and select the default one
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        emit(SignTranscriberErrorState(message: "No cameras found"));
        return;
      }

      final camera = cameras[currentCameraIndex];
      cameraController = CameraController(camera, ResolutionPreset.low);
      await cameraController!.initialize();

      emit(SignTranscriberLoadedState(cameraController: cameraController!));
      _startImageStream();
    } catch (e) {
      emit(SignTranscriberErrorState(
          message: "Failed to initialize the camera: $e"));
    }
  }

  Future<void> _startImageStream() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    int frameCount = 0; // Frame counter to limit how often we process

    cameraController!.startImageStream((CameraImage image) async {
      frameCount++;

      // Process only every Nth frame (for example, every 30 frames)
      if (frameCount % 30 == 0) {
        final frame = await _convertCameraImageToBytes(image);
        if (frame != null) {
          socketService.sendFrame(frame); // Send the frame via socket
        }
      }
    });
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

  void _onStopTranslation(
      StopTranslation event, Emitter<SignTranscriberState> emit) {
    _captureTimer?.cancel();
    _stopImageStream();
    close();
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
