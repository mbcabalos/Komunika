import 'package:flutter/material.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';

class SoundVisualizationCard extends StatelessWidget {
  final ThemeProvider themeProvider;
  final bool isActive;
  final List<double> barHeights; // <-- updated

  const SoundVisualizationCard({
    super.key,
    required this.themeProvider,
    required this.isActive,
    required this.barHeights,
  });

  @override
  Widget build(BuildContext context) {
    final theme = themeProvider.themeData;

    return Card(
      elevation: 2,
      color: theme.cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Sound Visualization"),
                Icon(
                  isActive ? Icons.mic : Icons.mic_off,
                  color:
                      isActive ? Theme.of(context).primaryColor : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(barHeights.length, (index) {
                  final scaledHeight =
                      barHeights[index] * 25; // temporarily scale higher
                  final height = scaledHeight.clamp(
                      2.0, 70.0); // min 2, max container height

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 10,
                      height: height,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
