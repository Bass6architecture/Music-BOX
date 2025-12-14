
import 'dart:math';
import 'package:on_audio_query/on_audio_query.dart';
import '../../player/player_cubit.dart';

class RecommendationEngine {
  
  static bool _isAllowed(SongModel song, PlayerStateModel state) {
    if (state.showHiddenFolders) return true;
    for (final folder in state.hiddenFolders) {
      if (song.data.startsWith(folder)) return false;
    }
    return true;
  }

  /// Generates a "Quick Play" mix based on recent listening habits and some randomness
  static List<SongModel> getQuickPlayMix(PlayerStateModel state, {int limit = 30}) {
    if (state.allSongs.isEmpty) return [];

    final allowedSongs = state.allSongs.where((s) => _isAllowed(s, state)).toList();
    if (allowedSongs.isEmpty) return [];

    // 1. Gather candidates
    final candidates = <SongModel>[];
    
    // Add recently played (high weight)
    final recent = state.lastPlayed.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Descending time
    
    final recentIds = recent.take(50).map((e) => e.key).toSet();
    
    // Add favorites (medium weight)
    final favorites = state.favorites.toList();
    
    // Add most played (high weight)
    final mostPlayed = state.playCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostPlayedIds = mostPlayed.take(20).map((e) => e.key).toSet();

    // 2. Build the mix
    // Strategy: 40% Recent/MostPlayed, 30% Favorites, 30% Random Discovery
    
    final allMap = {for (var s in allowedSongs) s.id: s}; // Use allowed songs only
    final random = Random();
    
    // Add some recents/most played
    for (var id in recentIds.take(10)) {
      if (allMap.containsKey(id)) candidates.add(allMap[id]!);
    }
    for (var id in mostPlayedIds.take(10)) {
       if (allMap.containsKey(id) && !candidates.contains(allMap[id])) {
         candidates.add(allMap[id]!);
       }
    }
    
    // Add favorites
    favorites.shuffle(random);
    for (var id in favorites.take(10)) {
      if (allMap.containsKey(id) && !candidates.contains(allMap[id])) {
        candidates.add(allMap[id]!);
      }
    }
    
    // Fill with random if needed
    if (candidates.length < limit) {
      final available = allowedSongs.where((s) => !candidates.contains(s)).toList();
      available.shuffle(random);
      candidates.addAll(available.take(limit - candidates.length));
    }
    
    // Shuffle the final result so it's not always sorted by type
    candidates.shuffle(random);
    
    return candidates.take(limit).toList();
  }

  /// Finds "Forgotten Gems": Songs with > 3 plays but not played in last 30 days
  static List<SongModel> getForgottenGems(PlayerStateModel state, {int limit = 10}) {
    if (state.allSongs.isEmpty) return [];

    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;
    
    // Filter
    final gems = state.allSongs.where((s) {
      if (!_isAllowed(s, state)) return false;

      final playCount = state.playCounts[s.id] ?? 0;
      final lastPlayed = state.lastPlayed[s.id] ?? 0;
      
      // Criteria: Played at least 3 times, but NOT in last 30 days (or never recorded in lastPlayed)
      final isForgotten = (now - lastPlayed) > thirtyDaysMs;
      return playCount >= 3 && isForgotten;
    }).toList();
    
    gems.shuffle();
    return gems.take(limit).toList();
  }

  /// Groups songs by Album for the "Cycles" section (Albums with recent activity)
  static List<SongModel> getRecentAlbums(PlayerStateModel state, {int limit = 6}) {
    if (state.allSongs.isEmpty) return [];
    
    // Get recent song IDs
    final recent = state.lastPlayed.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final recentIds = recent.take(50).map((e) => e.key).toSet();
    
    final recentSongs = state.allSongs.where((s) => recentIds.contains(s.id) && _isAllowed(s, state)).toList();
    
    // Count distinct songs per album in recent history
    final albumCounts = <String, Set<int>>{}; // AlbumName -> Set of SongIDs
    final albumRepresentative = <String, SongModel>{};
    
    for (var s in recentSongs) {
      final album = s.album ?? 'Unknown';
      if (!albumCounts.containsKey(album)) {
        albumCounts[album] = {};
        albumRepresentative[album] = s;
      }
      albumCounts[album]!.add(s.id);
    }
    
    // Filter albums with at least 2 distinct songs played recently (logic: "listening to the album")
    // Or just take the most recent albums
    final sortedAlbums = albumCounts.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length)); // Sort by "depth" of listening
      
    final result = <SongModel>[];
    for (var entry in sortedAlbums.take(limit)) {
      result.add(albumRepresentative[entry.key]!);
    }
    
    return result;
  }
  
  static List<SongModel> getRecentlyAdded(PlayerStateModel state, {int limit = 10}) {
    // MediaStore date_added is in seconds
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final thirtyDaysSec = 30 * 24 * 60 * 60;
    
    final allowed = state.allSongs.where((s) {
      if (!_isAllowed(s, state)) return false;
      // Filter last 30 days
      final dateAdded = s.dateAdded ?? 0;
      return dateAdded > (nowSec - thirtyDaysSec);
    }).toList();
    
    final sorted = List<SongModel>.from(allowed);
    sorted.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
    return sorted.take(limit).toList();
  }

  /// "Les Indémodables": Top played songs of all time
  static List<SongModel> getAllTimeHits(PlayerStateModel state, {int limit = 15}) {
    if (state.playCounts.isEmpty) return [];

    // Filter songs that are allowed AND have plays
    final candidates = state.allSongs.where((s) {
       if (!_isAllowed(s, state)) return false;
       return (state.playCounts[s.id] ?? 0) > 0;
    }).toList();

    // Sort by play count descending
    candidates.sort((a, b) {
      final playsA = state.playCounts[a.id] ?? 0;
      final playsB = state.playCounts[b.id] ?? 0;
      return playsB.compareTo(playsA);
    });

    return candidates.take(limit).toList();
  }

  /// Suggest random albums for new users or discovery
  static List<SongModel> getSuggestedAlbums(PlayerStateModel state, {int limit = 10}) {
    final allowed = state.allSongs.where((s) => _isAllowed(s, state)).toList();
    if (allowed.isEmpty) return [];

    final albumMap = <String, SongModel>{};
    // Group by album to get unique headers
    for (var s in allowed) {
      final alb = s.album ?? 'Unknown';
      if (!albumMap.containsKey(alb)) {
        albumMap[alb] = s;
      }
    }
    
    final albums = albumMap.values.toList();
    albums.shuffle();
    
    return albums.take(limit).toList();
  }
}
