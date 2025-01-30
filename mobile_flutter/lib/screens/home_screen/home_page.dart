import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komunika/screens/speech_to_text_screen/stt_page.dart';
import 'package:komunika/screens/text_to_speech_screen/voice_message_page.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/widgets/app_bar.dart';
import 'package:komunika/widgets/home_widgets/home_catalogs_card.dart';
import 'package:komunika/widgets/home_widgets/home_quick_speech_card.dart';
import 'package:komunika/widgets/home_widgets/home_tips_card.dart';
import 'package:path/path.dart' as p; //renamed as p to avoid conflict with showcase context eme
import 'package:path_provider/path_provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sqflite/sqflite.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> quickSpeechItems = [];
  GlobalKey _speechToTextKey = GlobalKey();
  bool _isShowcaseSeen = false;


@override
void initState() {
  super.initState();
  loadFavorites();

  if (!_isShowcaseSeen) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShowCaseWidget.of(context).startShowCase([_speechToTextKey]);
      _isShowcaseSeen = true;
    });
  }
}

  Future<void> loadFavorites() async {
    // Get the database path
    final databasePath = await getDatabasesPath();
    //final path = join(databasePath, 'audio_database.db');
    //will now use p.join
    String path = p.join(await getDatabasesPath(), 'audio_database.db');
    final database = await openDatabase(path);
    final List<Map<String, dynamic>> favorites = await database.query(
      'audio_items',
      where: 'favorites = 1',
    );
    setState(() {
      quickSpeechItems.clear();
      quickSpeechItems
          .addAll(favorites.map((item) => item['audioName'] as String));
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
                  contentSize: getResponsiveFontSize(context, 15),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
      
          // Body Section with white background
          Container(
            decoration: const BoxDecoration(
              color: ColorsPalette.background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              child: Column(
                children: [
                  Row(
                    children: [
                      Showcase(
                        key: _speechToTextKey,
                        description: "Tap here to test speech to text functionality",
                        child: GestureDetector(
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
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.04),
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
                      SizedBox(width: MediaQuery.of(context).size.width * 0.04),
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
                    content: quickSpeechItems,
                    contentSize: getResponsiveFontSize(context, 18),
                    onTap: (audioName) {
                      playAudio(audioName);
                    },
                  ),
                ],
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
