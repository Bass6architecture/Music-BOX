import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_box/generated/app_localizations.dart';
import 'package:music_box/widgets/optimized_artwork.dart';

import '../player/player_cubit.dart';

class SongPickerPage extends StatefulWidget {
  const SongPickerPage({super.key, this.initiallySelected = const <int>[]});

  final List<int> initiallySelected;

  @override
  State<SongPickerPage> createState() => _SongPickerPageState();
}

class _SongPickerPageState extends State<SongPickerPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final Set<int> _selected = <int>{};
  Future<List<SongModel>>? _future;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initiallySelected);
    _future = _load();
  }

  Future<List<SongModel>> _load() async {
    // Request permissions if needed
    final hasPerm = await _audioQuery.permissionsStatus();
    if (!hasPerm) {
      await _audioQuery.permissionsRequest();
    }
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
    );
    // Filtrer les fichiers avec des URIs valides
    final validSongs = songs.where((song) => song.uri != null).toList();
    // Filtrer les dossiers masqués
    if (!mounted) return [];
    final cubit = context.read<PlayerCubit>();
    final filteredSongs = cubit.filterSongs(validSongs);
    return filteredSongs;
  }

  void _toggle(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<PlayerCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addSongs),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selected.toList()),
            child: Text(AppLocalizations.of(context)!.done),
          ),
        ],
      ),
      body: FutureBuilder<List<SongModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final songs = snap.data ?? const <SongModel>[];
          if (songs.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noSongs));
          }
          return ListView.separated(
            itemCount: songs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = songs[index];
              final checked = _selected.contains(s.id);
              final isFav = cubit.isFavorite(s.id);
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  onTap: () => _toggle(s.id),
                  leading: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    child: OptimizedArtwork.square(
                      id: s.id,
                      type: ArtworkType.AUDIO,
                      size: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    [s.artist, s.album].where((e) => (e ?? '').isNotEmpty).join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
                        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : null),
                        onPressed: () => cubit.toggleFavoriteById(s.id),
                      ),
                      Checkbox(value: checked, onChanged: (_) => _toggle(s.id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => Navigator.pop(context, _selected.toList()),
            icon: const Icon(Icons.check),
            label: Text(AppLocalizations.of(context)!.songCount(_selected.length))
          ),
        ),
      ),
    );
  }
}
