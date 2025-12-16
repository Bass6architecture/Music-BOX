import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BackgroundType {
  none,
  gradientMusical,
  gradientDark,
  particles,
  waves,
  vinylSunset,
  glassMorphism,
  abstractDark,
}

class BackgroundCubit extends Cubit<BackgroundType> {
  BackgroundCubit() : super(BackgroundType.none);

  static const _keyBackground = 'selected_background';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_keyBackground);
    if (saved != null && saved < BackgroundType.values.length) {
      emit(BackgroundType.values[saved]);
    }
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
      case BackgroundType.gradientMusical:
        return 'assets/backgrounds/bg_gradient_musical.png';
      case BackgroundType.gradientDark:
        return 'assets/backgrounds/bg_gradient_dark.png';
      case BackgroundType.particles:
        return 'assets/backgrounds/bg_particles.png';
      case BackgroundType.waves:
        return 'assets/backgrounds/bg_waves.png';
      case BackgroundType.vinylSunset:
        return 'assets/backgrounds/bg_vinyl_sunset.png';
      case BackgroundType.glassMorphism:
        return 'assets/backgrounds/bg_glass_morphism.png';
      case BackgroundType.abstractDark:
        return 'assets/backgrounds/bg_abstract_dark.png';
    }
  }
}
