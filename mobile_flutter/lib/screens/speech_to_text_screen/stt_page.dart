import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_speech_to_text/speech_to_text_bloc.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class SpeechToTextPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const SpeechToTextPage({super.key, required this.themeProvider});

  @override
  State<SpeechToTextPage> createState() => SpeechToTextPageState();
}

class SpeechToTextPageState extends State<SpeechToTextPage> {
  late SpeechToTextBloc speechToTextBloc;
  final TextEditingController _textController = TextEditingController();
  GlobalKey _microphoneKey = GlobalKey();
  GlobalKey _textFieldKey = GlobalKey();
  GlobalKey _doneButtonKey = GlobalKey();
  bool _isShowcaseSeen = false;

  @override
  void initState() {
    super.initState();
    final socketService = SocketService();

    speechToTextBloc = SpeechToTextBloc(socketService);
    _initialize();
    _checkThenShowcase();
  }

  Future<void> _checkThenShowcase() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool pageOneDone = prefs.getBool('pageOneDone') ?? false;

    if (!pageOneDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context)
            .startShowCase([_microphoneKey, _textFieldKey, _doneButtonKey]);
        prefs.setBool('pageOneDone', true);
      });
    }
  }

  Future<void> _initialize() async {
    speechToTextBloc.add(SpeechToTextLoadingEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SpeechToTextBloc>(
      create: (context) => speechToTextBloc,
      child: Scaffold(
        backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
        appBar: AppBarWidget(
          title: 'Speech to text',
          titleSize: getResponsiveFontSize(context, 20),
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
    final double phoneHeight = MediaQuery.of(context).size.height * 0.5;
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
                Showcase(
                  key: _microphoneKey,
                  description: "Tap to start recording",
                  child: GestureDetector(
                    onTap: () async {
                      speechToTextBloc
                          .add(StartRecording()); // Trigger start recording
                    },
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image:
                              AssetImage('assets/icons/circle-microphone.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Tap to Record",
                    style: TextStyle(
                        fontSize: 25,
                        fontFamily: Fonts.main,
                        fontWeight: FontWeight.bold)),
              ],
            ),
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
                    description: "Wait for your message to be translated",
                    child: TextField(
                      readOnly: true,
                      controller: _textController,
                      style: TextStyle(
                          color: themeProvider
                              .themeData.textTheme.bodyMedium?.color,
                          fontSize: 20),
                      decoration: InputDecoration(
                        hintText: 'Message Here',
                        border: const OutlineInputBorder(),
                        fillColor: themeProvider.themeData.cardColor,
                        filled: true,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      maxLines: phoneHeight.toInt(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
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
