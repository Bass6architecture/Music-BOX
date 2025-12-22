import 'package:flutter/services.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class BatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel('com.synergydev.music_box/native');
  static const String _hasRequestedKey = 'battery_optimization_requested';

  /// VÃ©rifie si l'app est ignorÃ©e de l'optimisation batterie
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final bool isIgnoring = await _channel.invokeMethod('isIgnoringBatteryOptimizations');
      return isIgnoring;
    } catch (e) {
      return false;
    }
  }

  /// Demande Ã  l'utilisateur de dÃ©sactiver l'optimisation batterie
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final bool success = await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
      if (success) {
        await _markAsRequested();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// VÃ©rifie si on a dÃ©jÃ  demandÃ© l'autorisation
  static Future<bool> hasAlreadyRequested() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasRequestedKey) ?? false;
  }

  /// Marque comme dÃ©jÃ  demandÃ©
  static Future<void> _markAsRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasRequestedKey, true);
  }

  /// Demande automatiquement au premier lancement si pas dÃ©jÃ  autorisÃ©
  static Future<void> requestIfNeeded() async {
    if (!Platform.isAndroid) return;

    try {
      // VÃ©rifier si dÃ©jÃ  ignorÃ©
      final isIgnoring = await isIgnoringBatteryOptimizations();
      if (isIgnoring) return;

      // VÃ©rifier si dÃ©jÃ  demandÃ©
      final hasRequested = await hasAlreadyRequested();
      if (hasRequested) return;

      // Demander
      await requestIgnoreBatteryOptimizations();
    } catch (e) {
      // Ignorer les erreurs
    }
  }
}


