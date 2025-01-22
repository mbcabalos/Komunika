import 'package:flutter/material.dart';
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
      appBar: AppBarWidget(title: "Komunika", isBackButton: false, isSettingButton: false),
      
    );
  }
}