import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(const Locale('en'));

  static const String _localeKey = 'app_locale';
  bool _isSystemMode = true;

  bool get isSystemMode => _isSystemMode;

  /// Initialise la locale sauvegardée ou détecte automatiquement
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);
      
      if (savedLocale != null) {
        // L'utilisateur a déjà choisi une langue manuellement
        _isSystemMode = false;
        emit(Locale(savedLocale));
      } else {
        // Détecter automatiquement la langue du système
        _isSystemMode = true;
        final systemLocale = _detectSystemLocale();
        emit(systemLocale);
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de la locale: $e');
    }
  }

  /// Détecte la langue du système et retourne une langue supportée
  Locale _detectSystemLocale() {
    final systemLocales = ui.PlatformDispatcher.instance.locales;
    
    // Chercher une correspondance dans les langues supportées
    for (final systemLocale in systemLocales) {
      // Vérifier si le code de langue est supporté
      final isSupported = supportedLocales.any(
        (supported) => supported.languageCode == systemLocale.languageCode,
      );
      
      if (isSupported) {
        debugPrint('🌍 Langue du système détectée: ${systemLocale.languageCode}');
        return Locale(systemLocale.languageCode);
      }
    }
    
    // Fallback: anglais par défaut (universel)
    debugPrint('🌍 Langue du système non supportée, utilisation de l\'anglais');
    return const Locale('en');
  }

  /// Change la locale et sauvegarde la préférence (null = système)
  Future<void> setLocale(Locale? locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_localeKey);
        _isSystemMode = true;
        emit(_detectSystemLocale());
      } else {
        await prefs.setString(_localeKey, locale.languageCode);
        _isSystemMode = false;
        emit(locale);
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la locale: $e');
    }
  }

  /// Langues supportées
  static const List<Locale> supportedLocales = [
    Locale('fr'), // Français
    Locale('en'), // English
    Locale('ar'), // Arabic
    Locale('es'), // Spanish
    Locale('pt'), // Portuguese
    Locale('hi'), // Hindi
    Locale('de'), // German
    Locale('it'), // Italian
    Locale('ru'), // Russian
    Locale('zh'), // Chinese
    Locale('ja'), // Japanese
    Locale('ko'), // Korean
    Locale('tr'), // Turkish
    Locale('pl'), // Polish
    Locale('id'), // Indonesian
  ];

  /// Langues disponibles (incluant celles à venir)
  static const List<LocaleInfo> availableLocales = [
    LocaleInfo(locale: Locale('fr'), name: 'Français', flag: '🇫🇷'),
    LocaleInfo(locale: Locale('en'), name: 'English', flag: '🇬🇧'),
    LocaleInfo(locale: Locale('ar'), name: 'العربية', flag: '🇸🇦'),
    LocaleInfo(locale: Locale('es'), name: 'Español', flag: '🇪🇸'),
    LocaleInfo(locale: Locale('pt'), name: 'Português', flag: '🇧🇷'),
    LocaleInfo(locale: Locale('hi'), name: 'हिन्दी', flag: '🇮🇳'),
    LocaleInfo(locale: Locale('de'), name: 'Deutsch', flag: '🇩🇪'),
    LocaleInfo(locale: Locale('it'), name: 'Italiano', flag: '🇮🇹'),
    LocaleInfo(locale: Locale('ru'), name: 'Русский', flag: '🇷🇺'),
    LocaleInfo(locale: Locale('zh'), name: '简体中文', flag: '🇨🇳'),
    LocaleInfo(locale: Locale('ja'), name: '日本語', flag: '🇯🇵'),
    LocaleInfo(locale: Locale('ko'), name: '한국어', flag: '🇰🇷'),
    LocaleInfo(locale: Locale('tr'), name: 'Türkçe', flag: '🇹🇷'),
    LocaleInfo(locale: Locale('pl'), name: 'Polski', flag: '🇵🇱'),
    LocaleInfo(locale: Locale('id'), name: 'Bahasa Indonesia', flag: '🇮🇩'),
  ];

  String getLocaleName(Locale locale) {
    final info = availableLocales.firstWhere(
      (l) => l.locale.languageCode == locale.languageCode,
      orElse: () => availableLocales.first,
    );
    return info.name;
  }
}

class LocaleInfo {
  final Locale locale;
  final String name;
  final String flag;
  final bool comingSoon;

  const LocaleInfo({
    required this.locale,
    required this.name,
    required this.flag,
    this.comingSoon = false,
  });
}
