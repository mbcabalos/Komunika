import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';

class TTSCard extends StatelessWidget {
  final String audioName;
  final VoidCallback onTap; // Callback for onTap
  final VoidCallback onLongPress; // Callback for onLongPress

  const TTSCard({
    super.key,
    required this.audioName,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.9;

    return GestureDetector(
      onTap: onTap, 
      onLongPress: onLongPress, 
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorsPalette.card,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.only(left: 12),
          child: Text(
            audioName, // Display the audio name
            style: const TextStyle(
              fontFamily: Fonts.main,
              color: ColorsPalette.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
