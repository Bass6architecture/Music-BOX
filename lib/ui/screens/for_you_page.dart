
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_box/generated/app_localizations.dart';
import '../../player/player_cubit.dart';
import '../../core/recommendation_engine.dart';
import '../../widgets/optimized_artwork.dart';
import '../../core/constants/app_constants.dart';

class ForYouPage extends StatefulWidget {
  const ForYouPage({super.key});

  @override
  State<ForYouPage> createState() => _ForYouPageState();
}

class _ForYouPageState extends State<ForYouPage> with AutomaticKeepAliveClientMixin {
  List<SongModel> _quickPlayMix = [];
  List<SongModel> _forgottenGems = [];
  List<SongModel> _habits = [];
  List<SongModel> _suggestions = []; // New
  List<SongModel> _freshArrivals = [];
  List<SongModel> _allTimeHits = []; 
  bool _isInit = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendations();
    });
  }

  Future<void> _loadRecommendations() async {
    final cubit = context.read<PlayerCubit>();
    final state = cubit.state;
    
    // Create input DTO
    final inputs = RecommendationInputs(
      allSongs: state.allSongs,
      playCounts: Map.from(state.playCounts),
      lastPlayed: Map.from(state.lastPlayed),
      favorites: List.from(state.favorites),
      hiddenFolders: List.from(state.hiddenFolders),
      showHiddenFolders: state.showHiddenFolders,
    );

    // Run calculation in background isolate
    // This prevents UI jank when processing thousands of songs
    final results = await RecommendationEngine.computeRecommendations(inputs);

    if (mounted) {
      setState(() {
        _quickPlayMix = results.quickPlay;
        _forgottenGems = results.forgotten;
        _habits = results.habits; 
        _suggestions = results.suggestions;
        _freshArrivals = results.fresh;
        _allTimeHits = results.hits;
        _isInit = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return BlocListener<PlayerCubit, PlayerStateModel>(
      listenWhen: (prev, curr) => 
        prev.playCounts != curr.playCounts || 
        prev.lastPlayed != curr.lastPlayed ||
        prev.allSongs.length != curr.allSongs.length ||
        prev.hiddenFolders != curr.hiddenFolders, 
      listener: (context, state) {
        _loadRecommendations(); 
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: !_isInit 
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async => _loadRecommendations(),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Top Padding
                    const SliverGap(16),
                    
                    // 1. Compact Hero Card (Quick Play)
                    if (_quickPlayMix.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildCompactHero(context),
                        ),
                      ),
                    
                    const SliverGap(24),

                    // 2a. Habits / Cycles (Albums)
                    if (_habits.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(context, AppLocalizations.of(context)!.listeningHabits),
                      ),
                      SliverToBoxAdapter(
                        child: _buildHorizontalList(context, _habits, isAlbum: true),
                      ),
                      const SliverGap(24),
                    ]
                    // 2b. Fallback: Explorer (Suggestions)
                    else if (_suggestions.isNotEmpty) ...[
                       SliverToBoxAdapter(
                        child: _buildSectionTitle(context, AppLocalizations.of(context)!.explore),
                      ),
                      SliverToBoxAdapter(
                        child: _buildHorizontalList(context, _suggestions, isAlbum: true),
                      ),
                      const SliverGap(24),
                    ],

                    // 3. New: All Time Hits (Timeless)
                    if (_allTimeHits.isNotEmpty) ...[
                       SliverToBoxAdapter(
                        child: _buildSectionTitle(context, AppLocalizations.of(context)!.allTimeHits),
                      ),
                      SliverToBoxAdapter(
                        child: _buildHorizontalList(context, _allTimeHits, showRank: true),
                      ),
                      const SliverGap(24),
                    ],

                    // 4. Forgotten Gems
                    if (_forgottenGems.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(context, AppLocalizations.of(context)!.forgottenGems),
                      ),
                      SliverToBoxAdapter(
                        child: _buildHorizontalList(context, _forgottenGems, desaturate: true),
                      ),
                      const SliverGap(24),
                    ],

                    // 5. Fresh Arrivals (Vertical List - Only 30 days)
                    if (_freshArrivals.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _buildSectionTitle(context, AppLocalizations.of(context)!.recentlyAdded),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final song = _freshArrivals[index];
                            return _CompactSongRow(
                              song: song,
                              queue: _freshArrivals,
                              index: index,
                            );
                          },
                          childCount: _freshArrivals.length,
                        ),
                      ),
                       const SliverGap(100), // Bottom padding
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCompactHero(BuildContext context) {
    final theme = Theme.of(context);
    final seedSong = _quickPlayMix.first;

    return Container(
      height: 180, // Much more compact
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Artwork (Zooms in)
            OpacifiedArtwork(song: seedSong, opacity: 0.4),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                   // Floating Action Button style Play
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         Text(
                           AppLocalizations.of(context)!.quickPlay,
                           style: theme.textTheme.headlineSmall?.copyWith(
                             color: Colors.white,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           '${_quickPlayMix.length} ${AppLocalizations.of(context)!.songs.toLowerCase()}',
                           style: theme.textTheme.bodyMedium?.copyWith(
                             color: Colors.white70,
                             ),
                         ),
                       ],
                     ),
                   ),
                   
                   // Big Play Button
                   Material(
                     color: theme.colorScheme.primary,
                     shape: const CircleBorder(),
                     elevation: 8,
                     child: InkWell(
                       onTap: () {
                          HapticFeedback.mediumImpact();
                          context.read<PlayerCubit>().setQueueAndPlay(_quickPlayMix, 0);
                       },
                       customBorder: const CircleBorder(),
                       child: const Padding(
                         padding: EdgeInsets.all(16),
                         child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHorizontalList(BuildContext context, List<SongModel> songs, {bool isAlbum = false, bool desaturate = false, bool showRank = false}) {
    return SizedBox(
      height: 210, 
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final song = songs[index];
          return _DetailedSongCard(
            song: song,
            isAlbum: isAlbum,
            desaturate: desaturate,
            rank: showRank ? index + 1 : null,
            onTap: () {
               context.read<PlayerCubit>().setQueueAndPlay(songs, index);
            },
          );
        },
      ),
    );
  }
}

class OpacifiedArtwork extends StatelessWidget {
  final SongModel song;
  final double opacity;
  const OpacifiedArtwork({super.key, required this.song, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
        child: OptimizedArtwork.square(
          key: ValueKey(song.id),
          id: song.id,
          type: ArtworkType.AUDIO,
          size: 400,
          fit: BoxFit.cover,
        ),
    );
  }
}

class _DetailedSongCard extends StatelessWidget {
  const _DetailedSongCard({
    required this.song, 
    required this.onTap,
    this.isAlbum = false,
    this.desaturate = false,
    this.rank,
  });

  final SongModel song;
  final VoidCallback onTap;
  final bool isAlbum;
  final bool desaturate;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = 140.0;
    
    // Check active state
    final isActive = context.select((PlayerCubit c) => c.state.currentSongId == song.id);
    final isPlaying = context.select((PlayerCubit c) => c.state.isPlaying);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ColorFiltered(
                         colorFilter: desaturate 
                            ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                            : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                         child: OptimizedArtwork.square(
                          key: ValueKey(song.id),
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          size: size * 2,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  if (isActive)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: _MiniEq(animate: isPlaying, color: Colors.white),
                        ),
                      ),
                    ),
                  if (rank != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                             BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          '#$rank',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isAlbum ? (song.album ?? 'Unknown') : song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.bold,
                color: isActive ? theme.colorScheme.primary : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              song.artist ?? 'Artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.8) : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactSongRow extends StatelessWidget {
  const _CompactSongRow({
    required this.song,
    required this.queue,
    required this.index,
  });

  final SongModel song;
  final List<SongModel> queue;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = context.select((PlayerCubit c) => c.state.currentSongId == song.id);
    final isPlaying = context.select((PlayerCubit c) => c.state.isPlaying);
    final fgColor = isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return InkWell(
      onTap: () {
        context.read<PlayerCubit>().setQueueAndPlay(queue, index);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), // Thinner padding
        child: Row(
          children: [
            SizedBox(
              width: 56, // ✅ Restored to 56
              height: 56,
              child: Stack(
                children: [
                   ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: OptimizedArtwork.square(
                      key: ValueKey(song.id),
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      size: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (isActive)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: _MiniEq(animate: isPlaying, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title, 
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: fgColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist ?? 'Unknown',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isActive ? fgColor.withValues(alpha: 0.8) : theme.colorScheme.onSurfaceVariant
                    ),
                  ),
                ],
              ),
            ),
            // Badge removed per user request
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _MiniEq extends StatefulWidget {
  final bool animate;
  final Color color;
  const _MiniEq({required this.animate, required this.color});

  @override
  State<_MiniEq> createState() => _MiniEqState();
}

class _MiniEqState extends State<_MiniEq> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(_MiniEq oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) _controller.repeat();
      else _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12, height: 12,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
               final h = 4 + 8 * (0.5 + 0.5 * math.sin(_controller.value * 6 + i));
               return Container(
                 width: 2, height: h, 
                 decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(1)),
               );
            }),
          );
        },
      ),
    );
  }
}

class SliverGap extends StatelessWidget {
  final double size;
  const SliverGap(this.size, {super.key});
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: SizedBox(height: size));
  }
}
