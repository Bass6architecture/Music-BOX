import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  BannerAd? _bannerAd;
  bool _isBannerReady = false;

  // Mode test : utilisez true pour voir les pubs de test, false pour les vraies pubs
  static const bool _useTestAds = false; // ✅ MODE PRODUCTION - Vraies pubs activées !
  
  // IDs de test AdMob
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  
  // IDs AdMob réels
  static const String _androidBannerId = 'ca-app-pub-9535801913153032/3435168691';
  static const String _iosBannerId = 'ca-app-pub-9535801913153032/3435168691';

  bool get isBannerReady => _isBannerReady;

  /// Initialiser AdMob (à appeler au démarrage de l'app)
  Future<void> initialize() async {
    // ✅ En production : pas de configuration test device
    // Les vraies pubs seront affichées automatiquement
    
    await MobileAds.instance.initialize();
    if (kDebugMode) {
      print('✅ AdMob initialisé - Mode: ${_useTestAds ? "TEST" : "PRODUCTION"}');
      if (!_useTestAds) {
        print('   💰 Vraies pubs activées - Revenus générés !');
      }
    }
  }

  /// Charger la bannière publicitaire
  void loadBanner() {
    // Choisir l'ID selon le mode
    String adUnitId;
    if (_useTestAds) {
      adUnitId = _testBannerId;
    } else {
      adUnitId = Platform.isAndroid ? _androidBannerId : _iosBannerId;
    }
    
    if (kDebugMode) {
      print('🎯 Chargement bannière AdMob...');
      print('   ID: $adUnitId');
    }
    
    // Reset cache when loading new ad
    _cachedAdWidget = null;
    
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner, // 320x50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerReady = true;
          if (kDebugMode) {
            print('✅ Bannière AdMob chargée avec succès !');
          }
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerReady = false;
          _cachedAdWidget = null;
          ad.dispose();
          if (kDebugMode) {
            print('❌ Échec chargement bannière: ${error.message}');
            print('   Code: ${error.code}');
          }
          // Réessayer après 60 secondes en cas d'échec
          Future.delayed(const Duration(seconds: 60), () {
            if (kDebugMode) {
              print('🔄 Nouvelle tentative de chargement...');
            }
            loadBanner();
          });
        },
        onAdOpened: (ad) {
          if (kDebugMode) {
            print('📱 Bannière ouverte');
          }
        },
        onAdClosed: (ad) {
          if (kDebugMode) {
            print('📱 Bannière fermée');
          }
        },
      ),
    );
    _bannerAd?.load();
  }

  Widget? _cachedAdWidget;

  /// Widget de la bannière à afficher
  Widget getBannerWidget() {
    if (_isBannerReady && _bannerAd != null) {
      _cachedAdWidget ??= SizedBox(
        height: 50, // Hauteur standard d'une bannière AdMob
        width: double.infinity,
        child: AdWidget(ad: _bannerAd!),
      );
      return _cachedAdWidget!;
    }
    // Afficher un placeholder visible pendant le chargement (mode debug uniquement)
    if (kDebugMode) {
      return SizedBox(
        height: 50,
        width: double.infinity,
        child: Container(
          color: Colors.grey.withValues(alpha: 0.2),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Chargement pub...',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // En production, retourne un espace vide si la pub n'est pas prête
    return const SizedBox.shrink();
  }

  /// Libérer les ressources
  void dispose() {
    _bannerAd?.dispose();
    _isBannerReady = false;
    _cachedAdWidget = null;
  }
}
