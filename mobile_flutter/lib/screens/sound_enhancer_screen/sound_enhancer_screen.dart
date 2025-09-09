import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_sound_enhancer/sound_enhancer_bloc.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';
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
      {super.key,
      required this.soundEnhancerBloc,
      this.ttsNavKey});

  @override
  State<SoundEnhancerScreen> createState() => SoundEnhancerScreenState();
}

class SoundEnhancerScreenState extends State<SoundEnhancerScreen> {
  final TextEditingController _textController = TextEditingController();
  GlobalKey keyAmplifier = GlobalKey();
  GlobalKey keyVisualization = GlobalKey();
  GlobalKey keySpeechToText = GlobalKey();

  List<TargetFocus> targets = [];
  final dbHelper = DatabaseHelper();
  int _micMode = 0; // 0: Off, 1: On
  bool _isTranscriptionEnabled = false;

  @override
  void initState() {
    super.initState();
    _textController.clear();
    _initialize();
    // PreferencesUtils.resetWalkthrough();
    checkWalkthrough();
  }

  Future<void> _initialize() async {
    widget.soundEnhancerBloc.add(SoundEnhancerLoadingEvent());
    widget.soundEnhancerBloc.add(RequestPermissionEvent());
  }

  Future<void> checkWalkthrough() async {
    bool isDone = await PreferencesUtils.getWalkthroughDone();

    if (!isDone) {
      _initTargets();
      _showTutorial();
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
            child: Text(
              "(ENGLISH) This card shows sound visualization.\n\n(FILIPINO) Ito ay nagpapakita ng tunog.",
              style: TextStyle(color: Colors.white, fontSize: 18),
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
            align: ContentAlign.top,
            child: Text("(ENGLISH) Here you can amplify, denoisen and modify the audio balance of the audio with transcription.\n\n(FILIPINO) Dito, maaari mong palakasin, linisin, at baguhin ang balanse ng tunog ng mikropono kasama ang transkripsyon.",
              
              style: TextStyle(color: Colors.white, fontSize: 18),
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
            child: Text(
              "(ENGLISH) Tap here to proceed...\n\n(FILIPINO) Pindutin dito upang magpatuloy...",
              style: TextStyle(color: Colors.white, fontSize: 18),
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
    return RefreshIndicator.adaptive(
      onRefresh: _initialize,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(
            ResponsiveUtils.getResponsiveSize(context, 16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
              SoundVisualizationCard(
                key: keyVisualization, 
                themeProvider: themeProvider,
                isActive: _micMode == 0 ? false : true,
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
                  textController: _textController,
                  micMode: _micMode,
                  isTranscriptionEnabled: _isTranscriptionEnabled,
                  onTranscriptionToggle: (enabled) {
                    setState(() => _isTranscriptionEnabled = enabled);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
