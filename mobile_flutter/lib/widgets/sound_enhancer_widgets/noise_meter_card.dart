import 'package:flutter/material.dart';

class NoiseMeterWidget extends StatelessWidget {
  final double db; // Current decibel level (measured)
  final bool isActive;

  const NoiseMeterWidget({
    super.key,
    required this.db,
    required this.isActive,
  });

  /// Normalize inverted dB range (your real mic gives ~89 quiet → 76 loud)
  double normalizeDb(double db) {
    const minDb = 89.0; // quietest (highest numeric value)
    const maxDb = 76.0; // loudest (lowest numeric value)

    // invert mapping: 89 → 0.0, 76 → 1.0
    final normalized = (minDb - db) / (minDb - maxDb);
    return normalized.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeDb(db);
    final barColor = isActive ? _getColorFromLevel(normalized) : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Noise Level",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Icon(
              isActive ? Icons.mic : Icons.mic_off,
              color: isActive ? barColor : Colors.grey,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Horizontal Noise Line
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 16,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green,
                  Colors.yellow,
                  Colors.orange,
                  Colors.red,
                ],
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: MediaQuery.of(context).size.width * normalized,
                decoration: BoxDecoration(
                  color: isActive ? barColor : Colors.grey,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Labels for 4 levels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Quiet", style: TextStyle(fontSize: 12)),
            Text("Normal", style: TextStyle(fontSize: 12)),
            Text("Noisy", style: TextStyle(fontSize: 12)),
            Text("Very Noisy", style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  /// Returns color based on normalized level
  Color _getColorFromLevel(double level) {
    if (level < 0.25) return Colors.green;
    if (level < 0.5) return Colors.yellow;
    if (level < 0.75) return Colors.orange;
    return Colors.red;
  }
}
