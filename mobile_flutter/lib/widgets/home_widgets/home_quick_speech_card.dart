import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';

class HomeQuickSpeechCard extends StatelessWidget {
  final List<String> content;
  final double contentSize;
  const HomeQuickSpeechCard(
      {super.key, required this.content, required this.contentSize});

  @override
  Widget build(BuildContext context) {
    List<String> items = ['Greeting', 'Thank You', 'Sorry', 'Goobbye'];
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
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
      child: Column(
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
                  "Quick Speech",
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
          for (var item in items)
            Container(
              width: MediaQuery.of(context).size.width * 0.95,
              margin: const EdgeInsets.only(left: 20, right: 20,top: 20),
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
              child: Text(
                item,
                style: TextStyle(
                  color: ColorsPalette.black,
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
