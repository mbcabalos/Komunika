import 'package:flutter/material.dart';
import 'package:komunika/bloc/bloc_sound_enhancer/sound_enhancer_bloc.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:headset_connection_event/headset_event.dart';
import 'package:permission_handler/permission_handler.dart';

class SoundAmplifierCard extends StatefulWidget {
  final ThemeProvider themeProvider;
  final SoundEnhancerBloc soundEnhancerBloc;
  final int micMode;
  final ValueChanged<int> onMicModeChanged;

  const SoundAmplifierCard({
    super.key,
    required this.themeProvider,
    required this.micMode,
    required this.onMicModeChanged,
    required this.soundEnhancerBloc,
  });

  @override
  State<SoundAmplifierCard> createState() => _SoundAmplifierCardState();
}

class _SoundAmplifierCardState extends State<SoundAmplifierCard>
    with WidgetsBindingObserver {
  double _amplifierVolumeLevel = 1.0;
  double _audioBalanceLevel = 0.5;
  bool isNoiseSupressorActive = false;
  bool isAGCActive = false;
  bool isVADActive = false;
  bool _isHeadsetConnected = false;
  final _headsetEvent = HeadsetEvent();
  HeadsetState? _headsetState;
  bool get _isAnyHeadsetConnected => _isHeadsetConnected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initHeadsetDetection();
    _loadEnhancerSharedPrefValues();
  }

  Future<void> _initHeadsetDetection() async {
    // Request permission for Android 12+
    await _headsetEvent.requestPermission();

    // Get initial state
    final currentState = await _headsetEvent.getCurrentState;
    setState(() {
      _headsetState = currentState;
      _isHeadsetConnected = currentState == HeadsetState.CONNECT;
    });

    // If disconnected at startup, ensure mic is off
    if (!_isHeadsetConnected) {
      widget.onMicModeChanged(0);
      widget.soundEnhancerBloc.add(StopRecordingEvent());
    }

    // Listen for headset changes
    _headsetEvent.setListener((HeadsetState state) {
      setState(() {
        _headsetState = state;
        _isHeadsetConnected = state == HeadsetState.CONNECT;
      });

      if (_isHeadsetConnected) {
        if (widget.micMode == 1) {
          widget.soundEnhancerBloc.add(StopRecordingEvent());
          Future.delayed(const Duration(milliseconds: 500), () {
            widget.soundEnhancerBloc.add(StartRecordingEvent());
          });
        }
      } else {
        widget.onMicModeChanged(0);
        widget.soundEnhancerBloc.add(StopRecordingEvent());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _headsetEvent.getCurrentState.then((value) {
        setState(() {
          _headsetState = value;
          _isHeadsetConnected = value == HeadsetState.CONNECT;
        });
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _showHeadsetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.themeProvider.themeData.cardColor,
        title:
            Text(context.translate("sound_enhancer_amplifier_warning_title")),
        content: Text(
          context.translate("sound_enhancer_amplifier_warning_content"),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: widget.themeProvider.themeData.primaryColor,
              foregroundColor:
                  widget.themeProvider.themeData.textTheme.bodySmall?.color,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadEnhancerSharedPrefValues() async {
    try {
      final prefs = await Future.wait([
        PreferencesUtils.getNoiseReductionEnabled(),
        PreferencesUtils.getAGCEnabled(),
        PreferencesUtils.getAmplifierVolume(),
        PreferencesUtils.getVADEnabled(),
      ]);
      if (mounted) {
        setState(() {
          isNoiseSupressorActive = prefs[0] as bool;
          isAGCActive = prefs[1] as bool;
          _amplifierVolumeLevel = prefs[2] as double;
          if (isNoiseSupressorActive) {
            isVADActive = prefs[3] as bool;
          } else {
            isVADActive = false;
          }
        });
      }
      widget.soundEnhancerBloc.add(
        prefs[0] as bool
            ? StartNoiseSupressorEvent()
            : StopNoiseSupressorEvent(),
      );
      widget.soundEnhancerBloc.add(
        prefs[1] as bool ? StartAGCEvent() : StopAGCEvent(),
      );
    } catch (e) {
      debugPrint('Error loading enhancer values: $e');
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

  Future<void> _storeAudioBalanceLevel(double balance) async {
    try {
      await PreferencesUtils.storeAudioBalanceLevel(balance);
      debugPrint('Volume stored: $balance');
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
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            context.translate("sound_enhancer_amplifier_off"),
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context, 14),
                              color: widget.themeProvider.themeData.textTheme
                                  .bodyMedium?.color,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context
                                    .translate("sound_enhancer_amplifier_on"),
                                style: TextStyle(
                                  fontSize:
                                      ResponsiveUtils.getResponsiveFontSize(
                                          context, 14),
                                  color: widget.themeProvider.themeData
                                      .textTheme.bodyMedium?.color,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _isAnyHeadsetConnected
                                    ? Icons.headset
                                    : Icons.headset_off,
                                size: ResponsiveUtils.getResponsiveSize(
                                    context, 16),
                                color: _isAnyHeadsetConnected
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ],
                      onPressed: (index) async {
                        // if (index == 1 && !_isAnyHeadsetConnected) {
                        //   _showHeadsetDialog();
                        //   return;
                        // }

                        widget.onMicModeChanged(index);

                        if (index == 0) {
                          widget.soundEnhancerBloc.add(StopRecordingEvent());
                          return;
                        }
                        if (index == 1) {
                          // --- 1) Microphone permission ---
                          var micStatus = await Permission.microphone.status;
                          if (!micStatus.isGranted) {
                            micStatus = await Permission.microphone.request();
                            if (!micStatus.isGranted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Microphone permission denied")),
                              );
                              // revert toggle back to 0
                              widget.onMicModeChanged(0);
                              return;
                            }
                          }

                          // --- 2) Notification permission (Android 13+) ---
                          var notifStatus =
                              await Permission.notification.status;
                          if (!notifStatus.isGranted) {
                            notifStatus =
                                await Permission.notification.request();
                            if (!notifStatus.isGranted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Notification permission denied")),
                              );
                              // revert toggle back to 0
                              widget.onMicModeChanged(0);
                              return;
                            }
                          }

                          // All checks passed -> start recording
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
                    context
                        .translate("sound_enhancer_amplifier_noise_reduction"),
                    isNoiseSupressorActive,
                    onChanged: (bool enabled) {
                      setState(() {
                        isNoiseSupressorActive = enabled;
                        if (!enabled) {
                          isVADActive = false;
                          widget.soundEnhancerBloc.add(StopVADEvent());
                        }
                      });
                      if (enabled) {
                        widget.soundEnhancerBloc
                            .add(StartNoiseSupressorEvent());
                      } else {
                        widget.soundEnhancerBloc.add(StopNoiseSupressorEvent());
                      }
                    },
                  ),

                  const SizedBox(height: 12),
                  Opacity(
                    opacity: isNoiseSupressorActive ? 1.0 : 0.5,
                    child: IgnorePointer(
                      ignoring: !isNoiseSupressorActive,
                      child: buildSwitchRow(
                        context.translate("Voice Activity Detection"),
                        isVADActive,
                        onChanged: (bool enabled) {
                          setState(() {
                            isVADActive = enabled;
                          });

                          if (enabled) {
                            widget.soundEnhancerBloc.add(StartVADEvent());
                          } else {
                            widget.soundEnhancerBloc.add(StopVADEvent());
                          }
                        },
                      ),
                    ),
                  ),
                  // AGC Toggle
                  const SizedBox(height: 12),
                  buildSwitchRow(
                    context.translate("AGC (Automatic Gain Control)"),
                    isAGCActive,
                    onChanged: (bool enabled) {
                      setState(() {
                        isAGCActive = enabled;
                      });
                      if (enabled) {
                        widget.soundEnhancerBloc.add(StartAGCEvent());
                      } else {
                        widget.soundEnhancerBloc.add(StopAGCEvent());
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Amplifier Level
                  buildAmplifierSlider(widget.themeProvider),
                  const SizedBox(height: 12),

                  // Audio Balance
                  buildBalanceSliderRow(
                      context
                          .translate("sound_enhancer_amplifier_audio_balance"),
                      0.5,
                      Icons.volume_up,
                      labelL: 'L',
                      labelR: 'R'),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      _isAnyHeadsetConnected
                          ? context
                              .translate("sound_enhancer_amplifier_connected")
                          : context.translate(
                              "sound_enhancer_amplifier_disconnected"),
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
        Text(
          title,
          style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
              color:
                  widget.themeProvider.themeData.textTheme.bodyMedium?.color),
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
    );
  }

  Widget buildAmplifierSlider(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.translate("sound_enhancer_amplifier_amplifier_level"),
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

  Widget buildBalanceSliderRow(String title, double value, IconData icon,
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
                value: _audioBalanceLevel.clamp(0.0, 1.0),
                onChanged: (double value) {
                  setState(() {
                    _audioBalanceLevel = value;
                  });
                  _storeAudioBalanceLevel(value);
                  widget.soundEnhancerBloc.add(
                    SetAudioBalanceLevel(value),
                  );
                },
              ),
            )),
            if (labelR.isNotEmpty) Text(labelR),
          ],
        ),
      ],
    );
  }
}
