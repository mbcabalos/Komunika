import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:komunika/widgets/app_bar.dart';
import 'package:path_provider/path_provider.dart';  // Required to get the file path in your device
import 'package:just_audio/just_audio.dart';  

class TextToSpeechScreen extends StatefulWidget {
  @override
  _TextToSpeechScreenState createState() => _TextToSpeechScreenState();
}

class _TextToSpeechScreenState extends State<TextToSpeechScreen> {
  final TextEditingController _textController = TextEditingController();

  Future<void> sendTextToSpeech(String text) async {
    try {
      // Create an HttpClient with the SSL certificate verification disabled
      final ioClient = HttpClient();
      ioClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      final client = IOClient(ioClient);

      final response = await client.post(
        // Uri.parse('https://127.0.0.1:5000/api/text-to-speech'),
        Uri.parse('https://192.168.1.133:5000/api/text-to-speech'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: '{"text": "$text"}',
      );

      if (response.statusCode == 200) {
        // final tempDir = await getTemporaryDirectory();
        // final filePath = '${tempDir.path}/output.mp3';
        // final file = File(filePath);
        final directory = await getExternalStorageDirectory();
        final downloadDir = Directory('${directory?.parent.path}/Downloads'); // Get Download directory
        await downloadDir.create(recursive: true); // Create directory if it doesn't exist

        final filePath = '${downloadDir.path}/output.mp3';
        final file = File(filePath);

        // Save the file to the Downloads folder
        await file.writeAsBytes(response.bodyBytes);
        print('Audio file saved at $filePath');

        // Play the audio after saving it
        final player = AudioPlayer();
        await player.setFilePath(filePath);
        await player.play();
      } else {
        print('Error: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'Text To Speech', isBackButton: true, isSettingButton: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(labelText: 'Enter text'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => sendTextToSpeech(_textController.text),
              child: Text('Convert to Speech'),
            ),
          ],
        ),
      ),
    );
  }
}
