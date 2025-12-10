import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_box/generated/app_localizations.dart';

import '../player/player_cubit.dart';
import '../player/mini_player.dart';
import 'now_playing_next_gen.dart';
import '../widgets/song_tile.dart';
import 'widgets/music_box_scaffold.dart';
import '../core/background/background_cubit.dart';
import '../widgets/song_actions.dart';

class AlbumDetailPage extends StatefulWidget {
  const AlbumDetailPage({super.key, this.albumId, required this.albumName});

  final int? albumId;
  final String albumName;

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  Future<List<SongModel>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<SongModel>> _load() async {
    final cubit = context.read<PlayerCubit>();
    // ✅ Optimization: Use cached songs
    final allSongs = cubit.state.allSongs;
    
    final albumId = widget.albumId;
    final albumName = widget.albumName;
    
    // Filter from cached songs
    final fromAlbum = allSongs.where((s) {
      if (albumId != null) return s.albumId == albumId;
      return (s.album ?? '').trim().toLowerCase() == albumName.trim().toLowerCase();
    }).toList();
    
    // Apply hidden folder filter
    final filtered = cubit.filterSongs(fromAlbum);

    return filtered;
  }

  Future<void> _playAndOpen(List<SongModel> list, int index) async {
    await context.read<PlayerCubit>().setQueueAndPlay(list, index);
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
    final title = widget.albumName;
    final theme = Theme.of(context);

    final scaffold = MusicBoxScaffold(
      body: Stack(
        children: [
          FutureBuilder<List<SongModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final songs = snap.data ?? const <SongModel>[];

          return BlocBuilder<BackgroundCubit, BackgroundType>(
            builder: (context, backgroundType) {
              final hasCustomBackground = backgroundType != BackgroundType.none;
              
              return CustomScrollView(
                slivers: [
                  // AppBar épinglée avec gradient
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    backgroundColor: hasCustomBackground ? Colors.black.withValues(alpha: 0.7) : theme.scaffoldBackgroundColor,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsetsDirectional.only(start: 60, bottom: 16),
                      title: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (!hasCustomBackground)
                            Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                  hasCustomBackground ? Colors.transparent : theme.colorScheme.surface,
                                ],
                                begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 60,
                        left: 0,
                        right: 0,
                        child: Icon(
                          Icons.album_rounded,
                          size: 80,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
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
                      Icon(
                        Icons.music_note,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.songCount(songs.length),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      // Bouton shuffle
                      FilledButton.tonalIcon(
                        onPressed: songs.isEmpty ? null : () => _playAll(songs, shuffle: true),
                        icon: const Icon(Icons.shuffle, size: 20),
                        label: Text(AppLocalizations.of(context)!.shuffleAll),
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

              // Liste des chansons
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
                      final subtitle = [s.artist, s.album].where((e) => (e ?? '').isNotEmpty).join(' • ');
                      return SongTile(
                        song: s,
                        subtitle: subtitle,
                        menuBuilder: (ctx, _) => SongMenu.commonItems(ctx, s),
                        onMenuSelected: (value) async {
                          await SongMenu.onSelected(context, s, value as String);
                        },
                        onTap: () => _playAndOpen(songs, index),
                      );
                    },
                    childCount: songs.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          );
        },
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
        if (mounted) setState(() => _future = _load());
      },
      child: scaffold,
    );
  }
}
