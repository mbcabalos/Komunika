import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';

class TTSCard extends StatefulWidget {
  final String audioName;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ThemeProvider themeProvider;
  final bool isPlaying;
  final bool isFavorite;

  const TTSCard({
    super.key,
    required this.audioName,
    required this.onTap,
    required this.onLongPress,
    required this.themeProvider,
    required this.isPlaying,
    required this.isFavorite,
  });

  @override
  State<TTSCard> createState() => _TTSCardState();
}

class _TTSCardState extends State<TTSCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isPlaying ? null : widget.onTap,
      onLongPress: widget.isPlaying ? null : widget.onLongPress,
      child: Opacity(
        opacity: widget.isPlaying ? 0.5 : 1.0,
        child: Container(
          margin: EdgeInsets.only(
            top: ResponsiveUtils.getResponsiveSize(context, 12),
            left: ResponsiveUtils.getResponsiveSize(context, 12),
            right: ResponsiveUtils.getResponsiveSize(context, 12),
          ),
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsets.all(
            ResponsiveUtils.getResponsiveSize(context, 16),
          ),
          decoration: BoxDecoration(
            color: widget.themeProvider.themeData.cardColor,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveSize(context, 25),
            ),
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
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Play/Pause Icon + Favorite Icon
              Row(
                children: [
                  // Favorite Icon
                  if (widget.isFavorite)
                    Icon(
                      Icons.star,
                      size: ResponsiveUtils.getResponsiveSize(context, 24),
                      color: Colors.amber,
                    ),
                  // Play/Pause Icon
                  SizedBox(
                      width: ResponsiveUtils.getResponsiveSize(context, 8)),
                  Icon(
                    widget.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    size: ResponsiveUtils.getResponsiveFontSize(context, 30),
                    color: widget.isPlaying
                        ? Colors.grey
                        : widget.themeProvider.themeData.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
