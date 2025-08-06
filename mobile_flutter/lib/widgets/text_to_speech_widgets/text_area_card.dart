import 'package:flutter/material.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/snack_bar.dart';
import 'package:komunika/utils/themes.dart';

class TextAreaCard extends StatefulWidget {
  final ThemeProvider themeProvider;
  final TextToSpeechBloc ttsBloc;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final double? width;
  final double? height;
  final int? maxLines;
  final bool showExpandButton;
  final bool showClearButton;

  const TextAreaCard({
    super.key,
    required this.ttsBloc,
    required this.titleController,
    required this.themeProvider,
    required this.contentController,
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
  bool save = false;
  bool _readOnly = true;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

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
            GestureDetector(
              onTap: () {
                setState(() {
                  _readOnly = false;
                });
                FocusScope.of(context).requestFocus(_focusNode);
              },
              child: AbsorbPointer(
                absorbing: !_focusNode.hasFocus && _readOnly,
                child: TextField(
                  focusNode: _focusNode,
                  controller: widget.contentController,
                  readOnly: _readOnly,
                  style: TextStyle(
                    color: widget
                        .themeProvider.themeData.textTheme.bodyMedium?.color,
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 20),
                  ),
                  decoration: InputDecoration(
                    hintText: "Type your text here...",
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 16),
                    ),
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal:
                          ResponsiveUtils.getResponsiveSize(context, 12),
                      vertical: ResponsiveUtils.getResponsiveSize(context, 16),
                    ),
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  maxLines: widget.maxLines,
                  keyboardType: TextInputType.multiline,
                  onEditingComplete: () {
                    setState(() {
                      _readOnly = true;
                    });
                    _focusNode.unfocus();
                  },
                ),
              ),
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
              // Positioned(
              //   bottom: 8,
              //   right: 8,
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       const SizedBox(width: 8),
              //       Container(
              //         width: 30,
              //         height: 30,
              //         decoration: BoxDecoration(
              //           color: ColorsPalette.grey.withOpacity(0.2),
              //           borderRadius: BorderRadius.circular(15),
              //         ),
              //         child: IconButton(
              //           icon: const Icon(Icons.check,
              //               size: 15, color: Colors.grey),
              //           onPressed: () {
              //             _saveText();
              //           },
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
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
                      icon:
                          const Icon(Icons.clear, size: 15, color: Colors.grey),
                      onPressed: () {
                        widget.contentController.clear();
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
                      controller: widget.contentController,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      keyboardType: TextInputType.multiline,
                      style:
                          widget.themeProvider.themeData.textTheme.bodyMedium,
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

  Future<void> _saveText() async {
    final text = widget.contentController.text.trim();
    if (text.isEmpty) {
      showCustomSnackBar(context, "Text field is empty!", ColorsPalette.red);
      return;
    }

    final enteredTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.themeProvider.themeData.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Enter Title",
            style: TextStyle(
              color: widget.themeProvider.themeData.textTheme.bodySmall?.color,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            decoration: BoxDecoration(
              color: widget.themeProvider.themeData.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: widget.titleController,
              style: widget.themeProvider.themeData.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: "Enter title here",
                hintStyle: TextStyle(
                  color: Colors.grey.shade600,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                widget.titleController.clear();
                save = false;
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: ColorsPalette.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              child: Text(
                context.translate("tts_cancel"),
                style: TextStyle(
                  color:
                      widget.themeProvider.themeData.textTheme.bodySmall?.color,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                save = true;
                Navigator.pop(context, widget.titleController.text.trim());
              },
              style: FilledButton.styleFrom(
                backgroundColor: ColorsPalette.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              child: Text(
                context.translate("tts_proceed"),
                style: TextStyle(
                  color:
                      widget.themeProvider.themeData.textTheme.bodySmall?.color,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (save && enteredTitle != null && enteredTitle.isNotEmpty) {
      widget.ttsBloc.add(
        CreateTextToSpeechEvent(
          text: text,
          title: enteredTitle,
          save: true,
        ),
      );
      widget.titleController.clear();
      widget.contentController.clear();
      showCustomSnackBar(context, "Saved!", ColorsPalette.green);
    }
  }
}
