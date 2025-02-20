import 'package:flutter/material.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/themes.dart';

class HomeCatalogsCard extends StatelessWidget {
  final String imagePath;
  final bool isImagePath;
  final String content;
  final double contentSize;
  final double cardHeight;
  final double cardWidth;
  final ThemeProvider themeProvider;
  const HomeCatalogsCard(
      {super.key,
      this.imagePath = "",
      required this.isImagePath,
      required this.content,
      required this.contentSize,
      this.cardHeight = 0,
      this.cardWidth = 0,
      required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.43,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:  themeProvider.themeData.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: themeProvider.themeData.scaffoldBackgroundColor.withOpacity(0.3),
              blurRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isImagePath == true)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.06,
                height: MediaQuery.of(context).size.height * 0.06,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                child: Text(
                  content,
                  style: TextStyle(
                    color: themeProvider.themeData.textTheme.bodyMedium?.color,
                    fontSize: contentSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: Fonts.main,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
