import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/screens/text_to_speech_screen/voice_message_page.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:komunika/utils/snack_bar.dart';
import 'package:komunika/utils/themes.dart';

class TextToSpeechScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  final TextToSpeechBloc ttsBloc;
  const TextToSpeechScreen({
    super.key,
    required this.themeProvider,
    required this.ttsBloc,
  });

  @override
  State<TextToSpeechScreen> createState() => _TextToSpeechScreenState();
}

class _TextToSpeechScreenState extends State<TextToSpeechScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  Map<String, String> ttsSettings = {};
  bool _isMaleVoice = false;
  String selectedLangauge = '';
  String selectedVoice = '';
  bool currentlyPlaying = false;
  bool save = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    widget.ttsBloc.add(TextToSpeechLoadingEvent());
    // Load saved TTS settings
    ttsSettings = await PreferencesUtils.getTTSSettings();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.ttsBloc,
      child: Scaffold(
        backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(top: 7.0),
            child: Text(
              context.translate("tts_title"),
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
                _textController.clear();
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
                icon: Icon(
                  _isMaleVoice ? Icons.male_rounded : Icons.female_rounded,
                  color: _isMaleVoice ? ColorsPalette.blue : ColorsPalette.red,
                  size: ResponsiveUtils.getResponsiveSize(context, 25),
                ),
                onPressed: () async {
                  setState(() {
                    _isMaleVoice = !_isMaleVoice;
                  });

                  selectedVoice = _isMaleVoice
                      ? "fil-ph-x-fie-local"
                      : "fil-ph-x-fic-local";
                  await flutterTts.setLanguage('fil-PH');
                  await flutterTts
                      .setVoice({"name": selectedVoice, "locale": "fil-PH"});
                  print("Selected Voice: $selectedVoice");
                },
              ),
            ),
          ],
        ),
        body: BlocConsumer<TextToSpeechBloc, TextToSpeechState>(
          listener: (context, state) {
            if (state is TextToSpeechErrorState) {
              showCustomSnackBar(
                  context, "Eror, Please try again", ColorsPalette.red);
            }
            if (state is AudioPlaybackCompletedState) {
              setState(() {
                currentlyPlaying = false;
              });
            }
          },
          builder: (context, state) {
            if (state is TextToSpeechLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TextToSpeechLoadedSuccessState) {
              return _buildContent(widget.themeProvider);
            } else if (state is TextToSpeechErrorState) {
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
    final double phoneHeight = MediaQuery.of(context).size.height * 0.7;
    final double phoneWidth = MediaQuery.of(context).size.width * 1.0;
    return RefreshIndicator.adaptive(
      onRefresh: _initialize,
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.getResponsiveSize(context, 16),
        ),
        child: ListView(
          children: [
            SizedBox(
              width: phoneWidth,
              height: phoneHeight,
              child: Column(
                children: [
                  // Title TextField with Shadow
                  Container(
                    decoration: BoxDecoration(
                      color: themeProvider.themeData.cardColor,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getResponsiveSize(context, 12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _titleController,
                      style: TextStyle(
                        color:
                            themeProvider.themeData.textTheme.bodyMedium?.color,
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 20),
                      ),
                      decoration: InputDecoration(
                        hintText: context.translate("tts_hint1"),
                        border: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal:
                              ResponsiveUtils.getResponsiveSize(context, 12),
                          vertical:
                              ResponsiveUtils.getResponsiveSize(context, 16),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getResponsiveSize(context, 10)),
                  // Main TextField with Shadow and Clear Button
                  Container(
                    decoration: BoxDecoration(
                      color: themeProvider.themeData.cardColor,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getResponsiveSize(context, 12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        TextField(
                          readOnly: false,
                          controller: _textController,
                          style: TextStyle(
                            color: themeProvider
                                .themeData.textTheme.bodyMedium?.color,
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context, 20),
                          ),
                          decoration: InputDecoration(
                            hintText: context.translate("tts_hint2"),
                            border: InputBorder.none,
                            fillColor: Colors.transparent,
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getResponsiveSize(
                                  context, 12),
                              vertical: ResponsiveUtils.getResponsiveSize(
                                  context, 16),
                            ),
                          ),
                          textAlignVertical: TextAlignVertical.center,
                          maxLines: 15,
                          keyboardType: TextInputType.multiline,
                        ),
                        // Clear Button (Positioned at the bottom-right)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 8),
                              _buildIconButton(Icons.clear, ColorsPalette.grey,
                                  () {
                                _textController.clear();
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Buttons Row with Shadows
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // History Button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VoiceMessagePage(
                              themeProvider: widget.themeProvider,
                              textToSpeechBloc: widget.ttsBloc),
                        ),
                      );
                    },
                    child: Container(
                      width: ResponsiveUtils.getResponsiveSize(context, 50),
                      height: ResponsiveUtils.getResponsiveSize(context, 50),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeProvider.themeData.primaryColor,
                      ),
                      child: Icon(
                        Icons.list_rounded,
                        color:
                            themeProvider.themeData.textTheme.bodySmall?.color,
                        size: ResponsiveUtils.getResponsiveSize(context, 40),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSize(context, 20)),
                // Play/Pause Button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: currentlyPlaying
                        ? null // Disable tap when audio is playing
                        : () {
                            final title = _titleController.text.trim();
                            final text = _textController.text.trim();
                            if (text.isNotEmpty) {
                              setState(() {
                                currentlyPlaying = true;
                              });
                              // widget.ttsBloc.add(CreateTextToSpeechEvent(
                              //   text: text,
                              //   title: title,
                              //   save: false,
                              // ));
                              widget.ttsBloc.add(FlutterTTSEvent(
                                  text: text,
                                  language: ttsSettings['language'].toString(),
                                  voice: ttsSettings['voice'].toString()));
                            } else {
                              showCustomSnackBar(
                                context,
                                "Text field is empty!",
                                ColorsPalette.red,
                              );
                            }
                          },
                    child: Container(
                      width: ResponsiveUtils.getResponsiveSize(context, 80),
                      height: ResponsiveUtils.getResponsiveSize(context, 80),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeProvider.themeData.primaryColor,
                      ),
                      child: currentlyPlaying
                          ? Icon(
                              Icons.pause_outlined,
                              color: themeProvider
                                  .themeData.textTheme.bodySmall?.color,
                              size: ResponsiveUtils.getResponsiveSize(
                                  context, 60),
                            )
                          : Icon(
                              Icons.play_arrow_rounded,
                              color: themeProvider
                                  .themeData.textTheme.bodySmall?.color,
                              size: ResponsiveUtils.getResponsiveSize(
                                  context, 60),
                            ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSize(context, 20)),
                // Save Button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      final title = _titleController.text.trim();
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        widget.ttsBloc.add(
                          CreateTextToSpeechEvent(
                              text: text, title: title, save: true),
                        );
                        _titleController.clear();
                        _textController.clear();
                        showCustomSnackBar(
                            context, "Saved!", ColorsPalette.green);
                      } else {
                        showCustomSnackBar(
                            context, "Text field is empty!", ColorsPalette.red);
                      }
                    },
                    child: Container(
                      width: ResponsiveUtils.getResponsiveSize(context, 50),
                      height: ResponsiveUtils.getResponsiveSize(context, 50),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeProvider.themeData.primaryColor,
                      ),
                      child: Icon(
                        Icons.save_alt_rounded,
                        color:
                            themeProvider.themeData.textTheme.bodySmall?.color,
                        size: ResponsiveUtils.getResponsiveSize(context, 35),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: IconButton(
        icon: Icon(icon, size: 15, color: Colors.grey),
        onPressed: onPressed,
      ),
    );
  }
}
