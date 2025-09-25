import 'package:flutter/material.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  final ThemeProvider themeProvider;
  const AboutPage({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.themeData.scaffoldBackgroundColor,
          appBar: AppBarWidget(
            title: context.translate("about_title"),
            titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
            themeProvider: themeProvider,
            isBackButton: true,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(
              ResponsiveUtils.getResponsiveSize(context, 20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                /// App Logo with gradient circle
                Container(
                  width: ResponsiveUtils.getResponsiveSize(context, 140),
                  height: ResponsiveUtils.getResponsiveSize(context, 140),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorsPalette.white.withOpacity(0.9),
                        ColorsPalette.white.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/app_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// App Title
                Text(
                  "Komunika",
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 26),
                    fontFamily: Fonts.main,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: themeProvider.themeData.textTheme.bodyMedium?.color,
                  ),
                ),

                const SizedBox(height: 8),

                /// App Version
                Text(
                  "${context.translate("about_version")} 1.0.0",
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 15),
                    fontFamily: Fonts.main,
                    color: ColorsPalette.grey,
                  ),
                ),

                const SizedBox(height: 30),

                /// Authors Section
                _buildSectionHeader(
                    context.translate("about_project_team"),
                    ResponsiveUtils.getResponsiveFontSize(context, 18),
                    themeProvider),

                const SizedBox(height: 15),

                _buildAuthorCard(
                  name: "Mark Benedict Abalos",
                  role: "Project Manager",
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 15),
                  themeProvider: themeProvider,
                ),
                _buildAuthorCard(
                  name: "Kobe Roca",
                  role: "UI/UX Designer",
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 15),
                  themeProvider: themeProvider,
                ),
                _buildAuthorCard(
                  name: "Sweet Lana Sison",
                  role: "Frontend Developer",
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 15),
                  themeProvider: themeProvider,
                ),
                _buildAuthorCard(
                  name: "Marvin John Macam",
                  role: "Backend Developer",
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 15),
                  themeProvider: themeProvider,
                ),
                _buildAuthorCard(
                  name: "David Aldrin Mondero",
                  role: "Full Stack Developer",
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 15),
                  themeProvider: themeProvider,
                ),

                const SizedBox(height: 30),

                /// Social Media
                _buildSectionHeader(
                    context.translate("about_follow_us"),
                    ResponsiveUtils.getResponsiveFontSize(context, 18),
                    themeProvider),

                const SizedBox(height: 15),

                Wrap(
                  spacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildSocialMediaButton(
                      assetPath: 'assets/icons/communication.png',
                      themeProvider: themeProvider,
                      onPressed: () {
                        launchUrl(Uri.parse(
                            'https://web.facebook.com/profile.php?id=61573900271206'));
                      },
                      size: ResponsiveUtils.getResponsiveSize(context, 30),
                    ),
                    _buildSocialMediaButton(
                      assetPath: 'assets/icons/github.png',
                      themeProvider: themeProvider,
                      onPressed: () {
                        launchUrl(
                            Uri.parse('https://github.com/Yakage/Komunika'));
                      },
                      size: ResponsiveUtils.getResponsiveSize(context, 30),
                    ),
                    _buildSocialMediaButton(
                      assetPath: 'assets/icons/mail.png',
                      themeProvider: themeProvider,
                      onPressed: () {
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: 'komunika.up@gmail.com',
                        );
                        launchUrl(emailUri);
                      },
                      size: ResponsiveUtils.getResponsiveSize(context, 30),
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

  Widget _buildSectionHeader(
      String title, double fontSize, ThemeProvider themeProvider) {
    return Text(
      title,
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: Fonts.main,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: themeProvider.themeData.textTheme.bodyMedium?.color,
      ),
    );
  }

  Widget _buildAuthorCard({
    required String name,
    required double fontSize,
    required String role,
    required ThemeProvider themeProvider,
  }) {
    return Card(
      elevation: 2,
      color: themeProvider.themeData.cardColor,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
              fontSize: fontSize * 0.9,
              fontFamily: Fonts.main,
              color: ColorsPalette.grey,
            ),
          ),
        ),
      ),
    );
  }

  _buildSocialMediaButton({
    required String assetPath,
    required double size,
    required ThemeProvider themeProvider,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: themeProvider.themeData.cardColor.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
