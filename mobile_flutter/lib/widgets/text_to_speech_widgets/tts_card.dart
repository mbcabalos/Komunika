import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/themes.dart';

class TTSCard extends StatelessWidget {
  final String audioName;
  final VoidCallback onTap; // Callback for onTap
  final VoidCallback onLongPress; // Callback for onLongPress
  final ThemeProvider themeProvider;
  final bool isDisabled;

  const TTSCard({
    super.key,
    required this.audioName,
    required this.onTap,
    required this.onLongPress,
    required this.themeProvider,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.9;

    return GestureDetector(
      onTap: isDisabled ? null : onTap, 
      onLongPress: isDisabled
          ? null
          : onLongPress, 
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0, 
        child: Container(
          margin: const EdgeInsets.only(top: 12, left: 12),
          width: cardWidth,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeProvider.themeData.cardColor,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: ColorsPalette.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            audioName, // Display the audio name
            style: TextStyle(
              fontFamily: Fonts.main,
              color: themeProvider.themeData.textTheme.bodyMedium?.color,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
