import 'dart:async';

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';

/// Helper class to process heavy music data operations in background isolates.
class MusicDataProcessor {
  
  /// Groups songs by album in a background isolate.
  static Future<List<AlbumItem>> groupSongsByAlbum(List<SongModel> songs) async {
    return compute(_groupSongsByAlbumIsolate, songs);
  }

  /// Filters and sorts songs in a background isolate.
  static Future<List<SongModel>> filterAndSortSongs({
    required List<SongModel> songs,
    required String query,
    required int sortTypeIndex, // Pass index instead of enum to be safe across isolates
    required bool ascending,
    required Map<int, Map<String, dynamic>> overrides, // Pass raw JSON map for overrides
    required Set<String> hiddenFolders,
    required bool showHiddenFolders,
  }) async {
    return compute(_filterAndSortSongsIsolate, _FilterParams(
      songs: songs,
      query: query,
      sortTypeIndex: sortTypeIndex,
      ascending: ascending,
      overrides: overrides,
      hiddenFolders: hiddenFolders,
      showHiddenFolders: showHiddenFolders,
    ));
  }

  /// Extracts dominant color from image bytes in a background isolate.
  static Future<int?> extractDominantColor(Uint8List bytes) async {
    try {
      return await compute(_extractColorIsolate, bytes);
    } catch (e) {
      debugPrint('Error extracting color in isol ate: $e');
      return null;
    }
  }

  /// Extracts full palette (dominant, vibrant, muted) from artwork bytes.
  /// Decodes image on main thread, then extracts palette (still heavy but unavoidable).
  static Future<Map<String, int>?> extractPalette(Uint8List bytes) async {
    try {
      // âœ… MUST decode on main thread (dart:ui required)
      final codec = await instantiateImageCodec(bytes, targetWidth: 100);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // âœ… PaletteGenerator can run on main thread with async gap
      final palette = await PaletteGenerator.fromImage(
        image,
        maximumColorCount: 16,
      );

      final dominant = palette.dominantColor?.color ?? 
                       palette.lightMutedColor?.color ?? 
                       const Color(0xFF2a2a3e);
                       
      final vibrant = palette.vibrantColor?.color ?? 
                      palette.lightVibrantColor?.color ?? 
                      palette.darkVibrantColor?.color ?? 
                      palette.mutedColor?.color ?? 
                      dominant;
                      
      final muted = palette.mutedColor?.color ?? 
                    palette.darkMutedColor?.color ?? 
                    palette.lightMutedColor?.color ?? 
                    const Color(0xFF26304e);

      return {
        'dominant': dominant.toARGB32(),
        'vibrant': vibrant.toARGB32(),
        'muted': muted.toARGB32(),
      };
    } catch (e) {
      debugPrint('Error extracting palette: $e');
      return null;
    }
  }

  // --- Isolate Functions (Must be static or top-level) ---

  static List<AlbumItem> _groupSongsByAlbumIsolate(List<SongModel> songs) {
    final map = <String, AlbumItem>{};
    
    for (final s in songs) {
      // Use a composite key to avoid collisions if IDs are missing
      final key = '${s.albumId ?? -1}_${s.album ?? "unknown"}';
      
      final item = map.putIfAbsent(
        key,
        () => AlbumItem(
          albumId: s.albumId,
          title: s.album ?? 'Unknown Album', // We'll localize on UI side if needed, or pass locale
          artist: s.artist ?? 'Unknown Artist',
          sampleSongId: s.id,
        ),
      );
      
      // Keep the first valid ID
      item.sampleSongId ??= s.id;
      item.count += 1;
    }

    final list = map.values.toList();
    // Sort by title
    list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  static List<SongModel> _filterAndSortSongsIsolate(_FilterParams params) {
    final query = params.query.toLowerCase();
    
    // 0. Apply overrides to all songs FIRST
    // This ensures we filter and sort on the final displayed values
    final processedSongs = params.songs.map((s) {
      final o = params.overrides[s.id];
      if (o == null) return s;

      // Apply override logic (similar to PlayerCubit.applyOverrides but simplified for isolate)
      final baseTitle = o['title'] as String?;
      final baseArtist = o['artist'] as String?;
      final baseAlbum = o['album'] as String?;

      // Safely access original values
      final map = s.getMap;
      final dispName = map['display_name'] as String?;
      final uri = map['_uri'] as String? ?? map['_data'] as String? ?? '';
      final duration = map['duration'] as int? ?? 0;
      final size = map['size'] as int? ?? 0;
      final dateAdded = map['date_added'] as int? ?? 0;
      final dateModified = map['date_modified'] as int? ?? 0;
      final albumId = map['album_id'];
      final artistId = map['artist_id'];
      
      // Original values if not overridden
      final orgTitle = map['title'] as String?;
      final orgArtist = map['artist'] as String?;
      final orgAlbum = map['album'] as String?;

      // Calculate final values
      // Note: We can't use path.basename here easily without importing path package.
      // But we can do a simple string split if needed, or just rely on display_name.
      final finalTitle = (baseTitle ?? orgTitle ?? dispName ?? 'Unknown').trim();
      final finalArtist = (baseArtist ?? orgArtist ?? '').trim();
      final finalAlbum = (baseAlbum ?? orgAlbum ?? '').trim();
      final finalDisplayName = (dispName ?? finalTitle).trim();

      return SongModel({
        '_id': s.id,
        'title': finalTitle,
        'artist': finalArtist,
        'album': finalAlbum,
        '_uri': uri,
        '_data': map['_data'], // Keep data path
        'duration': duration,
        'display_name': finalDisplayName,
        'size': size,
        'date_added': dateAdded,
        'date_modified': dateModified,
        'album_id': albumId,
        'artist_id': artistId,
      });
    }).toList();

    // 1. Filter
    final filtered = processedSongs.where((s) {
      // Check hidden folders first
      if (!params.showHiddenFolders && s.data.isNotEmpty) {
        for (final hidden in params.hiddenFolders) {
          if (s.data.startsWith(hidden)) return false;
        }
      }
      
      // Filter on ALREADY OVERRIDDEN values
      return s.title.toLowerCase().contains(query) ||
             (s.artist ?? '').toLowerCase().contains(query) ||
             (s.album ?? '').toLowerCase().contains(query);
    }).toList();

    // 2. Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (params.sortTypeIndex) {
        case 0: // title
          comparison = a.title.compareTo(b.title);
          break;
        case 1: // artist
          comparison = (a.artist ?? '').compareTo(b.artist ?? '');
          break;
        case 2: // album
          comparison = (a.album ?? '').compareTo(b.album ?? '');
          break;
        case 3: // duration
          comparison = (a.duration ?? 0).compareTo(b.duration ?? 0);
          break;
        case 4: // date
          comparison = (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0);
          break;
      }
      return params.ascending ? comparison : -comparison;
    });

    return filtered;
  }

  static Future<int?> _extractColorIsolate(Uint8List bytes) async {
    try {
      // Decode image in isolate
      final codec = await instantiateImageCodec(bytes, targetWidth: 100); // Resize for speed
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // PaletteGenerator can run in background isolates in modern Flutter
      final palette = await PaletteGenerator.fromImage(
        image,
        maximumColorCount: 16,
      );
      
      final color = palette.vibrantColor?.color ?? 
                    palette.lightVibrantColor?.color ?? 
                    palette.darkVibrantColor?.color ?? 
                    palette.dominantColor?.color;
                    
      return color?.toARGB32();
    } catch (e) {
      return null;
    }
  }
}

// --- Helper Classes ---

class AlbumItem {
  AlbumItem({
    required this.albumId,
    required this.title,
    required this.artist,
    this.sampleSongId,
  });
  
  final int? albumId;
  final String title;
  final String artist;
  int? sampleSongId;
  int count = 0;
}

class _FilterParams {
  final List<SongModel> songs;
  final String query;
  final int sortTypeIndex;
  final bool ascending;
  final Map<int, Map<String, dynamic>> overrides;
  final Set<String> hiddenFolders;
  final bool showHiddenFolders;

  _FilterParams({
    required this.songs,
    required this.query,
    required this.sortTypeIndex,
    required this.ascending,
    required this.overrides,
    required this.hiddenFolders,
    required this.showHiddenFolders,
  });
}




