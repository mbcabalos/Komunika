import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/screens/text_to_speech_screen/voice_message_page.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/snack_bar.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';
import 'package:showcaseview/showcaseview.dart';

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
  bool currentlyPlaying = false;
  bool save = false;
  GlobalKey _titleKey = GlobalKey();
  GlobalKey _typeSomethingKey = GlobalKey();
  GlobalKey _soundKey = GlobalKey();
  GlobalKey _saveKey = GlobalKey();
  GlobalKey _listKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    widget.ttsBloc.add(TextToSpeechLoadingEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.ttsBloc,
      child: Scaffold(
        backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
        appBar: AppBarWidget(
          title: context.translate("tts_title"),
          titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          themeProvider: widget.themeProvider,
          isBackButton: true,
          isSettingButton: false,
          isHistoryButton: false,
          database: '',
        ),
        body: BlocConsumer<TextToSpeechBloc, TextToSpeechState>(
          listener: (context, state) {
            if (state is TextToSpeechErrorState) {
              showCustomSnackBar(
                  context, "Errr, Please try again", ColorsPalette.red);
            }
            if (state is AudioPlaybackCompletedState) {
              setState(() {
                currentlyPlaying = false; // Reset when audio finishes
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
                  Showcase(
                    key: _titleKey,
                    description: "Tap to enter title",
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getResponsiveSize(context, 12),
                        ),
                      ),
                      child: TextField(
                        controller: _titleController,
                        style: TextStyle(
                          color: themeProvider
                              .themeData.textTheme.bodyMedium?.color,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 20),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Title',
                          border: InputBorder.none,
                          fillColor: themeProvider.themeData.cardColor,
                          filled: true,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSize(context, 10),
                  ),
                  Showcase(
                    key: _typeSomethingKey,
                    description: "Type the message",
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getResponsiveSize(context, 12),
                        ),
                      ),
                      color: themeProvider.themeData.cardColor,
                      child: TextField(
                        readOnly: false,
                        controller: _textController,
                        style: TextStyle(
                          color: themeProvider
                              .themeData.textTheme.bodyMedium?.color,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 20),
                        ),
                        decoration: InputDecoration(
                          hintText: context.translate("tts_hint"),
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
                        textAlignVertical: TextAlignVertical.center,
                        maxLines: 15,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Showcase(
                  key: _listKey,
                  description: "Add another entry",
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
                      width: ResponsiveUtils.getResponsiveSize(context, 40),
                      height: ResponsiveUtils.getResponsiveSize(context, 40),
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        image: const DecorationImage(
                          image: AssetImage('assets/icons/clipboard.png'),
                          fit: BoxFit.contain,
                        ),
                        color: themeProvider.themeData.cardColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSize(context, 20)),
                Showcase(
                  key: _soundKey,
                  description: "Hear the speech output.",
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
                              widget.ttsBloc.add(CreateTextToSpeechEvent(
                                text: text,
                                title: title,
                                save: false,
                              ));
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
                          color: themeProvider.themeData.primaryColor),
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
                Showcase(
                  key: _saveKey,
                  description: "Save generated speech.",
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
                      width: ResponsiveUtils.getResponsiveSize(context, 40),
                      height: ResponsiveUtils.getResponsiveSize(context, 40),
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        image: const DecorationImage(
                          image: AssetImage('assets/icons/saved.png'),
                          fit: BoxFit.contain,
                        ),
                        color: themeProvider.themeData.cardColor,
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
}
