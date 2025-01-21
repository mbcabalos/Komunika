import 'package:flutter/material.dart';
import 'package:komunika/screens/text_to_speech_screen/tts_page.dart';
import 'package:komunika/widgets/app_bar.dart';
import 'package:komunika/utils/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'Home', isBackButton: false, isSettingButton: true),
      floatingActionButton: FloatingActionButton(
                backgroundColor: ColorsPalette.black.withOpacity(0.6),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TextToSpeechScreen()),
                  );
                },
                child: const Icon(Icons.mic, color: Colors.white),
              )
    );
  }
}

class ColorPalette {
}