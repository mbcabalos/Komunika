import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komunika/screens/text_to_speech_screen/tts_page.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/widgets/app_bar.dart';
import 'package:komunika/widgets/text_to_speech_widgets/tts_card.dart';
import 'package:komunika/widgets/text_to_speech_widgets/tts_card.dart';
import 'package:path_provider/path_provider.dart'; // Import your custom card widget (if used)

class VoiceMessagePage extends StatefulWidget {
  const VoiceMessagePage({super.key});

  @override
  State<VoiceMessagePage> createState() => _VoiceMessagePageState();
}

class _VoiceMessagePageState extends State<VoiceMessagePage> {
  // List to store the fetched audioPaths
  List<Map<String, dynamic>> audioItems = [];

  // Fetch audio paths from the database
  Future<void> fetchAudioPaths() async {
    List<Map<String, dynamic>> data = await DatabaseHelper()
        .fetchAudioItems(); // Assuming this fetches all items
    setState(() {
      audioItems = data; // Store the fetched data in the state
    });
  }

  Future<void> playAudio(String path) async {
    final directory = await getExternalStorageDirectory();
    final downloadDir = Directory('${directory?.parent.path}/files/audio');
    final filePath = '${downloadDir.path}/$path.mp3';
    final player = AudioPlayer();
    await player.setFilePath(filePath); // Set file path (local file or URL)
    await player.play(); // Play the audio
  }

  @override
  void initState() {
    super.initState();
    fetchAudioPaths();
  }

  @override
  Widget build(BuildContext context) {
    final double phoneHeight = MediaQuery.of(context).size.height * 0.8;
    final double phoneWidth = MediaQuery.of(context).size.width * 0.9;
    return Scaffold(
      backgroundColor: ColorsPalette.background,
      appBar: const AppBarWidget(
          title: "Text to Speech",
          titleSize: 20,
          isBackButton: false,
          isSettingButton: false),
      body: Center(
        child: Column(
          children: [
            Container(
              height: phoneHeight,
              margin: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Display the fetched audio items in a ListView
                  Expanded(
                    child: ListView.builder(
                      itemCount: audioItems.length,
                      itemBuilder: (context, index) {
                        final audioPath = audioItems[index]['audioPath'];
                        return GestureDetector(
                          onTap: () {
                            playAudio(audioPath);
                          },
                          child: TTSCard(
                            text: audioPath,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsPalette.buttonPrimary,
                minimumSize: Size(phoneWidth, 50),
              ),
              onPressed: () async {
                print("pop");
                final bool isSaved = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TextToSpeechScreen(),
                  ),
                );

                // Check if the returned value is true
                if (isSaved) {
                  // After the navigation, refresh the audio list
                  fetchAudioPaths(); // Re-fetch audio items after returning
                }
              },
              child: const Text(
                "Add New Speech",
                style: TextStyle(fontSize: 20, color: ColorsPalette.black),
              ),
            )
          ],
        ),
      ),
    );
  }
}
