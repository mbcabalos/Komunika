import 'package:flutter/material.dart';
import 'package:komunika/widgets/app_bar.dart';

class SpeechToTextPage extends StatefulWidget {
  const SpeechToTextPage({super.key});

  @override
  State<SpeechToTextPage> createState() => SpeechToTextPageState();
}

class SpeechToTextPageState extends State<SpeechToTextPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(title: "Speech To Text", isBackButton: true, isSettingButton: false),
      
    );
  }
}