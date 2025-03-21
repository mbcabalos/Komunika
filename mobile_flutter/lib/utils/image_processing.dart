import 'dart:typed_data';
import 'dart:isolate';
import 'package:image/image.dart' as imglib;

// Top-level function for isolate processing
void imageProcessingIsolate(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort
      .send(receivePort.sendPort); // Send the receive port to the main isolate

  receivePort.listen((data) async {
    final yPlane = data['yPlane'] as Uint8List;
    final uPlane = data['uPlane'] as Uint8List;
    final vPlane = data['vPlane'] as Uint8List;
    final width = data['width'] as int;
    final height = data['height'] as int;
    final SendPort resultSendPort = data['result'];

    try {
      // Reconstruct the image from YUV planes
      final img = await _convertYUV420toImageFast(
          yPlane, uPlane, vPlane, width, height);

      // Resize image (optional)
      final smallImg = imglib.copyResize(img, height: 256, width: 256);

      // Convert image to JPEG
      final jpeg = Uint8List.fromList(imglib.encodeJpg(smallImg, quality: 30));

      // Send the processed JPEG image data back to the main isolate
      resultSendPort.send({'frame': jpeg});
    } catch (e) {
      print("Error during image processing: $e");
      resultSendPort.send({'frame': null});
    }
  });
}

// Top-level function for YUV to RGB conversion with optimization
Future<imglib.Image> _convertYUV420toImageFast(Uint8List yPlane,
    Uint8List uPlane, Uint8List vPlane, int width, int height) async {
  final img = imglib.Image(width: width, height: height);
  final int rowStride = width;
  final int uvStride = (width / 2).toInt();

  await Future.wait([
    for (int y = 0; y < height; y++)
      Future(() {
        for (int x = 0; x < width; x++) {
          final yIndex = y * rowStride + x;
          final uvIndex = ((y ~/ 2) * uvStride + (x ~/ 2));

          final yValue = yPlane[yIndex];
          final uValue = uPlane[uvIndex];
          final vValue = vPlane[uvIndex];

          // YUV to RGB conversion
          final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
          final g =
              (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                  .clamp(0, 255)
                  .toInt();
          final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

          // Set pixel color
          img.setPixel(x, y, imglib.ColorInt8.rgb(r, g, b));
        }
      }),
  ]);

  return imglib.copyRotate(img, angle: 0);
}
