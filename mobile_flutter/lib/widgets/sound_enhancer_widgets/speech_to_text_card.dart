import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_sound_enhancer/sound_enhancer_bloc.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
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
  final SocketService socketService = SocketService();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    // Set up periodic connection checks
    _startConnectionMonitoring();
  }

  void _startConnectionMonitoring() {
    // Check connection every 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkConnection();
        _startConnectionMonitoring();
      }
    });
  }

  void _checkConnection() {
    setState(() {
      _isConnected = socketService.isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show the card if micMode == 1
    if (widget.micMode != 1) {
      return const SizedBox.shrink();
    }

    print("History Mode in Widget: ${widget.historyMode}");
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

          if (widget.isTranscriptionEnabled) _buildTranscriptionContent(),
        ],
      ),
    );
  }

  Widget _buildTranscriptionContent() {
    return AnimatedCrossFade(
      firstChild: _buildCollapsedCard(),
      secondChild: _buildExpandedCard(),
      crossFadeState: widget.isTranscriptionEnabled && !_isCollapsed
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
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
            child: _isConnected
                ? _buildTranscriptionArea()
                : _buildServerNotConnected(),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionArea() {
    return Stack(
      children: [
        BlocBuilder<SoundEnhancerBloc, SoundEnhancerState>(
          builder: (context, state) {
            if (state is LivePreviewTranscriptionState) {
              widget.contentController.text = _lastTranscription + state.text;
              widget.contentController.selection = TextSelection.fromPosition(
                TextPosition(offset: widget.contentController.text.length),
              );
            }
            if (state is TranscriptionUpdatedState) {
              widget.contentController.text = _lastTranscription + state.text;
              _lastTranscription = widget.contentController.text;
              widget.soundEnhancerBloc.add(ClearTextEvent());
            }

            return TextField(
              readOnly: true,
              controller: widget.contentController,
              style: TextStyle(
                color:
                    widget.themeProvider.themeData.textTheme.bodyMedium?.color,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
              ),
              decoration: InputDecoration(
                hintText:
                    context.translate("sound_enhancer_transcription_hint"),
                border: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsiveSize(context, 8),
                  vertical: ResponsiveUtils.getResponsiveSize(context, 16),
                ),
              ),
              textAlignVertical: TextAlignVertical.center,
              maxLines: null,
              keyboardType: TextInputType.multiline,
            );
          },
        ),

        // History mode buttons - Only show when connected
        if (widget.historyMode.toLowerCase() == 'manual' && _isConnected)
          Positioned(
            bottom: 0,
            right: 0,
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
                    icon: const Icon(Icons.check, size: 15, color: Colors.grey),
                    onPressed: () {
                      _showSaveConfirmationDialog();
                    },
                  ),
                ),
              ],
            ),
          ),

        // Clear button - Only show when connected
        if (_isConnected)
          Positioned(
            bottom: 0,
            right: 0 + (widget.historyMode.toLowerCase() == 'manual' ? 37 : 0),
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
                  if (widget.historyMode.toLowerCase() == 'auto' &&
                      widget.contentController.text.isNotEmpty) {
                    _lastTranscription = "";
                    dbHelper
                        .saveSpeechToTextHistory(widget.contentController.text);
                  }
                  widget.contentController.clear();
                  widget.soundEnhancerBloc.add(ClearTextEvent());
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildServerNotConnected() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Server not connected image/icon
          Icon(
            Icons.cloud_off,
            size: ResponsiveUtils.getResponsiveSize(context, 64),
            color: ColorsPalette.red,
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 16)),
          Text(
            context.translate("server_not_connected"),
            style: TextStyle(
              color: widget.themeProvider.themeData.textTheme.bodyMedium?.color,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
          Text(
            context.translate("server_not_connected_message"),
            style: TextStyle(
              color: widget.themeProvider.themeData.textTheme.bodyMedium?.color
                  ?.withOpacity(0.7),
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 16)),
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

  Future<void> _showSaveConfirmationDialog() async {
    bool confirmSave = false;
    final themeProvider = widget.themeProvider;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: themeProvider.themeData.primaryColor,
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
                  color: themeProvider.themeData.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.translate('save_confirmation_message'),
                style: TextStyle(
                  color: themeProvider.themeData.textTheme.bodySmall?.color,
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
                      Navigator.of(context).pop(false); // Return false
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
                      Navigator.of(context).pop(true); // Return true
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
    ).then((value) {
      if (value == true && mounted) {
        if (widget.contentController.text.isNotEmpty) {
          dbHelper.saveSpeechToTextHistory(widget.contentController.text);
          print(
              'Text saved to database in Manual mode: ${widget.contentController.text}');

          setState(() {
            _lastTranscription = "";
            widget.contentController.clear();
          });
          widget.soundEnhancerBloc.add(ClearTextEvent());
        }
      }
    });
  }
}
