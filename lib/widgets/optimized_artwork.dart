import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../player/player_cubit.dart';

/// High-quality, cached artwork widget for local audio/album images via on_audio_query.
/// - Uses DPR-aware downscaled decoding (cacheWidth/cacheHeight)
/// - filterQuality: high, gapless, antialias
/// - Simple in-memory cache by (type:id)
class OptimizedArtwork extends StatefulWidget {
  const OptimizedArtwork.square({
    super.key,
    required this.id,
    required this.type,
    this.size,
    this.fit = BoxFit.cover,
    this.fallbackBuilder,
    this.useCustomOverrides = true,
    this.borderRadius, // ✅ New parameter
  });

  final int id;
  final ArtworkType type;
  final double? size;
  final BoxFit fit;
  // Optional: allows caller to override the default placeholder when no bytes found
  final Widget Function(BuildContext context, double logicalSide)? fallbackBuilder;
  // When true (default), uses PlayerCubit.customArtworkPaths for AUDIO covers.
  // Set to false when used inside Sliver lists/grids to avoid provider select.
  final bool useCustomOverrides;
  final BorderRadius? borderRadius; // ✅ New parameter

  @override
  State<OptimizedArtwork> createState() => _OptimizedArtworkState();
}

class _OptimizedArtworkState extends State<OptimizedArtwork> {
  static final OnAudioQuery _query = OnAudioQuery();
  static final Map<String, Uint8List?> _cache = <String, Uint8List?>{};
  static const int _maxCacheSize = 250; // ✅ Increased cache size for smoother scrolling

  Uint8List? _bytes;
  int? _lastRequestedPx; // track last DPR-aware size we requested
  String? _lastCustomPath; // track last custom cover file path used

  String get _key => '${_typeKey(widget.type)}:${widget.id}';

  static String _typeKey(ArtworkType t) {
    switch (t) {
      case ArtworkType.ALBUM:
        return 'album';
      case ArtworkType.ARTIST:
        return 'artist';
      case ArtworkType.AUDIO:
        return 'audio';
      case ArtworkType.PLAYLIST:
        return 'playlist';
      case ArtworkType.GENRE:
        return 'genre';
    }
  }

  @override
  void initState() {
    super.initState();
    
    // ✅ 1. Sync check: Try to find exact match immediately to avoid flicker
    final exactKey = '${_typeKey(widget.type)}:${widget.id}';
    if (_cache.containsKey(exactKey)) {
      _bytes = _cache[exactKey];
    } 
    // ✅ 2. Placeholder check: If no exact match, try to find ANY cached version for this ID (e.g. from MiniPlayer)
    // This ensures Hero animation has *something* to fly with immediately.
    else {
      final partialKey = ':${widget.id}'; // Suffix for this ID
      for (final k in _cache.keys) {
        if (k.endsWith(partialKey) && _cache[k] != null) {
          _bytes = _cache[k];
          break; // Use the first one found (likely MiniPlayer's small version)
        }
      }
    }

    // Initial load with a safe default. Will be refined after first layout.
    _load(sizePx: (widget.size != null) ? (widget.size! * 3).round() : 1024);
  }

  @override
  void didUpdateWidget(covariant OptimizedArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || oldWidget.type != widget.type) {
      _lastRequestedPx = null; // force recalculation
      _bytes = null; // Reset bytes to show placeholder or new image
      
      // ✅ Try to find cached version for new ID immediately
      final exactKey = '${_typeKey(widget.type)}:${widget.id}';
      if (_cache.containsKey(exactKey)) {
        _bytes = _cache[exactKey];
      } else {
         final partialKey = ':${widget.id}';
         for (final k in _cache.keys) {
          if (k.endsWith(partialKey) && _cache[k] != null) {
            _bytes = _cache[k];
            break;
          }
        }
      }
      
      // Trigger a quick reload; exact size will be adjusted on next build.
      _load(sizePx: (widget.size != null) ? (widget.size! * 3).round() : 1024);
    }
  }

  Future<void> _load({required int sizePx}) async {
    // If we already have something cached for this EXACT key, use it immediately.
    // Note: We might have loaded a low-res placeholder in initState, but we still want to load the high-res version if requested.
    final cached = _cache[_key];
    if (cached != null) {
      // ✅ LRU: Move to end (most recently used)
      _cache.remove(_key);
      _cache[_key] = cached;
      
      if (mounted && _bytes != cached) {
         setState(() => _bytes = cached);
      }
      // If we have the exact match, we are done.
      return; 
    }

    // Avoid redundant requests for the same effective size.
    if (_lastRequestedPx != null && (sizePx - _lastRequestedPx!).abs() < 16) return;
    _lastRequestedPx = sizePx;

    try {
      // Request artwork with DPR-aware size. The Dart API provides defaults
      // for quality/format; we only override size and set quality to max.
      final art = await _query.queryArtwork(
        widget.id,
        widget.type,
        size: sizePx,
        quality: 100,
      );
      if (!mounted) return;
      
      // ✅ Limiter la taille du cache (LRU eviction)
      if (_cache.length >= _maxCacheSize) {
        _cache.remove(_cache.keys.first); // Removes the oldest (least recently used)
      }
      
      // Add to end (most recently used)
      _cache.remove(_key);
      _cache[_key] = art;
      setState(() => _bytes = art);
    } catch (_) {
      if (!mounted) return;
      // Don't cache nulls for failures, just leave it.
      // _cache[_key] = null; 
      // Keep showing placeholder or whatever we have
    }
  }

  @override
  Widget build(BuildContext context) {
    final confSize = widget.size; // logical size if explicitly provided
    final String? customPath = (widget.type == ArtworkType.AUDIO && widget.useCustomOverrides)
        ? context.select((PlayerCubit c) => c.state.customArtworkPaths[widget.id])
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine the square's logical side: either provided size or constraints
        final logicalSide = confSize ??
            (constraints.hasBoundedWidth && constraints.hasBoundedHeight
                ? (constraints.biggest.shortestSide.isFinite
                    ? constraints.biggest.shortestSide
                    : 0)
                : 0);

        // Compute desired pixel size based on DPR, clamp to sane bounds
        final dpr = MediaQuery.of(context).devicePixelRatio;
        int desiredPx = (logicalSide > 0 ? (logicalSide * dpr * 1.5) : 768).round();
        desiredPx = desiredPx.clamp(256, 3072);
        // Hint the engine to not upscale beyond what we requested
        final cachePx = desiredPx;

        // Read potential custom path for this AUDIO item
        final bool hasCustom = customPath != null && customPath.isNotEmpty && File(customPath).existsSync();

        // Schedule a fetch from on_audio_query only when no custom cover
        if (!hasCustom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _load(sizePx: desiredPx);
          });
        }

        // If a custom cover exists for this song, evict cache and render it directly
        if (hasCustom) {
          final file = File(customPath);
          DateTime? mtime;
          try { mtime = file.lastModifiedSync(); } catch (_) {}
          final cacheBuster = mtime?.millisecondsSinceEpoch.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

          // Evict any stale cached image for this file path on every build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            try { painting.imageCache.evict(FileImage(file)); } catch (_) {}
            if (_lastCustomPath != null && _lastCustomPath!.isNotEmpty && _lastCustomPath != customPath) {
              try { painting.imageCache.evict(FileImage(File(_lastCustomPath!))); } catch (_) {}
            }
            _lastCustomPath = customPath;
          });

          return RepaintBoundary(
            child: Image.file(
              file,
              // Include a cache-busting key so Flutter rebuilds when the file content changes
              key: ValueKey<String>('custom:${widget.id}:$cacheBuster'),
              width: confSize,
              height: confSize,
              fit: widget.fit,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              isAntiAlias: true,
              cacheWidth: cachePx,
              // cacheHeight: cachePx, // ✅ Removed to preserve aspect ratio
              // cacheHeight: cachePx, // ✅ Removed to preserve aspect ratio
            ),
          );
        }

        // Placeholder when no bytes yet
        if (_bytes == null || _bytes!.isEmpty) {
          final theme = Theme.of(context);
          final side = (logicalSide > 0 ? logicalSide : 64.0);
          final circle = side * 0.6;
          final iconSize = side * 0.36;
          final icon = () {
            switch (widget.type) {
              case ArtworkType.ALBUM:
                return Icons.album_rounded;
              case ArtworkType.ARTIST:
                return Icons.person_rounded;
              case ArtworkType.AUDIO:
                return Icons.music_note_rounded;
              case ArtworkType.PLAYLIST:
                return Icons.queue_music_rounded;
              case ArtworkType.GENRE:
                return Icons.category_rounded;
            }
          }();

          // If a custom fallbackBuilder is provided, use it
          if (widget.fallbackBuilder != null) {
            return SizedBox(
              width: confSize,
              height: confSize,
              child: widget.fallbackBuilder!(context, side),
            );
          }

          return RepaintBoundary(
            child: Container(
              width: confSize,
              height: confSize,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius, // ✅ Apply radius
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                    theme.colorScheme.primary.withValues(alpha: 0.30),
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IgnorePointer(
                      child: Container(
                        width: side * 0.55,
                        height: side * 0.55,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.13),
                              Colors.transparent,
                            ],
                            radius: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: circle,
                      height: circle,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: iconSize,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RepaintBoundary(
          child: Container(
            width: confSize,
            height: confSize,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius, // ✅ Apply radius
              image: DecorationImage(
                image: ResizeImage(
                  MemoryImage(_bytes!),
                  width: cachePx,
                  allowUpscaling: true,
                ),
                fit: widget.fit,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
