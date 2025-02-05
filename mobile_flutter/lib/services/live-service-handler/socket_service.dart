import 'dart:typed_data';

import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  IO.Socket? socket;
  bool isSocketInitialized = false;

  SocketService._internal();

  Future<void> initSocket() async {
    String serverUrl = 'http://192.168.254.116:5000'; // Your Flask server

    if (socket != null && isSocketInitialized) {
      print("✅ Socket already initialized!");
      return;
    }

    print("🔌 Connecting to WebSocket...");

    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket?.clearListeners();
    socket?.connect();

    socket?.onConnect((_) {
      print("✅ Connected to WebSocket Server");
      isSocketInitialized = true;
    });

    socket?.onDisconnect((_) {
      print("❌ Disconnected from WebSocket");
      isSocketInitialized = false;
    });

    socket?.onError((error) {
      print("⚠️ Socket Error: $error");
      isSocketInitialized = false;
    });

    socket?.on('transcription_data', (data) {
      if (data['text'] != null) {
        print("📝 Transcription: ${data['text']}");
      } else if (data['error'] != null) {
        print("❌ Transcription Error: ${data['error']}");
      }
    });
  }

  Future<void> sendAudio(Uint8List audioChunk) async {
    if (isSocketInitialized) {
      print("🎤 Sending audio stream...");
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
