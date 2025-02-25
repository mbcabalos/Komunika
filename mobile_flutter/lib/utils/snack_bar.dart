import 'package:flutter/material.dart';
import 'package:komunika/utils/colors.dart';

void showCustomSnackBar(BuildContext context, String message, Color bgColor) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: ColorsPalette.white), 
      ),
      backgroundColor: bgColor,
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), 
      ),
    ),
  );
}
