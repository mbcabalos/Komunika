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
      15,
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.translate("faq_description"),
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 22),
                    fontFamily: Fonts.main,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.themeData.textTheme.bodyMedium?.color,
                  ),
                ),
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSize(context, 20),
                ),
                ExpansionPanelList(
                  elevation: 0,
                  expandedHeaderPadding: EdgeInsets.zero,
                  expansionCallback: (int index, bool isExpanded) {
                    setState(() {
                      faqs[index].isExpanded = !faqs[index].isExpanded;
                    });
                  },
                  children: faqs.map<ExpansionPanel>((FAQItem faq) {
                    return ExpansionPanel(
                      backgroundColor: themeProvider.themeData.cardColor,
                      headerBuilder: (BuildContext context, bool isExpanded) {
                        return ListTile(
                          title: Text(
                            context.translate(faq.question),
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
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveUtils.getResponsiveSize(context, 16),
                          0,
                          ResponsiveUtils.getResponsiveSize(context, 16),
                          ResponsiveUtils.getResponsiveSize(context, 16),
                        ),
                        child: Text(
                          context.translate(faq.answer), 
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
