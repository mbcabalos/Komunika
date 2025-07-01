import 'package:flutter/material.dart';
import 'package:komunika/bloc/bloc_speech_to_text/speech_to_text_bloc.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/utils/shared_prefs.dart';

class SoundAmplifierScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  final SpeechToTextBloc speechToTextBloc;
  final int micMode;
  final ValueChanged<int> onMicModeChanged;
  final bool isTranscriptionEnabled;
  final ValueChanged<bool> onTranscriptionToggle;

  const SoundAmplifierScreen({
    super.key,
    required this.themeProvider,
    required this.micMode,
    required this.onMicModeChanged,
    required this.speechToTextBloc,
    required this.isTranscriptionEnabled,
    required this.onTranscriptionToggle,
  });

  @override
  State<SoundAmplifierScreen> createState() => _SoundAmplifierScreenState();
}

class _SoundAmplifierScreenState extends State<SoundAmplifierScreen> {
  double _volumeLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _loadVolume();
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
    }
  }

  Future<void> _storeVolume(double volume) async {
    try {
      await PreferencesUtils.storeAmplifierVolume(volume);
      debugPrint('Volume stored: $volume');
    } catch (e) {
      debugPrint('Error storing volume: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 2,
          color: widget.themeProvider.themeData.cardColor,
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getResponsiveSize(context, 8),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Mic Mode Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ToggleButtons(
                      borderRadius: BorderRadius.circular(12),
                      isSelected: [
                        widget.micMode == 0,
                        widget.micMode == 1,
                        widget.micMode == 2,
                      ],
                      color: widget.themeProvider.themeData.primaryColor,
                      selectedColor: widget
                          .themeProvider.themeData.scaffoldBackgroundColor,
                      fillColor: widget.themeProvider.themeData.primaryColor,
                      borderColor: widget.themeProvider.themeData.primaryColor,
                      selectedBorderColor:
                          widget.themeProvider.themeData.primaryColor,
                      splashColor: widget.themeProvider.themeData.primaryColor
                          .withOpacity(0.3),
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Off"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Phone Mic"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Headset Mic"),
                        ),
                      ],
                      onPressed: (index) {
                        widget.onMicModeChanged(index);
                        if (index == 0) {
                          widget.speechToTextBloc.add(StopRecordingEvent());
                        } else if (index == 1) {
                          widget.speechToTextBloc.add(StartTapRecordingEvent());
                        } else if (index == 2) {
                          widget.speechToTextBloc.add(StartTapRecordingEvent());
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                if (widget.micMode != 0) ...[
                  // Noise Reduction Toggle
                  buildSwitchRow("Noise Reduction", false),
                  const SizedBox(height: 12),

                  // Transcription Toggle
                  buildSwitchRow(
                    "Transcription",
                    widget.isTranscriptionEnabled,
                    onChanged: widget.onTranscriptionToggle,
                  ),
                  const SizedBox(height: 12),

                  // Amplifier Level
                  buildAmplifierSlider(widget.themeProvider),
                  const SizedBox(height: 12),

                  // Audio Balance
                  buildSliderRow("Audio Balance", 0.5, Icons.volume_up,
                      labelL: 'L', labelR: 'R'),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      "Please select a mic mode to enable sound enhancement features.",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 14),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildSwitchRow(String title, bool value,
      {ValueChanged<bool>? onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Theme(
          data: ThemeData(
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (value) {
                    return widget.themeProvider.themeData.primaryColor;
                  }
                  return Colors.grey; // Grey when off
                },
              ),
              trackColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (value) {
                    return widget.themeProvider.themeData.primaryColor
                        .withOpacity(0.5);
                  }
                  return Colors.grey.withOpacity(0.5); // Grey when off
                },
              ),
            ),
          ),
          child: Switch(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget buildAmplifierSlider(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Amplifier Level',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.equalizer,
              size: ResponsiveUtils.getResponsiveSize(context, 18),
            ),
          ],
        ),
        Row(
          children: [
            Text('0x'),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  sliderTheme: SliderTheme.of(context).copyWith(
                    activeTrackColor: themeProvider.themeData.primaryColor,
                    inactiveTrackColor:
                        themeProvider.themeData.primaryColor.withOpacity(0.5),
                    thumbColor: themeProvider.themeData.primaryColor,
                    trackHeight: ResponsiveUtils.getResponsiveSize(context, 3),
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius:
                          ResponsiveUtils.getResponsiveSize(context, 10),
                    ),
                    overlayShape: RoundSliderOverlayShape(
                      overlayRadius:
                          ResponsiveUtils.getResponsiveSize(context, 16),
                    ),
                  ),
                ),
                child: Slider(
                  value: _volumeLevel.clamp(0.0, 3.0),
                  min: 0,
                  max: 3,
                  divisions: 6,
                  label: '${_volumeLevel.toStringAsFixed(1)}x',
                  onChanged: (double value) {
                    setState(() {
                      _volumeLevel = value;
                    });
                    _storeVolume(value);
                    widget.speechToTextBloc.add(
                      SetAmplificationEvent(value),
                    );
                  },
                ),
              ),
            ),
            Text('3x'),
          ],
        ),
      ],
    );
  }

  Widget buildSliderRow(String title, double value, IconData icon,
      {String labelL = '', String labelR = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Icon(icon, size: 18),
          ],
        ),
        Row(
          children: [
            if (labelL.isNotEmpty) Text(labelL),
            Expanded(
                child: Theme(
              data: ThemeData(
                  sliderTheme: SliderThemeData(
                activeTrackColor: widget.themeProvider.themeData.primaryColor,
                inactiveTrackColor: widget.themeProvider.themeData.primaryColor
                    .withOpacity(0.5),
                thumbColor: widget.themeProvider.themeData.primaryColor,
              )),
              child: Slider(
                value: value,
                onChanged: (v) {},
              ),
            )),
            if (labelR.isNotEmpty) Text(labelR),
          ],
        ),
      ],
    );
  }
}
