import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_box/generated/app_localizations.dart';
import 'package:music_box/widgets/song_tile.dart';
import 'package:music_box/widgets/song_actions.dart';

import '../player/player_cubit.dart';
import '../player/mini_player.dart';
import 'now_playing_next_gen.dart';
import 'widgets/music_box_scaffold.dart';
import '../core/background/background_cubit.dart';

class FavoriteSongsPage extends StatefulWidget {
  const FavoriteSongsPage({super.key});

  @override
  State<FavoriteSongsPage> createState() => _FavoriteSongsPageState();
}

class _FavoriteSongsPageState extends State<FavoriteSongsPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  Future<List<SongModel>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  

  Future<List<SongModel>> _load() async {
    final cubit = context.read<PlayerCubit>();
    final favIds = cubit.state.favorites;
    // ✅ Optimization: Use cached songs from Cubit
    final allSongs = cubit.state.allSongs;
    
    // Filtrer les dossiers masqués
    final filteredSongs = cubit.filterSongs(allSongs);
    
    return filteredSongs.where((song) => favIds.contains(song.id)).toList();
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
    final cubit = context.watch<PlayerCubit>();

    final favIds = cubit.state.favorites;

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

              return BlocBuilder<BackgroundCubit, BackgroundType>(
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
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text(
                            AppLocalizations.of(context)!.favorites,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          centerTitle: false,
                          titlePadding: const EdgeInsetsDirectional.only(start: 60, bottom: 16),
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.withValues(alpha: 0.1),
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
                            child: Icon(
                              Icons.favorite_rounded,
                              size: 140,
                              color: Colors.red.withValues(alpha: 0.1),
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
                            AppLocalizations.of(context)!.songCount(favIds.length),
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
                          AppLocalizations.of(context)!.noFavorites,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final s = songs[index];

                          return SongTile(
                            song: s,
                            menuBuilder: (ctx, _) => SongMenu.commonItems(
                              ctx,
                              s,
                              includePlayNext: false,
                              includeAddToQueue: false,
                              includeAlbum: false,
                              includeArtist: false,
                              includeAddToPlaylist: true,
                              includeRemoveFromPlaylist: false,
                            ),
                            onMenuSelected: (value) async {
                              await SongMenu.onSelected(context, s, value as String);
                            },
                            onTap: () async {
                              await _playAndOpen(songs, index);
                            },
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
        setState(() => _future = _load());
      },
      child: scaffold,
    );
  }

}





