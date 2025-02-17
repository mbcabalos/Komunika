import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_speech_to_text/speech_to_text_bloc.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class SpeechToTextPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  final SpeechToTextBloc speechToTextBloc;
  const SpeechToTextPage(
      {super.key, required this.themeProvider, required this.speechToTextBloc});

  @override
  State<SpeechToTextPage> createState() => SpeechToTextPageState();
}

class SpeechToTextPageState extends State<SpeechToTextPage> {
  final TextEditingController _textController = TextEditingController();
  GlobalKey _microphoneKey = GlobalKey();
  GlobalKey _textFieldKey = GlobalKey();
  GlobalKey _saveKey = GlobalKey();
  GlobalKey _plusKey = GlobalKey();
  bool _isShowcaseSeen = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  Future<void> _initialize() async {
    widget.speechToTextBloc.add(SpeechToTextLoadingEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.speechToTextBloc,
      child: Scaffold(
        backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
        appBar: AppBarWidget(
          title: context.translate("stt_title"),
          titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          isBackButton: true,
          isSettingButton: false,
        ),
        body: BlocConsumer<SpeechToTextBloc, SpeechToTextState>(
          listener: (context, state) {
            if (state is SpeechToTextErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is SpeechToTextLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SpeechToTextLoadedSuccessState) {
              return _buildContent(widget.themeProvider);
            } else if (state is SpeechToTextErrorState) {
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
    final double phoneHeight =
        MediaQuery.of(context).size.height * 0.6; // Increased height
    final double phoneWidth = MediaQuery.of(context).size.width * 0.9;
    return RefreshIndicator.adaptive(
      onRefresh: _initialize,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                SizedBox(
                  width: phoneWidth,
                  height: phoneHeight,
                  child: BlocBuilder<SpeechToTextBloc, SpeechToTextState>(
                    builder: (context, state) {
                      if (state is TranscriptionUpdated) {
                        _textController.text += state.text;
                        _textController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _textController.text.length));
                      }
                      return Showcase(
                        key: _textFieldKey,
                        description: "See translated message here",
                        child: Card(
                          elevation: 1, // Adds shadow effect
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12), // Rounded corners
                          ),
                          color: themeProvider.themeData.cardColor,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: TextField(
                              readOnly: true,
                              controller: _textController,
                              style: TextStyle(
                                color: themeProvider
                                    .themeData.textTheme.bodyMedium?.color,
                                fontSize: 20,
                              ),
                              decoration: InputDecoration(
                                hintText: context.translate("stt_hint"),
                                border: InputBorder.none,
                                fillColor: Colors.transparent,
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 16),
                              ),
                              textAlignVertical: TextAlignVertical.center,
                              maxLines: null, // Allows for infinite lines
                              keyboardType: TextInputType.multiline,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Showcase(
                      key: _plusKey,
                      description: "Add new entry",
                      child: GestureDetector(
                        onTap: () {
                          print("clicked");
                          _textController.clear();
                        },
                        child: Container(
                          width: ResponsiveUtils.getResponsiveSize(context, 35),
                          height:
                              ResponsiveUtils.getResponsiveSize(context, 35),
                          decoration: const BoxDecoration(
                            shape: BoxShape.rectangle,
                            image: DecorationImage(
                              image: AssetImage('assets/icons/plus.png'),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Showcase(
                      key: _microphoneKey,
                      description: "Tap and hold to start recording",
                      child: GestureDetector(
                        onTap: () async {
                          if (!_isRecording) {
                            setState(() {
                              _isRecording = true;
                            });
                            widget.speechToTextBloc.add(StartTapRecording());
                          } else {
                            setState(() {
                              _isRecording = false;
                            });
                            widget.speechToTextBloc.add(StopTapRecording());
                          }
                        },
                        onLongPress: () async {
                          setState(() {
                            _isRecording = true;
                          });
                          widget.speechToTextBloc.add(StartRecording());
                        },
                        onLongPressUp: () async {
                          setState(() {
                            _isRecording = false;
                          });
                          widget.speechToTextBloc.add(StopRecording());
                        },
                        child: Container(
                          width: ResponsiveUtils.getResponsiveSize(context, 80),
                          height:
                              ResponsiveUtils.getResponsiveSize(context, 80),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeProvider.themeData.primaryColor,
                          ),
                          child: _isRecording
                              ? const Icon(
                                  Icons.graphic_eq_rounded,
                                  color: Colors.white,
                                  size: 60,
                                )
                              : const Icon(
                                  Icons.mic,
                                  color: Colors.white,
                                  size: 60,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Showcase(
                      key: _saveKey,
                      description: "Save transcription",
                      child: GestureDetector(
                        onTap: () async {
                          final SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          await prefs.setBool('pageOneDone', true);
                        },
                        child: Container(
                          width: ResponsiveUtils.getResponsiveSize(context, 40),
                          height:
                              ResponsiveUtils.getResponsiveSize(context, 40),
                          decoration: const BoxDecoration(
                            shape: BoxShape.rectangle,
                            image: DecorationImage(
                              image: AssetImage('assets/icons/saved.png'),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  context.translate("stt_hold_microphone"),
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 15),
                    fontFamily: Fonts.main,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
