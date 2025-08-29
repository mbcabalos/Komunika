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
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class SettingScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const SettingScreen({super.key, required this.themeProvider});

  @override
  State<SettingScreen> createState() => SettingScreenState();
}

class SettingScreenState extends State<SettingScreen> {
  String selectedTheme = 'Light';
  String selectedLanguage = 'English';
  GlobalKey keyTheme = GlobalKey();
  GlobalKey keyLanguage = GlobalKey();
  GlobalKey keyHelpSupport = GlobalKey();

  List<TargetFocus> settingsTargets = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> checkWalkthrough() async {
    bool isDone = await PreferencesUtils.getWalkthroughDone();

    if (!isDone) {
      _initTargets();
      _showTutorial();
    }
  }

  void _initTargets() {
    settingsTargets = [
      TargetFocus(
        identify: "Theme",
        keyTarget: keyTheme,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(
              "(ENGLISH) Change between Light and Dark themes here.\n\n(FILIPINO) Magpalit sa pagitan ng Liwanag at Madilim na tema dito.",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Language",
        keyTarget: keyLanguage,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Text(
              "(ENGLISH) Select your preferred language here.\n\n(FILIPINO) Piliin ang iyong nais na wika dito.",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Help",
        keyTarget: keyHelpSupport,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Text(
              "(ENGLISH) For questions, access FAQ and support here.\n\n (FILIPINO) Para sa mga katanungan, i-access ang FAQ at suporta dito.",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    ];
  }

void _showTutorial() {
  TutorialCoachMark(
    targets: settingsTargets,
    colorShadow: Colors.black.withOpacity(0.8),
    textSkip: "SKIP",
    paddingFocus: 8,
    alignSkip: Alignment.bottomLeft,
    onFinish: () {
      PreferencesUtils.storeWalkthroughDone(true);
    },
    onSkip: () {
      PreferencesUtils.storeWalkthroughDone(true);
      return true;
    },
  ).show(context: context);
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
            isBackButton: false,
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
                  key: keyTheme,
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
                  key: keyLanguage,
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
                Column(
                  key: keyHelpSupport,
                  children: [
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
                  ],
                )
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
    Key? key,
    required IconData icon,
    required ThemeProvider themeProvider,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      key: key,
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
