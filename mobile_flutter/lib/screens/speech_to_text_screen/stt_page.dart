import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_speech_to_text/speech_to_text_bloc.dart';
import 'package:komunika/services/api/global_repository_impl.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/widgets/app_bar.dart';

class SpeechToTextPage extends StatefulWidget {
  const SpeechToTextPage({super.key});

  @override
  State<SpeechToTextPage> createState() => SpeechToTextPageState();
}

class SpeechToTextPageState extends State<SpeechToTextPage> {
  late SpeechToTextBloc speechToTextBloc;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final globalService = GlobalRepositoryImpl();
    speechToTextBloc = SpeechToTextBloc(globalService);
    _initialize();
  }

  Future<void> _initialize() async {
    speechToTextBloc.add(SpeechToTextLoadingEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SpeechToTextBloc>(
      create: (context) => speechToTextBloc,
      child: Scaffold(
        backgroundColor: ColorsPalette.background,
        appBar: AppBarWidget(
            title: "Speech to Text",
            titleSize: getResponsiveFontSize(context, 15),
            isBackButton: true,
            isSettingButton: false),
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
              return _buildContent();
            } else if (state is SpeechToTextErrorState) {
              return const Text('Error processing text to speech!');
            } else {
              return _buildContent();
            }
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
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
                GestureDetector(
                  onTap: () async {
                    speechToTextBloc.add(CreateSpeechToTextEvent());
                  },
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/icons/circle-microphone.png'),
                        fit: BoxFit.contain,
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
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.black, fontSize: 20),
                decoration: const InputDecoration(
                  hintText: 'Message Here',
                  border: OutlineInputBorder(),
                  fillColor: ColorsPalette.card,
                  filled: true,
                ),
                textAlignVertical: TextAlignVertical.center,
                maxLines: phoneHeight.toInt(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsPalette.accent,
                minimumSize: Size(MediaQuery.of(context).size.width * 0.3, 50),
              ),
              onPressed: () {},
              child: const Text(
                "Done",
                style: TextStyle(
                    fontFamily: Fonts.main,
                    fontSize: 20,
                    color: ColorsPalette.white),
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
