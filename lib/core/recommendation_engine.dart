
import 'dart:math';
import 'package:flutter/foundation.dart'; // Pour compute
import 'package:on_audio_query/on_audio_query.dart';


/// DTO for passing data to Isolate
class RecommendationInputs {
  final List<SongModel> allSongs;
  final Map<int, int> playCounts;
  final Map<int, int> lastPlayed;
  final List<int> favorites;
  final List<String> hiddenFolders;
  final bool showHiddenFolders;

  RecommendationInputs({
    required this.allSongs,
    required this.playCounts,
    required this.lastPlayed,
    required this.favorites,
    required this.hiddenFolders,
    required this.showHiddenFolders,
  });
}

/// DTO for returning results from Isolate
class RecommendationResults {
  final List<SongModel> quickPlay;
  final List<SongModel> forgotten;
  final List<SongModel> habits;
  final List<SongModel> fresh;
  final List<SongModel> hits;
  final List<SongModel> suggestions;

  RecommendationResults({
    required this.quickPlay,
    required this.forgotten,
    required this.habits,
    required this.fresh,
    required this.hits,
    required this.suggestions,
  });
}

class RecommendationEngine {
  
  /// Main Entry Point: Runs calculation in a background isolate
  static Future<RecommendationResults> computeRecommendations(RecommendationInputs inputs) async {
    return await compute(_calculateSync, inputs);
  }

  /// Internal synchronous calculation (runs in isolate)
  static RecommendationResults _calculateSync(RecommendationInputs inputs) {
    final quick = _getQuickPlayMix(inputs);
    final forgotten = _getForgottenGems(inputs);
    final habits = _getRecentAlbums(inputs);
    final fresh = _getRecentlyAdded(inputs);
    final hits = _getAllTimeHits(inputs);
    final suggestions = habits.isEmpty ? _getSuggestedAlbums(inputs) : <SongModel>[];

    return RecommendationResults(
      quickPlay: quick,
      forgotten: forgotten,
      habits: habits,
      fresh: fresh,
      hits: hits,
      suggestions: suggestions,
    );
  }

  static bool _isAllowed(SongModel song, RecommendationInputs inputs) {
    if (inputs.showHiddenFolders) return true;
    for (final folder in inputs.hiddenFolders) {
      if (song.data.startsWith(folder)) return false;
    }
    return true;
  }

  static List<SongModel> _getQuickPlayMix(RecommendationInputs inputs, {int limit = 30}) {
    if (inputs.allSongs.isEmpty) return [];

    final allowedSongs = inputs.allSongs.where((s) => _isAllowed(s, inputs)).toList();
    if (allowedSongs.isEmpty) return [];

    final candidates = <SongModel>[];
    
    final recent = inputs.lastPlayed.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final recentIds = recent.take(50).map((e) => e.key).toSet();
    final favorites = inputs.favorites.toList();
    
    final mostPlayed = inputs.playCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostPlayedIds = mostPlayed.take(20).map((e) => e.key).toSet();

    final allMap = {for (var s in allowedSongs) s.id: s}; 
    final random = Random();
    
    for (var id in recentIds.take(10)) {
      if (allMap.containsKey(id)) candidates.add(allMap[id]!);
    }
    for (var id in mostPlayedIds.take(10)) {
       if (allMap.containsKey(id) && !candidates.contains(allMap[id])) {
         candidates.add(allMap[id]!);
       }
    }
    
    favorites.shuffle(random);
    for (var id in favorites.take(10)) {
      if (allMap.containsKey(id) && !candidates.contains(allMap[id])) {
        candidates.add(allMap[id]!);
      }
    }
    
    if (candidates.length < limit) {
      final available = allowedSongs.where((s) => !candidates.contains(s)).toList();
      available.shuffle(random);
      candidates.addAll(available.take(limit - candidates.length));
    }
    
    candidates.shuffle(random);
    return candidates.take(limit).toList();
  }

  static List<SongModel> _getForgottenGems(RecommendationInputs inputs, {int limit = 10}) {
    if (inputs.allSongs.isEmpty) return [];

    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;
    
    // Si pas assez d'historique, prendre des chansons alÃ©atoires peu jouÃ©es
    final gems = inputs.allSongs.where((s) {
      if (!_isAllowed(s, inputs)) return false;
      final playCount = inputs.playCounts[s.id] ?? 0;
      // Relaxed: playCount < 5 (moins jouÃ©es) au lieu de >= 3 && forgotten
      return playCount < 5;
    }).toList();
    
    gems.shuffle();
    return gems.take(limit).toList();
  }

  static List<SongModel> _getRecentAlbums(RecommendationInputs inputs, {int limit = 6}) {
    if (inputs.allSongs.isEmpty) return [];
    
    final recent = inputs.lastPlayed.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final recentIds = recent.take(50).map((e) => e.key).toSet();
    
    final recentSongs = inputs.allSongs.where((s) => recentIds.contains(s.id) && _isAllowed(s, inputs)).toList();
    
    final albumCounts = <String, Set<int>>{}; 
    final albumRepresentative = <String, SongModel>{};
    
    for (var s in recentSongs) {
      final album = s.album ?? 'Unknown';
      if (!albumCounts.containsKey(album)) {
        albumCounts[album] = {};
        albumRepresentative[album] = s;
      }
      albumCounts[album]!.add(s.id);
    }
    
    final sortedAlbums = albumCounts.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length)); 
      
    final result = <SongModel>[];
    for (var entry in sortedAlbums.take(limit)) {
      result.add(albumRepresentative[entry.key]!);
    }
    
    return result;
  }
  
  static List<SongModel> _getRecentlyAdded(RecommendationInputs inputs, {int limit = 15}) {
    // Relaxed: Just sort by dateAdded descending, no time limit
    final allowed = inputs.allSongs.where((s) => _isAllowed(s, inputs)).toList();
    
    allowed.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
    return allowed.take(limit).toList();
  }

  static List<SongModel> _getAllTimeHits(RecommendationInputs inputs, {int limit = 15}) {
    if (inputs.playCounts.isEmpty) return [];

    final candidates = inputs.allSongs.where((s) {
       if (!_isAllowed(s, inputs)) return false;
       return (inputs.playCounts[s.id] ?? 0) > 0;
    }).toList();

    candidates.sort((a, b) {
      final playsA = inputs.playCounts[a.id] ?? 0;
      final playsB = inputs.playCounts[b.id] ?? 0;
      return playsB.compareTo(playsA);
    });

    return candidates.take(limit).toList();
  }

  static List<SongModel> _getSuggestedAlbums(RecommendationInputs inputs, {int limit = 10}) {
    final allowed = inputs.allSongs.where((s) => _isAllowed(s, inputs)).toList();
    if (allowed.isEmpty) return [];

    final albumMap = <String, SongModel>{};
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
