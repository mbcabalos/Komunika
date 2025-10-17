import 'dart:async';
import 'dart:typed_data';
import 'package:komunika/services/endpoint.dart';
import 'package:image/image.dart' as img; // The image package
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  String socketUrl = Endpoint.socketUrl;
  IO.Socket? socket;
  bool isSocketInitialized = false;
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  SocketService._internal();
  final _transcriptionController = StreamController<String>.broadcast();
  bool get isConnected => socket?.connected == true && isSocketInitialized;

  Future<void> initSocket() async {
    String serverUrl = socketUrl;

    if (socket != null && isSocketInitialized) {
      print("✅ Socket already initialized!");
      return;
    }

    print("🔌 Connecting to WebSocket...");

    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket?.clearListeners();
    socket?.connect();

    socket?.onConnect((_) {
      print("✅ Connected to WebSocket Server");
      isSocketInitialized = true;
    });

    socket?.on("transcription_result", (data) {
      if (data != null && data["text"] != null) {
        _transcriptionController.add(data["text"]);
      }
      else{
        print("Data is empty.");
      }
    });

    socket?.onDisconnect((_) {
      print("❌ Disconnected from WebSocket");
      isSocketInitialized = false;
    });

    socket?.onError((error) {
      print("⚠️ Socket Error: $error");
      isSocketInitialized = false;
    });
  }

  Future<void> reconnect() async {
    if (socket != null) {
      print("🔄 Attempting WebSocket Reconnect...");
      socket!.disconnect();
      await Future.delayed(Duration(seconds: 2)); 
      socket!.connect();
    }
  }

  Future<void> sendAudio(Uint8List audioChunk) async {
    if (isSocketInitialized) {
      socket?.emit('audio_stream', audioChunk);
    } else {
      print("❌ Socket is not connected yet!");
    }
  }

  Future<void> sendAudioFile(Uint8List audioChunk) async {
    if (isSocketInitialized) {
      print("Emitting socket");
      socket?.emit('audio_upload', audioChunk);
    } else {
      print("❌ Socket is not connected yet!");
    }
  }

  Future<void> sendCaptionAudio(Uint8List audioChunk) async {
    if (isSocketInitialized) {
      socket?.emit('caption_stream', audioChunk);
    } else {
      print("❌ Socket is not connected yet!");
    }
  }

  void sendFrame(Uint8List frame) {
    if (socket != null && isSocketInitialized) {
      try {
        // Decode the frame into an image object
        img.Image? image = img.decodeImage(frame);
        if (image == null) {
          print("❌ Failed to decode the image!");
          return;
        }

        Uint8List jpegBytes = Uint8List.fromList(img.encodeJpg(image));

        print("✅ Sending frame...");
        socket!.emit('frame', jpegBytes);
      } catch (e) {
        print("❌ Error while encoding image: $e");
      }
    } else {
      print("❌ Socket not connected!");
    }
  }

  void closeSocket() {
    if (socket != null && isSocketInitialized) {
      socket?.disconnect();
      print("🔌 Socket disconnected");
    }
  }
}
