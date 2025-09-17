import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_sound_enhancer/sound_enhancer_bloc.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';

class SpeechToTextCard extends StatefulWidget {
  final ThemeProvider themeProvider;
  final SoundEnhancerBloc soundEnhancerBloc;
  final TextEditingController contentController;
  final bool isTranscriptionEnabled;
  final int micMode;
  final String historyMode;
  final Function(bool) onTranscriptionToggle;

  const SpeechToTextCard({
    super.key,
    required this.themeProvider,
    required this.soundEnhancerBloc,
    required this.contentController,
    required this.micMode,
    required this.historyMode,
    required this.isTranscriptionEnabled,
    required this.onTranscriptionToggle,
  });

  @override
  State<SpeechToTextCard> createState() => _SpeechToTextCardState();
}

class _SpeechToTextCardState extends State<SpeechToTextCard> {
  final dbHelper = DatabaseHelper();
  bool _isCollapsed = true; // Start collapsed by default
  String _lastTranscription = "";

  @override
  Widget build(BuildContext context) {
    // Only show the card if micMode == 1
    if (widget.micMode != 1) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 4,
      color: widget.themeProvider.themeData.cardColor,
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSize(context, 8),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveSize(context, 12),
        ),
      ),
      child: Column(
        children: [
          // Transcription Toggle
          buildSwitchRow(
            context.translate("sound_enhancer_transcription"),
            widget.isTranscriptionEnabled,
            onChanged: (bool enabled) {
              widget.onTranscriptionToggle(enabled);
              if (enabled) {
                widget.soundEnhancerBloc.add(StartTranscriptionEvent());
                setState(() => _isCollapsed = false);
              } else {
                widget.soundEnhancerBloc.add(StopTranscriptionEvent());
                setState(() => _isCollapsed = true);
              }
            },
          ),
          if (widget.isTranscriptionEnabled)
            AnimatedCrossFade(
              firstChild: _buildCollapsedCard(),
              secondChild: _buildExpandedCard(),
              crossFadeState: widget.isTranscriptionEnabled && !_isCollapsed
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsedCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.translate("sound_enhancer_transcription_translated_text"),
            style: TextStyle(
              color: widget.themeProvider.themeData.textTheme.bodyMedium?.color,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.expand_more),
            onPressed: () => setState(() => _isCollapsed = false),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context
                    .translate("sound_enhancer_transcription_translated_text"),
                style: TextStyle(
                  color: widget
                      .themeProvider.themeData.textTheme.bodyMedium?.color,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.expand_less),
                onPressed: () => setState(() => _isCollapsed = true),
              ),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Stack(
              children: [
                BlocBuilder<SoundEnhancerBloc, SoundEnhancerState>(
                  builder: (context, state) {
                    if (state is LivePreviewTranscriptionState) {
                      widget.contentController.text =
                          _lastTranscription + state.text;
                      widget.contentController.selection =
                          TextSelection.fromPosition(
                        TextPosition(
                            offset: widget.contentController.text.length),
                      );
                    }
                    if (state is TranscriptionUpdatedState) {
                      widget.contentController.text =
                          _lastTranscription + state.text;
                      _lastTranscription = widget.contentController.text;
                      widget.soundEnhancerBloc.add(ClearTextEvent());
                    }

                    return TextField(
                      readOnly: true,
                      controller: widget.contentController,
                      style: TextStyle(
                        color: widget.themeProvider.themeData.textTheme
                            .bodyMedium?.color,
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 16),
                      ),
                      decoration: InputDecoration(
                        hintText: context
                            .translate("sound_enhancer_transcription_hint"),
                        border: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal:
                              ResponsiveUtils.getResponsiveSize(context, 8),
                          vertical:
                              ResponsiveUtils.getResponsiveSize(context, 16),
                        ),
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    );
                  },
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
                            icon: const Icon(Icons.check,
                                size: 15, color: Colors.grey),
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
                      icon:
                          const Icon(Icons.clear, size: 15, color: Colors.grey),
                      onPressed: () {
                        if (widget.historyMode == 'Auto' &&
                            widget.contentController.text.isNotEmpty) {
                          _lastTranscription = "";
                          dbHelper.saveSpeechToTextHistory(
                              widget.contentController.text);
                        }
                        widget.contentController.clear();
                        widget.soundEnhancerBloc.add(ClearTextEvent());
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSwitchRow(
    String title,
    bool value, {
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: widget.themeProvider.themeData.textTheme.bodyMedium?.color,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
            ),
          ),
          Theme(
            data: ThemeData(
              switchTheme: SwitchThemeData(
                thumbColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (value) {
                      return widget.themeProvider.themeData.primaryColor;
                    }
                    return Colors.grey;
                  },
                ),
                trackColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (value) {
                      return widget.themeProvider.themeData.primaryColor
                          .withOpacity(0.5);
                    }
                    return Colors.grey.withOpacity(0.5);
                  },
                ),
              ),
            ),
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  void _showSaveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.translate('save_confirmation_title')),
          content: Text(context.translate('save_confirmation_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (widget.contentController.text.isNotEmpty) {
                  dbHelper
                      .saveSpeechToTextHistory(widget.contentController.text);
                }
                widget.contentController.clear();
                Navigator.pop(context);
              },
              child: Text(context.translate('save')),
            ),
          ],
        );
      },
    );
  }
}
