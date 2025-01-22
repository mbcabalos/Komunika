import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/services/api/global_repository_impl.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/widgets/app_bar.dart';

class TextToSpeechScreen extends StatefulWidget {
  const TextToSpeechScreen({super.key});

  @override
  State<TextToSpeechScreen> createState() => _TextToSpeechScreenState();
}

class _TextToSpeechScreenState extends State<TextToSpeechScreen> {
  late TextToSpeechBloc textToSpeechBloc;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final globalService = GlobalRepositoryImpl();
    textToSpeechBloc = TextToSpeechBloc(globalService);
    _initialize();
  }

  Future<void> _initialize() async {
    textToSpeechBloc.add(TextToSpeechLoadingEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TextToSpeechBloc>(
      create: (context) => textToSpeechBloc,
      child: Scaffold(
        backgroundColor: ColorsPalette.background,
        appBar: const AppBarWidget(
          title: 'Text To Speech',
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
              return _buildContent();
            } else if (state is TextToSpeechErrorState) {
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
    final double phoneHeight = MediaQuery.of(context).size.height * 0.6;
    final double phoneWidth = MediaQuery.of(context).size.width * 0.9;
    return RefreshIndicator.adaptive(
      onRefresh: _initialize,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              width: phoneWidth,
              height: phoneHeight,
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.black, fontSize: 20),
                decoration: const InputDecoration(
                  hintText: 'Type Something .....',
                  border: OutlineInputBorder(),
                  fillColor: ColorsPalette.whiteYellow,
                  filled: true,
                ),
                textAlignVertical: TextAlignVertical.center,
                maxLines: phoneHeight.toInt(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsPalette.blue,
                    minimumSize:
                        Size(MediaQuery.of(context).size.width * 0.3, 50),
                  ),
                  onPressed: () {
                    final text = _textController.text.trim();
                    if (text.isNotEmpty) {
                      textToSpeechBloc.add(CreateTextToSpeechEvent(text: text));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Text field is empty!')),
                      );
                    }
                  },
                  child: const Text(
                    "Play",
                    style: TextStyle(fontSize: 20, color: ColorsPalette.black),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsPalette.green,
                    minimumSize:
                        Size(MediaQuery.of(context).size.width * 0.3, 50),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "Save",
                    style: TextStyle(fontSize: 20, color: ColorsPalette.black),
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
