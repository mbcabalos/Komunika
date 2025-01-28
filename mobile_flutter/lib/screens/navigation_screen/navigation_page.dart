import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/widgets/app_bar.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsPalette.background,
      appBar: AppBarWidget(
          title: "Navigation",
          titleSize: getResponsiveFontSize(context, 15),
          isBackButton: false,
          isSettingButton: false),
    );
  }
  double getResponsiveFontSize(BuildContext context, double size) {
    double baseWidth = 375.0; // Reference width (e.g., iPhone 11 Pro)
    double screenWidth = MediaQuery.of(context).size.width;
    return size * (screenWidth / baseWidth);
  }
}
