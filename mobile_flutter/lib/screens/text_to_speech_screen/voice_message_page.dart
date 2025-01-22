import 'package:flutter/material.dart';
import 'package:komunika/screens/text_to_speech_screen/tts_page.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/widgets/app_bar.dart';
import 'package:komunika/widgets/text_to_speech_widgets/tts_card.dart';

class VoiceMessagePage extends StatefulWidget {
  const VoiceMessagePage({super.key});

  @override
  State<VoiceMessagePage> createState() => _VoiceMessagePageState();
}

class _VoiceMessagePageState extends State<VoiceMessagePage> {
  @override
  Widget build(BuildContext context) {
    final double phoneHeight = MediaQuery.of(context).size.height * 0.8;
    final double phoneWidth = MediaQuery.of(context).size.width * 0.9;
    return Scaffold(
      backgroundColor: ColorsPalette.background,
      appBar: const AppBarWidget(
          title: "Text To Speech", isBackButton: true, isSettingButton: false),
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
                  const TTSCard(
                    text: 'Demo',
                  ),
                  const SizedBox(height: 16),
                  const TTSCard(
                    text: 'Demo',
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(phoneWidth, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TextToSpeechScreen(),
                  ),
                );
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
