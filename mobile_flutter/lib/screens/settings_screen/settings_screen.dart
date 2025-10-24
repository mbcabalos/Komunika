import 'package:flutter/material.dart';
import 'package:komunika/main.dart';
import 'package:komunika/widgets/setting_widgets/settings_FAQ_page.dart';
import 'package:komunika/widgets/setting_widgets/settings_about_page.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:komunika/widgets/setting_widgets/settings_terms_condition_page.dart';
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
  bool sttEnabled = false;
  bool ttsEnabled = false;
  String sttHistoryMode = "Auto";
  String ttsHistoryMode = "Auto";
  GlobalKey customizationKey = GlobalKey();
  GlobalKey historyKey = GlobalKey();
  GlobalKey helpSupportKey = GlobalKey();

  List<TargetFocus> settingsTargets = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadHistoryModes();
  }

  Future<void> _loadHistoryModes() async {
    sttHistoryMode = await PreferencesUtils.getSTTHistoryMode();
    ttsHistoryMode = await PreferencesUtils.getTTSHistoryMode();
    setState(() {});
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
        identify: "customization",
        keyTarget: customizationKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "(ENGLISH) Customization allows you to personalize the application according to your preferences. Here, you can change the visual theme for a comfortable viewing experience and select your preferred language for easier navigation.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 16),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
                Text(
                  "(FILIPINO) Sa seksyong Customization, maaari mong i-personalize ang application ayon sa iyong kagustuhan. Maaari mong baguhin ang tema para sa mas komportableng paggamit at pumili ng wika para sa mas madaling pag-navigate.",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 16)),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "history",
        keyTarget: historyKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "(ENGLISH) In the History Section, you can choose whether you want to manually, automatically, or not save the history of your speech interactions.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 16),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
                Text(
                  "(FILIPINO) Sa seksyong Historya, maaari mong piliin kung nais mong mano-mano, awtomatiko, o hindi na lang i-save ang historya ng iyong mga speech interaction.",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 16)),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "helpSupport",
        keyTarget: helpSupportKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "(ENGLISH) In the Help section, you can access Frequently Asked Questions for quick solutions or visit the About page to learn more about the application, its purpose, and its developers.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 16),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
                Text(
                  "(FILIPINO) Sa seksyong Help, maaari mong puntahan ang Frequently Asked Questions para sa mabilis na solusyon o bisitahin ang About page upang mas makilala ang application, ang layunin nito, at ang mga developer.",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 16)),
                ),
              ],
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
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getResponsiveSize(context, 16),
              vertical: ResponsiveUtils.getResponsiveSize(context, 8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  key: customizationKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                        context.translate('settings_customization'),
                        themeProvider),
                    _buildSettingItem(
                      themeProvider: themeProvider,
                      icon: Icons.color_lens,
                      title: context.translate('settings_theme'),
                      trailing: DropdownButton<String>(
                        value: selectedTheme,
                        dropdownColor: themeProvider.themeData.cardColor,
                        onChanged: (String? newValue) async {
                          setState(() {
                            selectedTheme = newValue!;
                          });
                          themeProvider.setTheme(newValue.toString());
                          await PreferencesUtils.storeTheme(
                              newValue.toString());
                        },
                        items: (selectedLanguage == 'Filipino'
                                ? ['Sistema', 'Maliwanag', 'Madilim']
                                : ['System', 'Light', 'Dark'])
                            .asMap()
                            .entries
                            .map<DropdownMenuItem<String>>((entry) {
                          final index = entry.key;
                          final displayText = entry.value;
                          final internalValue =
                              ['System', 'Light', 'Dark'][index];

                          return DropdownMenuItem<String>(
                            value: internalValue,
                            child: Text(
                              displayText,
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
                    _buildSettingItem(
                      themeProvider: themeProvider,
                      icon: Icons.language,
                      title: context.translate('settings_language'),
                      trailing: DropdownButton<String>(
                        value: selectedLanguage,
                        dropdownColor: themeProvider.themeData.cardColor,
                        onChanged: (String? newValue) async {
                          setState(() {
                            selectedLanguage = newValue!;
                          });
                          await PreferencesUtils.storeLanguage(
                              newValue.toString());
                          Locale newLocale = newValue == 'Filipino'
                              ? const Locale('fil', 'PH')
                              : const Locale('en', 'US');
                          MyApp.setLocale(context, newLocale);
                        },
                        items: (selectedLanguage == 'Filipino'
                                ? ['Ingles', 'Filipino']
                                : ['English', 'Filipino'])
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: (selectedLanguage == 'Filipino' &&
                                    value == 'Ingles')
                                ? 'English'
                                : value,
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
                  ],
                ),
                Column(
                  key: historyKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                        context.translate('settings_history'), themeProvider),
                    _buildSettingItem(
                      themeProvider: themeProvider,
                      icon: Icons.mic,
                      title: context.translate('settings_speech_to_text'),
                      trailing: DropdownButton<String>(
                        value: sttHistoryMode,
                        dropdownColor: themeProvider.themeData.cardColor,
                        onChanged: (String? newValue) async {
                          sttHistoryMode = newValue!;
                          await PreferencesUtils.storeSTTHistoryMode(
                              sttHistoryMode);
                          setState(() {});
                        },
                        items: (selectedLanguage == 'Filipino'
                                ? ['Awtomatiko', 'Manwal', 'Wala']
                                : ['Auto', 'Manual', 'None'])
                            .asMap()
                            .entries
                            .map<DropdownMenuItem<String>>((entry) {
                          final index = entry.key;
                          final displayText = entry.value;

                          // keep the internal values constant
                          final internalValue =
                              ['Auto', 'Manual', 'None'][index];

                          return DropdownMenuItem<String>(
                            value: internalValue,
                            child: Text(
                              displayText,
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
                    _buildSettingItem(
                      themeProvider: themeProvider,
                      icon: Icons.volume_down,
                      title: context.translate('settings_text_to_speech'),
                      trailing: DropdownButton<String>(
                        value: ttsHistoryMode,
                        dropdownColor: themeProvider.themeData.cardColor,
                        onChanged: (String? newValue) async {
                          ttsHistoryMode = newValue!;
                          await PreferencesUtils.storeTTSHistoryMode(
                              ttsHistoryMode);
                          setState(() {});
                        },
                        items: (selectedLanguage == 'Filipino'
                                ? ['Awtomatiko', 'Manwal', 'Wala']
                                : ['Auto', 'Manual', 'None'])
                            .asMap()
                            .entries
                            .map<DropdownMenuItem<String>>((entry) {
                          final index = entry.key;
                          final displayText = entry.value;
                          final internalValue =
                              ['Auto', 'Manual', 'None'][index];

                          return DropdownMenuItem<String>(
                            value: internalValue,
                            child: Text(
                              displayText,
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
                  ],
                ),
                Column(
                  key: helpSupportKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                        context.translate('settings_help_support'),
                        themeProvider),
                    _buildSettingItem(
                      themeProvider: themeProvider,
                      icon: Icons.description_outlined,
                      title: context.translate('settings_terms_and_conditions'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TermsAndConditionsPage(
                              themeProvider: themeProvider,
                            ),
                          ),
                        );
                      },
                    ),
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
      elevation: 2,
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.getResponsiveSize(context, 10),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveSize(context, 12),
        ),
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
