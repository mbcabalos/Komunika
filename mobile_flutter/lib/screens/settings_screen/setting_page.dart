import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/widgets/app_bar.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsPalette.background,
      appBar: const AppBarWidget(
          title: "Settings",
          titleSize: 25,
          isBackButton: false,
          isSettingButton: false),
      
    );
  }
}