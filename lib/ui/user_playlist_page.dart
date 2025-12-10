import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_box/generated/app_localizations.dart';
import 'package:music_box/widgets/song_tile.dart';
import 'package:music_box/ui/widgets/music_box_scaffold.dart';
import '../core/background/background_cubit.dart';
import '../widgets/song_actions.dart';

import '../player/player_cubit.dart';
import '../player/mini_player.dart';
import 'song_picker_page.dart';
import 'now_playing_next_gen.dart';
import 'widgets/music_box_scaffold.dart';

class UserPlaylistPage extends StatefulWidget {
  const UserPlaylistPage({super.key, required this.playlistId, required this.playlistName});

  final String playlistId;
  final String playlistName;

  @override
  State<UserPlaylistPage> createState() => _UserPlaylistPageState();
}

class _UserPlaylistPageState extends State<UserPlaylistPage> {

  Future<List<SongModel>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
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

  Future<List<SongModel>> _load() async {
    final cubit = context.read<PlayerCubit>();
    // ✅ Optimization: Use cached songs from Cubit instead of querying again
    final allSongs = cubit.state.allSongs;
    
    // Get playlist song IDs
    final playlist = cubit.state.userPlaylists.firstWhere(
      (p) => p.id == widget.playlistId,
      orElse: () => const UserPlaylist(id: '', name: '', songIds: [], createdAtMillis: 0),
    );
    
    if (playlist.id.isEmpty) return [];

    // Create map for fast lookup
    final songMap = {for (var s in allSongs) s.id: s};
    
    // Retrieve songs in playlist order
    final result = <SongModel>[];
    for (final id in playlist.songIds) {
      final song = songMap[id];
      if (song != null) {
        result.add(song);
      }
    }
    
    // ✅ Apply hidden folder filter
    return cubit.filterSongs(result);
  }


  Future<void> _rename() async {
    final cubit = context.read<PlayerCubit>();
    final currentName = cubit.state.userPlaylists.firstWhere(
      (p) => p.id == widget.playlistId,
      orElse: () => const UserPlaylist(id: '', name: '', songIds: <int>[], createdAtMillis: 0),
    ).name;
    final controller = TextEditingController(text: currentName.isEmpty ? widget.playlistName : currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.renamePlaylist),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: AppLocalizations.of(context)!.playlistName),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text(AppLocalizations.of(context)!.save)),
          ],
        );
      },
    );
    if (newName != null && newName.trim().isNotEmpty) {
      cubit.renameUserPlaylist(widget.playlistId, newName.trim());
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _delete() async {
    final cubit = context.read<PlayerCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deletePlaylist),
        content: Text(AppLocalizations.of(context)!.confirmDeletePlaylist),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
          FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.delete)),
        ],
      ),
    );
    if (ok == true) {
      cubit.deleteUserPlaylist(widget.playlistId);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<PlayerCubit>();
    final upList = cubit.state.userPlaylists.where((p) => p.id == widget.playlistId);
    final displayName = upList.isNotEmpty ? upList.first.name : widget.playlistName;
    final theme = Theme.of(context);

    final scaffold = MusicBoxScaffold(
      body: Stack(
        children: [
          FutureBuilder<List<SongModel>>(
            future: _future,
            builder: (context, snap) {
              final songs = snap.connectionState == ConnectionState.done ? (snap.data ?? const <SongModel>[]) : const <SongModel>[];
              
              return BlocBuilder<BackgroundCubit, BackgroundType>(
                builder: (context, backgroundType) {
                  final hasCustomBackground = backgroundType != BackgroundType.none;
                  
                  return CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 180,
                        pinned: true,
                        stretch: true,
                        backgroundColor: hasCustomBackground ? Colors.black.withValues(alpha: 0.7) : theme.scaffoldBackgroundColor,
                        actions: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: _rename,
                        tooltip: AppLocalizations.of(context)!.renamePlaylist,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded),
                        onPressed: _delete,
                        tooltip: AppLocalizations.of(context)!.delete,
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
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
                                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                              Icons.queue_music_rounded,
                              size: 140,
                              color: theme.colorScheme.primary.withValues(alpha: 0.05),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Playlist Stats & Actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.music_note_rounded,
                                  size: 16,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(context)!.songCount(songs.length),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: songs.isEmpty
                                ? null
                                : () async {
                                    await _playAndOpen(songs, 0);
                                  },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(AppLocalizations.of(context)!.playAll),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: songs.isEmpty
                                ? null
                                : () async {
                                    // Shuffle logic here if needed, or just play random
                                    final random = List<SongModel>.from(songs)..shuffle();
                                    await _playAndOpen(random, 0);
                                  },
                            icon: const Icon(Icons.shuffle_rounded),
                            tooltip: AppLocalizations.of(context)!.shuffleAll,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (snap.connectionState != ConnectionState.done)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (songs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.music_off_rounded,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.emptyPlaylist,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.addSongsToPlaylistDesc,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () => _addSongs(cubit),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(AppLocalizations.of(context)!.addSongs),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverReorderableList(
                      itemCount: songs.length,
                      onReorder: (oldIndex, newIndex) async {
                        context.read<PlayerCubit>().reorderUserPlaylist(widget.playlistId, oldIndex, newIndex);
                        setState(() => _future = _load());
                      },
                      itemBuilder: (context, index) {
                        final s = songs[index];
                        final subtitle = [s.artist, s.album].where((e) => (e ?? '').isNotEmpty).join(' • ');
                        return ReorderableDelayedDragStartListener(
                          key: ValueKey('pl_${widget.playlistId}_${s.id}'),
                          index: index,
                          child: SongTile(
                            song: s,
                            subtitle: subtitle,
                            menuBuilder: (ctx, _) => SongMenu.commonItems(
                              ctx,
                              s,
                              includePlayNext: true,
                              includeAddToQueue: true,
                              includeAlbum: true,
                              includeArtist: true,
                              includeAddToPlaylist: true,
                              includeRemoveFromPlaylist: true,
                            ),
                            onMenuSelected: (value) async {
                              await SongMenu.onSelected(
                                context,
                                s,
                                value as String,
                                playlistId: widget.playlistId,
                                refresh: () => setState(() => _future = _load()),
                              );
                            },
                            onTap: () async {
                              await _playAndOpen(songs, index);
                            },
                          ),
                        );
                      },
                    ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
        },
          );
        },
      ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const MiniPlayer(),
          ),
          // Floating Action Button for adding songs (only visible when list is not empty)
          FutureBuilder<List<SongModel>>(
            future: _future,
            builder: (context, snap) {
              if (snap.hasData && snap.data!.isNotEmpty) {
                return Positioned(
                  right: 16,
                  bottom: 90, // Above MiniPlayer
                  child: FloatingActionButton(
                    onPressed: () => _addSongs(cubit),
                    tooltip: AppLocalizations.of(context)!.addSongs,
                    child: const Icon(Icons.add_rounded),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
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

  Future<void> _addSongs(PlayerCubit cubit) async {
    final added = await Navigator.of(context).push<List<int>>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PlayerCubit>(),
          child: SongPickerPage(
            initiallySelected: cubit.state.userPlaylists.firstWhere((p) => p.id == widget.playlistId).songIds,
          ),
        ),
      ),
    );
    if (added != null) {
      final p = cubit.state.userPlaylists.firstWhere((p) => p.id == widget.playlistId);
      // Remove unselected
      for (final id in List<int>.from(p.songIds)) {
        if (!added.contains(id)) {
           cubit.removeSongFromUserPlaylist(widget.playlistId, id);
        }
      }
      // Add new selected
      for (final id in added) {
        if (!p.songIds.contains(id)) {
          cubit.addSongToUserPlaylist(widget.playlistId, id);
        }
      }
      setState(() => _future = _load());
    }
  }
}
