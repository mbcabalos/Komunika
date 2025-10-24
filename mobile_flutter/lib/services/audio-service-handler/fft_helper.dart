import 'dart:math';

/// Computes FFT magnitude spectrum from real PCM samples.
/// Input: List<double> of PCM values (-1.0 to 1.0)
/// Output: List<double> of magnitudes (same length)
List<double> computeFFT(List<double> input) {
  int n = input.length;

  // Ensure n is power of 2
  if ((n & (n - 1)) != 0) {
    throw Exception("Input length must be a power of 2");
  }

  // Initialize real and imaginary arrays
  List<double> real = List.from(input);
  List<double> imag = List.filled(n, 0.0);

  // Cooley-Tukey FFT
  _fftRecursive(real, imag);

  // Compute magnitudes
  List<double> mags = List.filled(n ~/ 2, 0.0);
  for (int i = 0; i < n ~/ 2; i++) {
    mags[i] = sqrt(real[i] * real[i] + imag[i] * imag[i]);
  }

  return mags;
}

void _fftRecursive(List<double> real, List<double> imag) {
  int n = real.length;
  if (n <= 1) return;

  // Divide
  List<double> evenReal = List.filled(n ~/ 2, 0.0);
  List<double> evenImag = List.filled(n ~/ 2, 0.0);
  List<double> oddReal = List.filled(n ~/ 2, 0.0);
  List<double> oddImag = List.filled(n ~/ 2, 0.0);

  for (int i = 0; i < n ~/ 2; i++) {
    evenReal[i] = real[i * 2];
    evenImag[i] = imag[i * 2];
    oddReal[i] = real[i * 2 + 1];
    oddImag[i] = imag[i * 2 + 1];
  }

  _fftRecursive(evenReal, evenImag);
  _fftRecursive(oddReal, oddImag);

  // Conquer
  for (int k = 0; k < n ~/ 2; k++) {
    double tReal =
        cos(-2 * pi * k / n) * oddReal[k] - sin(-2 * pi * k / n) * oddImag[k];
    double tImag =
        sin(-2 * pi * k / n) * oddReal[k] + cos(-2 * pi * k / n) * oddImag[k];

    real[k] = evenReal[k] + tReal;
    imag[k] = evenImag[k] + tImag;
    real[k + n ~/ 2] = evenReal[k] - tReal;
    imag[k + n ~/ 2] = evenImag[k] - tImag;
  }
}
