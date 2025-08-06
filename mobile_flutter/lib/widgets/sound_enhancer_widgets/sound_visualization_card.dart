import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';

class SoundVisualizationCard extends StatefulWidget {
  final ThemeProvider themeProvider;
  final bool isActive;

  const SoundVisualizationCard({
    super.key,
    required this.themeProvider,
    required this.isActive,
  });

  @override
  State<SoundVisualizationCard> createState() => _SoundVisualizationCardState();
}

class _SoundVisualizationCardState extends State<SoundVisualizationCard> {
  late final RecorderController recorderController;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() async {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;

    if (widget.isActive) {
      await recorderController.record();
    }
  }

  @override
  void didUpdateWidget(covariant SoundVisualizationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        recorderController.record();
      } else {
        recorderController.stop();
      }
    }
  }

  @override
  void dispose() {
    recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.translate("sound_enhancer_visualization"),
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 16),
                  ),
                ),
                Icon(
                  widget.isActive ? Icons.mic : Icons.mic_off,
                  color: widget.isActive
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: AudioWaveforms(
                size: Size(ResponsiveUtils.getResponsiveSize(context, 300),
                    ResponsiveUtils.getResponsiveSize(context, 120)),
                recorderController: recorderController,
                waveStyle: WaveStyle(
                  extendWaveform: true,
                  showMiddleLine: false,
                  waveColor: Theme.of(context).primaryColor,
                  gradient: _createGradient(context),
                ),
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Shader _createGradient(BuildContext context) {
    return LinearGradient(
      colors: [
        Theme.of(context).primaryColor.withOpacity(0.8),
        Theme.of(context).primaryColor,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(const Rect.fromLTWH(0, 0, 300, 100));
  }
}
