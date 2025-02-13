import 'package:flutter/material.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/app_bar.dart';

class SignTranscribePage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const SignTranscribePage({super.key, required this.themeProvider});

  @override
  State<SignTranscribePage> createState() => SignTranscribePageState();
}

class SignTranscribePageState extends State<SignTranscribePage> {
  bool isSignTranscriptionEnabled = false;
  final TextEditingController _textController = TextEditingController();
  String translatedMessage = "This is a note, this is a...";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
          title: "Sign Transcibe",
          titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          isBackButton: true,
          isSettingButton: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: widget.themeProvider.themeData.cardColor,
              child: TextField(
                readOnly: false,
                controller: _textController,
                style: TextStyle(
                  color: widget
                      .themeProvider.themeData.textTheme.bodyMedium?.color,
                  fontSize: 20,
                ),
                decoration: const InputDecoration(
                  hintText: "Waiting Progress ni Kobe",
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                textAlignVertical: TextAlignVertical.center,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: widget.themeProvider.themeData.cardColor,
              child: TextField(
                readOnly: false,
                controller: _textController,
                style: TextStyle(
                  color: widget
                      .themeProvider.themeData.textTheme.bodyMedium?.color,
                  fontSize: 20,
                ),
                decoration: InputDecoration(
                  hintText: "Translated Message",
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                textAlignVertical: TextAlignVertical.center,
                maxLines: 12,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
