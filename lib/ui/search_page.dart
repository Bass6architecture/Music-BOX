import 'widgets/music_box_scaffold.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music_box/generated/app_localizations.dart'; 
import 'package:music_box/ui/now_playing_next_gen.dart';
import 'package:music_box/widgets/song_tile.dart';
import 'package:music_box/widgets/song_actions.dart';
import '../player/player_cubit.dart';
import '../player/mini_player.dart';

import '../core/background/background_cubit.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.embedded = false, this.initialQuery});

  final bool embedded;
  final String? initialQuery;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  bool _hasPermission = false;
  bool _loading = false;
  String _query = '';

  List<SongModel> _allSongs = const [];

  List<SongModel> _songs = const [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      _query = widget.initialQuery!;
    }
    _init();
  }

  Future<void> _init() async {
    final has = await _audioQuery.permissionsStatus();
    if (!mounted) return;
    setState(() => _hasPermission = has);
    if (!has) return;

    setState(() => _loading = true);
    try {
      final cubit = context.read<PlayerCubit>();
      List<SongModel> songs;
      
      // ✅ Attendre que les chansons soient chargées
      while (cubit.state.isLoading) {
        await cubit.stream.first;
      }
      
      // ✅ Optimization: Use cached songs if available
      if (cubit.state.allSongs.isNotEmpty) {
        songs = cubit.state.allSongs;
      } else {
        songs = await _audioQuery.querySongs(
          sortType: SongSortType.TITLE,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
        );
      }
      
      // Filtrer les fichiers avec des URIs valides
      final validSongs = songs.where((song) => song.uri != null).toList();
      
      // Filtrer les dossiers masquÃ©s
      if (!mounted) return;
      final filteredSongs = cubit.filterSongs(validSongs);
      setState(() {
        _allSongs = filteredSongs;
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestPermission() async {
    final ok = await _audioQuery.permissionsRequest();
    if (!mounted) return;
    setState(() => _hasPermission = ok);
    if (ok) _init();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      setState(() => _query = value.trim());
      _applyFilter();
    });
  }

  void _applyFilter() {
    final q = _query.toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _songs = const [];
      });
      return;
    }

    final songs = _allSongs.where((s) {
      final title = (s.title).toLowerCase();
      final artist = (s.artist ?? '').toLowerCase();
      // Rechercher dans le titre OU l'artiste
      return title.contains(q) || artist.contains(q);
    }).toList();

    setState(() {
      _songs = songs;
    });
  }

  Future<void> _playSongs(List<SongModel> list, int index) async {
    await context.read<PlayerCubit>().setQueueAndPlay(list, index);
    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => openNextGenNowPlaying(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
        opaque: false, // âœ… Transparent
      ),
    );
  }

  

  Widget _buildResultsHeader(BuildContext context) {
    if (_query.isEmpty) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 16,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              '${_songs.length} rÃ©sultat${_songs.length > 1 ? "s" : ""} pour "$_query"',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongs(BuildContext context) {
    final theme = Theme.of(context);
    if (_songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(AppLocalizations.of(context)!.noSongs, style: theme.textTheme.bodyMedium),
        ),
      );
    }
    return ListView.builder(
      itemCount: _songs.length,
      itemBuilder: (context, i) {
        final s = _songs[i];
        final subtitle = [s.artist, s.album].where((e) => (e ?? '').isNotEmpty).join(' â€¢ ');

        return SongTile(
          song: s,
          subtitle: subtitle,
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
          onTap: () => _playSongs(_songs, i),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildResultsHeader(context),

          if (!_hasPermission)
            Material(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
                title: Text(AppLocalizations.of(context)!.settings),
                trailing: const Icon(Icons.chevron_right),
                onTap: _requestPermission,
              ),
            )
          else if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: _buildSongs(context),
            ),
        ],
      ),
    );

    if (widget.embedded) return content;

    return BlocBuilder<BackgroundCubit, BackgroundType>(
      builder: (context, backgroundType) {
        final hasCustomBackground = backgroundType != BackgroundType.none;

        final scaffold = MusicBoxScaffold(
          appBar: AppBar(
            backgroundColor: hasCustomBackground ? Colors.transparent : null,
            title: TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.search,
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              onChanged: _onQueryChanged,
            ),
            actions: [
              if (_query.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _onQueryChanged('');
                  },
                ),
            ],
          ),
          body: Stack(
            children: [
              content,
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
            // Recharger l'index de recherche pour reflÃ©ter le masquage/dÃ©masquage
            if (_hasPermission) {
              _init();
            }
          },
          child: scaffold,
        );
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}


