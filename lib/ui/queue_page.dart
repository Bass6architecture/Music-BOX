import 'widgets/music_box_scaffold.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_box/generated/app_localizations.dart';
import '../player/player_cubit.dart';
import '../widgets/optimized_artwork.dart';
import '../player/mini_player.dart';


class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  late final ScrollController _scrollController;
  bool _hasScrolled = false;

  final Set<int> _selectedIds = {};
  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Auto-scroll to current song after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasScrolled && mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_hasScrolled) {
            _scrollToCurrentSong(animated: true);
            _hasScrolled = true;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    final cubit = context.read<PlayerCubit>();
    setState(() {
      if (_selectedIds.length == cubit.state.songs.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(cubit.state.songs.map((s) => s.id).toList());
      }
    });
  }

  void _deleteSelected() {
    final cubit = context.read<PlayerCubit>();
    final currentId = cubit.state.currentSongId;
    
    // Filter out current song from deletion
    final toDelete = _selectedIds.where((id) => id != currentId).toList();
    
    // Process deletion (assuming cubit has a method to remove multiple or we loop)
    // Cubit usually creates a new list. Efficient way: Get current list, remove items, set new queue.
    // Or just loop removeFromQueue (can be slow index shifting)
    // Better: cubit.removeIds(toDelete) if exists, or implement it.
    // For now, I'll assume we iterate reverse to avoid index shift issues if removing by index, 
    // BUT we have IDs.
    // Let's implement bulk remove in UI logic:
    
    final currentQueue = [...cubit.state.songs];
    currentQueue.removeWhere((s) => toDelete.contains(s.id));
    
    cubit.updateQueue(currentQueue);
    
    setState(() {
      _selectedIds.clear();
    });
  }

  void _scrollToCurrentSong({bool animated = true}) {
    final cubit = context.read<PlayerCubit>();
    final currentIndex = cubit.state.currentIndex ?? -1;
    
    if (currentIndex >= 0 && _scrollController.hasClients) {
      // Estimate position: Header (approx 60) + (Index * ItemHeight approx 72)
      // This is an estimation because Slivers are lazy, but good enough for initial scroll
      final estimatedOffset = 60.0 + (currentIndex * 72.0) - (MediaQuery.of(context).size.height * 0.3);
      final maxScroll = _scrollController.position.maxScrollExtent;
      final safeOffset = estimatedOffset.clamp(0.0, maxScroll > 0 ? maxScroll : estimatedOffset);

      if (animated) {
        _scrollController.animateTo(
          safeOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuart,
        );
      } else {
        _scrollController.jumpTo(safeOffset);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.watch<PlayerCubit>();
    final songs = cubit.state.songs;
    final currentIndex = cubit.state.currentIndex ?? -1;
    final currentSongId = cubit.state.currentSongId;

    return MusicBoxScaffold(
      // Use transparent background to let MusicBoxScaffold handle the gradient/image
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _selectedIds.clear()),
              )
            : IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: _isSelectionMode
            ? Row(
                children: [
                  // Circle Left: Select All / Count
                  InkWell(
                    onTap: _selectAll,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedIds.length == songs.length ? Icons.check_circle : Icons.circle_outlined, 
                            color: Colors.white, size: 20
                          ),
                          const SizedBox(width: 8),
                          Text("${_selectedIds.length}", style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              )
            : Text(
                AppLocalizations.of(context)!.queue,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white), // "petite cercle avec un tiret"
              onPressed: _deleteSelected,
            )
          else if (songs.isNotEmpty) ...[
            if (currentIndex >= 0)
              IconButton(
                onPressed: () => _scrollToCurrentSong(animated: true),
                icon: const Icon(Icons.my_location_rounded, color: Colors.white),
                tooltip: AppLocalizations.of(context)!.nowPlaying,
              ),
            IconButton(
              onPressed: () => _showClearDialog(context),
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
              tooltip: AppLocalizations.of(context)!.clearQueue,
            ),
          ],
        ],
      ),
      body: songs.isEmpty
          ? _buildEmptyState(context)
          : Stack(
              children: [
                // âœ… Glassmorphism Background
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                
                CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header Info
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${songs.length} ${AppLocalizations.of(context)!.songs}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // The List
                    SliverReorderableList(
                      itemCount: songs.length,
                      onReorder: (oldIndex, newIndex) {
                        // Haptic feedback on drop
                        HapticFeedback.lightImpact();
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        cubit.reorderQueue(oldIndex, newIndex);
                      },
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (BuildContext context, Widget? child) {
                            final double animValue = Curves.easeInOut.transform(animation.value);
                            final double elevation = lerpDouble(0, 6, animValue)!;
                            return Material(
                              elevation: elevation,
                              color: Colors.transparent,
                              shadowColor: Colors.black.withValues(alpha: 0.3),
                              child: Transform.scale(
                                scale: 1.02, // Slightly larger when dragging
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        final isPlaying = song.id == currentSongId;
                        
                        // Separator logic (optional visual break)
                        final bool showUpNextHeader = isPlaying && index < songs.length - 1;

                        return Column(
                          key: ValueKey('queue_wrapper_${song.id}'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildDismissibleItem(context, cubit, song, index, isPlaying, theme),
                            
                            if (showUpNextHeader)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                                child: Row(
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.upNext.toUpperCase(),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    
                    // Bottom padding for MiniPlayer
                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                ),
                
                // Gradient fade at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 120,
                  child: IgnorePointer(
                    child: Container(
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
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const MiniPlayer(disableNavigation: true),
    );
  }

  Widget _buildDismissibleItem(
    BuildContext context,
    PlayerCubit cubit,
    SongModel song,
    int index,
    bool isPlaying,
    ThemeData theme,
  ) {
    // If we are in Selection Mode, disable Dismissible (swipe)
    // Actually, user wants to REMOVE swipe completely ("je veux plus de cette swipe").
    // So we just return the item wrapped in InkWell/LongPress logic.
    
    return _QueueItem(
      song: song,
      index: index,
      isPlaying: isPlaying,
      // Selection props
      isSelectionMode: _isSelectionMode,
      isSelected: _selectedIds.contains(song.id),
      onLongPress: () {
        if (!_isSelectionMode) {
           HapticFeedback.mediumImpact();
           _toggleSelection(song.id);
        }
      },
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(song.id);
        } else {
          cubit.playAt(index);
        }
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.queue_music_rounded,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.queueEmpty,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppLocalizations.of(context)!.clearQueue,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          AppLocalizations.of(context)!.confirmClearQueue,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PlayerCubit>().clearQueue();
            },
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }
}

class _QueueItem extends StatelessWidget {
  const _QueueItem({
    required this.song,
    required this.index,
    required this.isPlaying,
    required this.onTap,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onLongPress,
  });

  final SongModel song;
  final int index;
  final bool isPlaying;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Background color logic: Highligh if selected OR if playing
    Color? backgroundColor;
    if (isSelected) {
      backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.2);
    } else if (isPlaying) {
      backgroundColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    }

    // Border logic
    BoxBorder? border;
    if (isPlaying && !isSelected) {
       border = Border(
        left: BorderSide(
          color: theme.colorScheme.primary,
          width: 4,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: 72, 
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: border,
          ),
          child: Row(
            children: [
               // Selection Checkbox (Left)
               if (isSelectionMode) ...[
                 Icon(
                   isSelected ? Icons.check_circle : Icons.circle_outlined,
                   color: isSelected ? theme.colorScheme.primary : Colors.white.withValues(alpha: 0.5),
                   size: 24,
                 ),
                 const SizedBox(width: 16),
               ],

              // Artwork
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  children: [
                    OptimizedArtwork.square(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      size: 48,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    if (isPlaying)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: _AnimatedEqualizer(),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isPlaying ? theme.colorScheme.primary : Colors.white,
                        fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist ?? AppLocalizations.of(context)!.unknownArtist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Drag Handle or Spacer - Hide drag handle in selection mode?
              if (!isSelectionMode)
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.transparent,
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: isPlaying 
                          ? theme.colorScheme.primary.withValues(alpha: 0.5) 
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedEqualizer extends StatefulWidget {
  const _AnimatedEqualizer();

  @override
  State<_AnimatedEqualizer> createState() => _AnimatedEqualizerState();
}

class _AnimatedEqualizerState extends State<_AnimatedEqualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildBar(0, 0.6),
          _buildBar(1, 0.9),
          _buildBar(2, 0.5),
        ],
      ),
    );
  }

  Widget _buildBar(int index, double maxHeight) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Simple sine wave simulation
        final t = _controller.value + (index * 0.33);
        final height = 0.3 + (0.7 * (0.5 + 0.5 * (math.sin(t * math.pi * 2))));
        
        return Container(
          width: 3,
          height: 16 * height * maxHeight,
          decoration: BoxDecoration(
            color: Colors.white, // âœ… Fixed: White color
            borderRadius: BorderRadius.circular(1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

// Helper for lerpDouble
double? lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0;
  b ??= 0.0;
  return a + (b - a) * t;
}




