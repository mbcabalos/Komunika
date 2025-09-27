import 'package:flutter/material.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';
import 'package:provider/provider.dart';

class FAQPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const FAQPage({super.key, required this.themeProvider});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  late List<FAQItem> faqs;

  @override
  void initState() {
    super.initState();
    faqs = List.generate(
      10,
      (i) => FAQItem(
        question: "faq_question${i + 1}",
        answer: "faq_answer${i + 1}",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.themeData.scaffoldBackgroundColor,
          appBar: AppBarWidget(
            title: context.translate("faq_title"),
            titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
            themeProvider: widget.themeProvider,
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
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSize(context, 8),
                ),
                ...faqs
                    .map((faq) => _buildFAQCard(faq, themeProvider))
                    .toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAQCard(FAQItem faq, ThemeProvider themeProvider) {
    return Card(
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
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, 
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getResponsiveSize(context, 16),
            vertical: ResponsiveUtils.getResponsiveSize(context, 4),
          ),
          title: Text(
            context.translate(faq.question),
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 15),
              fontFamily: Fonts.main,
              fontWeight: FontWeight.w600,
              color: themeProvider.themeData.textTheme.bodyMedium?.color ??
                  ColorsPalette.black,
            ),
          ),
          iconColor: themeProvider.themeData.iconTheme.color,
          collapsedIconColor: themeProvider.themeData.iconTheme.color,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.getResponsiveSize(context, 16),
                0,
                ResponsiveUtils.getResponsiveSize(context, 16),
                ResponsiveUtils.getResponsiveSize(context, 16),
              ),
              child: Text(
                context.translate(faq.answer),
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                  fontFamily: Fonts.main,
                  color: ColorsPalette.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FAQItem {
  String question;
  String answer;
  bool isExpanded;

  FAQItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}
