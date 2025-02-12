import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:komunika/screens/auto_caption_screen/auto_caption_page.dart';
import 'package:komunika/screens/speech_to_text_screen/stt_page.dart';
import 'package:komunika/screens/text_to_speech_screen/voice_message_page.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/app_bar.dart';
import 'package:komunika/widgets/home_widgets/home_catalogs_card.dart';
import 'package:komunika/widgets/home_widgets/home_quick_speech_card.dart';
import 'package:komunika/widgets/home_widgets/home_tips_card.dart';
import 'package:path/path.dart'
    as p; //renamed as p to avoid conflict with showcase context eme
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
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
  GlobalKey _textToSpeechKey = GlobalKey();
  bool _isShowcaseSeen = false;
  String theme = "";

  @override
  void initState() {
    super.initState();
    // loadTheme();
    requestPermissions();
    loadFavorites();
    PreferencesUtils.resetShowcaseFlags();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShowCaseWidget.of(context).startShowCase([_speechToTextKey]);
    });
  }

  Future<void> loadFavorites() async {
    // Get the database path
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

  Future<void> requestPermissions() async {
    var status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      print("Microphone permission is required!");
      // Optionally, guide the user to the app settings to enable it
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.themeData.primaryColor,
          appBar: AppBarWidget(
            title: context.translate("home_title"),
            titleSize: ResponsiveUtils.getResponsiveFontSize(context, 35),
            isBackButton: false,
            isSettingButton: true,
          ),
          body: ListView(
            children: [
              // Header Section
              Container(
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.95,
                      height: MediaQuery.of(context).size.height * 0.15,
                      child: Text(
                        context.translate("home_header"),
                        style: TextStyle(
                          fontFamily: Fonts.main,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 30),
                          color: themeProvider
                              .themeData.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    HomeTipsCard(
                      content: context.translate("home_tips"),
                      contentSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 15),
                      themeProvider: themeProvider,
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // Body Section with white background
              Container(
                decoration: BoxDecoration(
                  color: themeProvider.themeData.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
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
                          Showcase(
                            key: _speechToTextKey,
                            description: context
                                .translate("home_speech_to_text_description"),
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SpeechToTextPage(
                                            themeProvider: themeProvider,
                                          )),
                                );
                                if (result == "speechToTextCompleted") {
                                  print("Speech to Text process completed!");
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    ShowCaseWidget.of(context)
                                        .startShowCase([_textToSpeechKey]);
                                  });
                                }
                              },
                              child: HomeCatalogsCard(
                                imagePath: 'assets/icons/word-of-mouth.png',
                                isImagePath: true,
                                content:
                                    context.translate("home_speech_to_text"),
                                contentSize:
                                    ResponsiveUtils.getResponsiveFontSize(
                                        context, 14),
                                themeProvider: themeProvider,
                              ),
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.04),
                          Showcase(
                            key: _textToSpeechKey,
                            description: context
                                .translate("home_text_to_speech_description"),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VoiceMessagePage(
                                      themeProvider: themeProvider,
                                    ),
                                  ),
                                );
                              },
                              child: HomeCatalogsCard(
                                imagePath: 'assets/icons/text-to-speech.png',
                                isImagePath: true,
                                content:
                                    context.translate("home_text_to_speech"),
                                contentSize:
                                    ResponsiveUtils.getResponsiveFontSize(
                                        context, 14),
                                themeProvider: themeProvider,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          HomeCatalogsCard(
                            imagePath: 'assets/icons/hello.png',
                            isImagePath: true,
                            content: context.translate("home_sign_transcribe"),
                            contentSize: ResponsiveUtils.getResponsiveFontSize(
                                context, 14),
                            themeProvider: themeProvider,
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.04),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AutoCaptionScreen(
                                          themeProvider: themeProvider)));
                            },
                            child: HomeCatalogsCard(
                              imagePath: 'assets/icons/transcription.png',
                              isImagePath: true,
                              content:
                                  context.translate("home_screen_captions"),
                              contentSize:
                                  ResponsiveUtils.getResponsiveFontSize(
                                      context, 14),
                              themeProvider: themeProvider,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.04),
                      HomeQuickSpeechCard(
                        content: quickSpeechItems,
                        contentSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 18),
                        onTap: (audioName) {
                          playAudio(audioName);
                        },
                        themeProvider: themeProvider,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.04),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
