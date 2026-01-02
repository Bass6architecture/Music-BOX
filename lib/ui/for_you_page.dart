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
import 'album_detail_page.dart';
import 'artist_detail_page.dart';

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
    
    // Sélectionner 30 chansons aléatoires
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
        
        // Refresh quick play si vide
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
                child: _buildQuickPlayHeader(context, state),
              ),
              
              // Continue Listening
              if (state.lastPlayed.isNotEmpty) ...[
                _buildSectionHeader(context, l10n.recentlyPlayed, PhosphorIcons.clockCounterClockwise()),
                _buildHorizontalSongList(context, _getRecentlyPlayed(state, allSongs)),
              ],
              
              // Most Played
              if (state.playCounts.isNotEmpty) ...[
                _buildSectionHeader(context, l10n.mostPlayed, PhosphorIcons.chartBar()),
                _buildHorizontalSongList(context, _getMostPlayed(state, allSongs)),
              ],
              
              // Recently Added
              _buildSectionHeader(context, l10n.recentlyAdded, PhosphorIcons.sparkle()),
              _buildHorizontalSongList(context, _getRecentlyAdded(allSongs)),
              
              // Discover (never played)
              _buildSectionHeader(context, 'Discover', PhosphorIcons.compass()),
              _buildHorizontalSongList(context, _getDiscoverSongs(state, allSongs)),
              
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
  
  Widget _buildQuickPlayHeader(BuildContext context, PlayerStateModel state) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    // Prendre la première chanson du quick play pour l'affichage
    final displaySong = _quickPlaySongs.isNotEmpty ? _quickPlaySongs.first : null;
    
    return Container(
      height: 220,
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background avec artwork blur
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
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.shuffle(),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Play',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Refresh button
                      IconButton(
                        onPressed: _refreshQuickPlay,
                        icon: Icon(
                          PhosphorIcons.arrowsClockwise(),
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Song info
                  if (displaySong != null) ...[
                    Text(
                      '${_quickPlaySongs.length} songs ready',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displaySong.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      displaySong.artist ?? 'Unknown Artist',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Play button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _playQuickPlay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: Icon(PhosphorIcons.play(PhosphorIconsStyle.fill)),
                      label: const Text(
                        'Play Mix',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
  
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
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
  
  Widget _buildHorizontalSongList(BuildContext context, List<SongModel> songs) {
    if (songs.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: songs.length.clamp(0, 15),
          itemBuilder: (context, index) {
            final song = songs[index];
            return _SongCard(
              song: song,
              onTap: () {
                final cubit = context.read<PlayerCubit>();
                HapticFeedback.lightImpact();
                cubit.setQueueAndPlay(songs, index);
              },
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

class _SongCard extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;
  
  const _SongCard({
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
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
            // Title
            Text(
              song.title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Artist
            Text(
              song.artist ?? 'Unknown',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
