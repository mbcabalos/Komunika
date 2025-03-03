import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_home/home_bloc.dart';
import 'package:komunika/bloc/bloc_speech_to_text/speech_to_text_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/bloc/bloc_walkthrough/walkthrough_bloc.dart';
import 'package:komunika/screens/auto_caption_screen/auto_caption_page.dart';
import 'package:komunika/screens/sign_transcribe_screen/sign_transcribe_page.dart';
import 'package:komunika/screens/speech_to_text_screen/stt_page.dart';
import 'package:komunika/screens/text_to_speech_screen/tts_page.dart';
import 'package:komunika/screens/text_to_speech_screen/voice_message_page.dart';
import 'package:komunika/services/api/global_repository_impl.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/test.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:komunika/utils/snack_bar.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';
import 'package:komunika/widgets/home_widgets/home_catalogs_card.dart';
import 'package:komunika/widgets/home_widgets/home_quick_speech_card.dart';
import 'package:komunika/widgets/home_widgets/home_tips_card.dart';
import 'package:komunika/widgets/home_widgets/home_walkthrough.dart';
import 'package:komunika/widgets/text_to_speech_widgets/tts_card.dart';
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
  late SpeechToTextBloc sttBloc;
  late TextToSpeechBloc ttsBloc;
  final socketService = SocketService();
  final globalService = GlobalRepositoryImpl();
  final databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> quickSpeechItems = [];
  String? currentlyPlaying;
  GlobalKey _speechToTextKey = GlobalKey();
  GlobalKey _textToSpeechKey = GlobalKey();
  bool _isShowcaseSeen = false;
  String theme = "";

  @override
  void initState() {
    super.initState();
    homeBloc = HomeBloc(databaseHelper);
    sttBloc = SpeechToTextBloc(socketService);
    ttsBloc = TextToSpeechBloc(globalService, databaseHelper);
    homeBloc.add(HomeLoadingEvent());
    homeBloc.add(RequestPermissionEvent());
    homeBloc.add(FetchAudioEvent());
    //PreferencesUtils.storeWalkthrough(false); //use to test walthrough
    _showWalkthrough();
  }

  void _showWalkthrough() async {
    bool isWalkthroughDone = await PreferencesUtils.getWalkthrough();
    if (!isWalkthroughDone) {
      showDialog(
        context: context,
        builder: (context) {
          return BlocProvider(
            create: (context) => WalkthroughBloc(),
            child: HomeWalkthrough(),
          );
        },
      );
    }
  }

  Future<void> _refreshScreen() async {
    print("Refreshing the screen..");
    homeBloc.add(HomeLoadingEvent());
    homeBloc.add(FetchAudioEvent());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (context) => homeBloc,
        ),
        BlocProvider<SpeechToTextBloc>(
          create: (context) => sttBloc,
        ),
        BlocProvider<TextToSpeechBloc>(
          create: (context) => ttsBloc,
        ),
      ],
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
                  showCustomSnackBar(
                      context, "Please try again", ColorsPalette.red);
                }
                if (state is AudioPlaybackCompletedState) {
                  setState(
                    () {
                      currentlyPlaying = null;
                    },
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
            ),
            floatingActionButton: FloatingActionButton(onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => GestureDetectorScreen()),
              );
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.camera),
            tooltip: "test gesture detsection",         
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
      ThemeProvider themeProvider, HomeSuccessLoadedState state) {
    quickSpeechItems = state.audioItems;
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
              height: quickSpeechItems.length <= 2
                  ? MediaQuery.of(context).size.height * 0.6
                  : null,
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
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SpeechToTextPage(
                                  themeProvider: themeProvider,
                                  speechToTextBloc: sttBloc,
                                ),
                              ),
                            );
                            _refreshScreen();
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
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TextToSpeechScreen(
                                  themeProvider: themeProvider,
                                  ttsBloc: ttsBloc,
                                ),
                              ),
                            );
                            _refreshScreen();
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
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignTranscriberPage(themeProvider: themeProvider,
                                  ),
                            ),
                          );
                        },
                        child: HomeCatalogsCard(
                          imagePath: 'assets/icons/hello.png',
                          isImagePath: true,
                          content: context.translate("home_sign_transcribe"),
                          contentSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 14),
                          themeProvider: themeProvider,
                        ),
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
                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.95,
                      padding: const EdgeInsets.only(top: 12, bottom: 24),
                      decoration: BoxDecoration(
                        color: themeProvider.themeData.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider
                                .themeData.scaffoldBackgroundColor
                                .withOpacity(0.3),
                            blurRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(
                                left: 20, right: 20, top: 8),
                            child: Text(
                              "Quick Speech",
                              style: TextStyle(
                                fontFamily: Fonts.main,
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                    context, 20),
                                fontWeight: FontWeight.w500,
                                color: themeProvider
                                    .themeData.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),

                          // Check if audioItems is empty
                          state.audioItems.isEmpty
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: Text(
                                          "No items for Quick Speech. Add one here!",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            color: themeProvider.themeData
                                                .textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  VoiceMessagePage(
                                                themeProvider: themeProvider,
                                                textToSpeechBloc: ttsBloc,
                                              ),
                                            ),
                                          );
                                          _refreshScreen();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: themeProvider
                                              .themeData.primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 12),
                                        ),
                                        child: Text(
                                          "Add",
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils
                                                .getResponsiveFontSize(
                                                    context, 16),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Flexible(
                                  child: ListView.builder(
                                    key: ValueKey(state.audioItems.length),
                                    itemCount: state.audioItems.length,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final audioPath =
                                          state.audioItems[index]['audioName'];
                                      final isPlaying =
                                          currentlyPlaying == audioPath;
                                      return GestureDetector(
                                        onTap: currentlyPlaying != null
                                            ? null
                                            : () {
                                                setState(() {
                                                  currentlyPlaying = isPlaying
                                                      ? null
                                                      : audioPath;
                                                });
                                                homeBloc.add(PlayAudioEvent(
                                                    audioName: audioPath));
                                              },
                                        child: HomeQuickSpeechCard(
                                          audioName: audioPath,
                                          onTap: currentlyPlaying != null
                                              ? null
                                              : () {
                                                  setState(() {
                                                    currentlyPlaying = isPlaying
                                                        ? null
                                                        : audioPath;
                                                  });
                                                  homeBloc.add(PlayAudioEvent(
                                                      audioName: audioPath));
                                                },
                                          onLongPress: null,
                                          themeProvider: themeProvider,
                                          isPlaying: isPlaying,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
