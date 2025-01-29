import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/widgets/app_bar.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => SettingPageState();
}

class SettingPageState extends State<SettingPage> {
  String selectedTheme = 'Light';
  String selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsPalette.background,
      appBar: AppBarWidget(
        title: "Settings",
        titleSize: getResponsiveFontSize(context, 20),
        isBackButton: false,
        isSettingButton: false,
      ),
      body: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.color_lens, color: ColorsPalette.black),
                    SizedBox(width: 8),
                    Text(
                      "Themes",
                      style: TextStyle(
                          fontSize: getResponsiveFontSize(context, 15),
                          fontFamily: Fonts.main,
                          fontWeight: FontWeight.w600,
                          color: ColorsPalette.black),
                    ),
                  ],
                ),
                DropdownButton<String>(
                  value: selectedTheme,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedTheme = newValue!;
                    });
                  },
                  items: <String>['Light', 'Dark', 'Blue', 'Green', 'Red']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),

            // Language Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.language, color: ColorsPalette.black),
                    SizedBox(width: 8),
                    Text(
                      "Language",
                      style: TextStyle(
                          fontSize: getResponsiveFontSize(context, 15),
                          fontFamily: Fonts.main,
                          fontWeight: FontWeight.w600,
                          color: ColorsPalette.black),
                    ),
                  ],
                ),
                DropdownButton<String>(
                  value: selectedLanguage,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedLanguage = newValue!;
                    });
                  },
                  items: <String>['English', 'Spanish', 'French', 'German']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),

            // FAQ Section
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: GestureDetector(
                onTap: () {
                  // Navigate to FAQ page
                },
                child: Row(
                  children: [
                    const Icon(Icons.help_outline, color: ColorsPalette.black),
                    const SizedBox(width: 8),
                    Text(
                      "FAQ",
                      style: TextStyle(
                          fontSize: getResponsiveFontSize(context, 15),
                          fontFamily: Fonts.main,
                          fontWeight: FontWeight.w600,
                          color: ColorsPalette.black),
                    ),
                  ],
                ),
              ),
            ),

            // About Section
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: GestureDetector(
                onTap: () {
                  // Navigate to About page
                },
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: ColorsPalette.black),
                    const SizedBox(width: 8),
                    Text(
                      "About",
                      style: TextStyle(
                          fontSize: getResponsiveFontSize(context, 15),
                          fontFamily: Fonts.main,
                          fontWeight: FontWeight.w600,
                          color: ColorsPalette.black),
                    ),
                  ],
                ),
              ),
            ),

            // New Version Section
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: GestureDetector(
                onTap: () {
                  // Navigate to About page
                },
                child: Row(
                  children: [
                    const Icon(Icons.update, color: ColorsPalette.black),
                    const SizedBox(width: 8),
                    Text(
                      "New version available",
                      style: TextStyle(
                          fontSize: getResponsiveFontSize(context, 15),
                          fontFamily: Fonts.main,
                          fontWeight: FontWeight.w600,
                          color: ColorsPalette.black),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double getResponsiveFontSize(BuildContext context, double size) {
    double baseWidth = 375.0; // Reference width (e.g., iPhone 11 Pro)
    double screenWidth = MediaQuery.of(context).size.width;
    return size * (screenWidth / baseWidth);
  }
}
