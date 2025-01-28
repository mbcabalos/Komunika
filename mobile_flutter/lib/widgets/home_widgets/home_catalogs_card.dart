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
    return Container(
      width: MediaQuery.of(context).size.width * 0.45,
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
              width: MediaQuery.of(context).size.width * 0.06,
              height: MediaQuery.of(context).size.height * 0.06,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
