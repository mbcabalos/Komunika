import 'package:flutter/material.dart';
import 'package:komunika/screens/settings_screen/settings_page.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/history.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double titleSize;
  final ThemeProvider themeProvider;
  final bool isBackButton;
  final bool isSettingButton;
  final bool isHistoryButton;
  final String database;
  const AppBarWidget({
    super.key,
    required this.title,
    required this.titleSize,
    required this.themeProvider,
    required this.isBackButton,
    required this.isSettingButton,
    required this.isHistoryButton,
    required this.database,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Padding(
        padding: const EdgeInsets.only(top: 7.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: titleSize,
          ),
        ),
      ),
      leading: isBackButton
          ? Padding(
              padding: const EdgeInsets.only(top: 7.0),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 10,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      actions: [
        if (isSettingButton)
          Padding(
            padding: const EdgeInsets.only(top: 7.0, right: 8.0),
            child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingPage(
                        themeProvider: themeProvider,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.settings)),
          ),
        if (isHistoryButton)
          Padding(
            padding: const EdgeInsets.only(top: 7.0, right: 8.0),
            child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryPage(
                        themeProvider: themeProvider,
                        database: database,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.history_rounded)),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
