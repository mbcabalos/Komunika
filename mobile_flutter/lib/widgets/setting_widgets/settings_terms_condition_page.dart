import 'package:flutter/material.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAndConditionsPage extends StatelessWidget {
  final ThemeProvider themeProvider;
  const TermsAndConditionsPage({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark =
            themeProvider.themeData.brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: themeProvider.themeData.scaffoldBackgroundColor,
          appBar: AppBarWidget(
            title: context.translate("settings_terms_and_conditions"),
            titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
            themeProvider: themeProvider,
            isBackButton: true,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getResponsiveSize(context, 16),
              vertical: ResponsiveUtils.getResponsiveSize(context, 8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
                _buildHeaderCard(
                    context,
                    themeProvider,
                    isDark,
                    context.translate("terms_welcome_title"),
                    context.translate("terms_welcome_content")),

                SizedBox(
                    height: ResponsiveUtils.getResponsiveSize(context, 16)),

                // Terms Cards
                _buildTermCard(
                  context: context,
                  number: "1",
                  title: context.translate("terms_acceptance_title"),
                  content: context.translate("terms_acceptance_content"),
                  themeProvider: themeProvider,
                  isDark: isDark,
                ),

                SizedBox(
                    height: ResponsiveUtils.getResponsiveSize(context, 8)),

                _buildTermCard(
                  context: context,
                  number: "2",
                  title: context.translate("terms_purpose_title"),
                  content: context.translate("terms_purpose_content"),
                  themeProvider: themeProvider,
                  isDark: isDark,
                ),

                SizedBox(
                    height: ResponsiveUtils.getResponsiveSize(context, 8)),

                _buildTermCard(
                  context: context,
                  number: "3",
                  title: context.translate("terms_responsibilities_title"),
                  content: context.translate("terms_responsibilities_content"),
                  themeProvider: themeProvider,
                  isDark: isDark,
                ),

                SizedBox(
                    height: ResponsiveUtils.getResponsiveSize(context, 8)),

                _buildTermCard(
                  context: context,
                  number: "4",
                  title: context.translate("terms_privacy_title"),
                  content: context.translate("terms_privacy_content"),
                  themeProvider: themeProvider,
                  isDark: isDark,
                ),

                SizedBox(
                    height: ResponsiveUtils.getResponsiveSize(context, 8)),

                _buildTermCard(
                  context: context,
                  number: "5",
                  title: context.translate("terms_property_title"),
                  content: context.translate("terms_property_content"),
                  themeProvider: themeProvider,
                  isDark: isDark,
                ),

                SizedBox(
                    height: ResponsiveUtils.getResponsiveSize(context, 8)),

                _buildTermCard(
                  context: context,
                  number: "6",
                  title: context.translate("terms_liability_title"),
                  content: context.translate("terms_liability_content"),
                  themeProvider: themeProvider,
                  isDark: isDark,
                ),

                SizedBox(
                    height: ResponsiveUtils.getResponsiveSize(context, 8)),

                _buildTermCard(
                  context: context,
                  number: "7",
                  title: context.translate("terms_updates_title"),
                  content: context.translate("terms_updates_content"),
                  themeProvider: themeProvider,
                  isDark: isDark,
                ),

                SizedBox(
                    height: ResponsiveUtils.getResponsiveSize(context, 8)),

                _buildTermCard(
                  context: context,
                  number: "8",
                  title: context.translate("terms_termination_title"),
                  content: context.translate("terms_termination_content"),
                  themeProvider: themeProvider,
                  isDark: isDark,
                ),

                SizedBox(
                    height: ResponsiveUtils.getResponsiveSize(context, 8)),

                _buildContactCard(
                    context: context,
                    themeProvider: themeProvider,
                    isDark: isDark,
                    title: context.translate("terms_contact_title"),
                    content: context.translate("terms_contact_content"),
                    email: context.translate("terms_contact_email")),

                SizedBox(
                    height: ResponsiveUtils.getResponsiveSize(context, 8)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(BuildContext context, ThemeProvider themeProvider,
      bool isDark, String title, String content) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSize(context, 20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.blue.shade900.withOpacity(0.8),
                  const Color.fromARGB(255, 40, 37, 43).withOpacity(0.8),
                ]
              : [
                  Colors.blue.shade50,
                  Colors.purple.shade50,
                ],
        ),
        borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveSize(context, 16)),
        border: Border.all(
          color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gavel_rounded,
                color: isDark ? Colors.blue.shade200 : Colors.blue.shade600,
                size: ResponsiveUtils.getResponsiveFontSize(context, 24),
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSize(context, 12)),
              Flexible(
                child: Text(
                  title,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 20),
                    fontFamily: Fonts.main,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.themeData.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 12)),
          Text(
            content,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              fontFamily: Fonts.main,
              color: themeProvider.themeData.textTheme.bodyMedium?.color
                  ?.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermCard({
    required BuildContext context,
    required String number,
    required String title,
    required String content,
    required ThemeProvider themeProvider,
    required bool isDark,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveSize(context, 12)),
      ),
      color: isDark
          ? themeProvider.themeData.cardColor.withOpacity(0.9)
          : themeProvider.themeData.cardColor,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSize(context, 16)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveSize(context, 12)),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: ResponsiveUtils.getResponsiveSize(context, 28),
                  height: ResponsiveUtils.getResponsiveSize(context, 28),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue.shade800 : Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 14),
                        fontFamily: Fonts.main,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.blue.shade100
                            : Colors.blue.shade800,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSize(context, 12)),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 16),
                      fontFamily: Fonts.main,
                      fontWeight: FontWeight.w600,
                      color:
                          themeProvider.themeData.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
            Padding(
              padding: EdgeInsets.only(
                  left: ResponsiveUtils.getResponsiveSize(context, 40)),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                  fontFamily: Fonts.main,
                  color: themeProvider.themeData.textTheme.bodyMedium?.color
                      ?.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required ThemeProvider themeProvider,
    required bool isDark,
    required String title,
    required String content,
    required String email,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveSize(context, 12)),
      ),
      color: isDark
          ? Colors.green.shade900.withOpacity(0.3)
          : Colors.green.shade50,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSize(context, 16)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveSize(context, 12)),
          border: Border.all(
            color: isDark ? Colors.green.shade700 : Colors.green.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.contact_support_rounded,
                  color: isDark ? Colors.green.shade200 : Colors.green.shade600,
                  size: ResponsiveUtils.getResponsiveFontSize(context, 24),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSize(context, 12)),
                Text(
                  title,
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 18),
                    fontFamily: Fonts.main,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.themeData.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 12)),
            Text(
              content,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                fontFamily: Fonts.main,
                color: themeProvider.themeData.textTheme.bodyMedium?.color
                    ?.withOpacity(0.9),
                height: 1.5,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
            GestureDetector(
              onTap: () {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: email,
                );
                launchUrl(emailUri);
              },
              child: Text(
                email,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                  fontFamily: Fonts.main,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.green.shade300 : Colors.green.shade700,
                  decoration: TextDecoration.underline,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
