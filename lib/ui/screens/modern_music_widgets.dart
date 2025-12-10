import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../player/player_cubit.dart';

class ModernMusicWidgets extends StatefulWidget {
  const ModernMusicWidgets({super.key});

  @override
  State<ModernMusicWidgets> createState() => _ModernMusicWidgetsState();
}

class _ModernMusicWidgetsState extends State<ModernMusicWidgets>
    with TickerProviderStateMixin {
  // États des lecteurs
  double progress = 0.35; // fallback visuel si pas de player

  // Contrôleurs d'animation
  late AnimationController _shimmerController;
  late AnimationController _glowController;
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _expandController;

  @override
  void initState() {
    super.initState();

    // ✅ Initialisation des animations - Limiter pour économiser la batterie
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 4), // ← Ralenti de 3s à 4s
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(seconds: 4), // ← Ralenti de 3s à 4s
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000), // ← Ralenti de 1500ms à 2000ms
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500), // ← Ralenti de 2s à 2.5s
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 10), // ← Ralenti de 8s à 10s
      vsync: this,
    )..repeat();

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 2500), // ← Ralenti de 2s à 2.5s
      vsync: this,
    )..repeat();
  }

  // Barre de progression basée sur la position réelle du player
  Widget _buildPositionBar(PlayerCubit cubit, {bool premium = false}) {
    return StreamBuilder<Duration>(
      stream: cubit.player.positionStream,
      builder: (context, snapshot) {
        final pos = snapshot.data ?? Duration.zero;
        final dur = cubit.player.duration ?? Duration.zero;
        final frac = dur.inMilliseconds > 0
            ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
            : (progress);
        return premium ? _buildPremiumProgressBarWith(frac) : _buildFuturisticProgressBarWith(frac);
      },
    );
  }

  Widget _buildFuturisticProgressBarWith(double fraction) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00D2FF), Color(0xFF9D50BB)],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D2FF).withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumProgressBarWith(double fraction) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF6B6B),
                Color(0xFF4ECDC4),
                Color(0xFF45B7D1),
              ],
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF45B7D1).withValues(alpha: 0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlayerCubit>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF000000),
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Titre
                Container(
                  margin: const EdgeInsets.only(bottom: 40),
                  child: const Text(
                    'WIDGETS MUSICAUX ULTRA-MODERNES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Widget 4x1
                _buildWidget4x1(cubit),
                const SizedBox(height: 30),

                // Widget 4x2
                _buildWidget4x2(cubit),
                const SizedBox(height: 30),

                // Widget 4x4 - VRAIE TAILLE
                _buildWidget4x4(cubit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET 4×1 - HORIZONTAL ULTRA-MODERNE CORRIGÉ
  Widget _buildWidget4x1(PlayerCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Widget 4×1 - Horizontal Ultra-Moderne',
            style: TextStyle(
              color: Color(0xFF00D2FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 85,
          child: Stack(
            children: [
              // Container principal avec gradient
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A1A2E),
                      Color(0xFF16213E),
                      Color(0xFF0F3460),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D2FF).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),

              // Effet shimmer
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment(-1.0 + 2.0 * _shimmerController.value, -1.0),
                        end: Alignment(1.0 + 2.0 * _shimmerController.value, 1.0),
                        colors: [
                          Colors.transparent,
                          const Color(0xFF00D2FF).withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Artwork avec effet glow
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B6B).withValues(alpha:
                                  0.4 + 0.3 * _glowController.value,
                                ),
                                blurRadius: 10 + 5 * _glowController.value,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 28,
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 15),

                    // Infos dynamiques
                    Expanded(
                      child: BlocBuilder<PlayerCubit, PlayerStateModel>(
                        buildWhen: (p, n) => p.currentIndex != n.currentIndex,
                        builder: (context, state) {
                          final song = cubit.currentSong;
                          final title = song?.title ?? '—';
                          final artist = song?.artist ?? '';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title.isEmpty ? '—' : title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                artist,
                                style: const TextStyle(
                                  color: Color(0xFF00D2FF),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Contrôles modernes
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModernControlButton(Icons.skip_previous, 20, cubit.previous),
                        const SizedBox(width: 10),
                        BlocBuilder<PlayerCubit, PlayerStateModel>(
                          buildWhen: (p, n) => p.isPlaying != n.isPlaying,
                          builder: (context, state) {
                            return _buildModernPlayButton(state.isPlaying, 26, cubit.toggle);
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildModernControlButton(Icons.skip_next, 20, cubit.next),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET 4×2 - MEDIUM FUTURISTE CORRIGÉ
  Widget _buildWidget4x2(PlayerCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Widget 4×2 - Medium Futuriste',
            style: TextStyle(
              color: Color(0xFF00D2FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 170,
          child: Stack(
            children: [
              // Container principal
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F0C29),
                      Color(0xFF302B63),
                      Color(0xFF24243e),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9D50BB).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),

              // Effet radial
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: RadialGradient(
                    center: const Alignment(0.3, 0.7),
                    radius: 1.0,
                    colors: [
                      const Color(0xFF9D50BB).withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        // Artwork avec pulse
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 85,
                              height: 85,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6B6B),
                                    Color(0xFF4ECDC4),
                                    Color(0xFF45B7D1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF45B7D1).withValues(alpha:
                                      0.6 + 0.3 * _pulseController.value,
                                    ),
                                    blurRadius: 15 + 10 * _pulseController.value,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.album,
                                color: Colors.white,
                                size: 35,
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 18),

                        // Infos + visualiseur
                        Expanded(
                          child: BlocBuilder<PlayerCubit, PlayerStateModel>(
                            buildWhen: (p, n) => p.currentIndex != n.currentIndex,
                            builder: (context, state) {
                              final song = cubit.currentSong;
                              final title = song?.title ?? '—';
                              final artist = song?.artist ?? '';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.isEmpty ? '—' : title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    artist,
                                    style: const TextStyle(
                                      color: Color(0xFF9D50BB),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMiniVisualizer(),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Progress bar futuriste (position réelle)
                    _buildPositionBar(cubit),

                    const SizedBox(height: 15),

                    // Contrôles
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildModernControlButton(Icons.favorite_border, 22, () {}),
                        _buildModernControlButton(Icons.skip_previous, 26, cubit.previous),
                        BlocBuilder<PlayerCubit, PlayerStateModel>(
                          buildWhen: (p, n) => p.isPlaying != n.isPlaying,
                          builder: (context, state) {
                            return _buildModernPlayButton(state.isPlaying, 30, cubit.toggle);
                          },
                        ),
                        _buildModernControlButton(Icons.skip_next, 26, cubit.next),
                        _buildModernControlButton(Icons.playlist_play, 22, () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET 4×4 - VRAIE GRANDE TAILLE PREMIUM
  Widget _buildWidget4x4(PlayerCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Widget 4×4 - Grande Taille Premium',
            style: TextStyle(
              color: Color(0xFF00D2FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 380, // VRAIE TAILLE 4x4
          child: Stack(
            children: [
              // Container principal
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF000428),
                      Color(0xFF004e92),
                      Color(0xFF009ffd),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF009ffd).withValues(alpha: 0.5),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),

              // Effet rotatif
              AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: SweepGradient(
                        center: Alignment.center,
                        startAngle: 2 * math.pi * _rotateController.value,
                        endAngle: 2 * math.pi * _rotateController.value + math.pi,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Artwork avec cercles d'ondes
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cercles expandants
                        ..._buildExpandingCircles(),

                        // Artwork principal
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            return Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6B6B),
                                    Color(0xFF4ECDC4),
                                    Color(0xFF45B7D1),
                                    Color(0xFF9D50BB),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _glowController.value < 0.5
                                        ? const Color(0xFF45B7D1).withValues(alpha: 0.8)
                                        : const Color(0xFF9D50BB).withValues(alpha: 0.8),
                                    blurRadius: 20 + 10 * _glowController.value,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.music_video,
                                color: Colors.white,
                                size: 55,
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Infos principales
                    BlocBuilder<PlayerCubit, PlayerStateModel>(
                      buildWhen: (p, n) => p.currentIndex != n.currentIndex,
                      builder: (context, state) {
                        final song = cubit.currentSong;
                        final title = song?.title ?? '—';
                        final artist = song?.artist ?? '';
                        return Column(
                          children: [
                            Text(
                              title.isEmpty ? '—' : title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              artist,
                              style: const TextStyle(
                                color: Color(0xFF87CEEB),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Interstellar Sounds',
                      style: TextStyle(
                        color: Color(0xFF87CEEB),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Visualiseur principal
                    _buildMainVisualizer(),

                    const SizedBox(height: 20),

                    // Temps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          '1:32',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '4:15',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Progress bar premium (position réelle)
                    _buildPositionBar(cubit, premium: true),

                    const SizedBox(height: 20),

                    // Contrôles premium
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildModernControlButton(Icons.shuffle, 24, cubit.toggleShuffle),
                        _buildModernControlButton(Icons.skip_previous, 30, cubit.previous),
                        BlocBuilder<PlayerCubit, PlayerStateModel>(
                          buildWhen: (p, n) => p.isPlaying != n.isPlaying,
                          builder: (context, state) {
                            return _buildModernPlayButton(state.isPlaying, 40, cubit.toggle);
                          },
                        ),
                        _buildModernControlButton(Icons.skip_next, 30, cubit.next),
                        _buildModernControlButton(Icons.repeat, 24, cubit.cycleRepeatMode),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Bouton de contrôle moderne
  Widget _buildModernControlButton(IconData icon, double size, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 16,
        height: size + 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size,
        ),
      ),
    );
  }

  // Bouton play/pause moderne
  Widget _buildModernPlayButton(bool isPlaying, double size, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 20,
        height: size + 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: size,
        ),
      ),
    );
  }

  // Mini visualiseur
  Widget _buildMiniVisualizer() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          children: List.generate(8, (index) {
            double height = 3 +
                10 * ((math.sin((_waveController.value * 2 * math.pi) + index * 0.5) + 1) / 2);
            return Container(
              margin: const EdgeInsets.only(right: 2),
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFF00D2FF),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  // Visualiseur principal
  Widget _buildMainVisualizer() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(12, (index) {
            double height = 8 +
                30 * ((math.sin((_waveController.value * 2 * math.pi) + index * 0.3) + 1) / 2);
            return Container(
              margin: const EdgeInsets.only(right: 3),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF00D2FF), Color(0xFF9D50BB)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  // (removed unused wrappers)

  // Cercles expandants
  List<Widget> _buildExpandingCircles() {
    return [
      AnimatedBuilder(
        animation: _expandController,
        builder: (context, child) {
          return Container(
            width: 140 + 20 * _expandController.value,
            height: 140 + 20 * _expandController.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3 - 0.2 * _expandController.value),
                width: 2,
              ),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _expandController,
        builder: (context, child) {
          double delayed = (_expandController.value + 0.5) % 1.0;
          return Container(
            width: 160 + 20 * delayed,
            height: 160 + 20 * delayed,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2 - 0.15 * delayed),
                width: 1,
              ),
            ),
          );
        },
      ),
    ];
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _glowController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _expandController.dispose();
    super.dispose();
  }
}
