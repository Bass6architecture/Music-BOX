import 'widgets/music_box_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_box/generated/app_localizations.dart';
import '../player/player_cubit.dart';
import '../player/mini_player.dart';
import '../widgets/song_tile.dart';
import '../widgets/song_actions.dart';


import 'now_playing_next_gen.dart';

import '../core/background/background_cubit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';



class RecentlyPlayedPage extends StatefulWidget {
  const RecentlyPlayedPage({super.key});

  @override
  State<RecentlyPlayedPage> createState() => _RecentlyPlayedPageState();
}

class _RecentlyPlayedPageState extends State<RecentlyPlayedPage> with AutomaticKeepAliveClientMixin {

  Future<List<SongModel>>? _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }




  Future<List<SongModel>> _load() async {
    final cubit = context.read<PlayerCubit>();
    
    // ✅ Attendre que les chansons soient chargées
    while (cubit.state.isLoading) {
      await cubit.stream.first;
    }
    
    final lastMap = cubit.state.lastPlayed;
    if (lastMap.isEmpty) return <SongModel>[];

    // ✅ Optimization: Use cached songs from Cubit
    final allSongs = cubit.state.allSongs;

    // Filtrer les fichiers avec des URIs valides
    final validSongs = allSongs.where((song) => song.uri != null).toList();

    final filteredSongs = cubit.filterSongs(validSongs);

    final songMap = <int, SongModel>{};
    for (final song in filteredSongs) {
      songMap[song.id] = song;
    }

    final sortedEntries = lastMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = <SongModel>[];
    for (final entry in sortedEntries) {
      if (result.length >= 100) break; // Limit to 100
      final song = songMap[entry.key];
      if (song != null) {
        result.add(song);
      }
    }
    
    return result;
  }

  Future<void> _playAndOpen(List<SongModel> list, int index) async {
    final cubit = context.read<PlayerCubit>();
    await cubit.setQueueAndPlay(list, index);
    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => openNextGenNowPlaying(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
        opaque: false, // ✅ Transparent
      ),
    );
  }

  void _playAll(List<SongModel> songs, {bool shuffle = false}) async {
    if (songs.isEmpty) return;
    final list = List<SongModel>.from(songs);
    if (shuffle) list.shuffle();
    if (!mounted) return;
    await _playAndOpen(list, 0);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);


    final scaffold = MusicBoxScaffold(
      body: Stack(
        children: [
          FutureBuilder<List<SongModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${AppLocalizations.of(context)!.error}: ${snap.error}'));
          }
          final songs = snap.data ?? const <SongModel>[];

          final theme = Theme.of(context);

              return RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _future = _load());
                    await _future;
                  },
                  child: BlocBuilder<BackgroundCubit, BackgroundType>(
                    builder: (context, backgroundType) {
                      final hasCustomBackground = backgroundType != BackgroundType.none;
                      
                      return CustomScrollView(
                        slivers: [
                          // AppBar épinglée avec gradient
                          SliverAppBar(
                            expandedHeight: 180,
                            pinned: true,
                            stretch: true,
                            backgroundColor: hasCustomBackground ? Colors.black.withValues(alpha: 0.7) : theme.scaffoldBackgroundColor,
                            actions: [
                    PopupMenuButton<String>(
                      tooltip: AppLocalizations.of(context)!.options,
                      onSelected: (value) async {
                        if (value == 'clear_history') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                                title: Text(AppLocalizations.of(context)!.recentlyPlayed, style: TextStyle()),
                                content: Text(AppLocalizations.of(context)!.confirmDelete, style: TextStyle()),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle())),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.delete, style: TextStyle())),
                                ],
                            ),
                          );
                          if (ok == true) {
                            if (!context.mounted) return;
                            await context.read<PlayerCubit>().clearHistory();
                            if (!context.mounted) return;
                            if (!mounted) return;
                            setState(() => _future = _load());
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context)!.historyCleared)),
                            );
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(value: 'clear_history', child: Text(AppLocalizations.of(context)!.clearHistory, style: TextStyle())),
                      ],
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      AppLocalizations.of(context)!.recentlyPlayed,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    centerTitle: false,
                    titlePadding: const EdgeInsetsDirectional.only(start: 60, bottom: 16), // ✅ Fix overlap
                              background: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.purple.withValues(alpha: 0.1),
                                          hasCustomBackground ? Colors.transparent : theme.colorScheme.surface,
                                        ],
                                        begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: PhosphorIcon(
                            PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill),
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Info et boutons
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.musicNote(),
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.songCount(songs.length),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        // Bouton shuffle
                        FilledButton.tonalIcon(
                          onPressed: songs.isEmpty ? null : () => _playAll(songs, shuffle: true),
                          icon: PhosphorIcon(PhosphorIcons.shuffle(), size: 20),
                          label: Text(AppLocalizations.of(context)!.shuffleAll, style: TextStyle(fontWeight: FontWeight.w600)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (songs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.noSongs,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final s = songs[index];
                        return Builder(
                          builder: (inner) {
                            final subtitle = () {
                              final parts = <String>[];
                              final meta = [s.artist, s.album]
                                  .where((e) => (e ?? '').isNotEmpty)
                                  .join(' • ');
                              if (meta.isNotEmpty) parts.add(meta);
                              // ✅ Removed relative time as requested
                              return parts.join(' • ');
                            }();
                            return Column(
                              children: [
                                SongTile(
                                  song: s,
                                  subtitle: subtitle,
                                  menuBuilder: (ctx, _) => SongMenu.commonItems(
                                    ctx,
                                    s,
                                    includeRemoveFromHistory: true,
                                  ),
                                  onMenuSelected: (value) async {
                                    await SongMenu.onSelected(
                                      context,
                                      s,
                                      value as String,
                                      refresh: () {
                                        if (mounted) setState(() => _future = _load());
                                      },
                                    );
                                  },
                                  onTap: () async {
                                    final list = await _future!;
                                    if (!context.mounted) return;
                                    await _playAndOpen(list, index);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      childCount: songs.length,
                    ),
                  ),

                // Extra bottom space so the last items don't sit behind the MiniPlayer
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            );
          },
        ),
      );
    },
  ),
          // Mini player en bas
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const MiniPlayer(),
          ),
        ],
      ),
    );

    return BlocListener<PlayerCubit, PlayerStateModel>(
      listenWhen: (prev, curr) =>
          prev.hiddenFolders != curr.hiddenFolders ||
          prev.showHiddenFolders != curr.showHiddenFolders ||
          prev.deletedSongIds != curr.deletedSongIds,
      listener: (context, state) {
        setState(() => _future = _load());
      },
      child: scaffold,
    );
  }

}

// (removed unused _ActionTile)




