import 'package:flutter/foundation.dart';

import 'speex_denoiser.dart';

class DenoiseArgs {
  final List<int> samples;
  final int frameSize;
  final int sampleRate;

  DenoiseArgs({
    required this.samples,
    required this.frameSize,
    required this.sampleRate,
  });
}

Future<List<int>> runDenoiseInIsolate(DenoiseArgs args) async {
  return await compute(_denoiseWorker, args);
}

List<int> _denoiseWorker(DenoiseArgs args) {
  final denoiser = SpeexDenoiser(
    frameSize: args.frameSize,
    sampleRate: args.sampleRate,
  );
  final output = denoiser.denoise(args.samples);
  denoiser.dispose();
  return output;
}
