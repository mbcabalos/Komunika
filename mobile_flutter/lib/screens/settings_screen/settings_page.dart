import 'package:flutter/material.dart';
import 'package:komunika/screens/settings_screen/settings_FAQ_page.dart';
import 'package:komunika/screens/settings_screen/settings_about_page.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:provider/provider.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/themes.dart';
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        selectedTheme = themeProvider.selectedTheme;
        return Scaffold(
          backgroundColor: themeProvider.themeData.scaffoldBackgroundColor,
          appBar: AppBarWidget(
          title: 'Settings',
          titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          isBackButton: true,
          isSettingButton: false,
        ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Appearance", themeProvider),
                _buildSettingItem(
                  themeProvider: themeProvider,
                  icon: Icons.color_lens,
                  title: "Theme",
                  trailing: DropdownButton<String>(
                    value: selectedTheme,
                    onChanged: (String? newValue) async {
                      setState(() {
                        selectedTheme = newValue!;
                      });
                      themeProvider.setTheme(newValue.toString());
                      await PreferencesUtils.storeTheme(newValue.toString());
                      String theme = await PreferencesUtils.getTheme();
                      print(theme);
                    },
                    items: <String>['Light', 'Dark']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 14,
                            color: themeProvider
                                .themeData.textTheme.bodyMedium?.color,
                          ),
                        ),
                      );
                    }).toList(),
                    underline: Container(),
                  ),
                ),
                _buildSectionHeader("Language & Region", themeProvider),
                _buildSettingItem(
                  themeProvider: themeProvider,
                  icon: Icons.language,
                  title: "Language",
                  trailing: DropdownButton<String>(
                    value: selectedLanguage,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedLanguage = newValue!;
                      });
                    },
                    items: <String>['English']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context, 14),
                            fontFamily: Fonts.main,
                            color: themeProvider
                                .themeData.textTheme.bodyMedium?.color,
                          ),
                        ),
                      );
                    }).toList(),
                    underline: Container(),
                  ),
                ),
                _buildSectionHeader("Help & Support", themeProvider),
                _buildSettingItem(
                  themeProvider: themeProvider,
                  icon: Icons.help_outline,
                  title: "FAQ",
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FAQPage()));
                  },
                ),
                _buildSettingItem(
                  themeProvider: themeProvider,
                  icon: Icons.info_outline,
                  title: "About",
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AboutPage()));
                  },
                ),
                _buildSettingItem(
                  themeProvider: themeProvider,
                  icon: Icons.update,
                  title: "New Version Available",
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorsPalette.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Update",
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 12),
                        fontFamily: Fonts.main,
                        color: ColorsPalette.white,
                      ),
                    ),
                  ),
                  onTap: () {
                    // Navigate to update page
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
          fontFamily: Fonts.main,
          fontWeight: FontWeight.bold,
          color: themeProvider.themeData.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required ThemeProvider themeProvider,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      color: themeProvider.themeData.cardColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ColorsPalette.grey.withOpacity(0.2), width: 1),
      ),
      child: ListTile(
        leading: Icon(icon, color: themeProvider.themeData.iconTheme.color),
        title: Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 15),
            fontFamily: Fonts.main,
            fontWeight: FontWeight.w600,
            color: themeProvider.themeData.textTheme.bodyMedium?.color ??
                ColorsPalette.black,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
