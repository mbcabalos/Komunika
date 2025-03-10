import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';

class CameraService {
  static final CameraService _singleton = CameraService._internal();
  final socketService = SocketService();

  factory CameraService() {
    return _singleton;
  }

  CameraService._internal();
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;

  CameraController? get cameraController => _cameraController;

  Future<void> initializeCamera() async {
    // Initialize camera only once
    if (_cameraController == null) {
      try {
        _cameras = await availableCameras();
        if (_cameras.isEmpty) {
          throw Exception("No cameras found");
        }

        final camera = _cameras[_currentCameraIndex];
        _cameraController = CameraController(camera, ResolutionPreset.low);
        await _cameraController!.initialize();
      } catch (e) {
        print("Failed to initialize camera: $e");
      }
    }
  }

  Future<void> startImageStream() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    int frameCount = 0;

    _cameraController!.startImageStream((CameraImage image) async {
      frameCount++;

      if (frameCount % 30 == 0) {
        final frame = await _convertCameraImageToBytes(image);
        if (frame != null) {
          // Send frame through socket
          socketService.sendFrame(frame);
        }
      }
    });
  }

  Future<Uint8List?> _convertCameraImageToBytes(CameraImage image) async {
    try {
      final img = _convertYUV420toImage(image);
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

  Future<void> stopImageStream() async {
    if (_cameraController != null) {
      await _cameraController!.stopImageStream();
    }
  }

  Future<void> dispose() async {
    await _cameraController?.dispose();
    _cameraController = null;
  }
}
