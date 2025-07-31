import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';

class TextAreaCard extends StatefulWidget {
  final ThemeProvider themeProvider;
  final TextEditingController textController;
  final double? width;
  final double? height;
  final int? maxLines;
  final bool showExpandButton;
  final bool showClearButton;

  const TextAreaCard({
    super.key,
    required this.themeProvider,
    required this.textController,
    this.width,
    this.height,
    this.maxLines = 17,
    this.showExpandButton = true,
    this.showClearButton = true,
  });

  @override
  State<TextAreaCard> createState() => _TextAreaCardState();
}

class _TextAreaCardState extends State<TextAreaCard> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Container(
        decoration: BoxDecoration(
          color: widget.themeProvider.themeData.cardColor,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveSize(context, 12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            TextField(
              controller: widget.textController,
              style: TextStyle(
                color:
                    widget.themeProvider.themeData.textTheme.bodyMedium?.color,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
              ),
              decoration: InputDecoration(
                hintText: "Type your text here...",
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                ),
                border: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsiveSize(context, 12),
                  vertical: ResponsiveUtils.getResponsiveSize(context, 16),
                ),
              ),
              textAlignVertical: TextAlignVertical.center,
              maxLines: widget.maxLines,
              keyboardType: TextInputType.multiline,
            ),
            if (widget.showExpandButton)
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: ColorsPalette.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.expand_outlined,
                            size: 15, color: Colors.grey),
                        onPressed: _showExpandedDialog,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.showClearButton)
              Positioned(
                bottom: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: ColorsPalette.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.clear,
                            size: 15, color: Colors.grey),
                        onPressed: () {
                          widget.textController.clear();
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showExpandedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor:
              widget.themeProvider.themeData.scaffoldBackgroundColor,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.expand_less, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.themeProvider.themeData.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: widget.textController,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      keyboardType: TextInputType.multiline,
                      style: widget.themeProvider.themeData.textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Type your text here...",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
