import 'package:flutter/material.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/app_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.themeData.scaffoldBackgroundColor,
          appBar: AppBarWidget(
            title: context.translate("about_title"),
            titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
            isBackButton: true,
            isSettingButton: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                // App Logo
                Container(
                  width: ResponsiveUtils.getResponsiveSize(context, 150),
                  height: ResponsiveUtils.getResponsiveSize(context, 150),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(100),
                  ),
                  alignment: Alignment.center,
                  child: ClipRRect(
                    child: Image.asset(
                      'assets/icons/logo.png',
                      width: ResponsiveUtils.getResponsiveSize(context, 100),
                      height: ResponsiveUtils.getResponsiveSize(context, 100),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // App Title
                Text(
                  "Komunika",
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 24),
                    fontFamily: Fonts.main,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.themeData.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 10),

                // App Version
                Text(
                  "${context.translate("about_version")} 1.0.0",
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 16),
                    fontFamily: Fonts.main,
                    color: ColorsPalette.grey,
                  ),
                ),
                const SizedBox(height: 30),

                // Authors Section
                _buildSectionHeader(
                    context.translate("about_project_team"),
                    ResponsiveUtils.getResponsiveFontSize(context, 18),
                    themeProvider),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                _buildAuthorCard(
                  name: "Mark Benedict Abalos",
                  role: "Lead Developer",
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                  themeProvider: themeProvider,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                _buildAuthorCard(
                  name: "Kobe Roca",
                  role: "UI/UX Designer",
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                  themeProvider: themeProvider,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                _buildAuthorCard(
                  name: "Sweet Lana Sison",
                  role: "Frontend Developer",
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                  themeProvider: themeProvider,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                _buildAuthorCard(
                  name: "Marvin John Macam",
                  role: "Backend Developer",
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                  themeProvider: themeProvider,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                _buildAuthorCard(
                  name: "Davd Aldrin Mondero",
                  role: "Full Stack Developer",
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                  themeProvider: themeProvider,
                ),
                const SizedBox(height: 30),

                // Social Media Links
                _buildSectionHeader(
                    context.translate("about_follow_us"),
                    ResponsiveUtils.getResponsiveFontSize(context, 18),
                    themeProvider),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialMediaButton(
                      assetPath: 'assets/icons/communication.png',
                      themeProvider: themeProvider,
                      onPressed: () {
                        launchUrl(
                            Uri.parse('https://www.facebook.com/yourpage'));
                      },
                      size: ResponsiveUtils.getResponsiveSize(context, 25),
                    ),
                    const SizedBox(width: 20),
                    _buildSocialMediaButton(
                      assetPath: 'assets/icons/github.png',
                      themeProvider: themeProvider,
                      onPressed: () {
                        launchUrl(
                            Uri.parse('https://github.com/Yakage/Komunika'));
                      },
                      size: ResponsiveUtils.getResponsiveSize(context, 25),
                    ),
                    const SizedBox(width: 20),
                    _buildSocialMediaButton(
                      assetPath: 'assets/icons/mail.png',
                      themeProvider: themeProvider,
                      onPressed: () {
                        // Open website link
                      },
                      size: ResponsiveUtils.getResponsiveSize(context, 25),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to build section headers
  Widget _buildSectionHeader(
      String title, double fontSize, ThemeProvider themeProvider) {
    return Text(
      title,
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: Fonts.main,
        fontWeight: FontWeight.bold,
        color: themeProvider.themeData.textTheme.bodyMedium?.color,
      ),
    );
  }

  // Helper method to build author cards
  Widget _buildAuthorCard({
    required String name,
    required double fontSize,
    required String role,
    required ThemeProvider themeProvider,
  }) {
    return Card(
      color: themeProvider.themeData.scaffoldBackgroundColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ColorsPalette.grey.withOpacity(0.2), width: 1),
      ),
      child: ListTile(
        title: Center(
          child: Text(
            name,
            style: TextStyle(
              fontSize: fontSize,
              fontFamily: Fonts.main,
              fontWeight: FontWeight.w600,
              color: themeProvider.themeData.textTheme.bodyMedium?.color,
            ),
          ),
        ),
        subtitle: Center(
          child: Text(
            role,
            style: TextStyle(
              fontSize: fontSize,
              fontFamily: Fonts.main,
              color: ColorsPalette.grey,
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build social media buttons
  _buildSocialMediaButton({
    required String assetPath,
    required double size,
    required ThemeProvider themeProvider,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      color: themeProvider.themeData.iconTheme.color,
      onPressed: onPressed,
      icon: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
