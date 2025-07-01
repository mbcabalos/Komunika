import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_sound_enhancer/sound_enhancer_bloc.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';

class SpeechToTextCard extends StatefulWidget {
  final ThemeProvider themeProvider;
  final SoundEnhancerBloc soundEnhancerBloc;
  final TextEditingController textController;
  final bool isTranscriptionEnabled;

  const SpeechToTextCard({
    super.key,
    required this.themeProvider,
    required this.soundEnhancerBloc,
    required this.textController,
    required this.isTranscriptionEnabled,
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
    if (!widget.isTranscriptionEnabled) {
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
      child: AnimatedCrossFade(
        firstChild: _buildCollapsedCard(),
        secondChild: _buildExpandedCard(),
        crossFadeState:
            _isCollapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        duration: const Duration(milliseconds: 200),
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
            "Transcription",
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
                "Transcription",
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
                      widget.textController.text =
                          _lastTranscription + state.text;
                      widget.textController.selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: widget.textController.text.length),
                      );
                    }
                    if (state is TranscriptionUpdatedState) {
                      widget.textController.text =
                          _lastTranscription + state.text;
                      _lastTranscription = widget.textController.text;
                      widget.soundEnhancerBloc.add(ClearTextEvent());
                    }

                    return TextField(
                      readOnly: true,
                      controller: widget.textController,
                      style: TextStyle(
                        color: widget.themeProvider.themeData.textTheme
                            .bodyMedium?.color,
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 16),
                      ),
                      decoration: InputDecoration(
                        hintText: context.translate("sound_enhancer_hint"),
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
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon:
                          const Icon(Icons.clear, size: 16, color: Colors.grey),
                      onPressed: () {
                        dbHelper.saveSpeechToTextHistory(
                            widget.textController.text);
                        widget.textController.clear();
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
}
