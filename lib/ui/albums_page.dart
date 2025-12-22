import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_box/generated/app_localizations.dart';
import 'package:music_box/player/player_cubit.dart';
import 'package:music_box/ui/album_detail_page.dart';
import 'package:music_box/widgets/optimized_artwork.dart';

import 'package:music_box/core/utils/music_data_processor.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  Future<List<AlbumItem>>? _future;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }
  
  void _startLoading() {
    if (_future == null) {
      setState(() => _future = _load());
    }
  }

  Future<List<AlbumItem>> _load() async {
    // Charger toutes les chansons, filtrer les dossiers masqués, puis regrouper par album
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.ALBUM,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    if (!mounted) return const [];
    final cubit = context.read<PlayerCubit>();
    final valid = songs.where((s) => s.uri != null).toList();
    final filtered = cubit.filterSongs(valid);

    // ✅ Use Isolate to group songs
    return MusicDataProcessor.groupSongsByAlbum(filtered);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = FutureBuilder<List<AlbumItem>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final albums = snap.data ?? const <AlbumItem>[];
        
        if (albums.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: PhosphorIcon(PhosphorIcons.disc(), size: 64, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noAlbums,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = _load());
            await _future;
          },
          child: CustomScrollView(
            slivers: [
              if (!widget.embedded)
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
                    title: Text(
                      AppLocalizations.of(context)!.albums,
                      style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: _albumTileMainExtent(context),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final a = albums[index];
                      return _AlbumCard(
                        album: a,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<PlayerCubit>(),
                                child: AlbumDetailPage(albumId: a.albumId, albumName: a.title),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: albums.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );

    final base = widget.embedded ? content : Scaffold(backgroundColor: Colors.transparent, body: content);

    return BlocListener<PlayerCubit, PlayerStateModel>(
      listenWhen: (prev, curr) =>
          prev.hiddenFolders != curr.hiddenFolders ||
          prev.showHiddenFolders != curr.showHiddenFolders ||
          prev.deletedSongIds != curr.deletedSongIds,
      listener: (context, state) {
        if (mounted) setState(() => _future = _load());
      },
      child: base,
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album, required this.onTap});

  final AlbumItem album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _AlbumArtworkTile(
                        albumId: album.albumId,
                        sampleSongId: album.sampleSongId,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${album.artist} • ${AppLocalizations.of(context)!.songCount(album.count)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



double _albumTextHeight(BuildContext context) {

  final ts = MediaQuery.textScalerOf(context).scale(1.0);
  final scale = ts > 1.0 ? 1.0 : ts;
  // Title (15) + Subtitle (12) + Spacing (4) + Padding (12 bottom)
  final titleSize = 15 * 1.2 * scale;
  final subSize = 12 * 1.2 * scale;
  return titleSize + subSize + 4;
}

double _albumTileMainExtent(BuildContext context) {
  final size = MediaQuery.of(context).size;
  const double horizontalPadding = 16 * 2;
  const double crossSpacing = 16;
  final double tileWidth = (size.width - horizontalPadding - crossSpacing) / 2;
  
  // Inner padding (12 top + 12 bottom) + Spacing (12) + Text block
  const double verticalPadding = 12 * 2;
  const double spacing = 12;
  
  // Image is square, so height = width (minus horizontal padding inside card)
  // Card inner width = tileWidth - 24 (12*2 padding)
  final double imageSize = tileWidth - 24;
  
  return imageSize + verticalPadding + spacing + _albumTextHeight(context);
}

class _AlbumArtworkTile extends StatelessWidget {
  const _AlbumArtworkTile({required this.albumId, required this.sampleSongId});

  final int? albumId;
  final int? sampleSongId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget fallback(BuildContext ctx, double side) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: PhosphorIcon(
            PhosphorIcons.disc(),
            size: side * 0.5,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    if (albumId != null) {
      return OptimizedArtwork.square(
        id: albumId!,
        type: ArtworkType.ALBUM,
        fit: BoxFit.cover,
        fallbackBuilder: fallback,
      );
    }
    if (sampleSongId != null) {
      return OptimizedArtwork.square(
        id: sampleSongId!,
        type: ArtworkType.AUDIO,
        fit: BoxFit.cover,
        fallbackBuilder: fallback,
      );
    }
    return fallback(context, 64);
  }
}
