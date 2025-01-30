import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Helper method for responsive font size
  static double getResponsiveFontSize(BuildContext context, double size) {
    double baseWidth = 375.0; // Reference width (e.g., iPhone 11 Pro)
    double screenWidth = MediaQuery.of(context).size.width;
    return size * (screenWidth / baseWidth);
  }

  static double getResponsiveSize(BuildContext context, double size) {
    double screenWidth = MediaQuery.of(context).size.width;
    return size *
        (screenWidth /
            375); // 375 is the reference width (e.g., iPhone 11 width)
  }
}
