import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';

import '../player/player_cubit.dart';
import '../widgets/optimized_artwork.dart';
import '../generated/app_localizations.dart';
import '../core/utils/music_data_processor.dart'; // ✅ Import Processor
import 'lyrics_page.dart';
import 'queue_page.dart';
import 'song_actions_sheet.dart';
import 'widgets/bouncy_button.dart';
import 'widgets/music_box_scaffold.dart';
import 'widgets/sleep_timer_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

/// Opens the Next Gen Now Playing page
Widget openNextGenNowPlaying(BuildContext context) {
  return BlocProvider.value(
    value: context.read<PlayerCubit>(),
    child: const _NextGenNowPlaying(),
  );
}

class _NextGenNowPlaying extends StatefulWidget {
  const _NextGenNowPlaying();

  @override
  State<_NextGenNowPlaying> createState() => _NextGenNowPlayingState();
}

class _NextGenNowPlayingState extends State<_NextGenNowPlaying>
    with TickerProviderStateMixin {
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<int?>? _idxSub;
  StreamSubscription<SequenceState?>? _seqSub;
  StreamSubscription<ProcessingState>? _procSub;
  
  double _progress = 0.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isScrubbing = false;
  double _scrubProgress = 0.0;
  
  Color _dominantColor = const Color(0xFF2a2a3e);
  Color _vibrantColor = const Color(0xFF4a9fff);
  Color _mutedColor = const Color(0xFF26304e);
  int? _lastExtractedSongId;
  
  late AnimationController _colorAnimationController;
  late Animation<Color?> _dominantColorAnimation;
  late Animation<Color?> _vibrantColorAnimation;
  late Animation<Color?> _mutedColorAnimation;
  
  Color _targetDominantColor = const Color(0xFF2a2a3e);
  Color _targetVibrantColor = const Color(0xFF4a9fff);
  Color _targetMutedColor = const Color(0xFF26304e);
  Map<int, List<Color>> _colorCache = {};
  static const int _maxColorCacheSize = 20; // ✅ Limiter le cache de couleurs

  // ✅ Garantir une couleur visible pour les icônes actives
  // ✅ Garantir une couleur visible pour les icônes actives
  Color get _activeButtonColor {
    // Convertir en HSL pour manipuler la luminosité et la saturation
    final hsl = HSLColor.fromColor(_vibrantColor);
    
    // ✅ Si c'est gris (saturation très faible), on veut du BLANC pur
    if (hsl.saturation < 0.2) {
      return Colors.white;
    }
    
    // 1. Assurer une luminosité minimale (pour être visible sur fond sombre)
    // Si la luminosité est < 0.6, on la remonte à 0.6 ou plus
    final double minLightness = 0.6;
    final double lightness = hsl.lightness < minLightness ? minLightness : hsl.lightness;
    
    // 2. Assurer une saturation minimale (pour garder la couleur)
    // Si la saturation est < 0.4, on la remonte à 0.6
    final double minSaturation = 0.4;
    final double saturation = hsl.saturation < minSaturation ? 0.6 : hsl.saturation;
    
    return hsl.withLightness(lightness).withSaturation(saturation).toColor();
  }

  @override
  void initState() {
    super.initState();
    final p = context.read<PlayerCubit>().player;

    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _dominantColorAnimation = ColorTween(
      begin: _dominantColor,
      end: _dominantColor,
    ).animate(CurvedAnimation(
      parent: _colorAnimationController,
      curve: Curves.easeInOut,
    ));

    _vibrantColorAnimation = ColorTween(
      begin: _vibrantColor,
      end: _vibrantColor,
    ).animate(CurvedAnimation(
      parent: _colorAnimationController,
      curve: Curves.easeInOut,
    ));

    _mutedColorAnimation = ColorTween(
      begin: _mutedColor,
      end: _mutedColor,
    ).animate(CurvedAnimation(
      parent: _colorAnimationController,
      curve: Curves.easeInOut,
    ));

    // ✅ Optimisation: Utiliser addListener au lieu de setState pour animations fluides
    _colorAnimationController.addListener(() {
      if (mounted) {
        final newDominant = _dominantColorAnimation.value ?? _dominantColor;
        final newVibrant = _vibrantColorAnimation.value ?? _vibrantColor;
        final newMuted = _mutedColorAnimation.value ?? _mutedColor;
        
        // Ne rebuild que si les couleurs ont vraiment changé
        if (newDominant != _dominantColor || newVibrant != _vibrantColor || newMuted != _mutedColor) {
          setState(() {
            _dominantColor = newDominant;
            _vibrantColor = newVibrant;
            _mutedColor = newMuted;
          });
        }
      }
    });

    _extractArtworkColors();
    
    // ✅ Throttle position updates pour meilleure fluidité (200ms au lieu de chaque frame)
    Duration? _lastPositionUpdate;
    _posSub = p.positionStream.listen((pos) {
      if (!mounted) return;
      if (_isScrubbing) return;

      final now = DateTime.now();
      if (_lastPositionUpdate != null && 
          now.difference(DateTime.fromMillisecondsSinceEpoch(_lastPositionUpdate!.inMilliseconds)) < const Duration(milliseconds: 200)) {
        return;
      }
      _lastPositionUpdate = Duration(milliseconds: now.millisecondsSinceEpoch);

      final dur = p.duration ?? Duration.zero;
      if (mounted) {
        setState(() {
          _position = pos;
          _duration = dur;
          _progress = dur.inMilliseconds > 0
              ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
              : 0.0;
        });
      }
    });

    _durSub = p.durationStream.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d ?? Duration.zero);
    });

    _idxSub = p.currentIndexStream.listen((_) {
      if (!mounted) return;
      _extractArtworkColors();
    });

    _seqSub = p.sequenceStateStream.listen((seq) {
      if (!mounted) return;
      if (seq != null && seq.currentIndex != null) {
        _preCacheNextSongColors(seq);
      }
    });

    _procSub = p.processingStateStream.listen((s) {
      if (!mounted) return;
      if (s == ProcessingState.completed) {
        setState(() {
          _progress = 1.0;
          _position = _duration;
        });
      }
    });
  }

  Future<void> _extractArtworkColors() async {
    // ✅ Delay to let transition finish (improves opening fluidity)
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final song = context.read<PlayerCubit>().currentSong;
    if (song == null || song.id == null) return;
    if (song.id == _lastExtractedSongId) return;

    if (_colorCache.containsKey(song.id)) {
      final cached = _colorCache[song.id]!;
      _animateToColors(cached[0], cached[1], cached[2]);
      _lastExtractedSongId = song.id;
      return;
    }

    _lastExtractedSongId = song.id;

    try {
      final bytes = await OnAudioQuery()
          .queryArtwork(song.id!, ArtworkType.AUDIO, size: 1024, quality: 100);
      
      if (bytes != null && bytes.isNotEmpty) {
        // ✅ Run in background isolate
        final colors = await MusicDataProcessor.extractPalette(bytes);
        
        if (colors != null) {
          final dominant = Color(colors['dominant']!);
          final vibrant = Color(colors['vibrant']!);
          final muted = Color(colors['muted']!);

          // ✅ Limiter la taille du cache de couleurs
          if (_colorCache.length >= _maxColorCacheSize) {
            _colorCache.remove(_colorCache.keys.first);
          }
          
          _colorCache[song.id!] = [dominant, vibrant, muted];
          _animateToColors(dominant, vibrant, muted);
        } else {
          // ✅ PAS de couleurs extraites → Réinitialiser aux couleurs par défaut
          const Color defaultDominant = Color(0xFF2a2a3e);
          const Color defaultVibrant = Color(0xFF4a9fff);
          const Color defaultMuted = Color(0xFF26304e);
          
          _colorCache[song.id!] = [defaultDominant, defaultVibrant, defaultMuted];
          _animateToColors(defaultDominant, defaultVibrant, defaultMuted);
        }
      } else {
        // ✅ PAS de pochette → Réinitialiser aux couleurs par défaut
        const Color defaultDominant = Color(0xFF2a2a3e);
        const Color defaultVibrant = Color(0xFF4a9fff);
        const Color defaultMuted = Color(0xFF26304e);
        
        // Mettre en cache les couleurs par défaut pour cette chanson
        _colorCache[song.id!] = [defaultDominant, defaultVibrant, defaultMuted];
        _animateToColors(defaultDominant, defaultVibrant, defaultMuted);
      }
    } catch (e) {
      // ✅ En cas d'erreur → Réinitialiser aux couleurs par défaut
      const Color defaultDominant = Color(0xFF2a2a3e);
      const Color defaultVibrant = Color(0xFF4a9fff);
      const Color defaultMuted = Color(0xFF26304e);
      
      _colorCache[song.id!] = [defaultDominant, defaultVibrant, defaultMuted];
      _animateToColors(defaultDominant, defaultVibrant, defaultMuted);
    }
  }

  void _animateToColors(Color dominant, Color vibrant, Color muted) {
    _targetDominantColor = dominant;
    _targetVibrantColor = vibrant;
    _targetMutedColor = muted;

    _dominantColorAnimation = ColorTween(
      begin: _dominantColor,
      end: _targetDominantColor,
    ).animate(CurvedAnimation(
      parent: _colorAnimationController,
      curve: Curves.easeInOut,
    ));

    _vibrantColorAnimation = ColorTween(
      begin: _vibrantColor,
      end: _targetVibrantColor,
    ).animate(CurvedAnimation(
      parent: _colorAnimationController,
      curve: Curves.easeInOut,
    ));

    _mutedColorAnimation = ColorTween(
      begin: _mutedColor,
      end: _targetMutedColor,
    ).animate(CurvedAnimation(
      parent: _colorAnimationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimationController.forward(from: 0.0);
  }

  Future<void> _preCacheNextSongColors(SequenceState seq) async {
    if (seq.effectiveSequence.isEmpty) return;
    final nextIndex = (seq.currentIndex ?? 0) + 1;
    if (nextIndex >= seq.effectiveSequence.length) return;

    final nextItem = seq.effectiveSequence[nextIndex];
    final nextId = int.tryParse(nextItem.tag.id);
    if (nextId == null || _colorCache.containsKey(nextId)) return;

    try {
      final bytes = await OnAudioQuery()
          .queryArtwork(nextId, ArtworkType.AUDIO, size: 1024, quality: 100);
      if (bytes != null && bytes.isNotEmpty) {
        final imageProvider = MemoryImage(bytes);
        final paletteGenerator =
            await PaletteGenerator.fromImageProvider(imageProvider);
        Color dominant = paletteGenerator.dominantColor?.color ??
            const Color(0xFF1a1a2e);
        Color vibrant = paletteGenerator.vibrantColor?.color ??
            const Color(0xFF7C4DFF);
        Color muted =
            paletteGenerator.mutedColor?.color ?? const Color(0xFF16213e);
        _colorCache[nextId] = [dominant, vibrant, muted];
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _colorAnimationController.dispose();
    _posSub?.cancel();
    _durSub?.cancel();
    _idxSub?.cancel();
    _seqSub?.cancel();
    _procSub?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes;
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  void _showSleepTimerSheet(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SleepTimerDialog(),
    );
  }



  @override
  Widget build(BuildContext context) {
    final baseSong = context.select((PlayerCubit c) => c.currentSong);
    if (baseSong == null) {
      Navigator.of(context).pop();
      return const SizedBox.shrink();
    }
    final song = context.read<PlayerCubit>().applyOverrides(baseSong);
    final player = context.read<PlayerCubit>().player;
    final screenW = MediaQuery.of(context).size.width;

    if (song.id != _lastExtractedSongId) {
      _extractArtworkColors();
    }

    return GestureDetector(
      onVerticalDragEnd: (details) {
        // ✅ Swipe down pour fermer (sans animation de suivi)
        if ((details.primaryVelocity ?? 0) > 500) {
          Navigator.of(context).pop();
        }
      },
      child: MusicBoxScaffold(
        backgroundColor: _dominantColor,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ✅ Fond dégradé animé (couleurs de la chanson)
            AnimatedBuilder(
              animation: _colorAnimationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _dominantColor.withValues(alpha: 0.8), // Transparence pour laisser voir un peu le fond custom si désiré
                        _mutedColor.withValues(alpha: 0.9),
                        Colors.black,
                      ],
                    ),
                  ),
                );
              },
            ),
            // Content
            SafeArea(
              child: Column(
                children: [
                  // Header + Artwork area
                  Column(
                    children: [
                      // Header avec back button et more button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: PhosphorIcon(PhosphorIcons.caretDown(),
                                  size: 28, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: PhosphorIcon(PhosphorIcons.dotsThreeVertical(),
                                  size: 32, color: Colors.white),
                              onPressed: () => openSongActionsSheet(context, song),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Large circular artwork avec ombre
                      // Large circular artwork avec ombre
                      SizedBox(
                        height: screenW * 0.7, // Fixed height for artwork area
                  child: Center(
                    child: RepaintBoundary(
                      child: Hero(
                        tag: 'artwork_${song.id}',
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 800),
                          child: Container(
                            key: ValueKey(song.id),
                            width: screenW * 0.58, // ✅ Reverted size
                            height: screenW * 0.58, // ✅ Reverted size
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _vibrantColor.withValues(alpha: 0.4),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: OptimizedArtwork.square(
                                id: song.id,
                                type: ArtworkType.AUDIO,
                                size: screenW * 0.58, // ✅ Reverted size
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Song info avec glassmorphism
                Expanded(
                  flex: 3, // ✅ Reverted flex
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                        // Title et Artist
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (song.artist ?? '').isNotEmpty
                                ? song.artist!
                                : AppLocalizations.of(context)!.unknownArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 0.2,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Favorite + Sleep Timer buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Favorite button
                              Builder(
                                builder: (context) {
                                  final isFavorite = context.select((PlayerCubit c) => c.state.favorites.contains(song.id));
                                  return IconButton(
                                    onPressed: () => context.read<PlayerCubit>().toggleFavoriteById(song.id),
                                    icon: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      transitionBuilder: (child, animation) {
                                        return ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        );
                                      },
                                      child: PhosphorIcon(
                                        isFavorite ? PhosphorIconsFill.heart() : PhosphorIcons.heart(),
                                        key: ValueKey(isFavorite),
                                        color: isFavorite ? Colors.red : Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              
                              const SizedBox(width: 24),
                              
                              // Sleep Timer button avec temps restant
                              Builder(
                                builder: (context) {
                                  final cubit = context.read<PlayerCubit>();
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => _showSleepTimerSheet(context),
                                        icon: PhosphorIcon(
                                          PhosphorIcons.timer(),
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                      if (cubit.isSleepTimerActive)
                                        StreamBuilder<void>(
                                          stream: Stream.periodic(const Duration(seconds: 1)),
                                          builder: (context, snapshot) {
                                            final remaining = cubit.sleepTimeRemaining;
                                            if (remaining == null || remaining.inSeconds <= 0) {
                                              return const SizedBox.shrink();
                                            }
                                            final mins = remaining.inMinutes;
                                            final secs = remaining.inSeconds % 60;
                                            return Text(
                                              '$mins:${secs.toString().padLeft(2, '0')}',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.7),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Progress slider avec glassmorphism
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 5,
                                        thumbShape:
                                            const RoundSliderThumbShape(
                                                enabledThumbRadius: 9),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                                overlayRadius: 18),
                                        activeTrackColor: _vibrantColor,
                                        inactiveTrackColor: Colors.white
                                            .withValues(alpha: 0.2),
                                        thumbColor: Colors.white,
                                        overlayColor: _vibrantColor
                                            .withValues(alpha: 0.3),
                                      ),
                                      child: Slider(
                                        value: (_isScrubbing
                                                ? _scrubProgress
                                                : _progress)
                                            .clamp(0.0, 1.0),
                                        onChangeStart: (_) =>
                                            setState(() => _isScrubbing = true),
                                        onChanged: (v) => setState(() =>
                                            _scrubProgress = v.clamp(0.0, 1.0)),
                                        onChangeEnd: (v) async {
                                          final target = v.clamp(0.0, 1.0);
                                          final dur =
                                              player.duration ?? _duration;
                                          if (dur.inMilliseconds > 0) {
                                            final ms =
                                                (target * dur.inMilliseconds)
                                                    .round();
                                            try {
                                              await player.seek(
                                                  Duration(milliseconds: ms));
                                            } catch (_) {}
                                            if (mounted) {
                                              setState(() {
                                                _position =
                                                    Duration(milliseconds: ms);
                                                _progress = target;
                                              });
                                            }
                                          }
                                          if (mounted) {
                                            setState(() => _isScrubbing = false);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(_isScrubbing
                                              ? Duration(
                                                  milliseconds: (_scrubProgress *
                                                          _duration
                                                              .inMilliseconds)
                                                      .round())
                                              : _position),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(_duration),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Main controls avec glassmorphism
                          ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Shuffle
                                  StreamBuilder<bool>(
                                    stream: player.shuffleModeEnabledStream,
                                    initialData: player.shuffleModeEnabled,
                                    builder: (context, snapshot) {
                                      final isShuffleOn =
                                          snapshot.data ?? false;
                                      return IconButton(
                                        icon: PhosphorIcon(
                                          PhosphorIcons.shuffle(),
                                          size: 26,
                                          color: isShuffleOn
                                              ? _activeButtonColor
                                              : Colors.white
                                                  .withValues(alpha: 0.5),
                                        ),
                                        onPressed: () => player
                                            .setShuffleModeEnabled(
                                                !isShuffleOn),
                                      );
                                    },
                                  ),
                                  // Previous
                                  BouncyButton(
                                    onPressed: () => player.seekToPrevious(),
                                    child: PhosphorIcon(
                                      PhosphorIconsFill.skipBack(),
                                      size: 44,
                                      color: Colors.white,
                                    ),
                                  ),
                                  // Play/Pause (grand bouton)
                                  StreamBuilder<bool>(
                                    stream: player.playingStream,
                                    initialData: player.playing,
                                    builder: (context, snap) {
                                      final isPlaying = snap.data ?? false;
                                      return BouncyButton(
                                        onPressed: () {
                                          if (isPlaying) {
                                            player.pause();
                                          } else {
                                            player.play();
                                          }
                                        },
                                        scaleDown: 0.95,
                                        child: Container(
                                          width: 68,
                                          height: 68,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                _vibrantColor,
                                                _vibrantColor.withValues(
                                                    alpha: 0.8),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _vibrantColor
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 20,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: PhosphorIcon(
                                            isPlaying
                                                ? PhosphorIconsFill.pause()
                                                : PhosphorIconsFill.play(),
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Next
                                  BouncyButton(
                                    onPressed: () => player.seekToNext(),
                                    child: PhosphorIcon(
                                      PhosphorIconsFill.skipForward(),
                                      size: 44,
                                      color: Colors.white,
                                    ),
                                  ),
                                  // Repeat
                                  StreamBuilder<LoopMode>(
                                    stream: player.loopModeStream,
                                    initialData: player.loopMode,
                                    builder: (context, snapshot) {
                                      final mode = snapshot.data ?? LoopMode.off;
                                      IconData ic = PhosphorIcons.repeat();
                                      if (mode == LoopMode.one) {
                                        ic = PhosphorIcons.repeatOnce();
                                      }
                                      final isOn = mode != LoopMode.off;
                                      return BouncyButton(
                                        onPressed: () {
                                          if (mode == LoopMode.off) {
                                            player.setLoopMode(LoopMode.all);
                                          } else if (mode == LoopMode.all) {
                                            player.setLoopMode(LoopMode.one);
                                          } else {
                                            player.setLoopMode(LoopMode.off);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: const BoxDecoration(
                                            color: Colors.transparent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: PhosphorIcon(
                                            ic,
                                            size: 26,
                                            color: isOn
                                                ? _activeButtonColor
                                                : Colors.white.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                          const SizedBox(height: 16),

                          // Bottom actions (Paroles, Sleep Timer, File d'attente)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GlassButton(
                                icon: PhosphorIcons.textAa,
                                label: AppLocalizations.of(context)!.lyrics,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: context.read<PlayerCubit>(),
                                        child: const LyricsPage(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              _GlassButton(
                                icon: PhosphorIcons.playlist,
                                label: AppLocalizations.of(context)!.queue,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: context.read<PlayerCubit>(),
                                        child: const QueuePage(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          SizedBox(height: 20 + MediaQuery.of(context).padding.bottom),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// Widget pour les boutons avec effet glassmorphism
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
              child: Row(
                children: [
                  PhosphorIcon(icon, size: 22, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ),
        ),
      ),
    );
  }
}
