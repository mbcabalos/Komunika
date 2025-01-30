import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/app_bar.dart';
import 'package:provider/provider.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  // List of FAQs
  final List<FAQItem> _faqs = [
    FAQItem(
      question: "What is Komunika?",
      answer:
          "Komunika is a communication app designed to help users connect and share information seamlessly.",
    ),
    FAQItem(
      question: "Is Komunika free to use?",
      answer: "Yes, Komunika is free to use.",
    ),
    FAQItem(
      question: "How do I contact support?",
      answer:
          "You can contact support by sending an email to support@komunika.com or using the in-app chat feature.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.themeData.scaffoldBackgroundColor,
          appBar: AppBarWidget(
            title: "FAQ",
            titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
            isBackButton: true,
            isSettingButton: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Frequently Asked Questions",
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 22),
                    fontFamily: Fonts.main,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.themeData.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 20),

                // FAQ List
                ExpansionPanelList(
                  elevation: 0,
                  expandedHeaderPadding: EdgeInsets.zero,
                  expansionCallback: (int index, bool isExpanded) {
                    setState(() {
                      _faqs[index].isExpanded = !isExpanded;
                    });
                  },
                  children: _faqs.map<ExpansionPanel>((FAQItem faq) {
                    return ExpansionPanel(
                      backgroundColor: themeProvider
                          .themeData.cardColor, // Set background color
                      headerBuilder: (BuildContext context, bool isExpanded) {
                        return ListTile(
                          title: Text(
                            faq.question,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context, 16),
                              fontFamily: Fonts.main,
                              fontWeight: FontWeight.w600,
                              color: themeProvider
                                  .themeData.textTheme.bodyMedium?.color,
                            ),
                          ),
                        );
                      },
                      body: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq.answer,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context, 14),
                            fontFamily: Fonts.main,
                            color: ColorsPalette.grey,
                          ),
                        ),
                      ),
                      isExpanded: faq.isExpanded,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// FAQ Item Model
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
