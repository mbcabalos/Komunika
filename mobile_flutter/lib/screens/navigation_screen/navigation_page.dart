import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';

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
          title: 'Navigation',
          titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          isBackButton: true,
          isSettingButton: false,
        ),
    );
  }
}
