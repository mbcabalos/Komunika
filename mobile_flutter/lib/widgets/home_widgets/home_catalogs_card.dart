import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';

class HomeCatalogsCard extends StatelessWidget {
  final String imagePath;
  final bool isImagePath;
  final String content;
  final double contentSize;
  final double cardHeight;
  final double cardWidth;
  const HomeCatalogsCard(
      {super.key,
      this.imagePath = "",
      required this.isImagePath,
      required this.content,
      required this.contentSize,
      this.cardHeight = 0,
      this.cardWidth = 0});

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.45;
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorsPalette.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isImagePath == true)
            Container(
              width: 35,
              height: 50,
              decoration: BoxDecoration(
                color: ColorsPalette.background,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: Text(
              content,
              style: TextStyle(
                color: ColorsPalette.black,
                fontSize: contentSize,
                fontWeight: FontWeight.bold,
                fontFamily: Fonts.main,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
