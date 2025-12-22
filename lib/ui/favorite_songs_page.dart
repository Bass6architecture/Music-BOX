import 'widgets/music_box_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_box/generated/app_localizations.dart';

import '../player/player_cubit.dart';
import '../player/mini_player.dart';
import 'now_playing_next_gen.dart';
import '../widgets/song_tile.dart';

import '../core/background/background_cubit.dart';
import '../widgets/song_actions.dart';
 
import 'package:share_plus/share_plus.dart'; 
import 'dart:math' as math;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';


class FavoriteSongsPage extends StatefulWidget {
  const FavoriteSongsPage({super.key});

  @override
  State<FavoriteSongsPage> createState() => _FavoriteSongsPageState();
}

class _FavoriteSongsPageState extends State<FavoriteSongsPage> {
  Future<List<SongModel>>? _future;
  
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;
  List<SongModel> _currentSongs = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<SongModel>> _load() async {
    final cubit = context.read<PlayerCubit>();
    final favIds = cubit.state.favorites;
    final allSongs = cubit.state.allSongs;
    
    final filteredSongs = cubit.filterSongs(allSongs);
    final result = filteredSongs.where((song) => favIds.contains(song.id)).toList();
    _currentSongs = result;
    
    if (_isSelectionMode) {
      final currentIds = _currentSongs.map((s) => s.id).toSet();
      _selectedIds.removeWhere((id) => !currentIds.contains(id));
      if (_selectedIds.isEmpty) _isSelectionMode = false;
    }
    
    return result;
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
        opaque: false, 
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
  
  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _currentSongs.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.addAll(_currentSongs.map((s) => s.id));
        _isSelectionMode = true;
      }
    });
  }
  
  void _exitSelectionMode() {
    if (!mounted) return;
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }
  
  void _playSelected() {
     if (_selectedIds.isEmpty) return;
     final selectedSongs = _currentSongs.where((s) => _selectedIds.contains(s.id)).toList();
     context.read<PlayerCubit>().setQueueAndPlay(selectedSongs, 0);
     _exitSelectionMode();
  }

  Future<void> _addToPlaylistSelected() async {
    final selectedSongs = _currentSongs.where((s) => _selectedIds.contains(s.id)).toList();
    if (selectedSongs.isEmpty) return;
    
    final cubit = context.read<PlayerCubit>();
    final playlists = cubit.state.userPlaylists;
    final l10n = AppLocalizations.of(context)!;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: PhosphorIcon(PhosphorIcons.plus()),
              title: Text(l10n.createPlaylist, style: GoogleFonts.outfit()),
              onTap: () async {
                Navigator.pop(ctx);
                final name = await _promptForText(context, title: l10n.createPlaylist, hint: l10n.playlistNameHint);
                if (name != null && name.trim().isNotEmpty) {
                  final id = cubit.createUserPlaylist(name.trim());
                  for (final s in selectedSongs) {
                    cubit.addSongToUserPlaylist(id, s.id);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.songAdded)));
                    _exitSelectionMode();
                  }
                }
              },
            ),
            const Divider(height: 1),
            SizedBox(
              height: math.min(MediaQuery.of(context).size.height * 0.5, 420),
              child: ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (_, i) {
                  final p = playlists[i];
                  return ListTile(
                    leading: PhosphorIcon(PhosphorIcons.playlist()),
                    title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit()),
                    subtitle: Text(l10n.songCount(p.songIds.length), style: GoogleFonts.outfit()),
                    onTap: () {
                      for (final s in selectedSongs) {
                         cubit.addSongToUserPlaylist(p.id, s.id);
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.songAdded)));
                      _exitSelectionMode();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<String?> _promptForText(BuildContext context, {required String title, String? hint}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: GoogleFonts.outfit()),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.outfit(),
          decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.outfit()),
          onSubmitted: (_) => Navigator.pop(context, controller.text),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel, style: GoogleFonts.outfit())),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(AppLocalizations.of(context)!.confirm, style: GoogleFonts.outfit())),
        ],
      ),
    );
  }

  Future<void> _shareSelected() async {
    final selectedSongs = _currentSongs.where((s) => _selectedIds.contains(s.id)).toList();
    if (selectedSongs.isEmpty) return;

    final xFiles = <XFile>[];
    for (final s in selectedSongs) {
      if ((s.data).isNotEmpty) { 
        xFiles.add(XFile(s.data));
      }
    }

    if (xFiles.isEmpty) return;

    try {
      await Share.shareXFiles(xFiles, text: '${xFiles.length} songs');
      _exitSelectionMode();
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error sharing: $e")));
      }
    }
  }

  Future<void> _removeSelected() async {
    final selectedSongs = _currentSongs.where((s) => _selectedIds.contains(s.id)).toList();
    if (selectedSongs.isEmpty) return;
    
    final cubit = context.read<PlayerCubit>();
    for (final s in selectedSongs) {
      cubit.toggleFavoriteById(s.id); 
    }
    
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("RetirÃ© des favoris"))); 
       _exitSelectionMode();
       _future = _load(); 
       setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<PlayerCubit>();
    final favIds = cubit.state.favorites;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<PlayerCubit, PlayerStateModel>(
      listenWhen: (prev, curr) =>
          prev.hiddenFolders != curr.hiddenFolders ||
          prev.showHiddenFolders != curr.showHiddenFolders ||
          prev.deletedSongIds != curr.deletedSongIds ||
          prev.favorites != curr.favorites,
      listener: (context, state) {
        setState(() => _future = _load());
      },
      child: PopScope(
        canPop: !_isSelectionMode,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_isSelectionMode) {
            _exitSelectionMode();
          }
        },
        child: MusicBoxScaffold(
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
                          SliverAppBar(
                            expandedHeight: _isSelectionMode ? 0 : 180,
                            pinned: true,
                            backgroundColor: _isSelectionMode 
                              ? theme.colorScheme.surface 
                              : (hasCustomBackground ? Colors.black.withValues(alpha: 0.7) : theme.scaffoldBackgroundColor),
                            automaticallyImplyLeading: !_isSelectionMode,
                            title: _isSelectionMode ? Row(
                                children: [
                                   IconButton(
                                     icon: PhosphorIcon(PhosphorIcons.x()), 
                                     onPressed: _exitSelectionMode,
                                   ),
                                   const SizedBox(width: 8),
                                   Text('${_selectedIds.length}', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                                   const Spacer(),
                                   TextButton.icon(
                                     onPressed: _selectAll,
                                     icon: PhosphorIcon(_selectedIds.length == songs.length ? PhosphorIcons.minusSquare() : PhosphorIcons.checkSquare()),
                                     label: Text(
                                       _selectedIds.length == songs.length ? "DÃ©sÃ©lect. tout" : l10n.selectAll, 
                                       style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                                     ),
                                   )
                                ],
                            ) : null,
                            centerTitle: false,
                            flexibleSpace: _isSelectionMode ? null : FlexibleSpaceBar(
                              title: Text(
                                l10n.favorites,
                                style: GoogleFonts.outfit(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
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
                                    child: PhosphorIcon(
                                      PhosphorIcons.heart(PhosphorIconsStyle.fill),
                                      size: 140,
                                      color: Colors.red.withValues(alpha: 0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (!_isSelectionMode)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  PhosphorIcon(
                                    PhosphorIcons.musicNote(),
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.songCount(favIds.length),
                                    style: GoogleFonts.outfit(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  FilledButton.tonalIcon(
                                    onPressed: songs.isEmpty ? null : () => _playAll(songs, shuffle: true),
                                    icon: PhosphorIcon(PhosphorIcons.shuffle(), size: 20),
                                    label: Text(l10n.shuffleAll, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
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
                                  l10n.noFavorites,
                                  style: GoogleFonts.outfit(),
                                ),
                              ),
                            )
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index >= songs.length) return const SizedBox(height: 100);
                                  
                                  final s = songs[index];
                                  final subtitle = [s.artist, s.album].where((e) => (e ?? '').isNotEmpty).join(' â€¢ ');
                                  return SongTile(
                                    song: s,
                                    subtitle: subtitle,
                                    isSelectionMode: _isSelectionMode,
                                    isSelected: _selectedIds.contains(s.id),
                                    onTap: () {
                                       if (_isSelectionMode) {
                                         _toggleSelection(s.id);
                                       } else {
                                         _playAndOpen(songs, index);
                                       }
                                    },
                                    onLongPress: () {
                                       if (!_isSelectionMode) _toggleSelection(s.id);
                                    },
                                    menuBuilder: _isSelectionMode ? null : (ctx, _) => SongMenu.commonItems(ctx, s),
                                    onMenuSelected: _isSelectionMode ? null : (value) async {
                                      await SongMenu.onSelected(context, s, value as String);
                                    },
                                  );
                                },
                                childCount: songs.length + 1,
                              ),
                            ),

                          if (!_isSelectionMode) const SliverToBoxAdapter(child: SizedBox(height: 96)),
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
                child: _isSelectionMode 
                    ? _buildSelectionBottomBar(context, l10n)
                    : const MiniPlayer(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSelectionBottomBar(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      child: Container(
        decoration: BoxDecoration(
           color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.95),
           borderRadius: BorderRadius.circular(24),
           boxShadow: [
             BoxShadow(
               color: Colors.black.withValues(alpha: 0.2),
               blurRadius: 16,
               offset: const Offset(0, 4),
             ),
           ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
             _buildBarAction(context, PhosphorIcons.play(PhosphorIconsStyle.fill), l10n.play, _playSelected),
             _buildBarAction(context, PhosphorIcons.playlist(PhosphorIconsStyle.fill), l10n.addToPlaylist, _addToPlaylistSelected),
             _buildBarAction(context, PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill), l10n.share, _shareSelected),
             _buildBarAction(context, PhosphorIcons.trash(PhosphorIconsStyle.fill), l10n.removeFromList, _removeSelected, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBarAction(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
     final theme = Theme.of(context);
     final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
     
     return InkWell(
       onTap: onTap,
       borderRadius: BorderRadius.circular(16),
       child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             PhosphorIcon(icon, color: color, size: 24),
             const SizedBox(height: 4),
             Text(
               label,
               textAlign: TextAlign.center,
               style: GoogleFonts.outfit(
                 color: color,
                 fontSize: 10,
               ),
             ),
           ],
         ),
       ),
     );
  }
}


