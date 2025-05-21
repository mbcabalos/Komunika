import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_speech_to_text/speech_to_text_bloc.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/history.dart';

class SpeechToTextPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  final SpeechToTextBloc speechToTextBloc;
  const SpeechToTextPage(
      {super.key, required this.themeProvider, required this.speechToTextBloc});

  @override
  State<SpeechToTextPage> createState() => SpeechToTextPageState();
}

class SpeechToTextPageState extends State<SpeechToTextPage> {
  final TextEditingController _textController = TextEditingController();
  String _lastTranscription = "";
  final dbHelper = DatabaseHelper();
  bool _isRecording = false;
  double _volumeLevel = 1;

  @override
  void initState() {
    super.initState();
    _textController.clear();
    _initialize();
    _loadVolume();
  }

  Future<void> _initialize() async {
    widget.speechToTextBloc.add(SpeechToTextLoadingEvent());
    widget.speechToTextBloc.add(RequestPermissionEvent());
  }

  Future<void> _loadVolume() async {
    try {
      final volume = await PreferencesUtils.getAmplifierVolume();
      if (mounted) {
        setState(() {
          _volumeLevel = volume;
        });
      }
    } catch (e) {
      debugPrint('Error loading volume: $e');
      // Keep default value
    }
  }

  void _toggleTapRecording() {
    if (!_isRecording) {
      setState(() {
        _isRecording = true;
      });
      widget.speechToTextBloc.add(StartTapRecordingEvent());
    } else {
      setState(() {
        _isRecording = false;
      });
      widget.speechToTextBloc.add(StopTapRecordingEvent());
    }
  }

  void _startRecording() {
    setState(() => _isRecording = true);
    widget.speechToTextBloc.add(StartRecordingEvent());
  }

  void _stopRecording() {
    setState(() => _isRecording = false);
    widget.speechToTextBloc.add(StopRecordingEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.speechToTextBloc,
      child: Scaffold(
        backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(top: 7.0),
            child: Text(
              context.translate("stt_title"),
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
              ),
            ),
          ),
          leading: Padding(
            padding: EdgeInsets.only(
              top: ResponsiveUtils.getResponsiveSize(context, 7),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: ResponsiveUtils.getResponsiveSize(context, 10),
              ),
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  dbHelper.saveSpeechToTextHistory(_textController.text);
                }
                _textController.clear();
                widget.speechToTextBloc.add(StopTapRecordingEvent());
                Navigator.pop(context);
              },
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(
                top: ResponsiveUtils.getResponsiveSize(context, 7),
                right: ResponsiveUtils.getResponsiveSize(context, 8),
              ),
              child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryPage(
                          themeProvider: widget.themeProvider,
                          database: 'stt',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history_rounded)),
            ),
          ],
        ),
        body: BlocConsumer<SpeechToTextBloc, SpeechToTextState>(
          listener: (context, state) {
            if (state is SpeechToTextErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is SpeechToTextLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SpeechToTextLoadedSuccessState) {
              return _buildContent(widget.themeProvider);
            } else if (state is SpeechToTextErrorState) {
              return const Text('Error processing text to speech!');
            } else {
              return _buildContent(widget.themeProvider);
            }
          },
        ),
      ),
    );
  }

  Widget _buildContent(ThemeProvider themeProvider) {
    final double phoneHeight = MediaQuery.of(context).size.height * 0.6;
    return RefreshIndicator.adaptive(
      onRefresh: _initialize,
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.getResponsiveSize(context, 16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: phoneHeight,
              child: BlocBuilder<SpeechToTextBloc, SpeechToTextState>(
                builder: (context, state) {
                  if (state is LivePreviewTranscriptionState) {
                    _textController.clear();
                    _textController.text = _lastTranscription + state.text;
                    _textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _textController.text.length));
                  }
                  if (state is TranscriptionUpdatedState) {
                    _textController.text = _lastTranscription + state.text;
                    _lastTranscription = _textController.text;
                    widget.speechToTextBloc.add(ClearTextEvent());
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: themeProvider.themeData.cardColor,
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
                          readOnly: true,
                          controller: _textController,
                          style: TextStyle(
                            color: themeProvider
                                .themeData.textTheme.bodyMedium?.color,
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context, 20),
                          ),
                          decoration: InputDecoration(
                            hintText: context.translate("stt_hint"),
                            border: InputBorder.none,
                            fillColor: Colors.transparent,
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getResponsiveSize(
                                  context, 12),
                              vertical: ResponsiveUtils.getResponsiveSize(
                                  context, 16),
                            ),
                          ),
                          textAlignVertical: TextAlignVertical.center,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
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
                              icon: const Icon(Icons.clear,
                                  size: 16, color: Colors.grey),
                              onPressed: () {
                                // Clear the text field
                                dbHelper.saveSpeechToTextHistory(
                                    _textController.text);
                                _textController.clear();
                                widget.speechToTextBloc.add(ClearTextEvent());
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: ResponsiveUtils.getResponsiveSize(context, 40),
            ),
            // Microphone and Text
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: _toggleTapRecording,
                    onLongPress: _startRecording,
                    onLongPressUp: _stopRecording,
                    child: Container(
                      width: ResponsiveUtils.getResponsiveSize(context, 80),
                      height: ResponsiveUtils.getResponsiveSize(context, 80),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeProvider.themeData.primaryColor,
                      ),
                      child: Icon(
                        _isRecording ? Icons.graphic_eq_rounded : Icons.mic,
                        color: Colors.white,
                        size: ResponsiveUtils.getResponsiveSize(context, 60),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSize(context, 10),
                ),
                Text(
                  context.translate("stt_hold_microphone"),
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 15),
                    fontFamily: Fonts.main,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildVolumeSlider(themeProvider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeSlider(ThemeProvider themeProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSize(context, 40),
      ),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: themeProvider.themeData.primaryColor,
              inactiveTrackColor:
                  themeProvider.themeData.primaryColor.withOpacity(0.2),
              trackHeight: ResponsiveUtils.getResponsiveSize(context, 3),
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius:
                    ResponsiveUtils.getResponsiveSize(context, 10),
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: ResponsiveUtils.getResponsiveSize(context, 16),
              ),
            ),
            child: Slider(
              value: _volumeLevel.clamp(
                  0.0, 3.0), // Ensure value stays within bounds
              min: 0,
              max: 3,
              divisions: 6,
              label: '${_volumeLevel.toStringAsFixed(1)}x',
              onChanged: (double value) {
                setState(() {
                  _volumeLevel = value;
                });
                // Fire-and-forget the storage operation
                _storeVolume(value).catchError((e) {
                  debugPrint('Error storing volume: $e');
                });
                context.read<SpeechToTextBloc>().add(SetAmplificationEvent(value));
              },
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Volume: ${_volumeLevel.toStringAsFixed(1)}x',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              color: themeProvider.themeData.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _storeVolume(double volume) async {
    try {
      await PreferencesUtils.storeAmplifierVolume(volume);
      debugPrint('Volume stored: $volume');
    } catch (e) {
      debugPrint('Error storing volume: $e');
      rethrow;
    }
  }
}
