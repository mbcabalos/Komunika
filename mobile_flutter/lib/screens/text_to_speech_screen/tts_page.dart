import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/services/api/global_repository_impl.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class TextToSpeechScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const TextToSpeechScreen({super.key, required this.themeProvider});

  @override
  State<TextToSpeechScreen> createState() => _TextToSpeechScreenState();
}

class _TextToSpeechScreenState extends State<TextToSpeechScreen> {
  late TextToSpeechBloc textToSpeechBloc;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  bool save = false;
  GlobalKey _titleKey = GlobalKey();
  GlobalKey _typeSomethingKey = GlobalKey();
  GlobalKey _soundKey = GlobalKey();
  GlobalKey _saveKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final globalService = GlobalRepositoryImpl();
    final databaseHelper = DatabaseHelper();
    textToSpeechBloc = TextToSpeechBloc(globalService, databaseHelper);
    _initialize();
    _checkThenShowcase();
  }

  Future<void> _checkThenShowcase() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool pageTwoDone = prefs.getBool('pageThreeDone') ?? false;

    if (!pageTwoDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context)
            .startShowCase([_titleKey, _typeSomethingKey, _soundKey, _saveKey]);
        prefs.setBool('pageThreeDone', true);
      });
    }
  }

  Future<void> _initialize() async {
    textToSpeechBloc.add(TextToSpeechLoadingEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TextToSpeechBloc>(
      create: (context) => textToSpeechBloc,
      child: Scaffold(
        backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
        appBar: AppBarWidget(
          title: 'Text to Speech',
          titleSize: getResponsiveFontSize(context, 20),
          isBackButton: true,
          isSettingButton: false,
        ),
        body: BlocConsumer<TextToSpeechBloc, TextToSpeechState>(
          listener: (context, state) {
            if (state is TextToSpeechErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
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
    final double phoneHeight = MediaQuery.of(context).size.height * 0.6;
    final double phoneWidth = MediaQuery.of(context).size.width * 0.9;
    return RefreshIndicator.adaptive(
      onRefresh: _initialize,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SizedBox(
              width: phoneWidth,
              height: phoneHeight,
              child: Column(
                children: [
                  Showcase(
                    key: _titleKey,
                    description: "Enter a title for your speech.",
                    child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Title',
                        border: const OutlineInputBorder(),
                        fillColor: themeProvider.themeData.cardColor,
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Showcase(
                    key: _typeSomethingKey,
                    description:
                        "Type the message you want to convert to speech.",
                    child: TextField(
                      controller: _textController,
                      style: TextStyle(
                          color: themeProvider
                              .themeData.textTheme.bodyMedium?.color,
                          fontSize: 20),
                      decoration: InputDecoration(
                        hintText: 'Type Something .....',
                        border: const OutlineInputBorder(),
                        fillColor: themeProvider.themeData.cardColor,
                        filled: true,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      maxLines: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 32, right: 32, top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeProvider.themeData.primaryColor,
                    ),
                    child: Showcase(
                      key: _soundKey,
                      description: "Tap here to hear the speech output.",
                      child: IconButton(
                        icon: Image.asset(
                          'assets/icons/speaker-filled-audio-tool.png',
                          height: MediaQuery.of(context).size.width * 0.10,
                          width: MediaQuery.of(context).size.width * 0.10,
                        ),
                        onPressed: () {
                          final title = _titleController.text.trim();
                          final text = _textController.text.trim();
                          if (text.isNotEmpty) {
                            textToSpeechBloc.add(CreateTextToSpeechEvent(
                                text: text, title: title, save: false));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Text field is empty!')),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeProvider.themeData.primaryColor,
                    ),
                    child: Showcase(
                      key: _saveKey,
                      description: "Tap here to save the generated speech.",
                      child: IconButton(
                        icon: Image.asset(
                          'assets/icons/diskette.png',
                          height: MediaQuery.of(context).size.width * 0.10,
                          width: MediaQuery.of(context).size.width * 0.10,
                        ),
                        onPressed: () {
                          final title = _titleController.text.trim();
                          final text = _textController.text.trim();
                          if (text.isNotEmpty) {
                            textToSpeechBloc.add(CreateTextToSpeechEvent(
                                text: text, title: title, save: true));
                            Navigator.pop(context, true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Text field is empty!')),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double getResponsiveFontSize(BuildContext context, double size) {
    double baseWidth = 375.0; // Reference width (e.g., iPhone 11 Pro)
    double screenWidth = MediaQuery.of(context).size.width;
    return size * (screenWidth / baseWidth);
  }
}
