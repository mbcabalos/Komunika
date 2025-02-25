import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/services/api/global_repository_impl.dart';
import 'package:komunika/services/repositories/database_helper.dart';
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
  bool save = false;
  GlobalKey _titleKey = GlobalKey();
  GlobalKey _typeSomethingKey = GlobalKey();
  GlobalKey _soundKey = GlobalKey();
  GlobalKey _saveKey = GlobalKey();
  GlobalKey _addKey = GlobalKey();

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
            isBackButton: false,
            isSettingButton: false),
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
                    description: "Tap to enter title",
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
                    description: "Type the message",
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
                //   key: _addKey,
                //   description: "Add another entry",
                //   child: GestureDetector(
                //     onTap: () {},
                //     child: Container(
                //       width: ResponsiveUtils.getResponsiveSize(context, 35),
                //       height: ResponsiveUtils.getResponsiveSize(context, 35),
                //       decoration: const BoxDecoration(
                //         shape: BoxShape.circle,
                //         image: DecorationImage(
                //           image: AssetImage('assets/icons/plus.png'),
                //           fit: BoxFit.contain,
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                const SizedBox(width: 50),
                Showcase(
                  key: _soundKey,
                  description: "Hear the speech output.",
                  child: GestureDetector(
                    onTap: () {
                      final title = _titleController.text.trim();
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        widget.ttsBloc.add(CreateTextToSpeechEvent(
                            text: text, title: title, save: false));
                      } else {
                        showCustomSnackBar(
                            context, "Text field is empty!", ColorsPalette.red);
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
                  description: "Save generated speech.",
                  child: GestureDetector(
                    onTap: () async {
                      final title = _titleController.text.trim();
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        widget.ttsBloc.add(CreateTextToSpeechEvent(
                            text: text, title: title, save: true));
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
