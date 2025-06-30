import 'package:flutter/material.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';

class SoundAmplifierScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const SoundAmplifierScreen({
    super.key,
    required this.themeProvider,
  });

  @override
  State<SoundAmplifierScreen> createState() => _SoundAmplifierScreenState();
}

class _SoundAmplifierScreenState extends State<SoundAmplifierScreen> {
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
                      isSelected: const [true, false, false],
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
                      onPressed: (index) {},
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Noise Reduction Toggle
                buildSwitchRow("Noise Reduction", true),
                const SizedBox(height: 12),

                // Transcription Toggle
                buildSwitchRow("Transcription", true),
                const SizedBox(height: 12),

                // Amplifier Level
                buildSliderRow("Amplifier Level", 0.5, Icons.equalizer),
                const SizedBox(height: 12),

                // Audio Balance
                buildSliderRow("Audio Balance", 0.5, Icons.volume_up,
                    labelL: 'L', labelR: 'R'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildSwitchRow(String title, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Theme(
          data: ThemeData(
              switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.all(
                widget.themeProvider.themeData.primaryColor),
            trackColor: WidgetStateProperty.all(
                widget.themeProvider.themeData.primaryColor.withOpacity(0.5)),
          )),
          child: Switch(value: value, onChanged: (v) {}),
        )
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
