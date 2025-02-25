import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';

class HomeQuickSpeechCard extends StatefulWidget {
  final String audioName;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ThemeProvider themeProvider;
  final bool isPlaying; // Track if the audio is playing

  const HomeQuickSpeechCard({
    super.key,
    required this.audioName,
    required this.onTap,
    required this.onLongPress,
    required this.themeProvider,
    required this.isPlaying,
  });

  @override
  State<HomeQuickSpeechCard> createState() => _HomeQuickCardState();
}

class _HomeQuickCardState extends State<HomeQuickSpeechCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isPlaying ? null : widget.onTap, // Disable if playing
      onLongPress:
          widget.isPlaying ? null : widget.onLongPress, // Disable if playing
      child: Opacity(
        opacity: widget.isPlaying ? 0.5 : 1.0, // Reduce opacity if playing
        child: Container(
          margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
          width: MediaQuery.of(context).size.width * 0.7,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.themeProvider.themeData.cardColor,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: ColorsPalette.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Audio Name
              Text(
                widget.audioName,
                style: TextStyle(
                  fontFamily: Fonts.main,
                  color: widget
                      .themeProvider.themeData.textTheme.bodyMedium?.color,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 17),
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Play/Pause Icon
              Icon(
                widget.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                size: 30,
                color: widget.isPlaying
                    ? Colors.grey // Gray out if playing
                    : widget.themeProvider.themeData.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
