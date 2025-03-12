import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_speech_to_text/speech_to_text_bloc.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/history.dart';

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
  final dbHelper = DatabaseHelper();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _textController.clear();
    _initialize();
  }

  Future<void> _initialize() async {
    widget.speechToTextBloc.add(SpeechToTextLoadingEvent());
    widget.speechToTextBloc.add(RequestPermissionEvent());
  }

  void _toggleTapRecording() {
    if (!_isRecording) {
      setState(() {
        _isRecording = true;
      });
      widget.speechToTextBloc.add(StartTapRecordingEvent());
    } else {
      setState(() {
        _isRecording = false;
      });
      widget.speechToTextBloc.add(StopTapRecordingEvent());
    }
  }

  void _startRecording() {
    setState(() => _isRecording = true);
    widget.speechToTextBloc.add(StartRecordingEvent());
  }

  void _stopRecording() {
    setState(() => _isRecording = false);
    widget.speechToTextBloc.add(StopRecordingEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.speechToTextBloc,
      child: Scaffold(
        backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(top: 7.0),
            child: Text(
              context.translate("stt_title"),
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
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
                widget.speechToTextBloc.add(StopTapRecordingEvent());
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
        padding: EdgeInsets.all(
          ResponsiveUtils.getResponsiveSize(context, 16),
        ),
        child: ListView(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSize(context, 20),
                ),
                SizedBox(
                  width: phoneWidth,
                  height: phoneHeight,
                  child: BlocBuilder<SpeechToTextBloc, SpeechToTextState>(
                    builder: (context, state) {
                      if (state is TranscriptionUpdatedState) {
                        _textController.text += state.text;
                        _textController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _textController.text.length));
                      }
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getResponsiveSize(context, 12),
                          ),
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
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context, 20),
                            ),
                            decoration: InputDecoration(
                              hintText: context.translate("stt_hint"),
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
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSize(context, 50),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        print("clicked");
                        dbHelper.saveSpeechToTextHistory(_textController.text);
                        _textController.clear();
                      },
                      child: Container(
                        width: ResponsiveUtils.getResponsiveSize(context, 35),
                        height: ResponsiveUtils.getResponsiveSize(context, 35),
                        decoration: const BoxDecoration(
                          shape: BoxShape.rectangle,
                          image: DecorationImage(
                            image: AssetImage('assets/icons/plus.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveUtils.getResponsiveSize(context, 20),
                    ),
                    GestureDetector(
                      onTap: _toggleTapRecording,
                      onLongPress: _startRecording,
                      onLongPressUp: _stopRecording,
                      child: Container(
                        width: ResponsiveUtils.getResponsiveSize(context, 80),
                        height: ResponsiveUtils.getResponsiveSize(context, 80),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeProvider.themeData.primaryColor,
                        ),
                        child: Icon(
                          _isRecording ? Icons.graphic_eq_rounded : Icons.mic,
                          color: Colors.white,
                          size: ResponsiveUtils.getResponsiveSize(context, 60),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveUtils.getResponsiveSize(context, 50),
                    ),
                  ],
                ),
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSize(context, 10),
                ),
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
