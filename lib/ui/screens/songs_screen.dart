import 'package:flutter/services.dart';

import 'dart:async'; // Fix for Timer
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_box/generated/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../player/player_cubit.dart';
import '../../widgets/song_tile.dart';
// import '../../widgets/song_actions.dart'; // legacy


import '../song_actions_sheet.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../core/utils/music_data_processor.dart';
import 'home_screen.dart'; // To access toggleSelectionMode
import 'package:share_plus/share_plus.dart'; // For sharing multiple files

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen>
    with AutomaticKeepAliveClientMixin {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  List<SongModel> _filteredSongs = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _isRequestingPermission = false;  // âœ… EmpÃªcher les clics multiples
  bool _isPermanentlyDenied = false;  // âœ… DÃ©tecter refus permanent

  _SortType _sortType = _SortType.title;
  bool _sortAscending = true;
  
  // Pour le lazy loading
  final ScrollController _scrollController = ScrollController();
  static const int _itemsPerPage = 50;
  int _currentMaxItems = _itemsPerPage;
  
  // Selection Mode
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
          context.findAncestorStateOfType<HomeScreenState>()?.toggleSelectionMode(false);
        }
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _filteredSongs.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
        context.findAncestorStateOfType<HomeScreenState>()?.toggleSelectionMode(false);
      } else {
        _selectedIds.addAll(_filteredSongs.map((s) => s.id));
        _isSelectionMode = true;
      }
    });
  }
  
  void _exitSelectionMode() {
    if (!mounted) return;
    context.findAncestorStateOfType<HomeScreenState>()?.toggleSelectionMode(false);
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadSongs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_currentMaxItems < _filteredSongs.length) {
        setState(() {
          _currentMaxItems += _itemsPerPage;
        });
      }
    }
  }

  Future<void> _checkPermissionAndLoadSongs() async {
    // âœ… EmpÃªcher les appels multiples
    if (_isRequestingPermission) return;
    
    setState(() {
      _isRequestingPermission = true;
      _isLoading = true;
    });
    
    try {
      // âœ… Utiliser permission_handler au lieu de on_audio_query pour Ã©viter le crash
      final status = await Permission.audio.status;
      if (!mounted) return;
      
      if (status.isGranted) {
        setState(() {
          _hasPermission = true;
          _isPermanentlyDenied = false;
        });
        await _loadSongs();
        return;
      }

      // âœ… VÃ©rifier si refus permanent AVANT de demander
      if (status.isPermanentlyDenied) {
        if (mounted) {
          setState(() {
            _isPermanentlyDenied = true;
            _isLoading = false;
          });
        }
        return;
      }

      // âœ… Demander avec permission_handler
      final newStatus = await Permission.audio.request();
      if (!mounted) return;
      
      if (newStatus.isGranted) {
        setState(() {
          _hasPermission = true;
          _isPermanentlyDenied = false;
        });
        await _loadSongs();
      } else {
        if (mounted) {
          setState(() {
            _hasPermission = false;
            _isLoading = false;
            _isPermanentlyDenied = newStatus.isPermanentlyDenied;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasPermission = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingPermission = false);
      }
    }
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      
      // âœ… Update raw songs first
      setState(() {
        _songs = songs.where((song) => song.duration != null && song.duration! > 0).toList();
      });
      
      // âœ… Await filter/sort to avoid "No songs" flash
      await _applyFilterAndSort();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  Future<void> _applyFilterAndSort() async {
    final cubit = context.read<PlayerCubit>();
    const query = '';

    // Prepare overrides map for isolate
    final overrides = <int, Map<String, dynamic>>{};
    for (final s in _songs) {
      final o = cubit.state.metadataOverrides[s.id];
      if (o != null) {
        overrides[s.id] = o.toJson();
      }
    }

    // âœ… Run in background isolate
    final filtered = await MusicDataProcessor.filterAndSortSongs(
      songs: _songs,
      query: query,
      sortTypeIndex: _SortType.values.indexOf(_sortType),
      ascending: _sortAscending,
      overrides: overrides,
      hiddenFolders: cubit.state.hiddenFolders.toSet(), // âœ… Convert List to Set
      showHiddenFolders: cubit.state.showHiddenFolders,
    );

    if (!mounted) return;
    setState(() {
      _filteredSongs = filtered;
      _currentMaxItems = _itemsPerPage;
    });
  }

  String _getSortSuffix() {
    final l10n = AppLocalizations.of(context)!;
    if (_sortType == _SortType.date) {
      return _sortAscending ? " (${l10n.sortOldest})" : " (${l10n.sortNewest})";
    }
    if (_sortType == _SortType.duration) {
      return _sortAscending ? " (${l10n.sortShortest})" : " (${l10n.sortLongest})";
    }
    return _sortAscending ? " (A-Z)" : " (Z-A)";
  }

  void _sortSongs(_SortType type) {
    setState(() {
      if (_sortType == type) {
        _sortAscending = !_sortAscending;
      } else {
        _sortType = type;
        _sortAscending = true;
      }
      _applyFilterAndSort();
    });
  }



  IconData _getSortIcon(_SortType type) {
    switch (type) {
      case _SortType.title:
        return PhosphorIcons.textAa();
      case _SortType.artist:
        return PhosphorIcons.user();
      case _SortType.album:
        return PhosphorIcons.disc();
      case _SortType.duration:
        return PhosphorIcons.hourglass();
      case _SortType.date:
        return PhosphorIcons.calendar();
      case _SortType.timer:
        return PhosphorIcons.timer();
    }
  }

  String _getSortLabel(_SortType type) {
    switch (type) {
      case _SortType.title:
        return AppLocalizations.of(context)!.title;
      case _SortType.artist:
        return AppLocalizations.of(context)!.artist;
      case _SortType.album:
        return AppLocalizations.of(context)!.album;
      case _SortType.duration:
        return AppLocalizations.of(context)!.duration;
      case _SortType.date:
        return AppLocalizations.of(context)!.sortByDateAdded;
      case _SortType.timer:
        return "Timer";
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final playerCubit = context.watch<PlayerCubit>();

    // Construire un contenu quel que soit l'Ã©tat, puis l'entourer d'un BlocListener
    late final Widget content;

    if (!_hasPermission) {
      content = _buildPermissionRequest();
    } else if (_isLoading) {
      content = _buildLoadingState();
    } else if (_filteredSongs.isEmpty) {
      content = _buildEmptyState();
    } else {
      // Use full list for proper scrollbar behavior
      final itemsToShow = _filteredSongs;

      final scaffold = Scaffold(
        backgroundColor: Colors.transparent,
        body: PopScope(
          canPop: !_isSelectionMode,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_isSelectionMode) {
              _exitSelectionMode();
            }
          },
          child: Stack(
            children: [
               Column(
                 children: [
                   // Fixed Selection Header (if in selection mode)
                   if (_isSelectionMode)
                     Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        color: Theme.of(context).colorScheme.surface,
                        child: SafeArea(
                          bottom: false,
                          child: Row(
                            children: [
                               IconButton(
                                 icon: PhosphorIcon(PhosphorIcons.x()), 
                                 onPressed: _exitSelectionMode,
                                 tooltip: AppLocalizations.of(context)!.cancel,
                               ),
                               const SizedBox(width: 8),
                               Text(
                                 '${_selectedIds.length}',
                                 style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                               ),
                               const Spacer(),
                               TextButton.icon(
                                 onPressed: _selectAll,
                                 icon: PhosphorIcon(_selectedIds.length == _filteredSongs.length ? PhosphorIcons.minusSquare() : PhosphorIcons.checkSquare()),
                                 label: Text(
                                   _selectedIds.length == _filteredSongs.length ? "DÃ©sÃ©lect. tout" : AppLocalizations.of(context)!.selectAll,
                                   style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                                 ),
                               )
                            ],
                          ),
                        ),
                     ),
  
                   Expanded(
                       child: Scrollbar(
                         controller: _scrollController,
                         thumbVisibility: true,
                         interactive: true,
                         thickness: 10, // Plus Ã©pais pour une meilleure prise en main
                         radius: const Radius.circular(8),
                       child: RefreshIndicator(
                         onRefresh: _loadSongs,
                         child: CustomScrollView(
                           controller: _scrollController,
                           slivers: [
                             // Standard Header (Only if NOT in selection mode)
                             if (!_isSelectionMode)
                               SliverToBoxAdapter(
                                 child: Container(
                                   padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                   child: SingleChildScrollView(
                                     scrollDirection: Axis.horizontal,
                                     child: Row(
                                     children: [
                                        FilterChip(
                                          avatar: PhosphorIcon(PhosphorIcons.shuffle(), size: 18),
                                          label: Text(AppLocalizations.of(context)!.shuffle, style: GoogleFonts.outfit()),
                                          onSelected: (_) {
                                            if (_filteredSongs.isNotEmpty) {
                                              final idx = math.Random().nextInt(_filteredSongs.length);
                                              playerCubit.setQueueAndPlay(_filteredSongs, idx);
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        MenuAnchor(
                                          builder: (context, controller, child) {
                                            return ActionChip(
                                               avatar: PhosphorIcon(PhosphorIcons.sortAscending(), size: 18),
                                              label: Text(
                                                '${_getSortLabel(_sortType)}${_getSortSuffix()}',
                                                style: GoogleFonts.outfit(),
                                              ),
                                              onPressed: () {
                                                if (controller.isOpen) {
                                                  controller.close();
                                                } else {
                                                  controller.open();
                                                }
                                              },
                                            );
                                          },
                                          menuChildren: _SortType.values.map((type) {
                                            return MenuItemButton(
                                               leadingIcon: PhosphorIcon(_getSortIcon(type), size: 20),
                                              child: Text(_getSortLabel(type), style: GoogleFonts.outfit()),
                                              onPressed: () => _sortSongs(type),
                                            );
                                          }).toList(),
                                        ),
  
                                        const SizedBox(width: 16),
                                        
                                        // Song Count (Discret)
                                          Text(
                                            AppLocalizations.of(context)!.songCount(_filteredSongs.length),
                                            style: GoogleFonts.outfit(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                     ),
                                   ),
                                   ),
                                 ),
  
  
                             SliverList(
                               delegate: SliverChildBuilderDelegate(
                                 (context, index) {
                                   if (index >= itemsToShow.length) {
                                      return const SizedBox(height: 100); 
                                   }
   
                                   final song = itemsToShow[index];
                                   return SongTile(
                                     song: song,
                                     isSelectionMode: _isSelectionMode,
                                     isSelected: _selectedIds.contains(song.id),
                                     onTap: () {
                                       if (_isSelectionMode) {
                                         _toggleSelection(song.id);
                                       } else {
                                         playerCubit.setQueueAndPlay(itemsToShow, index);
                                       }
                                     },
                                     onLongPress: () {
                                       if (!_isSelectionMode) {
                                         context.findAncestorStateOfType<HomeScreenState>()?.toggleSelectionMode(true);
                                         _toggleSelection(song.id);
                                       }
                                     },
                                     onMorePressed: _isSelectionMode ? null : () => openSongActionsSheet(context, song),
                                   );
                                 },
                                 childCount: itemsToShow.length + 1,
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),
                   ),
                 ],
               ),
  
               // Bottom Bar (Selection Actions)
               if (_isSelectionMode)
                 Positioned(
                   left: 0, 
                   right: 0,
                   bottom: 0,
                   child: _buildSelectionModeBar(context),
                 ),
            ],
          ),
        ),
      );
      content = scaffold;
    }

    return BlocListener<PlayerCubit, PlayerStateModel>(
      listenWhen: (prev, curr) =>
          prev.hiddenFolders != curr.hiddenFolders ||
          prev.showHiddenFolders != curr.showHiddenFolders ||
          prev.hiddenFolders != curr.hiddenFolders ||
          prev.showHiddenFolders != curr.showHiddenFolders ||
          prev.deletedSongIds != curr.deletedSongIds ||
          prev.metadataOverrides != curr.metadataOverrides, // âœ… Refresh list on metadata changes
      listener: (context, state) {
        // Re-appliquer le filtre/tri si la liste des dossiers masquÃ©s change
        if (mounted) {
          setState(() {
            _applyFilterAndSort();
          });
        }
      },
      child: content,
    );
  }

  Widget _buildPermissionRequest() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              _isPermanentlyDenied ? PhosphorIcons.prohibit() : PhosphorIcons.folderSimpleStar(), // Use something related
              size: 80,
              color: _isPermanentlyDenied ? theme.colorScheme.error : Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              _isPermanentlyDenied 
                  ? AppLocalizations.of(context)!.permissionDenied
                  : AppLocalizations.of(context)!.permissionRequired,
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _isPermanentlyDenied
                  ? AppLocalizations.of(context)!.permissionPermanentlyDenied
                  : AppLocalizations.of(context)!.storagePermissionRequired,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 16),
            ),
            const SizedBox(height: 32),
            if (_isPermanentlyDenied)
              FilledButton.icon(
                onPressed: () async {
                  final opened = await openAppSettings();
                  if (!opened && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.error),
                      ),
                    );
                  }
                },
                icon: PhosphorIcon(PhosphorIcons.gear()),
                label: Text(AppLocalizations.of(context)!.openSettings, style: GoogleFonts.outfit()),
              )
            else
              FilledButton.icon(
                onPressed: _isRequestingPermission ? null : _checkPermissionAndLoadSongs,
                icon: _isRequestingPermission 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : PhosphorIcon(PhosphorIcons.gear()),
                label: Text(_isRequestingPermission 
                    ? AppLocalizations.of(context)!.loading 
                    : AppLocalizations.of(context)!.grantPermission, style: GoogleFonts.outfit()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(
            PhosphorIcons.musicNote(), // musicNoteSlash is missing, using musicNote
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.noSongs,
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadSongs,
            icon: PhosphorIcon(PhosphorIcons.arrowsClockwise()),
            label: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }


  // selection mode UI
  Widget _buildSelectionModeBar(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
             _buildBarAction(context, PhosphorIcons.play(PhosphorIconsStyle.fill), l10n.play, _playSelected),
             _buildBarAction(context, PhosphorIcons.listPlus(PhosphorIconsStyle.fill), l10n.addToPlaylist, _addToPlaylistSelected),
             _buildBarAction(context, PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill), l10n.share, _shareSelected),
             _buildBarAction(context, PhosphorIcons.trash(PhosphorIconsStyle.fill), l10n.delete, _deleteSelected, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBarAction(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;

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
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _playSelected() {
     if (_selectedIds.isEmpty) return;
     final selectedSongs = _filteredSongs.where((s) => _selectedIds.contains(s.id)).toList();
     context.read<PlayerCubit>().setQueueAndPlay(selectedSongs, 0);
     _exitSelectionMode();
  }

  Future<void> _addToPlaylistSelected() async {
    final selectedSongs = _filteredSongs.where((s) => _selectedIds.contains(s.id)).toList();
    if (selectedSongs.isEmpty) return;
    
    // Using existing _openAddToPlaylist logic but adapted for multiple
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
              title: Text(l10n.createPlaylist),
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
        title: Text(title),
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
    final selectedSongs = _filteredSongs.where((s) => _selectedIds.contains(s.id)).toList();
    if (selectedSongs.isEmpty) return;

    final xFiles = <XFile>[];
    for (final s in selectedSongs) {
      if (s.data.isNotEmpty) {
        xFiles.add(XFile(s.data));
      }
    }

    if (xFiles.isEmpty) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorFileNotFound)));
      }
      return;
    }

    // Share using share_plus which handles multiple files natively
    try {
      await Share.shareXFiles(xFiles, text: '${xFiles.length} songs');
      _exitSelectionMode();
    } catch (e) {
      if (mounted) {
         if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error sharing: $e")));
         }
      }
    }
  }

  Future<void> _deleteSelected() async {
    final selectedSongs = _filteredSongs.where((s) => _selectedIds.contains(s.id)).toList();
    if (selectedSongs.isEmpty) return;
    
    final l10n = AppLocalizations.of(context)!;
    
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSong),
        content: Text("Voulez-vous vraiment supprimer ${selectedSongs.length} chansons dÃ©finitivement ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;

    // Remove UI immediately to be responsive
    if (mounted) {
       _exitSelectionMode();
    }

    // Call native batch delete
    const platform = MethodChannel('com.synergydev.music_box/native');
    try {
       // Send list of IDs
       final ids = selectedSongs.map((s) => s.id).toList();
       final result = await platform.invokeMethod('deleteAudioList', {'audioIds': ids});
       
       if (result == true) {
         // Update lists
         setState(() {
           _songs.removeWhere((s) => ids.contains(s.id));
           _filteredSongs.removeWhere((s) => ids.contains(s.id));
         });
         
         // Update PlayerCubit
         context.read<PlayerCubit>().removeSongsById(ids);
         
         if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text("${ids.length} ${l10n.fileDeleted}"), 
               backgroundColor: Colors.green,
             )
           );
         }
       }
    } catch (e) {
       debugPrint("Error deleting: $e");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("${l10n.error}: $e"))
         );
       }
    }
  }
}

enum _SortType { title, artist, album, duration, date, timer }

class _AlphabetScroll extends StatefulWidget {
  final List<SongModel> songs;
  final ScrollController controller;


  const _AlphabetScroll({
    required this.songs,
    required this.controller,

  });


  @override
  State<_AlphabetScroll> createState() => _AlphabetScrollState();
}

class _AlphabetScrollState extends State<_AlphabetScroll> {
  final List<String> _alphabet = [
    '#', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];
  String? _bubbleLetter;
  Timer? _hideTimer;

  void _scrollTo(String letter) {
    setState(() {
      _bubbleLetter = letter;
    });
    
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 1, milliseconds: 500), () {
      if (mounted) setState(() => _bubbleLetter = null);
    });

    if (widget.songs.isEmpty) return;

    int index = -1;
    if (letter == '#') {
      index = 0;
    } else {
      index = widget.songs.indexWhere((s) {
        final title = (s.title).toUpperCase().trim();
        if (title.isEmpty) return false;
        return title.startsWith(letter);
      });
    }

    if (index != -1) {
      final headerOffset = 60.0; 
      final itemHeight = 62.0;
      final offset = (index * itemHeight) + headerOffset;
      final maxScroll = widget.controller.position.maxScrollExtent;
      final target = offset.clamp(0.0, maxScroll);
      widget.controller.jumpTo(target);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        // 1. Central Bubble Overlay
        if (_bubbleLetter != null)
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 80, 
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary, // Blue/Primary bubble
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  _bubbleLetter!,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        // 2. Sidebar with Dots
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 40, // Wider touch area
            color: Colors.transparent, // Capture taps
            padding: const EdgeInsets.only(top: 60, bottom: 80),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (details) => _handleDrag(details.localPosition, context),
              onVerticalDragUpdate: (details) => _handleDrag(details.localPosition, context),
              onTapDown: (details) => _handleDrag(details.localPosition, context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _alphabet.map((letter) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        'â€¢', // Dots instead of letters
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5) // Subtle dots
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleDrag(Offset localPosition, BuildContext context) {
    // We need the height of the column, not the screen
    // Since we are inside LayoutBuilder or strict constraints within the Column
    // We can use context.size if available
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    final height = box.size.height;
    final step = height / _alphabet.length;
    
    int index = (localPosition.dy / step).floor();
    index = index.clamp(0, _alphabet.length - 1);
    
    _scrollTo(_alphabet[index]);
  }
}




