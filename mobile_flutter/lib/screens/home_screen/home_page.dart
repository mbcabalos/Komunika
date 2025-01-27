import 'package:flutter/material.dart';
import 'package:komunika/screens/speech_to_text_screen/stt_page.dart';
import 'package:komunika/screens/text_to_speech_screen/voice_message_page.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/widgets/app_bar.dart';
import 'package:komunika/widgets/home_widgets/home_catalogs_card.dart';
import 'package:komunika/widgets/home_widgets/home_quick_speech_card.dart';
import 'package:komunika/widgets/home_widgets/home_tips_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsPalette.accent,
      appBar: const AppBarWidget(
        title: 'Komunika',
        titleSize: 45,
        isBackButton: false,
        isSettingButton: false,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            margin: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Breaking Barriers, \nConnecting \nHearts. ",
                  style: TextStyle(
                    fontFamily: Fonts.main,
                    fontSize: 45,
                    color: ColorsPalette.white,
                  ),
                ),
                SizedBox(height: 16),
                HomeTipsCard(
                  content:
                      "“Ensure your phone’s microphone is not obstructed for optimal performance.”",
                  contentSize: 24,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Body Section with white background
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: ColorsPalette.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SpeechToTextPage(),
                              ),
                            );
                          },
                          child: const HomeCatalogsCard(
                            imagePath: 'assets/images/speech_to_text.png',
                            isImagePath: true,
                            content: 'Speech To Text',
                            contentSize: 20,
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VoiceMessagePage(),
                              ),
                            );
                          },
                          child: const HomeCatalogsCard(
                            imagePath: 'assets/images/text_to_speech.png',
                            isImagePath: true,
                            content: 'Text to Speech',
                            contentSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        HomeCatalogsCard(
                          imagePath: 'assets/images/sign_transcriber.png',
                          isImagePath: true,
                          content: 'Sign Transcribe',
                          contentSize: 20,
                        ),
                        SizedBox(width: 20),
                        HomeCatalogsCard(
                          imagePath: 'assets/images/on_screen_captions.png',
                          isImagePath: true,
                          content: 'Screen Captions',
                          contentSize: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const HomeQuickSpeechCard(content: "Hellooo", contentSize: 26)
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
