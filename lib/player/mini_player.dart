import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'player_cubit.dart';
import '../widgets/optimized_artwork.dart';
import '../ui/now_playing_next_gen.dart';
import '../ui/song_actions_sheet.dart';
import '../ui/widgets/bouncy_button.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key, this.disableNavigation = false});
  
  /// Si true, désactive l'ouverture de la page now playing (pour éviter les boucles)
  final bool disableNavigation;

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  bool _presenting = false;

  void _presentSheet() {
    if (_presenting) return;
    _presenting = true;
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => openNextGenNowPlaying(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // ✅ Animation "Directe" (Zoom + Fade) sans effet de glissement
          // C'est plus rapide et ne donne pas l'impression de "suivre le doigt"
          const curve = Curves.easeOutCubic;
          final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

          return FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnimation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        opaque: false, // ✅ Transparent pour voir l'écran derrière lors du dismiss
      ),
    ).whenComplete(() {
      _presenting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild MiniPlayer when the current song changes
    final cubit = context.read<PlayerCubit>();
    final player = cubit.player;
    final song = context.select((PlayerCubit c) => c.currentSong);

    if (song == null) {
      // Rien en cours — pas de barre
      return const SizedBox.shrink();
    }

    // Appliquer les overrides pour garantir des chaînes non nulles
    final safeSong = cubit.applyOverrides(song);
    // Violet principal de l'app
    final acc = Theme.of(context).colorScheme.primary;


    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.disableNavigation ? null : () => _presentSheet(),
          onVerticalDragEnd: widget.disableNavigation ? null : (details) {
            final v = details.primaryVelocity ?? 0;
            // Swipe up (negative velocity) opens Now Playing
            if (v < -300) {
              _presentSheet();
            }
          },
          onHorizontalDragEnd: widget.disableNavigation ? null : (details) async {
            final v = details.primaryVelocity ?? 0;
            try {
              if (v < -150) {
                await player.seekToNext();
              } else if (v > 150) {
                await player.seekToPrevious();
              }
            } catch (_) {}
          },
          onDoubleTap: widget.disableNavigation ? null : () async {
            try {
              final isPlaying = await player.playerStateStream.first.then((s) => s.playing);
              if (isPlaying) {
                await player.pause();
              } else {
                await player.play();
              }
            } catch (_) {}
          },
          onLongPress: widget.disableNavigation ? null : () => openSongActionsSheet(context, safeSong),
          child: Container(
            height: 76,
            margin: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ligne principale
                      Row(
                        children: [
                          // Pochette (Hero)
                          Hero(
                            tag: 'artwork_${safeSong.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: OptimizedArtwork.square(
                                  id: safeSong.id,
                                  type: ArtworkType.AUDIO,
                                  size: 56,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Titre / artiste
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  safeSong.title.isNotEmpty ? safeSong.title : 'Titre inconnu',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  safeSong.artist?.isNotEmpty == true ? safeSong.artist! : 'Artiste inconnu',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          // Contrôles circulaires 48dp
                          _MiniIconButton(
                            icon: Icons.skip_previous_rounded,
                            onPressed: () async { try { await player.seekToPrevious(); } catch (_) {} },
                          ),
                          StreamBuilder<PlayerState>(
                            stream: player.playerStateStream,
                            builder: (_, snap) {
                              final isPlaying = snap.data?.playing == true;
                              return _MiniIconButton(
                                icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                big: true,
                                accent: acc,
                                onPressed: () async { if (isPlaying) { await player.pause(); } else { await player.play(); } },
                              );
                            },
                          ),
                          _MiniIconButton(
                            icon: Icons.skip_next_rounded,
                            onPressed: () async { try { await player.seekToNext(); } catch (_) {} },
                          ),
                        ],
                      ),
                      // Barre de progression fine
                      const SizedBox(height: 6),
                      StreamBuilder<Duration>(
                        stream: player.positionStream,
                        initialData: player.position,
                        builder: (context, snap) {
                          final pos = snap.data ?? Duration.zero;
                          final dur = player.duration ?? Duration.zero;
                          final value = (dur.inMilliseconds > 0)
                              ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                              : 0.0;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 2,
                              backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(acc),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({required this.icon, required this.onPressed, this.big = false, this.accent});
  final IconData icon;
  final VoidCallback onPressed;
  final bool big;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = big ? 56.0 : 48.0;
    final iconSize = big ? 28.0 : 24.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: BouncyButton(
        onPressed: onPressed,
        scaleDown: 0.85,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: (big && accent != null)
                ? accent!.withValues(alpha: 0.18)
                : theme.colorScheme.surface.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: (big && accent != null)
                ? Colors.white
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
