import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_constants.dart';
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
    // Demander l'optimisation batterie au premier lancement
    BatteryOptimizationService.requestIfNeeded();
    
    // ✅ Connecter le cache artwork
    ArtworkPreloader.setCache(OptimizedArtwork.artworkCache);
    
    // Check permissions
    final audio = await Permission.audio.status;
    final storage = await Permission.storage.status;
    final notification = await Permission.notification.status;
    
    final hasAudio = audio.isGranted || storage.isGranted;
    final hasNotif = notification.isGranted;
    final allGranted = hasAudio && hasNotif;
    
    if (!allGranted) {
      await Future.delayed(const Duration(seconds: 2));
      if (!context.mounted) return;
      _navigateTo(const PermissionWrapper());
      return;
    }
    
    // ✅ Attendre que les chansons soient chargées
    final cubit = context.read<PlayerCubit>();
    
    // Boucle while robuste pour attendre le chargement
    while (cubit.state.isLoading || cubit.state.allSongs.isEmpty) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Timeout après 20 secondes
      if (DateTime.now().difference(_startTime).inSeconds > 20) {
        debugPrint('[SplashScreen] Timeout waiting for songs');
        break;
      }
    }
    
    if (!mounted) return;
    
    // ✅ Précharger les pochettes des chansons visibles
    final songs = cubit.state.allSongs;
    if (songs.isNotEmpty) {
      debugPrint('[SplashScreen] Preloading ${songs.length} songs artwork...');
      
      // Récupérer les IDs pour le préchargement
      final songIds = songs.take(30).map((s) => s.id).toList();
      
      // Albums uniques
      final albumIds = songs
          .where((s) => s.albumId != null)
          .map((s) => s.albumId!)
          .toSet()
          .take(15)
          .toList();
      
      // Artistes uniques
      final artistIds = songs
          .where((s) => s.artistId != null)
          .map((s) => s.artistId!)
          .toSet()
          .take(10)
          .toList();
      
      // Précharger les pochettes
      await ArtworkPreloader.preloadVisible(
        songIds: songIds,
        albumIds: albumIds,
        artistIds: artistIds,
        maxSongs: 30,
        maxAlbums: 15,
        maxArtists: 10,
        sizePx: 300,
      );
      
      debugPrint('[SplashScreen] Artwork preloading complete');
    }
    
    // ✅ Durée minimale du splash (3 secondes)
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
          return FadeTransition(
            opacity: animation,
            child: child,
          );
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
