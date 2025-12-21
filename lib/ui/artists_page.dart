import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_box/generated/app_localizations.dart';
import 'package:music_box/player/player_cubit.dart';
import 'package:music_box/ui/artist_detail_page.dart';
import 'package:music_box/widgets/optimized_artwork.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistsPage extends StatefulWidget {
  const ArtistsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  Future<List<_ArtistItem>>? _future;

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

  Future<List<_ArtistItem>> _load() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.ARTIST,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    if (!mounted) return const [];
    final cubit = context.read<PlayerCubit>();
    final valid = songs.where((s) => s.uri != null).toList();
    final filtered = cubit.filterSongs(valid);

    final map = <String, _ArtistItem>{};
    for (final s in filtered) {
      final name = (s.artist ?? 'Inconnu').trim();
      final item = map.putIfAbsent(name.toLowerCase(), () => _ArtistItem(name: name, sampleSongId: s.id));
      item.sampleSongId ??= s.id;
      item.count += 1;
    }
    final list = map.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = FutureBuilder<List<_ArtistItem>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final artists = snap.data ?? const <_ArtistItem>[];
        
        if (artists.isEmpty) {
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
                  child: PhosphorIcon(PhosphorIcons.user(), size: 64, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noArtists,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
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
                  backgroundColor: theme.scaffoldBackgroundColor,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
                    title: Text(
                      AppLocalizations.of(context)!.artists,
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                            theme.colorScheme.surface,
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
                    mainAxisExtent: _artistTileMainExtent(context),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final a = artists[index];
                      return _ArtistCard(
                        name: a.name,
                        count: a.count,
                        sampleSongId: a.sampleSongId,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<PlayerCubit>(),
                                child: ArtistDetailPage(artistName: a.name),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: artists.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );

    final base = widget.embedded ? content : Scaffold(body: content);

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

class _ArtistItem {
  _ArtistItem({required this.name, this.sampleSongId});
  final String name;
  int? sampleSongId;
  int count = 0;
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({required this.name, required this.count, required this.onTap, required this.sampleSongId});

  final String name;
  final int count;
  final int? sampleSongId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget placeholder(BuildContext _, double side) => Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Center(
            child: PhosphorIcon(PhosphorIcons.user(), color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5), size: side * 0.5),
          ),
        );

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
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: sampleSongId != null
                            ? OptimizedArtwork.square(
                                id: sampleSongId!,
                                type: ArtworkType.AUDIO,
                                fit: BoxFit.cover,
                                fallbackBuilder: placeholder,
                                useCustomOverrides: false,
                              )
                            : placeholder(context, 64),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.songCount(count),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
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



double _artistTextHeight(BuildContext context) {

  final ts = MediaQuery.textScalerOf(context).scale(1.0);
  final scale = ts > 1.0 ? 1.0 : ts;
  // Title (15) + Subtitle (12) + Spacing (4) + Padding (12 bottom)
  final titleSize = 15 * 1.2 * scale;
  final subSize = 12 * 1.2 * scale;
  return titleSize + subSize + 4;
}

double _artistTileMainExtent(BuildContext context) {
  final size = MediaQuery.of(context).size;
  const double horizontalPadding = 16 * 2;
  const double crossSpacing = 16;
  final double tileWidth = (size.width - horizontalPadding - crossSpacing) / 2;
  
  // Inner padding (12 top + 12 bottom) + Spacing (12) + Text block
  const double verticalPadding = 12 * 2;
  const double spacing = 12;
  
  // Image is square (circle inside square aspect ratio), so height = width (minus horizontal padding inside card)
  // Card inner width = tileWidth - 24 (12*2 padding)
  final double imageSize = tileWidth - 24;
  
  return imageSize + verticalPadding + spacing + _artistTextHeight(context);
}
