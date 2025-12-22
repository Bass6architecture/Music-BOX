import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_box/generated/app_localizations.dart';
import 'package:music_box/widgets/song_tile.dart';
import 'package:music_box/ui/widgets/music_box_scaffold.dart';
import '../core/background/background_cubit.dart';
import '../widgets/song_actions.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;

import '../player/player_cubit.dart';
import '../player/mini_player.dart';
import 'song_picker_page.dart';
import 'now_playing_next_gen.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';



class UserPlaylistPage extends StatefulWidget {
  const UserPlaylistPage({super.key, required this.playlistId, required this.playlistName});

  final String playlistId;
  final String playlistName;

  @override
  State<UserPlaylistPage> createState() => _UserPlaylistPageState();
}

class _UserPlaylistPageState extends State<UserPlaylistPage> {

  Future<List<SongModel>>? _future;
  
  // Selection Mode State
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;
  List<SongModel> _currentSongs = [];

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
    final filtered = cubit.filterSongs(result);
    _currentSongs = filtered;
    
    // Clean selection
    if (_isSelectionMode) {
      final currentIds = _currentSongs.map((s) => s.id).toSet();
      _selectedIds.removeWhere((id) => !currentIds.contains(id));
      if (_selectedIds.isEmpty) _isSelectionMode = false;
    }
    
    return filtered;
  }
  
  // Selection Logic
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
          title: Text(AppLocalizations.of(context)!.renamePlaylist, style: GoogleFonts.outfit()),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(hintText: AppLocalizations.of(context)!.playlistName, hintStyle: GoogleFonts.outfit()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel, style: GoogleFonts.outfit())),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text(AppLocalizations.of(context)!.save, style: GoogleFonts.outfit())),
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
        title: Text(AppLocalizations.of(context)!.deletePlaylist, style: GoogleFonts.outfit()),
        content: Text(AppLocalizations.of(context)!.confirmDeletePlaylist, style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel, style: GoogleFonts.outfit())),
          FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.delete, style: GoogleFonts.outfit())),
        ],
      ),
    );
    if (ok == true) {
      cubit.deleteUserPlaylist(widget.playlistId);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  // Selection Actions
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
          decoration: InputDecoration(hintText: hint),
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
    
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PlayerCubit>();
    
    // Direct removal for playlist
    for (final s in selectedSongs) {
      cubit.removeSongFromUserPlaylist(widget.playlistId, s.id);
    }
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.playlistSongRemoved, style: GoogleFonts.outfit()))); // Ensure this key exists or use generic
       _exitSelectionMode();
       _future = _load(); // Refresh list
       setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<PlayerCubit>();
    final upList = cubit.state.userPlaylists.where((p) => p.id == widget.playlistId);
    final displayName = upList.isNotEmpty ? upList.first.name : widget.playlistName;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<PlayerCubit, PlayerStateModel>(
      listenWhen: (prev, curr) =>
          prev.hiddenFolders != curr.hiddenFolders ||
          prev.showHiddenFolders != curr.showHiddenFolders ||
          prev.deletedSongIds != curr.deletedSongIds,
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
                  final songs = snap.connectionState == ConnectionState.done ? (snap.data ?? const <SongModel>[]) : const <SongModel>[];
                  
                  return BlocBuilder<BackgroundCubit, BackgroundType>(
                    builder: (context, backgroundType) {
                      final hasCustomBackground = backgroundType != BackgroundType.none;
                      
                      return CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            expandedHeight: _isSelectionMode ? 0 : 180,
                            pinned: true,
                            stretch: true,
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
                                    Text('${_selectedIds.length}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                   const Spacer(),
                                   TextButton.icon(
                                     onPressed: _selectAll,
                                     icon: PhosphorIcon(_selectedIds.length == songs.length ? PhosphorIcons.minusCircle(PhosphorIconsStyle.fill) : PhosphorIcons.checkSquareOffset()),
                                     label: Text(_selectedIds.length == songs.length ? "Désélect. tout" : l10n.selectAll, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                                   )
                                ],
                            ) : null,
                            centerTitle: false,

                            actions: _isSelectionMode ? null : [
                             IconButton(
                               icon: PhosphorIcon(PhosphorIcons.pencilLine(), size: 20),
                               onPressed: _rename,
                               tooltip: l10n.renamePlaylist,
                             ),
                             IconButton(
                               icon: PhosphorIcon(PhosphorIcons.trash(), size: 20),
                               onPressed: _delete,
                               tooltip: l10n.delete,
                             ),
                            ],
                            flexibleSpace: _isSelectionMode ? null : FlexibleSpaceBar(
                              title: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
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
                                  child: PhosphorIcon(
                                  PhosphorIcons.playlist(),
                                  size: 140,
                                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                                ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Playlist Stats & Actions (Hidden in Selection Mode)
                        if (!_isSelectionMode)
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
                                      PhosphorIcon(
                                        PhosphorIcons.musicNote(),
                                        size: 16,
                                        color: theme.colorScheme.onSecondaryContainer,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n.songCount(songs.length),
                                        style: GoogleFonts.outfit(
                                          color: theme.colorScheme.onSecondaryContainer,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
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
                                   icon: PhosphorIcon(PhosphorIcons.play(), size: 20),
                                   label: Text(l10n.playAll, style: GoogleFonts.outfit()),
                                 ),
                                const SizedBox(width: 8),
                                 IconButton.filledTonal(
                                   onPressed: songs.isEmpty
                                       ? null
                                       : () async {
                                           final random = List<SongModel>.from(songs)..shuffle();
                                           await _playAndOpen(random, 0);
                                         },
                                   icon: PhosphorIcon(PhosphorIcons.shuffle(), size: 24),
                                   tooltip: l10n.shuffleAll,
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
                                    child: PhosphorIcon(
                                      PhosphorIcons.musicNote(PhosphorIconsStyle.fill), // Utilisation de .fill pour remplacer musicNoteSlash si manquant
                                      size: 48,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.emptyPlaylist,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.addSongsToPlaylistDesc,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  FilledButton.icon(
                                    onPressed: () => _addSongs(cubit),
                                    icon: PhosphorIcon(PhosphorIcons.plus()),
                                    label: Text(l10n.addSongs, style: GoogleFonts.outfit()),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          // Use SliverList instead of Reorderable if in Selection Mode to avoid conflict?
                          // Actually, we can just disable reorder by not wrapping in Reorderable
                          _isSelectionMode 
                          ? SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index >= songs.length) return const SizedBox(height: 100);
                                  
                                  final s = songs[index];
                                  final subtitle = [s.artist, s.album].where((e) => (e ?? '').isNotEmpty).join(' • ');
                                  return SongTile(
                                    song: s,
                                    subtitle: subtitle,
                                    isSelectionMode: true,
                                    isSelected: _selectedIds.contains(s.id),
                                    onTap: () => _toggleSelection(s.id),
                                    onLongPress: () => _toggleSelection(s.id),
                                    menuBuilder: null, // No menu in selection mode
                                  );
                                },
                                childCount: songs.length + 1,
                              ),
                          )
                          : SliverReorderableList(
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
                                    onLongPress: () {
                                       _toggleSelection(s.id);
                                    },
                                  ),
                                );
                              },
                            ),
                        
                        if (!_isSelectionMode)
                           const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    );
              },
                );
              },
            ),
                // Floating Action Button for adding songs (only visible when list is not empty AND NOT in selection mode)
                if (!_isSelectionMode)
                FutureBuilder<List<SongModel>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.hasData && snap.data!.isNotEmpty) {
                      return Positioned(
                        right: 16,
                        bottom: 90, // Above MiniPlayer
                        child: FloatingActionButton(
                          onPressed: () => _addSongs(cubit),
                          tooltip: l10n.addSongs,
                          child: PhosphorIcon(PhosphorIcons.plus()),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
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
             _buildBarAction(context, PhosphorIcons.listPlus(PhosphorIconsStyle.fill), l10n.addToPlaylist, _addToPlaylistSelected),
             _buildBarAction(context, PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill), l10n.share, _shareSelected),
             // REMOVE instead of DELETE
             _buildBarAction(context, PhosphorIcons.minusCircle(), l10n.removeFromList, _removeSelected, isDestructive: true),
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
               style: theme.textTheme.labelSmall?.copyWith(
                 color: color,
                 fontSize: 10,
               ),
             ),
           ],
         ),
       ),
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
