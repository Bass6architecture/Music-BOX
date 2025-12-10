import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(const Locale('en'));

  static const String _localeKey = 'app_locale';

  /// Initialise la locale sauvegardée ou détecte automatiquement
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);
      
      if (savedLocale != null) {
        // L'utilisateur a déjà choisi une langue manuellement
        emit(Locale(savedLocale));
      } else {
        // Détecter automatiquement la langue du système
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

  /// Change la locale et sauvegarde la préférence
  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
      emit(locale);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la locale: $e');
    }
  }

  /// Langues supportées
  static const List<Locale> supportedLocales = [
    Locale('fr'), // Français
    Locale('en'), // English
  ];

  /// Langues disponibles (incluant celles à venir)
  static const List<LocaleInfo> availableLocales = [
    LocaleInfo(locale: Locale('fr'), name: 'Français', flag: '🇫🇷'),
    LocaleInfo(locale: Locale('en'), name: 'English', flag: '🇬🇧'),
    LocaleInfo(locale: Locale('ar'), name: 'العربية', flag: '🇸🇦', comingSoon: true),
    LocaleInfo(locale: Locale('es'), name: 'Español', flag: '🇪🇸', comingSoon: true),
    LocaleInfo(locale: Locale('pt'), name: 'Português', flag: '🇧🇷', comingSoon: true),
    LocaleInfo(locale: Locale('hi'), name: 'हिन्दी', flag: '🇮🇳', comingSoon: true),
    LocaleInfo(locale: Locale('de'), name: 'Deutsch', flag: '🇩🇪', comingSoon: true),
    LocaleInfo(locale: Locale('it'), name: 'Italiano', flag: '🇮🇹', comingSoon: true),
    LocaleInfo(locale: Locale('ru'), name: 'Русский', flag: '🇷🇺', comingSoon: true),
    LocaleInfo(locale: Locale('zh'), name: '简体中文', flag: '🇨🇳', comingSoon: true),
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
