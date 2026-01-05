import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../generated/app_localizations.dart';
import '../player/player_cubit.dart';
import '../widgets/optimized_artwork.dart';

class ForYouPage extends StatefulWidget {
  const ForYouPage({super.key});

  @override
  State<ForYouPage> createState() => _ForYouPageState();
}

class _ForYouPageState extends State<ForYouPage> {
  List<SongModel> _quickPlaySongs = [];
  final _random = Random();
  
  @override
  void initState() {
    super.initState();
    _refreshQuickPlay();
  }
  
  void _refreshQuickPlay() {
    final cubit = context.read<PlayerCubit>();
    final allSongs = cubit.state.allSongs;
    
    if (allSongs.isEmpty) return;
    
    final shuffled = List<SongModel>.from(allSongs)..shuffle(_random);
    setState(() {
      _quickPlaySongs = shuffled.take(30).toList();
    });
  }
  
  void _playQuickPlay() {
    if (_quickPlaySongs.isEmpty) return;
    
    final cubit = context.read<PlayerCubit>();
    HapticFeedback.mediumImpact();
    cubit.setQueueAndPlay(_quickPlaySongs, 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return BlocBuilder<PlayerCubit, PlayerStateModel>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allSongs = state.allSongs;
        if (allSongs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.musicNotes(),
                  size: 64,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noSongs,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }
        
        if (_quickPlaySongs.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _refreshQuickPlay());
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            _refreshQuickPlay();
          },
          child: CustomScrollView(
            slivers: [
              // Quick Play Header
              SliverToBoxAdapter(
                child: _buildQuickPlayHeader(context, l10n),
              ),
              
              // Recently Played - Pochettes RONDES
              if (state.lastPlayed.isNotEmpty) ...[
                _buildSectionHeader(context, l10n.recentlyPlayed, PhosphorIcons.clockCounterClockwise()),
                _buildCircularSongList(context, _getRecentlyPlayed(state, allSongs)),
              ],
              
              // Most Played - Pochettes CARRÉES avec badge
              if (state.playCounts.isNotEmpty) ...[
                _buildSectionHeader(context, l10n.mostPlayed, PhosphorIcons.chartBar()),
                _buildSquareSongListWithBadge(context, _getMostPlayed(state, allSongs), state),
              ],
              
              // Recently Added - Pochettes CARRÉES normales
              _buildSectionHeader(context, l10n.recentlyAdded, PhosphorIcons.sparkle()),
              _buildSquareSongList(context, _getRecentlyAdded(allSongs)),
              
              // Discover - Pochettes CARRÉES avec overlay gradient
              _buildSectionHeader(context, l10n.discover, PhosphorIcons.compass()),
              _buildDiscoverSongList(context, _getDiscoverSongs(state, allSongs)),
              
              // Bottom padding for mini player
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildQuickPlayHeader(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final displaySong = _quickPlaySongs.isNotEmpty ? _quickPlaySongs.first : null;
    
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background artwork
            if (displaySong != null)
              OptimizedArtwork.square(
                id: displaySong.id,
                type: ArtworkType.AUDIO,
                size: 300,
                borderRadius: BorderRadius.zero,
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
              ),
            
            // Blur overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Left: Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.shuffle(),
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.quickPlay,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.songsReady(_quickPlaySongs.length),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Play button
                        ElevatedButton.icon(
                          onPressed: _playQuickPlay,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          icon: Icon(PhosphorIcons.play(PhosphorIconsStyle.fill), size: 18),
                          label: Text(
                            l10n.playMix,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right: Refresh button
                  IconButton(
                    onPressed: _refreshQuickPlay,
                    icon: Icon(
                      PhosphorIcons.arrowsClockwise(),
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 28,
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
  
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // POCHETTES RONDES pour Recently Played
  Widget _buildCircularSongList(BuildContext context, List<SongModel> songs) {
    if (songs.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final theme = Theme.of(context);
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: songs.length.clamp(0, 15),
          itemBuilder: (context, index) {
            final song = songs[index];
            return GestureDetector(
              onTap: () {
                final cubit = context.read<PlayerCubit>();
                HapticFeedback.lightImpact();
                cubit.setQueueAndPlay(songs, index);
              },
              child: Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    // Pochette RONDE
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: OptimizedArtwork.square(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          size: 90,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      song.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      song.artist ?? 'Unknown',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // POCHETTES CARRÉES avec badge pour Most Played
  Widget _buildSquareSongListWithBadge(BuildContext context, List<SongModel> songs, PlayerStateModel state) {
    if (songs.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final theme = Theme.of(context);
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: songs.length.clamp(0, 15),
          itemBuilder: (context, index) {
            final song = songs[index];
            final playCount = state.playCounts[song.id] ?? 0;
            
            return GestureDetector(
              onTap: () {
                final cubit = context.read<PlayerCubit>();
                HapticFeedback.lightImpact();
                cubit.setQueueAndPlay(songs, index);
              },
              child: Container(
                width: 130,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: OptimizedArtwork.square(
                              id: song.id,
                              type: ArtworkType.AUDIO,
                              size: 130,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        // Badge play count
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${playCount}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // POCHETTES CARRÉES normales pour Recently Added
  Widget _buildSquareSongList(BuildContext context, List<SongModel> songs) {
    if (songs.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final theme = Theme.of(context);
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: songs.length.clamp(0, 15),
          itemBuilder: (context, index) {
            final song = songs[index];
            return GestureDetector(
              onTap: () {
                final cubit = context.read<PlayerCubit>();
                HapticFeedback.lightImpact();
                cubit.setQueueAndPlay(songs, index);
              },
              child: Container(
                width: 130,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: OptimizedArtwork.square(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          size: 130,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist ?? 'Unknown',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // POCHETTES avec overlay gradient pour Discover
  Widget _buildDiscoverSongList(BuildContext context, List<SongModel> songs) {
    if (songs.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final theme = Theme.of(context);
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: songs.length.clamp(0, 15),
          itemBuilder: (context, index) {
            final song = songs[index];
            return GestureDetector(
              onTap: () {
                final cubit = context.read<PlayerCubit>();
                HapticFeedback.lightImpact();
                cubit.setQueueAndPlay(songs, index);
              },
              child: Container(
                width: 140,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: OptimizedArtwork.square(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          size: 160,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    // Gradient overlay with title
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              song.artist ?? 'Unknown',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  List<SongModel> _getRecentlyPlayed(PlayerStateModel state, List<SongModel> allSongs) {
    final lastMap = state.lastPlayed;
    if (lastMap.isEmpty) return [];
    
    final songMap = {for (var s in allSongs) s.id: s};
    final sorted = lastMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted
        .where((e) => songMap.containsKey(e.key))
        .map((e) => songMap[e.key]!)
        .take(15)
        .toList();
  }
  
  List<SongModel> _getMostPlayed(PlayerStateModel state, List<SongModel> allSongs) {
    final counts = state.playCounts;
    if (counts.isEmpty) return [];
    
    final songMap = {for (var s in allSongs) s.id: s};
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted
        .where((e) => songMap.containsKey(e.key) && e.value > 0)
        .map((e) => songMap[e.key]!)
        .take(15)
        .toList();
  }
  
  List<SongModel> _getRecentlyAdded(List<SongModel> allSongs) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final thirtyDaysAgo = now - (30 * 24 * 60 * 60);
    
    final recent = allSongs.where((s) => (s.dateAdded ?? 0) >= thirtyDaysAgo).toList();
    recent.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
    
    return recent.take(15).toList();
  }
  
  List<SongModel> _getDiscoverSongs(PlayerStateModel state, List<SongModel> allSongs) {
    final played = state.playCounts.keys.toSet();
    final lastPlayed = state.lastPlayed.keys.toSet();
    final touchedIds = played.union(lastPlayed);
    
    final unplayed = allSongs.where((s) => !touchedIds.contains(s.id)).toList();
    unplayed.shuffle(_random);
    
    return unplayed.take(15).toList();
  }
}
