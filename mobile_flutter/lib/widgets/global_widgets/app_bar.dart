import 'package:flutter/material.dart';
import 'package:komunika/utils/responsive.dart';
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
  final Widget? customAction;
  final VoidCallback? onBackPressed; 

  const AppBarWidget({
    super.key,
    required this.title,
    required this.titleSize,
    required this.themeProvider,
    required this.isBackButton,
    this.isSettingButton = false,
    this.isHistoryButton = false,
    this.database = '',
    this.customAction,
    this.onBackPressed, 
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      automaticallyImplyLeading: false,
      backgroundColor: themeProvider.themeData.primaryColor,
      elevation: 2,
      title: Text(
        title,
        style: TextStyle(
          fontSize: titleSize,
          fontFamily: Fonts.main,
          fontWeight: FontWeight.w700,
          color: themeProvider.themeData.textTheme.bodyLarge?.color,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              blurRadius: 2,
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      leading: isBackButton
          ? Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                margin: const EdgeInsets.all(6),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_rounded, 
                    color: themeProvider.themeData.textTheme.bodyLarge?.color,
                    size: ResponsiveUtils.getResponsiveSize(context, 20),
                  ),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  splashRadius: ResponsiveUtils.getResponsiveSize(context, 20),
                  tooltip: 'Back', 
                ),
              ),
            )
          : null,
      actions: [
        if (customAction != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: customAction!,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
