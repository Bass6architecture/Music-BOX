import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../player/player_cubit.dart';
import '../generated/app_localizations.dart';

class SongMenu {
  static const String playNext = 'play_next';
  static const String addToQueue = 'add_to_queue';
  static const String addToPlaylist = 'add_to_playlist';
  static const String removeFromHistory = 'remove_from_history';
  static const String removeFromPlaylist = 'remove_from_playlist';

  static List<PopupMenuEntry<dynamic>> commonItems(
    BuildContext context,
    SongModel s, {
    bool includePlayNext = true,
    bool includeAddToQueue = true,
    bool includeAlbum = true,
    bool includeArtist = true,
    bool includeAddToPlaylist = true,
    bool includeRemoveFromHistory = false,
    bool includeRemoveFromPlaylist = false,
  }) {
    final items = <PopupMenuEntry<dynamic>>[];
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PlayerCubit>();
    
    // Ne pas afficher "Lire ensuite" et "Ajouter à la file" pour la chanson en cours
    final isCurrentSong = cubit.state.currentSongId == s.id;
    
    if (includePlayNext && !isCurrentSong) {
      items.add(PopupMenuItem<dynamic>(
        value: playNext,
        child: Text(l10n.playNext),
      ));
    }
    if (includeAddToQueue && !isCurrentSong) {
      items.add(PopupMenuItem<dynamic>(
        value: addToQueue,
        child: Text(l10n.addToQueueFull),
      ));
    }
    // Les actions "Aller à l'artiste" et "Aller à l'album" ont été retirées.
    if (includeRemoveFromHistory) {
      items.add(PopupMenuItem<dynamic>(
        value: removeFromHistory,
        child: Text(l10n.removeFromHistory),
      ));
    }
    if (includeRemoveFromPlaylist) {
      items.add(PopupMenuItem<dynamic>(
        value: removeFromPlaylist,
        child: Text(l10n.removeFromPlaylist),
      ));
    }
    if (includeAddToPlaylist) {
      items.add(PopupMenuItem<dynamic>(
        value: addToPlaylist,
        child: Text(l10n.addToMyPlaylists),
      ));
    }
    return items;
  }

  static Future<void> onSelected(
    BuildContext context,
    SongModel s,
    String value, {
    String? playlistId,
    VoidCallback? refresh,
  }) async {
    final cubit = context.read<PlayerCubit>();
    final l10n = AppLocalizations.of(context)!;

    Future<void> addToMyPlaylists() async {
      final playlists = cubit.state.userPlaylists;
      final targetId = await showDialog<String>(
        context: context,
        builder: (ctx) {
          return SimpleDialog(
            title: Text(l10n.addToMyPlaylists),
            children: [
              if (playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(l10n.noPlaylistsCreateOne),
                ),
              for (final p in playlists)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, p.id),
                  child: Text(p.name),
                ),
              const Divider(height: 1),
              SimpleDialogOption(
                onPressed: () async {
                  final controller = TextEditingController();
                  final name = await showDialog<String>(
                    context: ctx,
                    builder: (ctx2) => AlertDialog(
                      title: Text(l10n.newPlaylist),
                      content: TextField(
                        controller: controller,
                        decoration: InputDecoration(hintText: l10n.playlistName),
                        autofocus: true,
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx2), child: Text(l10n.cancel)),
                        FilledButton(onPressed: () => Navigator.pop(ctx2, controller.text.trim()), child: Text(l10n.create)),
                      ],
                    ),
                  );
                  if (name != null && name.isNotEmpty) {
                    final id = cubit.createUserPlaylist(name);
                    if (ctx.mounted) {
                      Navigator.pop(ctx, id);
                    }
                  }
                },
                child: Text(l10n.newPlaylistEllipsis),
              ),
            ],
          );
        },
      );
      if (!context.mounted) return;
      if (targetId != null) {
        cubit.addSongToUserPlaylist(targetId, s.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.songAddedToPlaylist)),
        );
      }
    }

    if (value == playNext) {
      await cubit.addToQueue([s], playNext: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scheduledNext)),
      );
    } else if (value == addToQueue) {
      await cubit.addToQueue([s]);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addedToQueue)),
      );
    } else if (value == addToPlaylist) {
      await addToMyPlaylists();
    } else if (value == removeFromHistory) {
      cubit.removeFromHistory(s.id);
      refresh?.call();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.removedFromHistory)),
      );
    } else if (value == removeFromPlaylist) {
      if (playlistId != null) {
        cubit.removeSongFromUserPlaylist(playlistId, s.id);
        refresh?.call();
      }
    }
  }
}
