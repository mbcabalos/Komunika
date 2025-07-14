import 'package:flutter/material.dart';
import 'package:komunika/bloc/bloc_sound_enhancer/sound_enhancer_bloc.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/utils/shared_prefs.dart';

class SoundAmplifierScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  final SoundEnhancerBloc soundEnhancerBloc;
  final int micMode;
  final ValueChanged<int> onMicModeChanged;

  const SoundAmplifierScreen({
    super.key,
    required this.themeProvider,
    required this.micMode,
    required this.onMicModeChanged,
    required this.soundEnhancerBloc,
  });

  @override
  State<SoundAmplifierScreen> createState() => _SoundAmplifierScreenState();
}

class _SoundAmplifierScreenState extends State<SoundAmplifierScreen> {
  double _amplifierVolumeLevel = 1.0;
  bool isNoiseSupressorActive = false;
  double _noiseReductionLevel = 0.5;

  @override
  void initState() {
    super.initState();
    _loadAmplifierVolume();
  }

  Future<void> _loadAmplifierVolume() async {
    try {
      final volume = await PreferencesUtils.getAmplifierVolume();
      if (mounted) {
        setState(() {
          _amplifierVolumeLevel = volume;
        });
      }
    } catch (e) {
      debugPrint('Error loading volume: $e');
    }
  }

  Future<void> _storeAmplifierVolume(double volume) async {
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
                          child: Text("Microphone (Phone / Headset)"),
                        ),
                      ],
                      onPressed: (index) {
                        widget.onMicModeChanged(index);
                        if (index == 0) {
                          widget.soundEnhancerBloc.add(StopRecordingEvent());
                        } else if (index == 1) {
                          widget.soundEnhancerBloc.add(StartRecordingEvent());
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                if (widget.micMode != 0) ...[
                  // Noise Reduction Toggle
                  buildSwitchRow(
                    "Noise Reduction",
                    isNoiseSupressorActive,
                    onChanged: (bool enabled) {
                      setState(() {
                        isNoiseSupressorActive = enabled;
                      });
                      if (enabled) {
                        widget.soundEnhancerBloc.add(StartNoiseSupressor());
                      } else {
                        widget.soundEnhancerBloc.add(StopNoiseSupressor());
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  // Noise Reduction Slider (always visible but conditionally enabled)
                  buildNoiseReductionSlider(),
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

  Widget buildNoiseReductionSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Noise Reduction Level',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                color: isNoiseSupressorActive
                    ? null
                    : Colors.grey, // Grey out text when disabled
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.noise_control_off,
              size: ResponsiveUtils.getResponsiveSize(context, 18),
              color: isNoiseSupressorActive
                  ? null
                  : Colors.grey, // Grey out icon when disabled
            ),
          ],
        ),
        Row(
          children: [
            Text('Low',
                style: TextStyle(
                  color: isNoiseSupressorActive ? null : Colors.grey,
                )),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  sliderTheme: SliderTheme.of(context).copyWith(
                    activeTrackColor: isNoiseSupressorActive
                        ? widget.themeProvider.themeData.primaryColor
                        : Colors.grey,
                    inactiveTrackColor: isNoiseSupressorActive
                        ? widget.themeProvider.themeData.primaryColor
                            .withOpacity(0.5)
                        : Colors.grey.withOpacity(0.3),
                    thumbColor: isNoiseSupressorActive
                        ? widget.themeProvider.themeData.primaryColor
                        : Colors.grey,
                    disabledActiveTrackColor: Colors.grey,
                    disabledThumbColor: Colors.grey,
                    disabledInactiveTrackColor: Colors.grey.withOpacity(0.3),
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
                  value: _noiseReductionLevel,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  label: '${(_noiseReductionLevel * 100).round()}%',
                  onChanged: isNoiseSupressorActive
                      ? (double value) {
                          setState(() {
                            _noiseReductionLevel = value;
                          });
                        }
                      : null, // Disable slider when noise reduction is off
                ),
              ),
            ),
            Text('High',
                style: TextStyle(
                  color: isNoiseSupressorActive ? null : Colors.grey,
                )),
          ],
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
                  value: _amplifierVolumeLevel.clamp(0.0, 3.0),
                  min: 0,
                  max: 3,
                  divisions: 6,
                  label: '${_amplifierVolumeLevel.toStringAsFixed(1)}x',
                  onChanged: (double value) {
                    setState(() {
                      _amplifierVolumeLevel = value;
                    });
                    _storeAmplifierVolume(value);
                    widget.soundEnhancerBloc.add(
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
