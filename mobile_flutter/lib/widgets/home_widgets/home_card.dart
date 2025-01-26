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
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: ColorsPalette.background,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Image.asset(
              widget.imagePath,
              fit: BoxFit.contain,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: Text(
              widget.text,
              style: const TextStyle(
                color: ColorsPalette.black,
                fontSize: 16,
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
