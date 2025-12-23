import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import 'generated/app_localizations.dart';


import 'ui/screens/home_screen.dart';
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
                    home: const _InitialRoute(),
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

/// Fast initial route - skips splash and goes directly to HomeScreen or PermissionWrapper
class _InitialRoute extends StatefulWidget {
  const _InitialRoute();

  @override
  State<_InitialRoute> createState() => _InitialRouteState();
}

class _InitialRouteState extends State<_InitialRoute> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _hasNavigated = false;


  @override
  void initState() {
    super.initState();
    
    // Pulse animation for dots
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    
    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    
    
    // Initialiser AdMob ici seulement (quand UI visible) pour Ã©viter crash background
    AdService().initialize();
    
    // Connect ArtworkPreloader to OptimizedArtwork cache
    ArtworkPreloader.setCache(OptimizedArtwork.artworkCache);

    _checkAndNavigate();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
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
    
    // Wait for songs to load and pre-cache artwork
    await _waitAndPreload();
    
    // Navigate to home
    _navigateTo(const HomeScreen());
  }
  
  Future<void> _waitAndPreload() async {
    final cubit = context.read<PlayerCubit>();
    final audioQuery = OnAudioQuery();
    
    // Set timeout to prevent infinite splash
    // Limite de 10s pour le chargement comme demandÃ©
    final timeout = Future.delayed(const Duration(seconds: 10));
    
    // Wait for songs to be loaded and state restored (or timeout)
    final songsLoaded = _waitForInitialization(cubit);
    
    await Future.any([songsLoaded, timeout]);
    
    if (!mounted || _hasNavigated) return;
    
    // Status update (optional logging)
    debugPrint('[Splash] Chargement des pochettes...');
    
    // Get all unique IDs for pre-caching
    try {
      final songs = cubit.state.allSongs;
      final songIds = songs.map((s) => s.id).toList();
      
      // Query albums and artists
      final albums = await audioQuery.queryAlbums();
      final artists = await audioQuery.queryArtists();
      
      final albumIds = albums.map((a) => a.id).toList();
      final artistIds = artists.map((a) => a.id).toList();
      
      debugPrint('[Splash] Pre-caching: ${songIds.length} songs, ${albumIds.length} albums, ${artistIds.length} artists');
      
      // Pre-cache all artwork with mini timeout
      final preloadFuture = ArtworkPreloader.preloadAll(
        songIds: songIds,
        albumIds: albumIds,
        artistIds: artistIds,
        sizePx: 300,
      );
      
      // Give it max 8 more seconds for artwork (total ~10s splash max)
      await Future.any([
        preloadFuture,
        Future.delayed(const Duration(seconds: 8)),
      ]);
      
    } catch (e) {
      debugPrint('[Splash] Pre-cache error: $e');
    }
  }
  
  Future<void> _waitForInitialization(PlayerCubit cubit) async {
    // If not loading state, return immediately
    if (!cubit.state.isLoading) return;
    
    // Otherwise wait for state change
    final completer = Completer<void>();
    late StreamSubscription sub;
    
    sub = cubit.stream.listen((state) {
      if (!state.isLoading && !completer.isCompleted) {
        completer.complete();
        sub.cancel();
      }
    });
    
    // Also check again in case it loaded between check and subscription
    if (!cubit.state.isLoading && !completer.isCompleted) {
      completer.complete();
      sub.cancel();
    }
    
    await completer.future;
  }
  
  void _navigateTo(Widget page) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => page,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Image.asset(
                'assets/app_icon.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 32),
              // Pulsating dots loader
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final delay = index * 0.2;
                      final value = ((_pulseController.value + delay) % 1.0);
                      final scale = 0.5 + (0.5 * _bounce(value));
                      final opacity = 0.4 + (0.6 * _bounce(value));
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: opacity),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Smooth bounce curve
  double _bounce(double t) {
    return (1 - (2 * t - 1).abs());
  }
}




