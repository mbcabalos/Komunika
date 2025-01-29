import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';

class HomeQuickSpeechCard extends StatelessWidget {
  final List<String> content;
  final double contentSize;
  final Function(String) onTap;

  const HomeQuickSpeechCard({
    super.key,
    required this.content,
    required this.contentSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
      child: content.isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "No quick speech items available",
                  style: TextStyle(
                    color: ColorsPalette.black,
                    fontSize: contentSize,
                    fontWeight: FontWeight.normal,
                    fontFamily: Fonts.main,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                    height: 16), // Add spacing between text and button
                TextButton(
                  onPressed: null, // Callback when the button is pressed
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.zero, // Remove padding for better alignment
                  ),
                  child: Text(
                    "Add One Now",
                    style: TextStyle(
                      fontSize: contentSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: Fonts.main,
                      color: ColorsPalette
                          .accent, // Use primary color for the text
                      decoration: TextDecoration
                          .underline, // Add underline for emphasis
                    ),
                  ),
                ),
              ],
            )
          : Column(
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
                for (var item in content)
                  GestureDetector(
                    onTap: () {
                      onTap(item);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.95,
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
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
                  ),
              ],
            ),
    );
  }
}
