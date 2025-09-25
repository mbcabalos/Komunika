import 'package:flutter/material.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';

class TextAreaCard extends StatefulWidget {
  final ThemeProvider themeProvider;
  final TextToSpeechBloc ttsBloc;
  final DatabaseHelper dbHelper;
  final TextEditingController contentController;
  final double? width;
  final double? height;
  final int? maxLines;
  final bool showExpandButton;
  final VoidCallback? onClear;
  final String historyMode;

  const TextAreaCard({
    super.key,
    required this.ttsBloc,
    required this.dbHelper,
    required this.themeProvider,
    required this.contentController,
    this.width,
    this.height,
    this.maxLines = 15,
    this.showExpandButton = true,
    this.onClear,
    required this.historyMode,
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
    return Card(
      color: widget.themeProvider.themeData.cardColor,
      elevation: 2,
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.getResponsiveSize(context, 10),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveSize(context, 12),
        ),
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
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                ),
                decoration: InputDecoration(
                  hintText: context.translate('tts_hint2'),
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 16),
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

          // History mode buttons
          if (widget.historyMode == 'Manual')
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
                          const Icon(Icons.check, size: 15, color: Colors.grey),
                      onPressed: () {
                        _showSaveConfirmationDialog();
                      },
                    ),
                  ),
                ],
              ),
            ),

          Positioned(
            bottom: 8,
            right: 8 + (widget.historyMode == 'Manual' ? 37 : 0),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: ColorsPalette.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                icon: const Icon(Icons.clear, size: 15, color: Colors.grey),
                onPressed: () {
                  if (widget.historyMode == 'Auto' &&
                      widget.contentController.text.isNotEmpty) {
                    widget.dbHelper
                        .saveTextToSpeechHistory(widget.contentController.text);
                  }
                  if (widget.onClear != null) widget.onClear!();
                },
              ),
            ),
          ),
        ],
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
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: context.translate('tts_hint2'),
                        hintStyle: const TextStyle(color: Colors.grey),
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

  Future<void> _showSaveConfirmationDialog() async {
    bool confirmSave = false;
    final themeProvider = widget.themeProvider;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: themeProvider.themeData.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.translate('save_confirmation_title'),
                style: TextStyle(
                  color: themeProvider.themeData.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.translate('save_confirmation_message'),
                style: TextStyle(
                  color: themeProvider.themeData.textTheme.bodyMedium?.color,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorsPalette.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    child: Text(
                      context.translate('cancel'),
                      style: TextStyle(
                        color:
                            themeProvider.themeData.textTheme.bodySmall?.color,
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      confirmSave = true;
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorsPalette.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    child: Text(
                      context.translate('save'),
                      style: TextStyle(
                        color:
                            themeProvider.themeData.textTheme.bodySmall?.color,
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmSave && mounted) {
      if (widget.contentController.text.isNotEmpty) {
        widget.dbHelper.saveTextToSpeechHistory(widget.contentController.text);
      }
      widget.contentController.clear();
    }
  }
}
