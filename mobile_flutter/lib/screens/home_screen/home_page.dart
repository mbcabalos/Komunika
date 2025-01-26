import 'package:flutter/material.dart';
import 'package:komunika/screens/speech_to_text_screen/stt_page.dart';
import 'package:komunika/screens/text_to_speech_screen/voice_message_page.dart';
import 'package:komunika/widgets/app_bar.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/widgets/home_widgets/home_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsPalette.background,
      appBar: const AppBarWidget(
        title: 'Komunika',
        isBackButton: false,
        isSettingButton: false,
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  child: Text("Breaking Barriers, \n Connecting Hearts. "),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const SpeechToTextPage()));
                      },
                      child: const HomeCard(
                        imagePath: 'assets/images/speech_to_text.png',
                        text: 'Speech To Text',
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const VoiceMessagePage()));
                      },
                      child: const HomeCard(
                        imagePath: 'assets/images/text_to_speech.png',
                        text: 'Text to Speech',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    HomeCard(
                      imagePath: 'assets/images/sign_transcriber.png',
                      text: 'Sign Transcriber',
                    ),
                    SizedBox(width: 16),
                    HomeCard(
                      imagePath: 'assets/images/on_screen_captions.png',
                      text: 'Screen Captions',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
