import 'dart:convert';
import 'dart:io';

import 'package:http/io_client.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komunika/services/endpoint.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/services/repositories/global_repository.dart';
import 'package:path_provider/path_provider.dart';

class GlobalRepositoryImpl extends GlobalRepository {
  // final baseURL = "http://192.168.254.116:5000/api"; // David
  // final baseURL = "http://192.168.1.133:5000/api"; // BEnedict
  final baseURL = Endpoint.baseUrl; // BEnedict
  @override
  Future<void> sendTextToSpeech(String text, String title, bool save) async {
    try {
      // Create an HttpClient with the SSL certificate verification disabled
      final ioClient = HttpClient();
      ioClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      final client = IOClient(ioClient);

      final response = await client.post(
        Uri.parse("$baseURL/text-to-speech"),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: '{"text": "$text"}',
      );

      if (response.statusCode == 200) {
        final directory = await getExternalStorageDirectory();

        final downloadDir = Directory(
            '${directory?.parent.path}/files/audio'); // Get Download directory
        await downloadDir.create(
            recursive: true); // Create directory if it doesn't exist

        final filePath = '${downloadDir.path}/$title.mp3';
        final file = File(filePath);

        // Save the file to the Downloads folder
        await file.writeAsBytes(response.bodyBytes);
        print('Audio file saved at $filePath');

        print("$save");

        if (save == true) {
          DatabaseHelper().insertAudioItem("$title");
        } else {
          final player = AudioPlayer();
          print(filePath);
          await player.setFilePath(
              filePath); // If it's a URL, or use setFilePath(filePath) for local file
          await player.play();
          print('Playing audio: $filePath');
        }
      } else {
        print('Error: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> startLiveTranscription() async {
    try {
      // Create an HttpClient with SSL verification disabled
      final ioClient = HttpClient();
      ioClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      final client = IOClient(ioClient);

      final response = await client.post(
        Uri.parse('${baseURL}live-transcription'),
      );

      if (response.statusCode == 200) {
        print('Transcription started: ${jsonDecode(response.body)}');
      } else {
        print('Error: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
