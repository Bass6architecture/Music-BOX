import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_box/generated/app_localizations.dart';
import 'package:path/path.dart' as p;

import '../player/player_cubit.dart';
import '../player/mini_player.dart';
import '../widgets/song_tile.dart';
import '../widgets/song_actions.dart';
import 'song_actions_sheet.dart';
import 'widgets/music_box_scaffold.dart';
import '../core/background/background_cubit.dart';

class FolderSongsPage extends StatefulWidget {
  final String folderPath;
  final int songCount;

  const FolderSongsPage({
    super.key,
    required this.folderPath,
    required this.songCount,
  });

  @override
  State<FolderSongsPage> createState() => _FolderSongsPageState();
}

class _FolderSongsPageState extends State<FolderSongsPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _loading = true);
    try {
      final allSongs = await _audioQuery.querySongs(
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      
      if (!mounted) return;
      final cubit = context.read<PlayerCubit>();
      final visibleSongs = cubit.filterSongs(allSongs.where((s) => s.uri != null).toList());
      
      // Filtrer les chansons de ce dossier uniquement
      final folderSongs = visibleSongs.where((s) {
        if (s.data.isEmpty) return false;
        final dir = p.dirname(s.data);
        return dir == widget.folderPath;
      }).toList();
      
      // Trier par titre
      folderSongs.sort((a, b) => (a.title).compareTo(b.title));
      
      if (!mounted) return;
      setState(() {
        _songs = folderSongs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    } finally {
      if (mounted && _loading) setState(() => _loading = false); // Ensure loading is false even if error occurs before setState in try block
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PlayerCubit>();
    final folderName = p.basename(widget.folderPath);

    return MusicBoxScaffold(
      body: Stack(
        children: [
          BlocBuilder<BackgroundCubit, BackgroundType>(
            builder: (context, backgroundType) {
              final hasCustomBackground = backgroundType != BackgroundType.none;
              
              return CustomScrollView(
                slivers: [
          // AppBar avec gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: hasCustomBackground ? Colors.black.withValues(alpha: 0.7) : theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                folderName,
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
                      Icons.folder_rounded,
                      size: 80,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Informations du dossier
          SliverToBoxAdapter(
            child: Container(
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
                    l10n.songCount(_songs.length),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  // Bouton shuffle all
                  FilledButton.tonalIcon(
                    onPressed: _songs.isEmpty
                        ? null
                        : () async {
                            // Mélanger et jouer
                            final shuffled = List<SongModel>.from(_songs)..shuffle();
                            await cubit.setQueueAndPlay(shuffled, 0);
                          },
                    icon: const Icon(Icons.shuffle, size: 20),
                    label: Text(l10n.shuffleAll),
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
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_songs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.music_off,
                      size: 56,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noSongs,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final song = _songs[i];
                    return SongTile(
                      song: song,
                      onTap: () async {
                        await cubit.setQueueAndPlay(_songs, i);
                      },
                      onMorePressed: () => openSongActionsSheet(
                        context,
                        song,
                      ),
                      menuBuilder: (ctx, s) => SongMenu.commonItems(
                        ctx,
                        s,
                        includeRemoveFromPlaylist: false,
                      ),
                      onMenuSelected: (value) async {
                        await SongMenu.onSelected(
                          context,
                          song,
                          value,
                          refresh: _loadSongs,
                        );
                      },
                    );
                  },
                  childCount: _songs.length,
                ),
              ),
            ),
        ],
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
  }
}
