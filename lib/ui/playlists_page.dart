import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_box/generated/app_localizations.dart';
import '../player/player_cubit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/theme/app_theme.dart';
import 'widgets/modern_widgets.dart';


import 'package:music_box/ui/favorite_songs_page.dart';
import 'package:music_box/ui/recently_added_page.dart';
import 'package:music_box/ui/recently_played_page.dart';
import 'package:music_box/ui/most_played_page.dart';
import 'package:music_box/ui/user_playlist_page.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.watch<PlayerCubit>();
    final playlists = cubit.state.userPlaylists;

    final allSongs = cubit.state.allSongs;
    final visibleSongs = cubit.filterSongs(allSongs);
    final visibleSongIds = visibleSongs.map((s) => s.id).toSet();
      
      final favoritesCount = visibleSongs.where((s) => cubit.state.favorites.contains(s.id)).length;
      
      final recentAddedCount = visibleSongs.where((s) {
        final now = DateTime.now();
        final thirtyDaysAgo = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch / 1000;
        return (s.dateAdded ?? 0) >= thirtyDaysAgo;
      }).length;
      
      final recentPlayedCount = visibleSongs.where((s) => cubit.state.lastPlayed.containsKey(s.id)).length;
      final displayRecentPlayedCount = recentPlayedCount > 100 ? 100 : recentPlayedCount;
      
      final mostPlayedCount = visibleSongs.where((s) => cubit.state.playCounts.containsKey(s.id)).length;
      final displayMostPlayedCount = mostPlayedCount > 100 ? 100 : mostPlayedCount;

      final content = CustomScrollView(
        slivers: [
          // Header Title
          if (!widget.embedded)
            SliverAppBar(
              title: Text(AppLocalizations.of(context)!.playlists, style: TextStyle(fontWeight: FontWeight.bold)),
              floating: true,
              snap: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            ),

          // System Playlists Grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _SystemPlaylistCard(
                  title: AppLocalizations.of(context)!.favorites,
                  icon: PhosphorIcons.heart(PhosphorIconsStyle.fill),
                  color: Colors.red,
                  count: favoritesCount,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<PlayerCubit>(),
                        child: const FavoriteSongsPage(),
                      ),
                    ),
                  ),
                ),
                _SystemPlaylistCard(
                  title: AppLocalizations.of(context)!.recentlyAdded,
                  icon: PhosphorIcons.clock(PhosphorIconsStyle.fill),
                  color: Colors.blue,
                  count: recentAddedCount,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<PlayerCubit>(),
                        child: const RecentlyAddedPage(),
                      ),
                    ),
                  ),
                ),
                _SystemPlaylistCard(
                  title: AppLocalizations.of(context)!.recentlyPlayed,
                  icon: PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill),
                  color: Colors.purple,
                  count: displayRecentPlayedCount,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<PlayerCubit>(),
                        child: const RecentlyPlayedPage(),
                      ),
                    ),
                  ),
                ),
                _SystemPlaylistCard(
                  title: AppLocalizations.of(context)!.mostPlayed,
                  icon: PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill),
                  color: theme.colorScheme.primary,
                  count: displayMostPlayedCount,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<PlayerCubit>(),
                        child: const MostPlayedPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User Playlists Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.yourPlaylists,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _createNewPlaylist(context),
                    icon: PhosphorIcon(PhosphorIcons.plusCircle()),
                    tooltip: AppLocalizations.of(context)!.createPlaylist,
                  ),
                ],
              ),
            ),
          ),

          // User Playlists List
          if (playlists.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      PhosphorIcons.playlist(PhosphorIconsStyle.regular),
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noPlaylists,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => _createNewPlaylist(context),
                      icon: PhosphorIcon(PhosphorIcons.plus()),
                      label: Text(AppLocalizations.of(context)!.createPlaylist),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final playlist = playlists[index];
                  final count = playlist.songIds.where((id) => visibleSongIds.contains(id)).length;
                  return ModernListTile(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<PlayerCubit>(),
                            child: UserPlaylistPage(playlistId: playlist.id, playlistName: playlist.name),
                          ),
                        ),
                      );
                    },
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: PhosphorIcon(
                        PhosphorIcons.playlist(),
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(playlist.name),
                    subtitle: Text(AppLocalizations.of(context)!.songCount(count)),
                    trailing: PopupMenuButton<String>(
                            icon: PhosphorIcon(
                              PhosphorIcons.dotsThreeVertical(),
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onSelected: (value) {
                              if (value == 'rename') _renamePlaylist(context, playlist);
                              if (value == 'delete') _deletePlaylist(context, playlist);
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    PhosphorIcon(PhosphorIcons.pencilLine(), size: 20),
                                    const SizedBox(width: 12),
                                    Text(AppLocalizations.of(context)!.renamePlaylist, style: TextStyle()),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    PhosphorIcon(PhosphorIcons.trash(), size: 20),
                                    const SizedBox(width: 12),
                                    Text(AppLocalizations.of(context)!.deletePlaylist, style: TextStyle()),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  );
                },
                childCount: playlists.length,
              ),
            ),
            
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );

    return BlocListener<PlayerCubit, PlayerStateModel>(
      listenWhen: (prev, curr) =>
          prev.hiddenFolders != curr.hiddenFolders ||
          prev.showHiddenFolders != curr.showHiddenFolders ||
          prev.deletedSongIds != curr.deletedSongIds,
      listener: (context, state) {
        if (mounted) setState(() {});
      },
      child: widget.embedded 
          ? Material(color: Colors.transparent, child: content)
          : Scaffold(body: content),
    );
  }

  Future<void> _createNewPlaylist(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.createPlaylist, style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.playlistNameHint,
            hintStyle: TextStyle(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(AppLocalizations.of(context)!.create, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    
    if (name != null && name.trim().isNotEmpty && context.mounted) {
      final id = context.read<PlayerCubit>().createUserPlaylist(name.trim());
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<PlayerCubit>(),
            child: UserPlaylistPage(playlistId: id, playlistName: name.trim()),
          ),
        ),
      );
    }
  }

  Future<void> _renamePlaylist(BuildContext context, UserPlaylist p) async {
    final controller = TextEditingController(text: p.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.renamePlaylist, style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.playlistName,
            hintStyle: TextStyle(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(AppLocalizations.of(context)!.save, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && context.mounted) {
      context.read<PlayerCubit>().renameUserPlaylist(p.id, newName);
    }
  }

  Future<void> _deletePlaylist(BuildContext context, UserPlaylist p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deletePlaylist, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(AppLocalizations.of(context)!.confirmDeletePlaylist, style: TextStyle()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle()),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<PlayerCubit>().deleteUserPlaylist(p.id);
    }
  }

}

class _SystemPlaylistCard extends StatelessWidget {
  const _SystemPlaylistCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Soft background color based on the main color but very subtle
    final bgColor = color.withValues(alpha: 0.1);
    
    return ModernCard(
      padding: EdgeInsets.zero,
      color: bgColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: onTap,
        child: Stack(
          children: [
            // Icon - Top Left
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: PhosphorIcon(
                  icon,
                  color: color,
                  size: 24,
                )
              ),
            ),
            // Count - Top Right
            Positioned(
              right: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppLocalizations.of(context)!.songCount(count),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            // Title - Bottom Left
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}





