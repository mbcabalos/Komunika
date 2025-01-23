import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';

class HomeCard extends StatefulWidget {
  final String imagePath;
  final String text;
  const HomeCard({super.key, required this.imagePath, required this.text});

  @override
  State<HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<HomeCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorsPalette.whiteYellow,
        borderRadius: BorderRadius.circular(5),
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: ColorsPalette.background,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Image.asset(
              widget.imagePath,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 25),
              child: Text(
                widget.text,
                style: const TextStyle(
                  color: ColorsPalette.black,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: Fonts.main,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
