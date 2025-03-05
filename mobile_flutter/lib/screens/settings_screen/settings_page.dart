import 'package:flutter/material.dart';
import 'package:komunika/main.dart';
import 'package:komunika/screens/settings_screen/settings_FAQ_page.dart';
import 'package:komunika/screens/settings_screen/settings_about_page.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:provider/provider.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';

class SettingPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const SettingPage({super.key, required this.themeProvider});

  @override
  State<SettingPage> createState() => SettingPageState();
}

class SettingPageState extends State<SettingPage> {
  String selectedTheme = 'Light';
  String selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    String storedLanguage = await PreferencesUtils.getLanguage();
    setState(() {
      selectedLanguage = storedLanguage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        selectedTheme = themeProvider.selectedTheme;
        return Scaffold(
          backgroundColor: themeProvider.themeData.scaffoldBackgroundColor,
          appBar: AppBarWidget(
            title: context.translate('settings_title'),
            titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
            themeProvider: widget.themeProvider,
            isBackButton: true,
            isSettingButton: false,
            isHistoryButton: false,
            database: '',
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(
              ResponsiveUtils.getResponsiveSize(context, 20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                    context.translate('settings_appearance'), themeProvider),
                _buildSettingItem(
                  themeProvider: themeProvider,
                  icon: Icons.color_lens,
                  title: context.translate('settings_theme'),
                  trailing: DropdownButton<String>(
                    value: selectedTheme,
                    onChanged: (String? newValue) async {
                      setState(() {
                        selectedTheme = newValue!;
                      });
                      themeProvider.setTheme(newValue.toString());
                      await PreferencesUtils.storeTheme(newValue.toString());
                    },
                    items: <String>['Light', 'Dark']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context, 14),
                            color: themeProvider
                                .themeData.textTheme.bodyMedium?.color,
                          ),
                        ),
                      );
                    }).toList(),
                    underline: Container(),
                  ),
                ),
                _buildSectionHeader(
                    context.translate('settings_language_region'),
                    themeProvider),
                _buildSettingItem(
                  themeProvider: themeProvider,
                  icon: Icons.language,
                  title: context.translate('settings_language'),
                  trailing: DropdownButton<String>(
                    value: selectedLanguage,
                    onChanged: (String? newValue) async {
                      setState(() {
                        selectedLanguage = newValue!;
                      });
                      await PreferencesUtils.storeLanguage(newValue.toString());
                      Locale newLocale = newValue == 'Filipino'
                          ? const Locale('fil', 'PH')
                          : const Locale('en', 'US');
                      MyApp.setLocale(context, newLocale);
                    },
                    items: <String>['English', 'Filipino']
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
                _buildSectionHeader(
                    context.translate('settings_help_support'), themeProvider),
                _buildSettingItem(
                  themeProvider: themeProvider,
                  icon: Icons.help_outline,
                  title: context.translate('settings_faq'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FAQPage(
                          themeProvider: themeProvider,
                        ),
                      ),
                    );
                  },
                ),
                _buildSettingItem(
                  themeProvider: themeProvider,
                  icon: Icons.info_outline,
                  title: context.translate('settings_about'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AboutPage(
                          themeProvider: themeProvider,
                        ),
                      ),
                    );
                  },
                ),
                // _buildSettingItem(
                //   themeProvider: themeProvider,
                //   icon: Icons.update,
                //   title: context.translate('settings_update_available'),
                //   trailing: Container(
                //     padding:
                //         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                //     decoration: BoxDecoration(
                //       color: ColorsPalette.grey,
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     child: Text(
                //       context.translate('settings_update'),
                //       style: TextStyle(
                //         fontSize:
                //             ResponsiveUtils.getResponsiveFontSize(context, 12),
                //         fontFamily: Fonts.main,
                //         color: ColorsPalette.white,
                //       ),
                //     ),
                //   ),
                //   onTap: () {
                //     // Navigate to update page
                //   },
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, ThemeProvider themeProvider) {
    return Padding(
      padding: EdgeInsets.only(
        top: ResponsiveUtils.getResponsiveSize(context, 20),
        bottom: ResponsiveUtils.getResponsiveSize(context, 10),
      ),
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
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.getResponsiveSize(context, 10),
      ),
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
