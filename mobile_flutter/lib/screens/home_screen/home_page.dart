import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_home/home_bloc.dart';
import 'package:komunika/bloc/bloc_sound_enhancer/sound_enhancer_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/bloc/bloc_walkthrough/walkthrough_bloc.dart';
import 'package:komunika/screens/sound_enhancer_screen/sound_enhancer_screen.dart';
import 'package:komunika/screens/text_to_speech_screen/tts_page.dart';
import 'package:komunika/screens/text_to_speech_screen/voice_message_page.dart';
import 'package:komunika/services/api/global_repository_impl.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:komunika/services/live-service-handler/speex_denoiser.dart';
import 'package:komunika/services/repositories/database_helper.dart';
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
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeBloc homeBloc;
  late SoundEnhancerBloc soundEnhancerBloc;
  late TextToSpeechBloc textToSpeechBloc;
  final socketService = SocketService();
  final speexDenoiser = SpeexDenoiser();
  final globalService = GlobalRepositoryImpl();
  final databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> quickSpeechItems = [];
  String? currentlyPlaying;
  String theme = "";
  int homeTips = 0;
  final random = Random();

  @override
  void initState() {
    super.initState();
    homeBloc = HomeBloc(databaseHelper);
    soundEnhancerBloc = SoundEnhancerBloc(socketService, speexDenoiser);
    textToSpeechBloc = TextToSpeechBloc(globalService, databaseHelper);
    homeBloc.add(HomeLoadingEvent());
    homeBloc.add(FetchAudioEvent());
    homeBloc.add(PlayAudioEvent(audioName: "Start"));
    homeTips = random.nextInt(14) + 1;
    if (homeTips < 1 || homeTips > 14) {
      homeTips = 1;
    }
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
    homeTips = random.nextInt(14) + 1;
    print(homeTips);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (context) => homeBloc,
        ),
        BlocProvider<SoundEnhancerBloc>(
          create: (context) => soundEnhancerBloc,
        ),
        BlocProvider<TextToSpeechBloc>(
          create: (context) => textToSpeechBloc,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Scaffold(
            backgroundColor: themeProvider.themeData.primaryColor,
            appBar: AppBarWidget(
              title: context.translate("home_title"),
              titleSize: ResponsiveUtils.getResponsiveFontSize(context, 35),
              themeProvider: themeProvider,
              isBackButton: false,
              isSettingButton: true,
              isHistoryButton: false,
              database: '',
            ),
            body: BlocConsumer<HomeBloc, HomeState>(
              listener: (context, state) {
                if (state is HomeErrorState) {
                  showCustomSnackBar(
                      context, "Please try again", ColorsPalette.red);
                }
                if (state is AudioPlaybackCompletedState) {
                  currentlyPlaying = null;
                  // setState(
                  //   () {
                  //     currentlyPlaying = null;
                  //   },
                  // );
                }
              },
              builder: (context, state) {
                if (state is HomeLoadingState) {
                  return const Center(
                      child: CircularProgressIndicator(
                    color: ColorsPalette.white,
                  ));
                } else if (state is HomeSuccessLoadedState) {
                  return _buildContent(themeProvider, state);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
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
            margin: EdgeInsets.only(
              left: ResponsiveUtils.getResponsiveSize(context, 16),
              right: ResponsiveUtils.getResponsiveSize(context, 16),
              bottom: ResponsiveUtils.getResponsiveSize(context, 16),
            ),
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
                SizedBox(
                    height: ResponsiveUtils.getResponsiveSize(context, 20)),
                HomeTipsCard(
                  content: context.translate("home_tips$homeTips"),
                  contentSize:
                      ResponsiveUtils.getResponsiveFontSize(context, 15),
                  themeProvider: themeProvider,
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 10)),

          // Body Section with white background
          Container(
            height: quickSpeechItems.length <= 2
                ? MediaQuery.of(context).size.height * 0.6
                : null,
            decoration: BoxDecoration(
              color: themeProvider.themeData.scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(
                  ResponsiveUtils.getResponsiveSize(context, 30),
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getResponsiveSize(context, 16),
                vertical: ResponsiveUtils.getResponsiveSize(context, 30),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SoundEnhancerScreen(
                                themeProvider: themeProvider,
                                soundEnhancerBloc: soundEnhancerBloc,
                              ),
                            ),
                          );
                          _refreshScreen();
                        },
                        child: HomeCatalogsCard(
                          imagePath: 'assets/icons/word-of-mouth.png',
                          isImagePath: true,
                          content: context.translate("home_sound_enhancer"),
                          contentSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 14),
                          themeProvider: themeProvider,
                        ),
                      ),
                      SizedBox(
                          width:
                              ResponsiveUtils.getResponsiveSize(context, 20)),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TextToSpeechScreen(
                                themeProvider: themeProvider,
                                ttsBloc: textToSpeechBloc,
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
                    ],
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getResponsiveSize(context, 30)),
                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getResponsiveSize(context, 20),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.95,
                      padding: EdgeInsets.only(
                        top: ResponsiveUtils.getResponsiveSize(context, 12),
                        bottom: ResponsiveUtils.getResponsiveSize(context, 24),
                      ),
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
                            margin: EdgeInsets.only(
                              left: ResponsiveUtils.getResponsiveSize(
                                  context, 20),
                              right: ResponsiveUtils.getResponsiveSize(
                                  context, 20),
                              top:
                                  ResponsiveUtils.getResponsiveSize(context, 8),
                            ),
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
                                  padding: EdgeInsets.symmetric(
                                    vertical: ResponsiveUtils.getResponsiveSize(
                                        context, 20),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal:
                                              ResponsiveUtils.getResponsiveSize(
                                                  context, 20),
                                        ),
                                        child: Text(
                                          "No items for Quick Speech. Add one here!",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils
                                                .getResponsiveFontSize(
                                                    context, 16),
                                            fontWeight: FontWeight.w400,
                                            color: themeProvider.themeData
                                                .textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                          height:
                                              ResponsiveUtils.getResponsiveSize(
                                                  context, 12)),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  VoiceMessagePage(
                                                themeProvider: themeProvider,
                                                textToSpeechBloc:
                                                    textToSpeechBloc,
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
                                          padding: EdgeInsets.symmetric(
                                            horizontal: ResponsiveUtils
                                                .getResponsiveSize(context, 24),
                                            vertical: ResponsiveUtils
                                                .getResponsiveSize(context, 12),
                                          ),
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
                                                if (!isPlaying) {
                                                  homeBloc.add(PlayAudioEvent(
                                                      audioName: audioPath));
                                                  setState(() {
                                                    currentlyPlaying =
                                                        audioPath;
                                                  });
                                                }
                                              },
                                        child: HomeQuickSpeechCard(
                                          audioName: audioPath,
                                          onTap: currentlyPlaying != null
                                              ? null
                                              : () {
                                                  if (!isPlaying) {
                                                    homeBloc.add(PlayAudioEvent(
                                                        audioName: audioPath));
                                                    setState(() {
                                                      currentlyPlaying =
                                                          audioPath;
                                                    });
                                                  }
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
