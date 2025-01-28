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
      appBar: AppBarWidget(
        title: 'Komunika',
        titleSize: getResponsiveFontSize(context, 35),
        isBackButton: false,
        isSettingButton: false,
      ),
      body: ListView(
        children: [
          // Header Section
          Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.95,
                  height: MediaQuery.of(context).size.height * 0.18,
                  child: Text(
                    "Breaking Barriers, \nConnecting \nHearts. ",
                    style: TextStyle(
                      fontFamily: Fonts.main,
                      fontSize: getResponsiveFontSize(context, 35),
                      color: ColorsPalette.white,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                HomeTipsCard(
                  content:
                      "“Ensure your phone’s microphone is not obstructed for optimal performance.”",
                  contentSize: getResponsiveFontSize(context, 20),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),

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
                          child: HomeCatalogsCard(
                            imagePath: 'assets/images/speech_to_text.png',
                            isImagePath: true,
                            content: 'Speech To Text',
                            contentSize: getResponsiveFontSize(context, 14),
                          ),
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.04),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VoiceMessagePage(),
                              ),
                            );
                          },
                          child: HomeCatalogsCard(
                            imagePath: 'assets/images/text_to_speech.png',
                            isImagePath: true,
                            content: 'Text to Speech',
                            contentSize: getResponsiveFontSize(context, 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        HomeCatalogsCard(
                          imagePath: 'assets/images/sign_transcriber.png',
                          isImagePath: true,
                          content: 'Sign Transcribe',
                          contentSize: getResponsiveFontSize(context, 14),
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.04),
                        HomeCatalogsCard(
                          imagePath: 'assets/images/on_screen_captions.png',
                          isImagePath: true,
                          content: 'Screen Captions',
                          contentSize: getResponsiveFontSize(context, 14),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                    HomeQuickSpeechCard(
                      content: ["Good Morning"],
                      contentSize: getResponsiveFontSize(context, 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double getResponsiveFontSize(BuildContext context, double size) {
    double baseWidth = 375.0; // Reference width (e.g., iPhone 11 Pro)
    double screenWidth = MediaQuery.of(context).size.width;
    return size * (screenWidth / baseWidth);
  }
}
