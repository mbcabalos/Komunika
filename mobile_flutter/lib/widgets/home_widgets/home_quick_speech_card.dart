import 'package:flutter/material.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/screens/text_to_speech_screen/voice_message_page.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/themes.dart';

class HomeQuickSpeechCard extends StatelessWidget {
  final List<String> content;
  final double contentSize;
  final ThemeProvider themeProvider;
  final TextToSpeechBloc textToSpeechBloc;
  final Function(String) onTap;

  const HomeQuickSpeechCard({
    super.key,
    required this.content,
    required this.contentSize,
    required this.themeProvider,
    required this.onTap, required this.textToSpeechBloc,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeProvider.themeData.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: themeProvider.themeData.scaffoldBackgroundColor
                  .withOpacity(0.3),
              blurRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: content.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    context.translate("home_no_quick_speech"),
                    style: TextStyle(
                      color:
                          themeProvider.themeData.textTheme.titleMedium?.color,
                      fontSize: contentSize,
                      fontWeight: FontWeight.normal,
                      fontFamily: Fonts.main,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VoiceMessagePage(
                            themeProvider: themeProvider, textToSpeechBloc: textToSpeechBloc,
                          ),
                        ),
                      );
                    }, // Callback when the button is pressed
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      "Add One Now",
                      style: TextStyle(
                        fontSize: contentSize,
                        fontWeight: FontWeight.bold,
                        fontFamily: Fonts.main,
                        color: ColorsPalette.accent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 8, top: 8),
                        child: Text(
                          context.translate("home_quick_speech"),
                          style: TextStyle(
                            color: themeProvider
                                .themeData.textTheme.bodyMedium?.color,
                            fontSize: contentSize,
                            fontWeight: FontWeight.bold,
                            fontFamily: Fonts.main,
                          ),
                        ),
                      ),
                    ],
                  ),
                  for (var item in content)
                    GestureDetector(
                      onTap: () {
                        onTap(item);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.95,
                        margin:
                            const EdgeInsets.only(left: 20, right: 20, top: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: themeProvider.themeData.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            color: themeProvider
                                .themeData.textTheme.bodyMedium?.color,
                            fontSize: contentSize,
                            fontWeight: FontWeight.normal,
                            fontFamily: Fonts.main,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
