import 'package:flutter/material.dart';
import 'package:music_box/generated/app_localizations.dart';

/// Extension pour accéder facilement aux traductions depuis le BuildContext
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
