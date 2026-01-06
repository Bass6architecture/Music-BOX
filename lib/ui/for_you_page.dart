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
  
  static const int _minListensForHistory = 5;
  
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
    setState(() => _quickPlaySongs = shuffled.take(30).toList());
  }
  
  void _playQuickPlay() {
    if (_quickPlaySongs.isEmpty) return;
    final cubit = context.read<PlayerCubit>();
    HapticFeedback.mediumImpact();
    cubit.setQueueAndPlay(_quickPlaySongs, 0);
  }
  
  bool _hasListeningHistory(PlayerStateModel state) {
    final totalListens = state.playCounts.values.fold(0, (a, b) => a + b);
    return totalListens >= _minListensForHistory;
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
                Icon(PhosphorIcons.musicNotes(), size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(l10n.noSongs),
              ],
            ),
          );
        }
        
        if (_quickPlaySongs.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _refreshQuickPlay());
        }
        
        final hasHistory = _hasListeningHistory(state);
        
        return RefreshIndicator(
          onRefresh: () async => _refreshQuickPlay(),
          child: CustomScrollView(
            slivers: [
              // Quick Play Header
              SliverToBoxAdapter(child: _buildQuickPlayHeader(context, l10n)),
              
              if (hasHistory) ...[
                // Jouer en dernier
                if (state.lastPlayed.isNotEmpty) ...[
                  _buildSectionHeader(context, l10n.recentlyPlayed),
                  _buildNormalSongList(context, _getRecentlyPlayed(state, allSongs)),
                ],
                
                // Les plus joués avec badges #1 #2 #3
                if (state.playCounts.isNotEmpty) ...[
                  _buildSectionHeader(context, l10n.mostPlayed),
                  _buildRankedSongList(context, _getMostPlayed(state, allSongs)),
                ],
                
                // Pépites Oubliées (noir et blanc)
                _buildSectionHeader(context, l10n.forgottenGems),
                _buildGrayscaleSongList(context, _getForgottenGems(state, allSongs)),
              ] else ...[
                // Nouvel utilisateur - Découvrir
                _buildSectionHeader(context, l10n.discover),
                _buildNormalSongList(context, _getDiscoverSongs(allSongs)),
              ],
              
              // Récemment ajouté (en liste)
              _buildSectionHeader(context, l10n.recentlyAdded),
              _buildRecentlyAddedList(context, state, _getRecentlyAdded(allSongs)),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
      height: 180,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (displaySong != null)
              OptimizedArtwork.square(id: displaySong.id, type: ArtworkType.AUDIO, size: 400)
            else
              Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]))),
            
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Colors.black.withValues(alpha: 0.4), Colors.black.withValues(alpha: 0.6)],
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(PhosphorIcons.shuffle(), color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.quickPlay, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(l10n.songsReady(_quickPlaySongs.length), style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _playQuickPlay,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          icon: Icon(PhosphorIcons.play(PhosphorIconsStyle.fill), size: 16),
                          label: Text(l10n.playMix, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: _refreshQuickPlay, icon: Icon(PhosphorIcons.arrowsClockwise(), color: Colors.white70, size: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Header SANS icône - juste le titre
  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }
  
  // Pochettes normales
  Widget _buildNormalSongList(BuildContext context, List<SongModel> songs) {
    if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final theme = Theme.of(context);
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: songs.length.clamp(0, 15),
          itemBuilder: (context, index) => _buildSongCard(context, songs[index], songs, index, theme),
        ),
      ),
    );
  }
  
  // Pochettes avec badges #1 #2 #3
  Widget _buildRankedSongList(BuildContext context, List<SongModel> songs) {
    if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
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
                context.read<PlayerCubit>().setQueueAndPlay(songs, index);
                HapticFeedback.lightImpact();
              },
              child: Container(
                width: 130,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        _buildArtworkContainer(song.id, theme),
                        // Badge #1, #2, #3...
                        Positioned(
                          top: 8, left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: index < 3 ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '#${index + 1}',
                              style: TextStyle(
                                color: index < 3 ? Colors.white : theme.colorScheme.onSurface,
                                fontSize: 11, fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(song.title, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(song.artist ?? 'Unknown', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Pochettes en NOIR ET BLANC pour Pépites Oubliées
  Widget _buildGrayscaleSongList(BuildContext context, List<SongModel> songs) {
    if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
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
                context.read<PlayerCubit>().setQueueAndPlay(songs, index);
                HapticFeedback.lightImpact();
              },
              child: Container(
                width: 130,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pochette en noir et blanc
                    Container(
                      width: 130, height: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15), width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                          child: OptimizedArtwork.square(id: song.id, type: ArtworkType.AUDIO, size: 130),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(song.title, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(song.artist ?? 'Unknown', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Liste comme page chansons avec 3 points
  Widget _buildRecentlyAddedList(BuildContext context, PlayerStateModel state, List<SongModel> songs) {
    if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final theme = Theme.of(context);
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= songs.length || index >= 10) return null;
          final song = songs[index];
          final isFavorite = state.favorites.contains(song.id);
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: OptimizedArtwork.square(id: song.id, type: ArtworkType.AUDIO, size: 50),
              ),
            ),
            title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            subtitle: Text(song.artist ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            trailing: IconButton(
              icon: Icon(PhosphorIcons.dotsThreeVertical(), color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              onPressed: () => _showSongOptions(context, song, isFavorite),
            ),
            onTap: () {
              context.read<PlayerCubit>().setQueueAndPlay(songs, index);
              HapticFeedback.lightImpact();
            },
          );
        },
        childCount: songs.length.clamp(0, 10),
      ),
    );
  }
  
  void _showSongOptions(BuildContext context, SongModel song, bool isFavorite) {
    final cubit = context.read<PlayerCubit>();
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(PhosphorIcons.play()),
              title: Text(l10n.playNext),
              onTap: () { cubit.playNext(song); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.queue()),
              title: Text(l10n.addToQueue),
              onTap: () { cubit.addToQueue(song); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: Icon(isFavorite ? PhosphorIcons.heartBreak() : PhosphorIcons.heart()),
              title: Text(isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites),
              onTap: () { cubit.toggleFavorite(song.id); Navigator.pop(ctx); },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSongCard(BuildContext context, SongModel song, List<SongModel> songs, int index, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        context.read<PlayerCubit>().setQueueAndPlay(songs, index);
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildArtworkContainer(song.id, theme),
            const SizedBox(height: 10),
            Text(song.title, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(song.artist ?? 'Unknown', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
  
  Widget _buildArtworkContainer(int songId, ThemeData theme) {
    return Container(
      width: 130, height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: OptimizedArtwork.square(id: songId, type: ArtworkType.AUDIO, size: 130),
      ),
    );
  }
  
  List<SongModel> _getRecentlyPlayed(PlayerStateModel state, List<SongModel> allSongs) {
    final lastMap = state.lastPlayed;
    if (lastMap.isEmpty) return [];
    final songMap = {for (var s in allSongs) s.id: s};
    final sorted = lastMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.where((e) => songMap.containsKey(e.key)).map((e) => songMap[e.key]!).take(15).toList();
  }
  
  List<SongModel> _getMostPlayed(PlayerStateModel state, List<SongModel> allSongs) {
    final counts = state.playCounts;
    if (counts.isEmpty) return [];
    final songMap = {for (var s in allSongs) s.id: s};
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.where((e) => songMap.containsKey(e.key) && e.value > 0).map((e) => songMap[e.key]!).take(15).toList();
  }
  
  // Pépites Oubliées = chansons écoutées il y a longtemps mais plus récemment
  List<SongModel> _getForgottenGems(PlayerStateModel state, List<SongModel> allSongs) {
    final lastPlayed = state.lastPlayed;
    if (lastPlayed.isEmpty) return [];
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;
    
    final songMap = {for (var s in allSongs) s.id: s};
    
    // Chansons écoutées il y a plus de 30 jours
    final forgotten = lastPlayed.entries
        .where((e) => (now - e.value) > thirtyDaysMs && songMap.containsKey(e.key))
        .map((e) => songMap[e.key]!)
        .toList();
    
    forgotten.shuffle(_random);
    return forgotten.take(15).toList();
  }
  
  List<SongModel> _getRecentlyAdded(List<SongModel> allSongs) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final thirtyDaysAgo = now - (30 * 24 * 60 * 60);
    final recent = allSongs.where((s) => (s.dateAdded ?? 0) >= thirtyDaysAgo).toList();
    recent.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
    return recent.take(15).toList();
  }
  
  List<SongModel> _getDiscoverSongs(List<SongModel> allSongs) {
    final shuffled = List<SongModel>.from(allSongs)..shuffle(_random);
    return shuffled.take(15).toList();
  }
}
