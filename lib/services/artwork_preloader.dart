import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Service to pre-cache artwork during splash screen.
/// Populates OptimizedArtwork's static cache before navigation.
class ArtworkPreloader {
  static final OnAudioQuery _query = OnAudioQuery();
  
  // Reference to OptimizedArtwork's static cache - will be set externally
  static Map<String, Uint8List?>? _externalCache;
  
  /// Set the external cache reference from OptimizedArtwork
  static void setCache(Map<String, Uint8List?> cache) {
    _externalCache = cache;
  }
  
  /// Pre-cache artwork for all songs, albums, and artists.
  /// Returns the number of items cached.
  static Future<int> preloadAll({
    required List<int> songIds,
    required List<int> albumIds,
    required List<int> artistIds,
    int sizePx = 300,
  }) async {
    if (_externalCache == null) {
      debugPrint('[ArtworkPreloader] Cache not set, skipping pre-cache');
      return 0;
    }
    
    int cached = 0;
    final stopwatch = Stopwatch()..start();
    
    // Pre-cache songs (AUDIO type) in parallel batches
    cached += await _preloadBatch(songIds, ArtworkType.AUDIO, 'audio', sizePx);
    
    // Pre-cache albums
    cached += await _preloadBatch(albumIds, ArtworkType.ALBUM, 'album', sizePx);
    
    // Pre-cache artists
    cached += await _preloadBatch(artistIds, ArtworkType.ARTIST, 'artist', sizePx);
    
    stopwatch.stop();
    debugPrint('[ArtworkPreloader] Pre-cached $cached items in ${stopwatch.elapsedMilliseconds}ms');
    
    return cached;
  }
  
  /// Pre-cache a batch of IDs for a specific artwork type.
  static Future<int> _preloadBatch(
    List<int> ids,
    ArtworkType type,
    String typeKey,
    int sizePx,
  ) async {
    if (ids.isEmpty) return 0;
    
    int cached = 0;
    
    // Process in parallel batches of 10 for speed
    const batchSize = 10;
    for (int i = 0; i < ids.length; i += batchSize) {
      final batch = ids.skip(i).take(batchSize).toList();
      
      final futures = batch.map((id) async {
        final key = '$typeKey:$id';
        
        // Skip if already cached
        if (_externalCache!.containsKey(key)) return false;
        
        try {
          final bytes = await _query.queryArtwork(
            id,
            type,
            size: sizePx,
            quality: 100,
            format: ArtworkFormat.PNG,
          );
          
          if (bytes != null) {
            _externalCache![key] = bytes;
            return true;
          }
        } catch (e) {
          // Ignore errors, just skip this artwork
        }
        return false;
      });
      
      final results = await Future.wait(futures);
      cached += results.where((success) => success).length;
    }
    
    return cached;
  }
  
  /// Quick pre-load for visible items only (for faster splash).
  /// Pre-caches first N songs, albums, and artists.
  static Future<int> preloadVisible({
    required List<int> songIds,
    required List<int> albumIds,
    required List<int> artistIds,
    int maxSongs = 20,
    int maxAlbums = 12,
    int maxArtists = 8,
    int sizePx = 300,
  }) async {
    return preloadAll(
      songIds: songIds.take(maxSongs).toList(),
      albumIds: albumIds.take(maxAlbums).toList(),
      artistIds: artistIds.take(maxArtists).toList(),
      sizePx: sizePx,
    );
  }
}


