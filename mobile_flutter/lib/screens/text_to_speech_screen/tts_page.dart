import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/services/api/global_repository_impl.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class TextToSpeechScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  final VoidCallback isSaved; // Callback to refresh the parent screen

  const TextToSpeechScreen({
    super.key,
    required this.themeProvider,
    required this.isSaved,
  });

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
          title: context.translate("tts_title"),
          titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
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
    final double phoneHeight = MediaQuery.of(context).size.height * 0.7;
    final double phoneWidth = MediaQuery.of(context).size.width * 1.0;
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
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _titleController,
                        style: TextStyle(
                          color: themeProvider
                              .themeData.textTheme.bodyMedium?.color,
                          fontSize: 20,
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
                  const SizedBox(height: 10),
                  Showcase(
                    key: _typeSomethingKey,
                    description:
                        "Type the message you want to convert to speech.",
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: themeProvider.themeData.cardColor,
                      child: TextField(
                        readOnly: false,
                        controller: _textController,
                        style: TextStyle(
                          color: themeProvider
                              .themeData.textTheme.bodyMedium?.color,
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          hintText: context.translate("tts_hint"),
                          border: InputBorder.none,
                          fillColor: Colors.transparent,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
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
                // Showcase(
                //   key: GlobalKey(),
                //   description: "Pause recording",
                //   child: GestureDetector(
                //     onTap: () {},
                //     child: Container(
                //       width: ResponsiveUtils.getResponsiveSize(context, 40),
                //       height: ResponsiveUtils.getResponsiveSize(context, 40),
                //       decoration: const BoxDecoration(
                //         shape: BoxShape.circle,
                //         image: DecorationImage(
                //           image: AssetImage('assets/icons/pause.png'),
                //           fit: BoxFit.contain,
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                const SizedBox(width: 20),
                Showcase(
                  key: _soundKey,
                  description: "Tap here to hear the speech output.",
                  child: GestureDetector(
                    onTap: () {
                      final title = _titleController.text.trim();
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        textToSpeechBloc.add(CreateTextToSpeechEvent(
                            text: text, title: title, save: false));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Text field is empty!')),
                        );
                      }
                    },
                    child: Container(
                        width: ResponsiveUtils.getResponsiveSize(context, 80),
                        height: ResponsiveUtils.getResponsiveSize(context, 80),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeProvider.themeData.primaryColor),
                        child: const Icon(Icons.volume_up_rounded,
                            color: Colors.white, size: 60)),
                  ),
                ),
                const SizedBox(width: 20),
                Showcase(
                  key: _saveKey,
                  description: "Tap here to save the generated speech.",
                  child: GestureDetector(
                    onTap: () async {
                      final title = _titleController.text.trim();
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        textToSpeechBloc.add(CreateTextToSpeechEvent(
                            text: text, title: title, save: true));
                        widget
                            .isSaved(); // Call the callback to refresh the parent screen
                        Navigator.pop(context, true); // Close the screen
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Text field is empty!')),
                        );
                      }
                    },
                    child: Container(
                      width: ResponsiveUtils.getResponsiveSize(context, 40),
                      height: ResponsiveUtils.getResponsiveSize(context, 40),
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
          ],
        ),
      ),
    );
  }
}
