import 'dart:typed_data';
import 'dart:math';

class AudioUtils {
  /// Compute dB SPL and normalized 0–100 value from raw PCM16 bytes
  static Map<String, double> computeDbSpl(Uint8List rawBytes,
      {double micCalibration = 60.0}) {
    final shorts = Int16List.view(rawBytes.buffer);
    if (shorts.isEmpty) return {'dbSPL': 0.0, 'normalized': 0.0};

    // 1️⃣ RMS amplitude
    double sumSquares = 0.0;
    for (var s in shorts) {
      sumSquares += s * s;
    }
    double rms = sqrt(sumSquares / shorts.length);

    // 2️⃣ Convert RMS to dB SPL
    double dbSPL = 20 * log(rms / 32768.0) / ln10 + micCalibration;

    // 3️⃣ Normalized 0–100
    double maxRms = 32768 / sqrt(2); // full-scale sine
    double normalized = (rms / maxRms).clamp(0.0, 1.0) * 100;

    return {
      'dbSPL': dbSPL.clamp(0.0, 120.0),
      'normalized': normalized,
    };
  }
}
