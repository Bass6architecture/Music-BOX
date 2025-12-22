import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'optimized_artwork.dart';
import '../player/player_cubit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

/// Unified, customizable tile for displaying a song row across the app.
///
/// Features:
/// - Artwork via `OptimizedArtwork`
/// - Title + default subtitle (artist • album), customizable
/// - Optional favorite button
/// - Optional popup menu via a builder
/// - Optional index badge
/// - Optional active highlighting (now playing)

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    this.compact = false,
    this.subtitle,
    // ignore: unused_field
    this.showFavorite = false,
    this.isFavorite,
    this.onToggleFavorite,
    this.menuBuilder,
    this.onMenuSelected,
    this.onTap,
    this.index,
    this.highlightActive = true,
    this.onMorePressed,
    this.showTrailingActiveIndicator = false,
    this.trailing,
    this.applyMetadataOverrides = true, // ✅ New flag to skip redundant processing
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
  });

  final SongModel song;
  final bool compact;
  final String? subtitle;
  // ignore: unused_field
  final bool showFavorite;
  final bool? isFavorite;
  final VoidCallback? onToggleFavorite;
  final List<PopupMenuEntry<dynamic>> Function(BuildContext, SongModel)? menuBuilder;
  final void Function(dynamic)? onMenuSelected;
  final VoidCallback? onTap;
  final int? index; // Optional numeric badge on artwork
  final bool highlightActive;
  final VoidCallback? onMorePressed; // Alternative to menuBuilder: open custom sheet
  final bool showTrailingActiveIndicator; // Show EQ in trailing area when active
  final Widget? trailing; // ✅ Custom trailing widget (e.g. play count)
  final bool applyMetadataOverrides;
  
  // Selection Mode Support
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;

  String _defaultSubtitleFor(SongModel base) {
    final parts = <String>[];
    final artist = base.artist?.trim() ?? '';
    final album = base.album?.trim() ?? '';
    if (artist.isNotEmpty) parts.add(artist);
    if (album.isNotEmpty) parts.add(album);
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Apply local metadata overrides for display ONLY if requested
    final overrideSong = applyMetadataOverrides 
        ? context.select((PlayerCubit c) {
            final overrides = c.state.metadataOverrides[song.id];
            if (overrides == null) return song;
            return c.applyOverrides(song);
          })
        : song; // ✅ Use provided song directly if overrides are disabled (pre-processed)

    final isActive = highlightActive
        ? context.select((PlayerCubit c) => c.currentSong?.id == song.id)
        : false;
    
    final isPlaying = isActive
        ? context.select((PlayerCubit c) => c.state.isPlaying)
        : false;

    final artSize = 56.0; // ✅ Aligned with For You
    final radius = 8.0;   // ✅ Reduced radius
    
    // Slim text styles
    // Slim text styles
    final titleStyle = GoogleFonts.outfit(
      color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
      fontSize: 14,
    );
    
    final subtitleText = subtitle?.trim().isNotEmpty == true
        ? subtitle!.trim()
        : _defaultSubtitleFor(overrideSong);
        
    final subStyle = GoogleFonts.outfit(
      color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.8) : theme.colorScheme.onSurfaceVariant,
      fontSize: 12,
    );

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Selection Checkbox (Left)
        if (isSelectionMode) ...[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PhosphorIcon(
              isSelected ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill) : PhosphorIcons.circle(),
               color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
               size: 24,
            ),
          ),
        ],

        // Artwork + optional index badge
        SizedBox(
          width: artSize,
          height: artSize,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: OptimizedArtwork.square(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    size: artSize,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                ),
              ),
              // Darken artwork a bit when active so the EQ is always visible
                if (isActive)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(radius),
                      ),
                    ),
                  ),
              if (index != null)
                Positioned(
                  left: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text(
                      '$index',
                      style: GoogleFonts.outfit(
                        fontSize: theme.textTheme.labelSmall?.fontSize,
                        color: theme.textTheme.labelSmall?.color,
                        fontWeight: theme.textTheme.labelSmall?.fontWeight,
                      ),
                    ),
                  ),
                ),
                if (isActive)
                  Positioned.fill(
                    child: Center(
                      child: _EqIndicator(
                        color: Colors.white,
                        barCount: 3,
                        width: 16,
                        height: 12,
                        animate: isPlaying,
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Title + Subtitle
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overrideSong.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              if (subtitleText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: subStyle,
                  ),
                ),
            ],
          ),
        ),

        // Favorite button
        if (showFavorite && isFavorite != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: isFavorite! ? 'Retirer des favoris' : 'Ajouter aux favoris',
            icon: PhosphorIcon(
              isFavorite! ? PhosphorIcons.heart(PhosphorIconsStyle.fill) : PhosphorIcons.heart(),
              color: isFavorite!
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color,
            ),
            onPressed: onToggleFavorite,
          ),

        // Optional trailing active EQ indicator
        if (showTrailingActiveIndicator && isActive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _EqIndicator(
              color: Colors.white,
              barCount: 3,
              width: 16,
              height: 12,
              animate: isPlaying,
            ),
          ),

        // ✅ Custom trailing widget
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 4),
            child: trailing,
          ),

        // Popup menu
        if (onMorePressed != null)
          IconButton(
            tooltip: 'Plus',
            icon: PhosphorIcon(PhosphorIcons.dotsThreeVertical(), size: 24),
            onPressed: onMorePressed,
          )
        else if (menuBuilder != null)
          PopupMenuButton<dynamic>(
            tooltip: 'Options',
            icon: PhosphorIcon(PhosphorIcons.dotsThreeVertical(), size: 24),
            itemBuilder: (ctx) => menuBuilder!(ctx, song),
            onSelected: onMenuSelected,
          ),
      ],
    );

    // Background logic
    Color? backgroundColor;
    if (isSelected) {
      backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.15); // Subtle selection
    } else {
      backgroundColor = Colors.transparent; // No active background
    }

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          child: row,
        ),
      ),
    );
  }
}

class _EqIndicator extends StatefulWidget {
  const _EqIndicator({
    this.color,
    this.barCount = 3,
    this.width = 16,
    this.height = 12,
    this.animate = true,
  });

  final Color? color;
  final int barCount;
  final double width;
  final double height;
  final bool animate;

  @override
  State<_EqIndicator> createState() => _EqIndicatorState();
}

class _EqIndicatorState extends State<_EqIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.animate) {
      _c.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _EqIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        if (!_c.isAnimating) _c.repeat();
      } else {
        _c.stop();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final barW = widget.width / (widget.barCount + (widget.barCount - 1) * 0.5);
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final bars = <Widget>[];
          for (int i = 0; i < widget.barCount; i++) {
            final phase = i / widget.barCount;
            final v = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(2 * math.pi * (_c.value + phase)));
            final h = (v * widget.height).clamp(2.0, widget.height);
            bars.add(Container(
              width: barW,
              height: h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(barW),
              ),
            ));
            if (i != widget.barCount - 1) bars.add(SizedBox(width: barW * 0.5));
          }
          return Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars,
            ),
          );
        },
      ),
    );
  }
}
