import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:komunika/services/endpoint.dart';

class GlobalRepositoryImpl {
  final baseURL = Endpoint.baseUrl;

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
