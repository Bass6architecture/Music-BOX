import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:firebase_core/firebase_core.dart';

import 'generated/app_localizations.dart';


import 'ui/screens/splash_screen.dart';
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

