import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:firebase_core/firebase_core.dart';

import 'generated/app_localizations.dart';


import 'ui/screens/home_screen.dart';
import 'widgets/permission_wrapper.dart';
import 'player/player_cubit.dart';
import 'core/theme/theme_cubit.dart';
import 'core/l10n/locale_cubit.dart';
import 'core/background/background_cubit.dart';

import 'services/ad_service.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/modern_music_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  
  // Initialisation audio_service avec boutons personnalisés (J'aime, etc.)
  // Note: L'AudioHandler sera créé par le PlayerCubit au premier usage
  // Ceci permet d'avoir des boutons personnalisés dans la notification
  
  // Initialisation Firebase
  await Firebase.initializeApp();
  
  // Initialisation AdMob
  await AdService().initialize();
  
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
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => 
            (hasAudio && hasNotif) ? const HomeScreen() : const PermissionWrapper(),
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
                              color: theme.colorScheme.primary.withOpacity(opacity),
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

