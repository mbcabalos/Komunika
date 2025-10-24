import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_sound_enhancer/sound_enhancer_bloc.dart';
import 'package:komunika/screens/history_screen/history_screen.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';
import 'package:komunika/widgets/sound_enhancer_widgets/noise_meter_card.dart';
import 'package:komunika/widgets/sound_enhancer_widgets/sound_visualization_card.dart';
import 'package:komunika/widgets/sound_enhancer_widgets/sound_amplifier_card.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/sound_enhancer_widgets/speech_to_text_card.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class SoundEnhancerScreen extends StatefulWidget {
  final SoundEnhancerBloc soundEnhancerBloc;
  final GlobalKey? ttsNavKey;

  const SoundEnhancerScreen(
      {super.key, required this.soundEnhancerBloc, this.ttsNavKey});

  @override
  State<SoundEnhancerScreen> createState() => SoundEnhancerScreenState();
}

class SoundEnhancerScreenState extends State<SoundEnhancerScreen> {
  final TextEditingController _textController = TextEditingController();
  GlobalKey keyAmplifier = GlobalKey();
  GlobalKey keyVisualization = GlobalKey();
  GlobalKey keyNoisemeter = GlobalKey();
  GlobalKey keySpeechToText = GlobalKey();

  List<TargetFocus> targets = [];
  final dbHelper = DatabaseHelper();
  int _micMode = 0; // 0: Off, 1: On
  bool _isTranscriptionEnabled = false;
  String? historyMode;

  @override
  void initState() {
    super.initState();
    _textController.clear();
    _initialize();
    PreferencesUtils.resetWalkthrough();
    checkWalkthrough();
  }

  Future<void> _initialize() async {
    historyMode = await PreferencesUtils.getSTTHistoryMode();
    widget.soundEnhancerBloc.add(SoundEnhancerLoadingEvent());
    widget.soundEnhancerBloc.add(RequestPermissionEvent());
    
    print(  "History Mode: $historyMode");
  }

  Future<void> checkWalkthrough() async {
    bool isDone = await PreferencesUtils.getWalkthroughDone();

    if (!isDone) {
      _initTargets();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTutorial();
      });
    }
  }

  void _initTargets() {
    targets = [
      TargetFocus(
        identify: "Visualization",
        keyTarget: keyVisualization,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "(ENGLISH) This card shows sound visualization.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 16),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
                Text(
                  "(FILIPINO) Ito ay nagpapakita ng tunog.",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 16)),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Noise Meter",
        keyTarget: keyNoisemeter,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "(ENGLISH) This card shows the noise level.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 16),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
                Text(
                  "(FILIPINO) Ito ay nagpapakita ng antas ng ingay.",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 16)),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Amplifier",
        keyTarget: keyAmplifier,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "(ENGLISH) Here you can amplify, denoise and modify the audio balance of the audio with transcription.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 16),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
                Text(
                  "(FILIPINO) Dito, maaari mong palakasin, linisan, at baguhin ang balanse ng tunog ng mikropono kasama ang transkripsyon.",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 16)),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "goToTts",
        keyTarget: widget.ttsNavKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        enableTargetTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "(ENGLISH) Tap here to proceed...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 16),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
                Text(
                  "(FILIPINO) Pindutin dito upang magpatuloy...",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  void _showTutorial() {
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      textSkip: "SKIP",
      paddingFocus: 8,
      alignSkip: Alignment.bottomLeft,
      onSkip: () {
        PreferencesUtils.storeWalkthroughDone(true);
        return true;
      },
    ).show(context: context);
  }

  void refresh() {
    if (mounted) {
      setState(() {
        _initialize();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return BlocProvider.value(
      value: widget.soundEnhancerBloc,
      child: Scaffold(
        backgroundColor: themeProvider.themeData.scaffoldBackgroundColor,
        appBar: AppBarWidget(
          title: context.translate("sound_enhancer_title"),
          titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          themeProvider: themeProvider,
          isBackButton: false,
          customAction: IconButton(
            icon: Icon(
              Icons.history_rounded,
              color: themeProvider.themeData.textTheme.bodyLarge?.color,
            ),
            tooltip: context.translate("history_title"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(
                    themeProvider: themeProvider,
                    database: 'stt_history.db',
                  ),
                ),
              );
            },
          ),
        ),
        body: BlocConsumer<SoundEnhancerBloc, SoundEnhancerState>(
          listener: (context, state) {
            if (state is SoundEnhancerErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is SoundEnhancerLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SoundEnhancerLoadedSuccessState) {
              return _buildContent(themeProvider);
            } else if (state is SoundEnhancerErrorState) {
              return const Text('Error processing text to speech!');
            } else {
              return _buildContent(themeProvider);
            }
          },
        ),
      ),
    );
  }

  Widget _buildContent(ThemeProvider themeProvider) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.getResponsiveSize(context, 8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
            BlocBuilder<SoundEnhancerBloc, SoundEnhancerState>(
              builder: (context, state) {
                List<double> bars = List.filled(20, 0.2);
                double db = 90;
                bool isActive = false;

                if (state is SoundEnhancerSpectrumState) {
                  bars = state.spectrum;
                  db = state.decibel;
                  isActive = true;
                  print("DB from state: $db");
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sound bars visualizer
                    SoundVisualizationCard(
                      key: keyVisualization,
                      themeProvider: themeProvider,
                      isActive: isActive,
                      barHeights: bars,
                    ),

                    SizedBox(
                        height: ResponsiveUtils.getResponsiveSize(context, 16)),

                    // Noise meterR
                    NoiseMeterWidget(
                      key: keyNoisemeter,
                      db: db,
                      isActive: isActive,
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 16)),
            SoundAmplifierCard(
              key: keyAmplifier,
              themeProvider: themeProvider,
              soundEnhancerBloc: widget.soundEnhancerBloc,
              micMode: _micMode,
              onMicModeChanged: (int newMode) {
                setState(() {
                  _micMode = newMode;
                });
              },
            ),
            if (_micMode != 0)
              SpeechToTextCard(
                themeProvider: themeProvider,
                soundEnhancerBloc: widget.soundEnhancerBloc,
                contentController: _textController,
                micMode: _micMode,
                historyMode: historyMode.toString(),
                isTranscriptionEnabled: _isTranscriptionEnabled,
                onTranscriptionToggle: (enabled) {
                  setState(() => _isTranscriptionEnabled = enabled);
                },
              ),
          ],
        ),
      ),
    );
  }
}
