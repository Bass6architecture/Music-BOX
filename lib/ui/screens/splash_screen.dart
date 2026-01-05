import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/battery_optimization_service.dart';
import '../../services/artwork_preloader.dart';
import '../../widgets/permission_wrapper.dart';
import '../../widgets/optimized_artwork.dart';
import '../../player/player_cubit.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    _logoController.forward();
    _startLoading();
  }

  Future<void> _startLoading() async {
    BatteryOptimizationService.requestIfNeeded();
    ArtworkPreloader.setCache(OptimizedArtwork.artworkCache);
    
    // Check permissions
    final audio = await Permission.audio.status;
    final storage = await Permission.storage.status;
    final notification = await Permission.notification.status;
    
    final hasAudio = audio.isGranted || storage.isGranted;
    final hasNotif = notification.isGranted;
    
    if (!hasAudio || !hasNotif) {
      await Future.delayed(const Duration(seconds: 2));
      if (!context.mounted) return;
      _navigateTo(const PermissionWrapper());
      return;
    }
    
    // ✅ Attendre que les chansons soient chargées
    final cubit = context.read<PlayerCubit>();
    
    while (cubit.state.isLoading || cubit.state.allSongs.isEmpty) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (DateTime.now().difference(_startTime).inSeconds > 25) {
        break;
      }
    }
    
    if (!mounted) return;
    
    // ✅ Précharger TOUTES les pochettes (pas de limite)
    final songs = cubit.state.allSongs;
    if (songs.isNotEmpty) {
      debugPrint('[SplashScreen] Preloading ALL ${songs.length} songs...');
      
      final songIds = songs.map((s) => s.id).toList();
      final albumIds = songs
          .where((s) => s.albumId != null)
          .map((s) => s.albumId!)
          .toSet()
          .toList();
      final artistIds = songs
          .where((s) => s.artistId != null)
          .map((s) => s.artistId!)
          .toSet()
          .toList();
      
      // Précharger TOUT
      await ArtworkPreloader.preloadAll(
        songIds: songIds,
        albumIds: albumIds,
        artistIds: artistIds,
        sizePx: 300,
      );
      
      debugPrint('[SplashScreen] ALL artwork preloaded!');
    }
    
    // Durée minimale 3 secondes
    final elapsed = DateTime.now().difference(_startTime);
    if (elapsed < const Duration(seconds: 3)) {
      await Future.delayed(const Duration(seconds: 3) - elapsed);
    }
    
    if (!context.mounted) return;
    _navigateTo(const HomeScreen());
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _logoController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/app_icon.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
