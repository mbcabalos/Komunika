import 'package:flutter/foundation.dart';
import 'package:komunika/services/live-service-handler/speexdsp_helper.dart';

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
  final denoiser = SpeexDSP(
    frameSize: args.frameSize,
    sampleRate: args.sampleRate,
  );
  final output = denoiser.processFrame(args.samples);
  denoiser.dispose();
  return output;
}
