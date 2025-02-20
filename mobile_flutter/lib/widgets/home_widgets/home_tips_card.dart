import 'package:flutter/material.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/themes.dart';

class HomeTipsCard extends StatelessWidget {
  final String content;
  final double contentSize;
  final ThemeProvider themeProvider;
  const HomeTipsCard(
      {super.key,
      required this.content,
      required this.contentSize,
      required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.95;
    return Container(
      width: cardWidth,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: Text(
              'Tips 💡',
              style: TextStyle(
                color: themeProvider.themeData.textTheme.bodyMedium?.color,
                fontSize: contentSize,
                fontWeight: FontWeight.bold,
                fontFamily: Fonts.main,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8, top: 8),
            child: Text(
              content,
              style: TextStyle(
                color: themeProvider.themeData.textTheme.bodyMedium?.color,
                fontSize: contentSize,
                fontWeight: FontWeight.normal,
                fontFamily: Fonts.main,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
