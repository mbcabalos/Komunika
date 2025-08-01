import 'package:flutter/material.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/utils/fonts.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double titleSize;
  final ThemeProvider themeProvider;
  final bool isBackButton;
  final bool isSettingButton;
  final bool isHistoryButton;
  final String database;
  final Widget? customAction; // <-- Add this line

  const AppBarWidget({
    super.key,
    required this.title,
    required this.titleSize,
    required this.themeProvider,
    required this.isBackButton,
    this.isSettingButton = false,
    this.isHistoryButton = false,
    this.database = '',
    this.customAction, // <-- Add this line
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      automaticallyImplyLeading: false,
      backgroundColor: themeProvider.themeData.primaryColor,
      elevation: 0,
      title: Text(
        title,
        style: TextStyle(
          fontSize: titleSize,
          fontFamily: Fonts.main,
          fontWeight: FontWeight.w600,
          color: themeProvider.themeData.textTheme.bodyLarge?.color,
          letterSpacing: 5,
        ),
      ),
      leading: isBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: themeProvider.themeData.iconTheme.color,
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      actions: [
        if (customAction != null) customAction!, // <-- Add this line
        if (isHistoryButton)
          IconButton(
            icon: Icon(
              Icons.history,
              color: themeProvider.themeData.iconTheme.color,
            ),
            onPressed: () {
              // Handle history button press
            },
          ),
        if (isSettingButton)
          IconButton(
            icon: Icon(
              Icons.settings,
              color: themeProvider.themeData.iconTheme.color,
            ),
            onPressed: () {
              // Handle settings button press
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
