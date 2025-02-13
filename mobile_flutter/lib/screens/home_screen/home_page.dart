import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_home/home_bloc.dart';
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
  late HomeBloc homeBloc;
  List<String> quickSpeechItems = [];
  GlobalKey _speechToTextKey = GlobalKey();
  GlobalKey _textToSpeechKey = GlobalKey();
  bool _isShowcaseSeen = false;
  String theme = "";

  @override
  void initState() {
    super.initState();
    homeBloc = HomeBloc();
    homeBloc.add(HomeLoadingEvent());
    homeBloc.add(FetchAudioEvent());
    // loadTheme();
    requestPermissions();
    loadFavorites();
    PreferencesUtils.resetShowcaseFlags();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShowCaseWidget.of(context).startShowCase([_speechToTextKey]);
    });
  }

  Future<void> _refreshScreen() async {
    setState(() {
      print("Refreshing the screen..");
      homeBloc.add(HomeLoadingEvent());
      homeBloc.add(FetchAudioEvent());
    }); // This triggers a rebuild
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
    return BlocProvider<HomeBloc>(
      create: (context) => homeBloc,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Scaffold(
              backgroundColor: themeProvider.themeData.primaryColor,
              appBar: AppBarWidget(
                title: context.translate("home_title"),
                titleSize: ResponsiveUtils.getResponsiveFontSize(context, 35),
                isBackButton: false,
                isSettingButton: true,
              ),
              body: BlocConsumer<HomeBloc, HomeState>(
                listener: (context, state) {
                  if (state is HomeErrorState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is HomeLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is HomeSuccessLoadedState) {
                    return _buildContent(themeProvider, state);
                  } else {
                    return Center(child: Text(context.translate("home_error")));
                  }
                },
              ));
        },
      ),
    );
  }

  Widget _buildContent(
      ThemeProvider themeProvider, HomeSuccessLoadedState state) {
    quickSpeechItems = state.audioItems
        .map<String>((item) => item["audioName"] as String) // Extract names
        .toList();
    return RefreshIndicator(
      onRefresh: () => _refreshScreen(),
      child: ListView(
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
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 30),
                      color: themeProvider.themeData.textTheme.bodySmall?.color,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
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
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ShowCaseWidget.of(context)
                                    .startShowCase([_textToSpeechKey]);
                              });
                            }
                          },
                          child: HomeCatalogsCard(
                            imagePath: 'assets/icons/word-of-mouth.png',
                            isImagePath: true,
                            content: context.translate("home_speech_to_text"),
                            contentSize: ResponsiveUtils.getResponsiveFontSize(
                                context, 14),
                            themeProvider: themeProvider,
                          ),
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.04),
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
                            content: context.translate("home_text_to_speech"),
                            contentSize: ResponsiveUtils.getResponsiveFontSize(
                                context, 14),
                            themeProvider: themeProvider,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      HomeCatalogsCard(
                        imagePath: 'assets/icons/hello.png',
                        isImagePath: true,
                        content: context.translate("home_sign_transcribe"),
                        contentSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 14),
                        themeProvider: themeProvider,
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.04),
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
                          content: context.translate("home_screen_captions"),
                          contentSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 14),
                          themeProvider: themeProvider,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  HomeQuickSpeechCard(
                    content: quickSpeechItems,
                    contentSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 18),
                    onTap: (audioName) {
                      homeBloc.add(PlayAudioEvent(audioName: audioName));
                    },
                    themeProvider: themeProvider,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
