import 'dart:async';
import 'dart:typed_data';

import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  IO.Socket? socket;
  bool isSocketInitialized = false;
  Stream<String> get transcriptionStream => _transcriptionController.stream;

  SocketService._internal();

  final _transcriptionController = StreamController<String>.broadcast();

  Future<void> initSocket() async {
    String serverUrl = 'http://192.168.254.116:5000'; // Your Flask server

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

  Future<void> sendAudio(Uint8List audioChunk) async {
    if (isSocketInitialized) {
      socket?.emit('audio_stream', audioChunk);
    } else {
      print("❌ Socket is not connected yet!");
    }
  }

  void closeSocket() {
    if (socket != null && isSocketInitialized) {
      socket?.disconnect();
      print("🔌 Socket disconnected");
    }
  }
}
