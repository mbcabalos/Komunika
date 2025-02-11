import 'package:flutter/material.dart';
import 'package:komunika/utils/app_localization.dart';

extension LocalizationExtension on BuildContext {
  String translate(String key) {
    return AppLocalizations.of(this).translate(key);
  }
}
