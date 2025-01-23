import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';

class TTSCard extends StatefulWidget {
  final String text;
  const TTSCard({super.key, required this.text});

  @override
  State<TTSCard> createState() => _TTSCardState();
}

class _TTSCardState extends State<TTSCard> {
  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.9;
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsPalette.whiteYellow,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Expanded(
        child: Container(
          margin: const EdgeInsets.only(left: 12),
          child: Text(
            widget.text,
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
