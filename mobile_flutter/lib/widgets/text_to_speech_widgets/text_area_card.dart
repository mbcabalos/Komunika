import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/utils/shared_prefs.dart'; // added

class TextAreaCard extends StatefulWidget {
  final ThemeProvider themeProvider;
  final TextToSpeechBloc ttsBloc;
  final DatabaseHelper dbHelper;
  final TextEditingController contentController;
  final VoidCallback? onClear;
  final String historyMode;
  final String textFieldHint;

  const TextAreaCard({
    super.key,
    required this.ttsBloc,
    required this.dbHelper,
    required this.themeProvider,
    required this.contentController,
    this.onClear,
    required this.historyMode,
    required this.textFieldHint,
  });

  @override
  State<TextAreaCard> createState() => _TextAreaCardState();
}

class _TextAreaCardState extends State<TextAreaCard> {
  bool save = false;
  bool _readOnly = true;
  final int maxLines = 15;
  final bool showExpandButton = true;
  final FocusNode _focusNode = FocusNode();
  static const int maxCharacters = 1000;
  final ScrollController _scrollController = ScrollController();

  // Font size state
  double _fontSize = 14.0;

  @override
  void initState() {
    super.initState();
    widget.contentController.addListener(() {
      setState(() {}); // refresh counter
    });
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    try {
      final f = await PreferencesUtils.getTTSFontSize();
      setState(() => _fontSize = f);
    } catch (_) {}
  }

  Future<void> _changeFontSize(double delta) async {
    final newSize = (_fontSize + delta).clamp(10.0, 28.0);
    await PreferencesUtils.storeTTSFontSize(newSize);
    setState(() => _fontSize = newSize);
  }

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
          // Text Field with scrollbar
          GestureDetector(
            onTap: () {
              setState(() {
                _readOnly = false;
              });
              FocusScope.of(context).requestFocus(_focusNode);
            },
            child: AbsorbPointer(
              absorbing: !_focusNode.hasFocus && _readOnly,
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                thickness: ResponsiveUtils.getResponsiveSize(context, 2),
                radius: Radius.circular(
                    ResponsiveUtils.getResponsiveSize(context, 3)),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Builder(builder: (context) {
                    final double baseFont = 14.0;
                    final double lineHeightFactor = 1.4; // lines spacing
                    final double verticalPadding =
                        ResponsiveUtils.getResponsiveSize(context, 16);
                    final double fixedHeight =
                        (baseFont * lineHeightFactor) * maxLines +
                            verticalPadding * 13;

                    return SizedBox(
                      height: fixedHeight,
                      child: TextField(
                        focusNode: _focusNode,
                        controller: widget.contentController,
                        readOnly: _readOnly,
                        scrollController: _scrollController,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(maxCharacters)
                        ],
                        style: TextStyle(
                          color: widget.themeProvider.themeData.textTheme
                              .bodyMedium?.color,
                          fontSize:
                              _fontSize, // adjustable but does not affect height
                        ),
                        decoration: InputDecoration(
                          hintText: widget.textFieldHint,
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context, 16),
                          ),
                          border: InputBorder.none,
                          fillColor: Colors.transparent,
                          filled: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal:
                                ResponsiveUtils.getResponsiveSize(context, 12),
                            vertical: verticalPadding,
                          ),
                        ),
                        textAlignVertical: TextAlignVertical.top,
                        minLines: maxLines,
                        maxLines: maxLines, // fixed 15 lines visible
                        expands: false,
                        keyboardType: TextInputType.multiline,
                        onEditingComplete: () {
                          setState(() {
                            _readOnly = true;
                          });
                          _focusNode.unfocus();
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),

          // Character counter bottom-left
          Positioned(
            bottom: ResponsiveUtils.getResponsiveSize(context, 8),
            left: ResponsiveUtils.getResponsiveSize(context, 12),
            child: Text(
              "${widget.contentController.text.length.clamp(0, maxCharacters)} / $maxCharacters",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              ),
            ),
          ),

          // Expand button
          if (showExpandButton)
            Positioned(
              top: ResponsiveUtils.getResponsiveSize(context, 8),
              right: ResponsiveUtils.getResponsiveSize(context, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                      width: ResponsiveUtils.getResponsiveSize(context, 8)),
                  Container(
                    width: ResponsiveUtils.getResponsiveSize(context, 30),
                    height: ResponsiveUtils.getResponsiveSize(context, 30),
                    decoration: BoxDecoration(
                      color: ColorsPalette.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getResponsiveSize(context, 15)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.expand_outlined,
                          size: ResponsiveUtils.getResponsiveFontSize(
                              context, 15),
                          color: Colors.grey),
                      onPressed: _showExpandedDialog,
                    ),
                  ),
                ],
              ),
            ),

          // Bottom-right controls: decrease / increase / (optional check) / clear
          Positioned(
            bottom: ResponsiveUtils.getResponsiveSize(context, 8),
            right: ResponsiveUtils.getResponsiveSize(context, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decrease font
                Container(
                  width: ResponsiveUtils.getResponsiveSize(context, 30),
                  height: ResponsiveUtils.getResponsiveSize(context, 30),
                  margin: EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: ColorsPalette.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getResponsiveSize(context, 15)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.remove,
                        size:
                            ResponsiveUtils.getResponsiveFontSize(context, 15),
                        color: Colors.grey),
                    onPressed: () => _changeFontSize(-1.0),
                  ),
                ),

                // Increase font
                Container(
                  width: ResponsiveUtils.getResponsiveSize(context, 30),
                  height: ResponsiveUtils.getResponsiveSize(context, 30),
                  margin: EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: ColorsPalette.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getResponsiveSize(context, 15)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add,
                        size:
                            ResponsiveUtils.getResponsiveFontSize(context, 15),
                        color: Colors.grey),
                    onPressed: () => _changeFontSize(1.0),
                  ),
                ),

                // Manual save button (same row, no extra spacing needed)
                if (widget.historyMode == 'Manual')
                  Container(
                    width: ResponsiveUtils.getResponsiveSize(context, 30),
                    height: ResponsiveUtils.getResponsiveSize(context, 30),
                    margin: EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: ColorsPalette.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getResponsiveSize(context, 15)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.check,
                          size: ResponsiveUtils.getResponsiveFontSize(
                              context, 15),
                          color: Colors.grey),
                      onPressed: () {
                        _showSaveConfirmationDialog();
                      },
                    ),
                  ),

                // Clear button
                Container(
                  width: ResponsiveUtils.getResponsiveSize(context, 30),
                  height: ResponsiveUtils.getResponsiveSize(context, 30),
                  decoration: BoxDecoration(
                    color: ColorsPalette.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getResponsiveSize(context, 15)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.clear,
                        size:
                            ResponsiveUtils.getResponsiveFontSize(context, 15),
                        color: Colors.grey),
                    onPressed: () {
                      if (widget.historyMode == 'Auto' &&
                          widget.contentController.text.isNotEmpty) {
                        widget.dbHelper.saveTextToSpeechHistory(
                            widget.contentController.text);
                      }
                      if (widget.onClear != null) widget.onClear!();
                    },
                  ),
                ),
              ],
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                  ResponsiveUtils.getResponsiveSize(context, 32)),
              topRight: Radius.circular(
                  ResponsiveUtils.getResponsiveSize(context, 32)),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                    top: ResponsiveUtils.getResponsiveSize(context, 4),
                    right: ResponsiveUtils.getResponsiveSize(context, 8)),
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.expand_less,
                      color: Colors.grey,
                      size: ResponsiveUtils.getResponsiveFontSize(context, 20)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal:
                          ResponsiveUtils.getResponsiveSize(context, 16)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.themeProvider.themeData.cardColor,
                      borderRadius: BorderRadius.all(Radius.circular(
                          ResponsiveUtils.getResponsiveSize(context, 12))),
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            ResponsiveUtils.getResponsiveSize(context, 12)),
                    child: Scrollbar(
                      thumbVisibility: true,
                      thickness: ResponsiveUtils.getResponsiveSize(context, 2),
                      radius: Radius.circular(
                          ResponsiveUtils.getResponsiveSize(context, 3)),
                      child: Container(
                        margin: EdgeInsets.symmetric(
                            vertical:
                                ResponsiveUtils.getResponsiveSize(context, 8)),
                        child: SingleChildScrollView(
                          child: TextField(
                            controller: widget.contentController,
                            expands: false,
                            maxLines: null,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(maxCharacters)
                            ],
                            keyboardType: TextInputType.multiline,
                            style: widget
                                .themeProvider.themeData.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: widget.textFieldHint,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                    context, 14),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.getResponsiveSize(
                                    context, 8),
                                vertical: ResponsiveUtils.getResponsiveSize(
                                    context, 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: ResponsiveUtils.getResponsiveSize(context, 12),
                  right: ResponsiveUtils.getResponsiveSize(context, 20),
                  left: ResponsiveUtils.getResponsiveSize(context, 20),
                  top: ResponsiveUtils.getResponsiveSize(context, 4),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${widget.contentController.text.length.clamp(0, maxCharacters)} / $maxCharacters",
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 12)),
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
          borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveSize(context, 16)),
        ),
        child: Padding(
          padding:
              EdgeInsets.all(ResponsiveUtils.getResponsiveSize(context, 16)),
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
              SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 16)),
              Text(
                context.translate('save_confirmation_message'),
                style: TextStyle(
                  color: themeProvider.themeData.textTheme.bodyMedium?.color,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 24)),
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
                        borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getResponsiveSize(context, 8)),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal:
                              ResponsiveUtils.getResponsiveSize(context, 8),
                          vertical:
                              ResponsiveUtils.getResponsiveSize(context, 8)),
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
                  SizedBox(
                      width: ResponsiveUtils.getResponsiveSize(context, 8)),
                  FilledButton(
                    onPressed: () {
                      confirmSave = true;
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorsPalette.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getResponsiveSize(context, 8)),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal:
                              ResponsiveUtils.getResponsiveSize(context, 8),
                          vertical:
                              ResponsiveUtils.getResponsiveSize(context, 8)),
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
