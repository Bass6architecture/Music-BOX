import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BackgroundType {
  none,
  gradientDark,
  gradientMusical, // Restored
  particles, // Restored
  waves, // Restored
  abstractDark,
  // glassMorphism, // Removed
  // cosmicBeats, // Removed
  vinylSunset,
  deepSpace,
  midnightCity,
  obsidianFlow,
}

class BackgroundCubit extends Cubit<BackgroundType> {
  BackgroundCubit() : super(BackgroundType.none);

  static const _keyBackground = 'selected_background';
  static const _keyUnlocked = 'unlocked_backgrounds_v2'; // New key for timestamped unlocks

  // Map of unlocked backgrounds to their EXPIRATION date
  final Map<BackgroundType, DateTime> _unlocked = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load unlocked with expiration
    final unlockedList = prefs.getStringList(_keyUnlocked);
    if (unlockedList != null) {
      final now = DateTime.now();
      for (final item in unlockedList) {
        // Format: "index:expiry_millis"
        final parts = item.split(':');
        if (parts.length == 2) {
          final index = int.tryParse(parts[0]);
          final expiryMillis = int.tryParse(parts[1]);
          
          if (index != null && expiryMillis != null && index >= 0 && index < BackgroundType.values.length) {
             final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
             if (expiry.isAfter(now)) {
               _unlocked[BackgroundType.values[index]] = expiry;
             }
          }
        }
      }
    }

    final saved = prefs.getInt(_keyBackground);
    if (saved != null && saved >= 0 && saved < BackgroundType.values.length) {
      emit(BackgroundType.values[saved]);
    }
  }

  bool isUnlocked(BackgroundType type) {
    // Free backgrounds
    if (type == BackgroundType.none || type == BackgroundType.gradientDark) return true;
    
    // Check if in unlocked map and not expired (double check)
    if (_unlocked.containsKey(type)) {
       final expiry = _unlocked[type];
       if (expiry != null && expiry.isAfter(DateTime.now())) {
         return true;
       } else {
         _unlocked.remove(type); // Clean up expired
         _saveUnlocked();
         return false;
       }
    }
    return false;
  }

  Future<void> unlockBackground(BackgroundType type) async {
    // Set expiry to 30 days from now
    final expiry = DateTime.now().add(const Duration(days: 30));
    _unlocked[type] = expiry;
    await _saveUnlocked();
  }
  
  Future<void> _saveUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _unlocked.entries.map((e) => '${e.key.index}:${e.value.millisecondsSinceEpoch}').toList();
    await prefs.setStringList(_keyUnlocked, list);
  }

  Future<void> setBackground(BackgroundType background) async {
    emit(background);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBackground, background.index);
  }

  String? get assetPath => getAssetPathForType(state);

  static String? getAssetPathForType(BackgroundType type) {
    switch (type) {
      case BackgroundType.none:
        return null;
      case BackgroundType.gradientDark:
        return 'assets/backgrounds/bg_gradient_dark.png';
      case BackgroundType.gradientMusical:
        return 'assets/backgrounds/bg_gradient_musical.png';
      case BackgroundType.particles:
        return 'assets/backgrounds/bg_particles.png';
      case BackgroundType.waves:
        return 'assets/backgrounds/bg_waves.png';
      case BackgroundType.abstractDark:
        return 'assets/backgrounds/bg_abstract_dark.png';
      // case BackgroundType.glassMorphism: return 'assets/backgrounds/bg_glass_morphism.png';
      // case BackgroundType.cosmicBeats: return 'assets/backgrounds/bg_cosmic_beats.png'; // Removed (Too bright)
      case BackgroundType.vinylSunset:
        return 'assets/backgrounds/bg_vinyl_sunset.png';
      case BackgroundType.deepSpace:
        return 'assets/backgrounds/bg_deep_space.png';
      case BackgroundType.midnightCity:
        return 'assets/backgrounds/bg_midnight_city.png';
      case BackgroundType.obsidianFlow:
        return 'assets/backgrounds/bg_obsidian_flow.png';
    }
  }
}
