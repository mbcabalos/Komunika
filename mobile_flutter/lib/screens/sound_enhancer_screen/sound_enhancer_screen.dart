import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_sound_enhancer/sound_enhancer_bloc.dart';
import 'package:komunika/widgets/sound_enhancer_widgets/sound_visualization_card.dart';
import 'package:komunika/widgets/sound_enhancer_widgets/sound_amplifier_card.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/history.dart';
import 'package:komunika/widgets/sound_enhancer_widgets/speech_to_text_card.dart';

class SoundEnhancerScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  final SoundEnhancerBloc soundEnhancerBloc;
  const SoundEnhancerScreen(
      {super.key,
      required this.themeProvider,
      required this.soundEnhancerBloc});

  @override
  State<SoundEnhancerScreen> createState() => SoundEnhancerScreenState();
}

class SoundEnhancerScreenState extends State<SoundEnhancerScreen> {
  final TextEditingController _textController = TextEditingController();

  final dbHelper = DatabaseHelper();
  int _micMode = 0; // 0: Off, 1: Phone Mic, 2: Headset Mic
  bool _isTranscriptionEnabled = false;

  @override
  void initState() {
    super.initState();
    _textController.clear();
    _initialize();
  }

  Future<void> _initialize() async {
    widget.soundEnhancerBloc.add(SoundEnhancerLoadingEvent());
    widget.soundEnhancerBloc.add(RequestPermissionEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.soundEnhancerBloc,
      child: Scaffold(
        backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(top: 7.0),
            child: Text(
              "Sound Enhancer",
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
              ),
            ),
          ),
          leading: Padding(
            padding: EdgeInsets.only(
              top: ResponsiveUtils.getResponsiveSize(context, 7),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: ResponsiveUtils.getResponsiveSize(context, 10),
              ),
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  dbHelper.saveSpeechToTextHistory(_textController.text);
                }
                _textController.clear();
                widget.soundEnhancerBloc.add(StopRecordingEvent());
                Navigator.pop(context);
              },
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(
                top: ResponsiveUtils.getResponsiveSize(context, 7),
                right: ResponsiveUtils.getResponsiveSize(context, 8),
              ),
              child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryPage(
                          themeProvider: widget.themeProvider,
                          database: 'stt',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history_rounded)),
            ),
          ],
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
              return _buildContent(widget.themeProvider);
            } else if (state is SoundEnhancerErrorState) {
              return const Text('Error processing text to speech!');
            } else {
              return _buildContent(widget.themeProvider);
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
                themeProvider: widget.themeProvider,
                isActive: _micMode == 0 ? false : true,
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 16)),
              SoundAmplifierScreen(
                themeProvider: themeProvider,
                soundEnhancerBloc: widget.soundEnhancerBloc,
                micMode: _micMode,
                onMicModeChanged: (int newMode) {
                  setState(() {
                    _micMode = newMode;
                  });
                },
                isTranscriptionEnabled: _isTranscriptionEnabled,
                onTranscriptionToggle: (bool value) {
                  setState(() {
                    _isTranscriptionEnabled = value;
                    debugPrint(
                      "Transcription enabled: $_isTranscriptionEnabled",
                    );
                  });
                },
              ),
              if (_micMode != 0)
                SpeechToTextCard(
                  themeProvider: themeProvider,
                  soundEnhancerBloc: widget.soundEnhancerBloc,
                  textController: _textController,
                  isTranscriptionEnabled: _isTranscriptionEnabled,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
