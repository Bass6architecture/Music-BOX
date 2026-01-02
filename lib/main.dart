import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:firebase_core/firebase_core.dart';

import 'generated/app_localizations.dart';


import 'ui/screens/home_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'widgets/permission_wrapper.dart';
import 'widgets/optimized_artwork.dart';
import 'player/player_cubit.dart';
import 'core/theme/theme_cubit.dart';
import 'core/l10n/locale_cubit.dart';
import 'core/background/background_cubit.dart';

import 'services/ad_service.dart';
import 'services/artwork_preloader.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/modern_music_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // âœ… GESTION DES ERREURS GLOBALES: EmpÃªche le crash si AdMob fail sans rÃ©seau
  PlatformDispatcher.instance.onError = (error, stack) {
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socketexception')) {
      debugPrint('[GlobalError] Capture d\'une erreur rÃ©seau (attendue hors-ligne): $error');
      return true; // Erreur traitÃ©e, on ne crash pas l'app
    }
    return false; // Autres erreurs passÃ©es au framework
  };
  
  // âœ… OPTIMISATION RAM: Augmenter le cache d'images pour une fluiditÃ© maximale
  // On utilise 500MB de RAM pour les images (vs 100MB par dÃ©faut)
  PaintingBinding.instance.imageCache.maximumSizeBytes = 500 * 1024 * 1024; 
  PaintingBinding.instance.imageCache.maximumSize = 5000;
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  
  // Initialisation audio_service avec boutons personnalisÃ©s (J'aime, etc.)
  // Note: L'AudioHandler sera crÃ©Ã© par le PlayerCubit au premier usage
  // Ceci permet d'avoir des boutons personnalisÃ©s dans la notification
  
  // Initialisation Firebase
  await Firebase.initializeApp();
  
  // Initialisation AdMob
  // Initialisation AdMob supprimÃ©e ici pour Ã©viter crash en background (WebView)
  // DÃ©placÃ©e dans _InitialRoute

  
  runApp(const MusicBoxApp());
}

class MusicBoxApp extends StatelessWidget {
  const MusicBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => PlayerCubit()..init()),
        BlocProvider(create: (_) => ThemeCubit()..init()),
        BlocProvider(create: (_) => LocaleCubit()..init()),
        BlocProvider(create: (_) => BackgroundCubit()..init()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return BlocBuilder<BackgroundCubit, BackgroundType>(
                builder: (context, backgroundType) {
                  return MaterialApp(
                    title: AppConstants.appName,
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    // Force dark theme when custom background is active
                    themeMode: backgroundType != BackgroundType.none 
                        ? ThemeMode.dark 
                        : themeMode,
                    locale: locale,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: LocaleCubit.supportedLocales,
                    routes: {
                      '/modern': (context) => const ModernMusicWidgets(),
                    },
                    home: const SplashScreen(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Fast initial route - goes directly to HomeScreen or PermissionWrapper
class _InitialRoute extends StatefulWidget {
  const _InitialRoute();

  @override
  State<_InitialRoute> createState() => _InitialRouteState();
}

class _InitialRouteState extends State<_InitialRoute> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    
    // Initialiser AdMob ici seulement (quand UI visible) pour éviter crash background
    AdService().initialize();
    
    // Connect ArtworkPreloader to OptimizedArtwork cache
    ArtworkPreloader.setCache(OptimizedArtwork.artworkCache);

    // Check permissions and navigate immediately
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    final audio = await Permission.audio.status;
    final storage = await Permission.storage.status;
    final notification = await Permission.notification.status;
    
    final hasAudio = audio.isGranted || storage.isGranted;
    final hasNotif = notification.isGranted;
    
    if (!mounted) return;
    
    // If permissions not granted, go to permission screen immediately
    if (!hasAudio || !hasNotif) {
      _navigateTo(const PermissionWrapper());
      return;
    }
    
    // ✅ Go directly to HomeScreen - songs load in background
    _navigateTo(const HomeScreen());
  }
  
  void _navigateTo(Widget page) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => page,
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Simple loading indicator while checking permissions
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
