import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'dart:ui' as ui;
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';


import 'package:permission_handler/permission_handler.dart';

import '../services/audio_handler.dart';
import '../core/utils/music_data_processor.dart';

class UserPlaylist {
  const UserPlaylist({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAtMillis,
  });

  final String id; // uuid-like
  final String name;
  final List<int> songIds;
  final int createdAtMillis;

  UserPlaylist copyWith({String? name, List<int>? songIds}) => UserPlaylist(
        id: id,
        name: name ?? this.name,
        songIds: songIds ?? this.songIds,
        createdAtMillis: createdAtMillis,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'songIds': songIds,
        'createdAtMillis': createdAtMillis,
      };

  static UserPlaylist fromJson(Map<String, dynamic> map) => UserPlaylist(
        id: map['id'] as String,
        name: map['name'] as String,
        songIds: (map['songIds'] as List).map((e) => (e as num).toInt()).toList(),
        createdAtMillis: (map['createdAtMillis'] as num).toInt(),
      );
}

class LocalMetadataOverrides {
  const LocalMetadataOverrides({
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.year,
  });

  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? year;

  LocalMetadataOverrides copyWith({
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? year,
  }) {
    return LocalMetadataOverrides(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      year: year ?? this.year,
    );
  }

  // (moved: metadata/soft delete logic is implemented in PlayerCubit)

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (artist != null) 'artist': artist,
        if (album != null) 'album': album,
        if (genre != null) 'genre': genre,
        if (year != null) 'year': year,
      };

  static LocalMetadataOverrides fromJson(Map<String, dynamic> map) {
    return LocalMetadataOverrides(
      title: map['title'] as String?,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      genre: map['genre'] as String?,
      year: (map['year'] is int)
          ? (map['year'] as int)
          : (map['year'] is num)
              ? (map['year'] as num).toInt()
              : null,
    );
  }
}

class PlayerStateModel {
  const PlayerStateModel({
    required this.songs,
    this.allSongs = const <SongModel>[], // âœ… Full library
    required this.currentIndex,
    this.currentSongId,
    this.hiddenFolders = const <String>[],
    this.showHiddenFolders = false,
    required this.isPlaying,
    required this.favorites,
    required this.playCounts,
    required this.lastPlayed,
    required this.userPlaylists,
    this.customArtworkPaths = const <int, String>{},
    this.metadataOverrides = const <int, LocalMetadataOverrides>{},
    this.deletedSongIds = const <int>{},
    this.hideMetadataSaveWarning = false,
    this.accentPerSong = const <int, int>{},
    this.sleepTimerEndTime,
    this.isLoading = false,
    this.crossfadeDuration = 0,
    this.gaplessEnabled = false,
    this.playbackSpeed = 1.0,
    this.equalizerBands = const [],
    this.equalizerEnabled = false,
  });

  final List<SongModel> songs; // Current Queue
  final List<SongModel> allSongs; // âœ… Full Library
  final int? currentIndex; // index within songs
  final int? currentSongId;
  final bool isPlaying;
  final Set<int> favorites; // song ids
  final Map<int, int> playCounts; // songId -> count
  final Map<int, int> lastPlayed; // songId -> timestamp
  final List<UserPlaylist> userPlaylists;
  // Dossiers masquÃ©s
  final List<String> hiddenFolders;
  final bool showHiddenFolders;
  final Map<int, String> customArtworkPaths;
  final Map<int, LocalMetadataOverrides> metadataOverrides;
  final Set<int> deletedSongIds;
  final bool hideMetadataSaveWarning;
  final Map<int, int> accentPerSong;
  
  // âœ… Sleep Timer State
  final DateTime? sleepTimerEndTime;
  
  // âœ… Loading State
  final bool isLoading;

  // âœ… New Audio Features
  final int crossfadeDuration; // 0-12s
  final bool gaplessEnabled;
  final double playbackSpeed;

  // âœ… Equalizer State
  final List<double> equalizerBands; // gain in dB
  final bool equalizerEnabled;



  // Helpers
  bool get hasSleepTimer => sleepTimerEndTime != null;

  PlayerStateModel copyWith({
    List<SongModel>? songs,
    List<SongModel>? allSongs,
    int? currentIndex,
    int? currentSongId,
    bool? isPlaying,
    Set<int>? favorites,
    Map<int, int>? playCounts,
    Map<int, int>? lastPlayed,
    List<UserPlaylist>? userPlaylists,
    List<String>? hiddenFolders,
    bool? showHiddenFolders,
    Map<int, String>? customArtworkPaths,
    Map<int, LocalMetadataOverrides>? metadataOverrides,
    Set<int>? deletedSongIds,
    bool? hideMetadataSaveWarning,
    Map<int, int>? accentPerSong,
    DateTime? sleepTimerEndTime,
    bool clearSleepTimer = false,
    bool? isLoading,
    int? crossfadeDuration,
    bool? gaplessEnabled,
    double? playbackSpeed,
    List<double>? equalizerBands,
    bool? equalizerEnabled,
  }) {
    return PlayerStateModel(
      songs: songs ?? this.songs,
      allSongs: allSongs ?? this.allSongs,
      currentIndex: currentIndex ?? this.currentIndex,
      currentSongId: currentSongId ?? this.currentSongId,
      isPlaying: isPlaying ?? this.isPlaying,
      favorites: favorites ?? this.favorites,
      playCounts: playCounts ?? this.playCounts,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      userPlaylists: userPlaylists ?? this.userPlaylists,
      hiddenFolders: hiddenFolders ?? this.hiddenFolders,
      showHiddenFolders: showHiddenFolders ?? this.showHiddenFolders,
      customArtworkPaths: customArtworkPaths ?? this.customArtworkPaths,
      metadataOverrides: metadataOverrides ?? this.metadataOverrides,
      deletedSongIds: deletedSongIds ?? this.deletedSongIds,
      hideMetadataSaveWarning: hideMetadataSaveWarning ?? this.hideMetadataSaveWarning,
      accentPerSong: accentPerSong ?? this.accentPerSong,
      sleepTimerEndTime: clearSleepTimer ? null : (sleepTimerEndTime ?? this.sleepTimerEndTime),
      isLoading: isLoading ?? this.isLoading,
      crossfadeDuration: crossfadeDuration ?? this.crossfadeDuration,
      gaplessEnabled: gaplessEnabled ?? this.gaplessEnabled,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      equalizerBands: equalizerBands ?? this.equalizerBands,
      equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
    );
  }
}

class PlayerCubit extends Cubit<PlayerStateModel> {
  // âœ… Cache pour la pochette par dÃ©faut
  String? _defaultCoverPath;

  PlayerCubit()
      : super(const PlayerStateModel(
          songs: [],
          allSongs: [], 
          currentIndex: null,
          currentSongId: null,
          isPlaying: false,
          favorites: <int>{},
          playCounts: <int, int>{},
          lastPlayed: <int, int>{},
          userPlaylists: <UserPlaylist>[],
          hiddenFolders: [],
          metadataOverrides: <int, LocalMetadataOverrides>{},
          deletedSongIds: <int>{},
          hideMetadataSaveWarning: false,
          accentPerSong: <int, int>{},
          isLoading: true, 
          crossfadeDuration: 0,
          gaplessEnabled: false, 
          playbackSpeed: 1.0,
          equalizerBands: [],
          equalizerEnabled: false,
        ));

  final AndroidEqualizer _equalizer = AndroidEqualizer();
  late final AudioPlayer player = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: [
        _equalizer,
      ],
    ),
  );

  final MethodChannel _nativeChannel = const MethodChannel('com.synergydev.music_box/native');
  MusicBoxAudioHandler? _audioHandler;

  DateTime? _lastWidgetPush;
  final Set<int> _accentInProgress = <int>{};
  bool _artRefreshInProgress = false;
  Timer? _widgetUpdateTimer;
  DateTime? _ignoreIndexChangesUntil;
  
  // âœ… Cache for widget artwork to avoid repeated I/O
  String? _cachedWidgetArtPath;
  int? _cachedWidgetArtSongId;

  
  // âœ… Sleep Timer
  Timer? _sleepTimer;
  DateTime? _sleepEndTime;

  // Persistence Keys
  static const _keyLastSongId = 'last_song_id';
  static const _keyShuffleMode = 'shuffle_mode';
  static const _keyLoopMode = 'loop_mode';
  // Quick notification restore keys
  static const _keyLastSongTitle = 'last_song_title';
  static const _keyLastSongArtist = 'last_song_artist';
  static const _keyLastSongArtPath = 'last_song_art_path';
  static const _keyLastSongUri = 'last_song_uri';
  static const _keyLastSongDuration = 'last_song_duration';
  
  // New Audio Features Persistence Keys
  static const _keyCrossfade = 'crossfade_duration';
  static const _keyGapless = 'gapless_enabled';
  static const _keyPlaybackSpeed = 'playback_speed';
  static const _keyEqEnabled = 'eq_enabled';
  static const _keyEqBands = 'eq_bands';
  static const _keyTimerFinishSong = 'timer_finish_song';
  static const _keyTimerFadeOut = 'timer_fade_out';

  /// CrÃ©er une pochette par dÃ©faut
  Future<String> _getDefaultCoverPath() async {
    if (_defaultCoverPath != null) return _defaultCoverPath!;
    
    try {
      final tempDir = await getTemporaryDirectory();
      // âœ… Nouveau nom pour forcer la recrÃ©ation de la pochette
      final defaultCover = File(path.join(tempDir.path, 'default_artwork_material_icon.png'));
      
      // âœ… FORCER la suppression et recrÃ©ation Ã  chaque fois (temporairement)
      try {
        final oldCover1 = File(path.join(tempDir.path, 'default_artwork_optimized.png'));
        final oldCover2 = File(path.join(tempDir.path, 'default_artwork_music_note.png'));
        if (await oldCover1.exists()) await oldCover1.delete();
        if (await oldCover2.exists()) await oldCover2.delete();
        if (await defaultCover.exists()) await defaultCover.delete(); // RecrÃ©er Ã  chaque fois
      } catch (_) {}
      
      // Toujours recrÃ©er pour cette version pour appliquer le nouveau style gris
      if (true) {
        // âœ… CrÃ©er la pochette par dÃ©faut avec l'icÃ´ne Material (comme dans l'app)
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final size = 512.0;
        
        // Fond avec dÃ©gradÃ©
        // âœ… Fond neutre (Gris #212121) pour matcher le widget "Clean Glass"
        final bgPaint = Paint()..color = const Color(0xFF212121);
        canvas.drawRect(Rect.fromLTWH(0, 0, size, size), bgPaint);
        
        // Cercle central discret (optionnel, ou juste l'icÃ´ne)
        // On le retire pour Ãªtre 100% "flat" comme le widget
        // final circlePaint = Paint()..color = Colors.white.withValues(alpha: 0.05);
        // canvas.drawCircle(Offset(size / 2, size / 2), size * 0.35, circlePaint);
        
        // âœ… Dessiner l'icÃ´ne Material Icons.music_note_rounded
        final iconSize = size * 0.35;
        final iconBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: iconSize,
        ))
          ..pushStyle(ui.TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontFamily: 'MaterialIcons',
            fontSize: iconSize,
          ))
          ..addText(String.fromCharCode(Icons.music_note_rounded.codePoint));
        
        final paragraph = iconBuilder.build()
          ..layout(ui.ParagraphConstraints(width: size));
        
        canvas.drawParagraph(
          paragraph,
          Offset((size - paragraph.width) / 2, (size - paragraph.height) / 2),
        );
        
        // Convertir en image
        final picture = recorder.endRecording();
        final img = await picture.toImage(size.toInt(), size.toInt());
        final pngData = await img.toByteData(format: ui.ImageByteFormat.png);
        
        if (pngData != null) {
          await defaultCover.writeAsBytes(pngData.buffer.asUint8List(), flush: true);
        }
      }
      
      _defaultCoverPath = defaultCover.path;
      return _defaultCoverPath!;
    } catch (e) {
      debugPrint('âŒ Erreur crÃ©ation pochette par dÃ©faut: $e');
      return '';
    }
  }
  
  /// Optimise une image pour les notifications Android
  Future<String?> _optimizeArtworkForNotification(String imagePath) async {
    try {
      final sourceFile = File(imagePath);
      if (!await sourceFile.exists()) return null;
      
      // CrÃ©er un chemin de cache unique basÃ© sur le fichier ET sa date de modification
      final tempDir = await getTemporaryDirectory();
      final filename = path.basename(imagePath).replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_');
      final mtime = await sourceFile.lastModified();
      final timestamp = mtime.millisecondsSinceEpoch;
      final cachedFile = File(path.join(tempDir.path, 'artwork_${filename}_$timestamp.png'));
      
      // Si dÃ©jÃ  optimisÃ© avec ce timestamp, retourner
      if (await cachedFile.exists()) {
        return cachedFile.path;
      }
      
      // âœ… Nettoyer SEULEMENT les anciennes versions de CE fichier (pas tous les temp)
      try {
        final pattern = 'artwork_$filename';
        // Utiliser un pattern glob au lieu de lister tous les fichiers
        final oldFiles = tempDir.listSync().whereType<File>().where((f) => 
          f.path.contains(pattern) && f.path != cachedFile.path
        );
        for (final f in oldFiles) {
          try { await f.delete(); } catch (_) {}
        }
      } catch (_) {}
      
      // Lire l'image source
      final bytes = await sourceFile.readAsBytes();
      
      // DÃ©coder pour obtenir les dimensions rÃ©elles
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final sourceWidth = frame.image.width;
      final sourceHeight = frame.image.height;
      
      // âœ… TOUJOURS redimensionner pour garantir la nettetÃ© et la performance
      // AugmentÃ© Ã  1024 pour un affichage "Naturel" haute qualitÃ©
      final targetSize = 1024;
      final widthRatio = targetSize / sourceWidth;
      final heightRatio = targetSize / sourceHeight;
      final scale = widthRatio > heightRatio ? widthRatio : heightRatio;
      
      int targetWidth = (sourceWidth * scale).round();
      int targetHeight = (sourceHeight * scale).round();
      
      // S'assurer que c'est au moins 512x512
      if (targetWidth < targetSize) targetWidth = targetSize;
      if (targetHeight < targetSize) targetHeight = targetSize;
      
      // RedÃ©coder avec la taille optimale et haute qualitÃ©
      final optimizedCodec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        allowUpscaling: true,  // âœ… Permettre l'upscale pour les petites images
      );
      final optimizedFrame = await optimizedCodec.getNextFrame();
      
      // âœ… Utiliser PNG avec compression minimale pour qualitÃ© maximale
      final pngData = await optimizedFrame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (pngData == null) return imagePath; // Fallback
      
      await cachedFile.writeAsBytes(pngData.buffer.asUint8List(), flush: true);
      return cachedFile.path;

    } catch (e) {
      return imagePath;
    }
  }

  Future<void> loadAllSongs() async {
    try {
      emit(state.copyWith(isLoading: true)); // âœ… Start loading
      
      final audioQuery = OnAudioQuery();
      final hasPermission = await Permission.audio.request().isGranted;
      
      if (hasPermission) {
        final songs = await audioQuery.querySongs(
          sortType: SongSortType.TITLE,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        );
        final validSongs = songs.where((s) => s.duration != null && s.duration! > 0).toList();
        
        // âœ… Filter out hidden folders
        final filteredSongs = filterSongs(validSongs);
        
        // âœ… Populate both songs (queue) and allSongs (library)
        emit(state.copyWith(
          songs: filteredSongs, 
          allSongs: filteredSongs,
        ));
      
        // âœ… Restore player state (last song, shuffle, loop) in background
        // to avoid blocking the splash screen / startup flow.
        _restorePlayerState(); 
      } else {
        debugPrint('[PlayerCubit] Audio permission denied.');
      }
    } catch (e, stack) {
      debugPrint('Error loading songs: $e');
      debugPrint('Stack: $stack');
    } finally {
      // âœ… ALWAYS mark as not loading, even on error or denial
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    
    // Initialiser audio_service avec AudioHandler
    try {
      debugPrint('ðŸŽµ Initialisation AudioService...');
      _audioHandler = await AudioService.init(
        builder: () => MusicBoxAudioHandler(player),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.synergydev.music_box.audio',
          androidNotificationChannelName: 'Lecture Audio',
          androidNotificationChannelDescription: 'ContrÃ´les de lecture musicale',
          androidNotificationOngoing: true, // âœ… Garder la notif active pour Ã©viter que l'OS ne tue le service
          androidStopForegroundOnPause: false, // âœ… NE PAS arrÃªter le service en pause pour permettre la reprise
          androidNotificationIcon: 'drawable/ic_notification',
          androidNotificationClickStartsActivity: true,
          androidShowNotificationBadge: true,
          preloadArtwork: false, // âœ… Disable preloading to prevent hangs with large queues
          // âœ… Disable downscaling to keep high quality (we optimize manually to 1024px)
          artDownscaleWidth: null,
          artDownscaleHeight: null,
        ),
      );
      
      debugPrint('âœ… AudioService initialisÃ© : $_audioHandler');
      
      // Connecter le bouton J'aime
      _audioHandler?.onLikePressed = (songId) {
        toggleFavoriteById(songId);
      };
      
      // âœ… CrÃ©er la pochette par dÃ©faut au dÃ©marrage pour les notifications
      _getDefaultCoverPath().then((path) {
        _defaultCoverPath = path;
        debugPrint('âœ… Pochette par dÃ©faut crÃ©Ã©e : $path');
      }).catchError((e) {
        debugPrint('âŒ Erreur crÃ©ation pochette par dÃ©faut : $e');
      });
    } catch (e, stack) {
      debugPrint('âŒ AudioService init failed: $e');
      debugPrint('Stack: $stack');
    }
    
    // Configure les contrÃ´les de notification
    player.setAutomaticallyWaitsToMinimizeStalling(true);
    
    // âœ… Error logging to catch "No sound" (stuck at 0:00) issues
    player.playbackEventStream.listen((event) {
      // Optional: Log state changes if needed for debugging
    }, onError: (Object e, StackTrace stackTrace) {
      debugPrint('âŒ JustAudio Error: $e');
    });

    // Pause on interruptions and when becoming noisy
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        player.pause();
      }
    });
    session.becomingNoisyEventStream.listen((_) {
      player.pause();
    });

    // Keep Bloc state in sync with player streams
    player.playerStateStream.listen((ps) {
      emit(state.copyWith(isPlaying: ps.playing));
      _debounceWidgetUpdate();
    });
    
    // âœ… Save state on changes
    player.shuffleModeEnabledStream.listen((_) => _savePlayerState());
    player.loopModeStream.listen((_) => _savePlayerState());

    player.currentIndexStream.listen((i) {
      final now = DateTime.now();
      final shouldIgnore = _ignoreIndexChangesUntil != null && now.isBefore(_ignoreIndexChangesUntil!);
      if (i == null) return;
      
      // Skip if we should ignore changes during setQueueAndPlay
      if (shouldIgnore) {
        return;
      }
      
      // Check if the index actually changed
      if (i == state.currentIndex) {
        return;
      }
      
      final s = (i >= 0 && i < state.songs.length) ? state.songs[i] : null;
      if (s == null) return;
      
      // Increment play count and update last played
      final counts = Map<int, int>.from(state.playCounts);
      final last = Map<int, int>.from(state.lastPlayed);
      counts[s.id] = (counts[s.id] ?? 0) + 1;
      last[s.id] = DateTime.now().millisecondsSinceEpoch;
      
      // Limit history to 100 songs (FIFO)
      if (last.length > 100) {
        final sortedKeys = last.keys.toList()
          ..sort((a, b) => last[a]!.compareTo(last[b]!));
        if (sortedKeys.isNotEmpty) {
          last.remove(sortedKeys.first);
        }
      }

      // âœ… Handle Sleep Timer
      if (_sleepEndTime != null && DateTime.now().isAfter(_sleepEndTime!)) {
        _stopFromSleepTimer();
        return; // Don't play the next song
      }

      // âœ… Toujours Ã©mettre currentSongId avec currentIndex
      emit(state.copyWith(currentIndex: i, currentSongId: s.id, playCounts: counts, lastPlayed: last));
      
      
      // âœ… Save state when song changes
      _savePlayerState();

      // âš ï¸ SUPPRIMÃ‰ : Mise Ã  jour basÃ©e sur audioSource.tag (source de conflits)
      // Nous utilisons maintenant le listener plus bas (ligne ~660) qui utilise state.songs
      // et _refreshCurrentArtworkIfNeeded pour garantir que les mÃ©tadonnÃ©es sont Ã  jour.
      
      // Defer persistence to avoid blocking UI
      Future.microtask(_persistPlayStats);
      _debounceWidgetUpdate();
      // Trigger accent extraction for the current song (cached)
      ensureAccentForSong(s.id);
        // Refresh notification artwork in background if needed
      _refreshCurrentArtworkIfNeeded();
      // âœ… Pre-cache next songs to ensure sharp artwork in notification queue
      // Delayed to avoid blocking UI during transition
      Future.delayed(const Duration(seconds: 2), () {
        _preCacheArtworkForNextSongs();
      });
    });
    // âœ… Periodic position updates -> throttle widget updates (â‰ˆ1s pour temps rÃ©el)
    player.positionStream.listen((position) {
      final now = DateTime.now();
      
      // Handle Fade In/Out logic (Crossfade)
      _handleCrossfade(position);

      // Mettre Ã  jour le widget toutes les 1 seconde pendant la lecture
      if (_lastWidgetPush == null || now.difference(_lastWidgetPush!) > const Duration(seconds: 1)) {
        _lastWidgetPush = now;
        // Ne mettre Ã  jour que si en lecture (Ã©viter updates inutiles)
        if (player.playing) {
          _pushWidgetUpdate();
        }
      }
    });

    // Load persisted favorites and stats
    await _loadFavorites();
    await _loadPlayStats();
    await _loadUserPlaylists();
    await _loadCustomArtworkPaths();
    await _loadMetadataOverrides();
    await _loadSoftDeletedSongIds();
    await _loadHideMetadataSaveWarning();
    
    await _initEqualizer(); // âœ… Init Equalizer at startup

    await loadAllSongs();

    // Listen for native widget control actions
    _nativeChannel.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
          case 'widgetPlayPause':
            if (player.playing) {
              await player.pause();
            } else {
              await player.play();
            }
            break;
          case 'widgetNext':
            await next();
            break;
          case 'widgetPrevious':
            await previous();
            break;
          case 'widgetFavorite':
            await toggleFavorite();
            break;
          case 'widgetShuffle':
            await toggleShuffle();
            break;
          case 'widgetRepeat':
            await cycleRepeatMode();
            break;
          case 'toggleShuffle':
            await toggleShuffle();
            break;
          case 'cycleRepeat':
            await cycleRepeatMode();
            break;
          case 'toggleFavorite':
            await toggleFavorite();
            break;
          default:
            break;
        }
      } catch (e, stack) {
        debugPrint('Widget command error: $e\n$stack');
      }
    });
    
    // Configure les listeners pour les contrÃ´les de notification
    player.shuffleModeEnabledStream.listen((enabled) {
      _debounceWidgetUpdate();
    });
    
    player.loopModeStream.listen((mode) {
      _debounceWidgetUpdate();
    });

    // âœ… Listen for duration changes to update notification progress bar
    // This supports files where duration is unknown until playback starts
    player.durationStream.listen((duration) {
      if (duration != null && duration.inMilliseconds > 0 && _audioHandler != null) {
        final item = _audioHandler!.mediaItem.value;
        if (item != null && (item.duration == null || item.duration!.inMilliseconds == 0)) {
          debugPrint('ðŸŽµ Mise Ã  jour durÃ©e notification: ${duration.inMilliseconds}ms');
          final newItem = item.copyWith(duration: duration);
          _audioHandler!.mediaItem.add(newItem);
          // Force refresh state to ensure seek bar appears
          _audioHandler!.playbackState.add(_audioHandler!.playbackState.value.copyWith(
            updatePosition: player.position,
          ));
        }
      }
    });

    // âœ… CRITICAL FIX: Listen to track changes from notification buttons
    // This ensures artwork, liked state, and progress bar are updated when user
    // presses Next/Previous in the notification
    player.currentIndexStream.listen((index) async {
      if (index == null) return;
      
      // âœ… Skip if we just changed the track from within the app (prevents visual jump)
      if (_ignoreIndexChangesUntil != null && DateTime.now().isBefore(_ignoreIndexChangesUntil!)) {
        debugPrint('ðŸŽµ Ignoring index change (from app, not notification)');
        return;
      }
      
      // Only update if the index actually changed
      if (state.currentIndex != index && index < state.songs.length) {
        final newSong = state.songs[index];
        debugPrint('ðŸŽµ Track changed from notification: ${newSong.title}');
        
        // Update state
        emit(state.copyWith(currentIndex: index, currentSongId: newSong.id));
        
        // âœ… Immediately refresh notification with proper artwork and liked state
        if (_audioHandler != null) {
          // Refresh artwork in background (will call setMediaItemWithLikedState when ready)
          Future.microtask(() async {
            await _refreshCurrentArtworkIfNeeded();
            _debounceWidgetUpdate();
          });
        }
        
        // Update stats
        _savePlayerState();
        Future.microtask(_persistPlayStats);
      }
    });

    // Push an initial widget update so title/artist/artwork are shown even before playback resumes
    await _pushWidgetUpdate();
    // Prefetch accent for current song if any
    final s0 = currentSong;
    if (s0 != null) {
      // Fire and forget
      Future.microtask(() => ensureAccentForSong(s0.id));
    }
  }

  /// GÃ¨re le fondu (In/Out) en fonction de la position actuelle
  void _handleCrossfade(Duration position) {
    if (state.crossfadeDuration <= 0) {
      if ((player.volume - 1.0).abs() > 0.01) player.setVolume(1.0);
      return;
    }

    final duration = player.duration;
    if (duration == null) return;

    final crossfadeMillis = state.crossfadeDuration * 1000;
    final remainingMillis = (duration - position).inMilliseconds;
    final elapsedMillis = position.inMilliseconds;

    double targetVolume = 1.0;

    if (remainingMillis < crossfadeMillis && remainingMillis > 0) {
      // Fade Out (Fin de chanson)
      targetVolume = remainingMillis / crossfadeMillis;
    } else if (elapsedMillis < crossfadeMillis) {
      // Fade In (DÃ©but de chanson)
      targetVolume = elapsedMillis / crossfadeMillis;
    }

    final clampedVolume = targetVolume.clamp(0.0, 1.0);
    // On ne met Ã  jour que si la diffÃ©rence est significative pour Ã©viter de surcharger le lecteur
    if ((player.volume - clampedVolume).abs() > 0.01) {
      player.setVolume(clampedVolume);
    }
  }

  // -----------------------------
  // Accent color extraction & cache
  // -----------------------------
  Color? accentFor(int songId) {
    final v = state.accentPerSong[songId];
    return v == null ? null : Color(v);
  }

  Future<void> ensureAccentForSong(int songId) async {
    try {
      if (state.accentPerSong.containsKey(songId)) return;
      if (_accentInProgress.contains(songId)) return;
      _accentInProgress.add(songId);

      Uint8List? bytes;
      // Prefer custom cover saved locally
      final custom = state.customArtworkPaths[songId];
      if (custom != null && custom.isNotEmpty) {
        try {
          final f = File(custom);
          if (await f.exists()) {
            bytes = await f.readAsBytes();
          }
        } catch (_) {}
      }
      // Fallback to MediaStore artwork
      if (bytes == null) {
        try {
          bytes = await OnAudioQuery().queryArtwork(songId, ArtworkType.AUDIO);
        } catch (_) {}
      }
      if (bytes == null || bytes.isEmpty) return;

      // âœ… Use Isolate for heavy palette extraction
      final colorValue = await MusicDataProcessor.extractDominantColor(bytes);
      if (colorValue == null) return;

      final next = Map<int, int>.from(state.accentPerSong);
      next[songId] = colorValue;
      emit(state.copyWith(accentPerSong: next));
    } catch (_) {
      // ignore
    } finally {
      _accentInProgress.remove(songId);
    }
  }

  void _debounceWidgetUpdate() {
    _widgetUpdateTimer?.cancel();
    // âœ… ZERO DELAY: Update immediately for "instant" feel
    // Using microtask to allow current stack frame to finish (e.g. state emission)
    Future.microtask(_pushWidgetUpdate);
  }

  Future<void> _pushWidgetUpdate() async {
    try {
      final s = currentSong;
      final title = s?.title ?? '';
      final artist = s?.artist ?? '';
      final durMs = player.duration?.inMilliseconds ?? 0;
      final posMs = player.position.inMilliseconds;
      final progress = durMs > 0 ? ((posMs * 100) ~/ durMs).clamp(0, 100) : 0;
      String? artPath;
      if (s != null) {
        // âœ… Check cache first
        if (_cachedWidgetArtSongId == s.id && _cachedWidgetArtPath != null) {
          artPath = _cachedWidgetArtPath;
        } else {
          // 1) Custom cover saved in app docs
          final custom = state.customArtworkPaths[s.id];
          if (custom != null && custom.isNotEmpty) {
            try { if (await File(custom).exists()) artPath = custom; } catch (_) {}
          }
          // 2) Cached cover in app docs/covers/<id>.jpg
          if (artPath == null) {
            try {
              final docs = await getApplicationDocumentsDirectory();
              final candidate = File(path.join(docs.path, 'covers', '${s.id}.jpg'));
              if (await candidate.exists()) {
                artPath = candidate.path;
              }
            } catch (_) {}
          }
          // 3) Query system artwork as fallback (write once to cache)
          if (artPath == null) {
            try {
              final art = await OnAudioQuery().queryArtwork(s.id, ArtworkType.AUDIO);
              if (art != null && art.isNotEmpty) {
                final docs = await getApplicationDocumentsDirectory();
                final coversDir = Directory(path.join(docs.path, 'covers'));
                if (!await coversDir.exists()) { await coversDir.create(recursive: true); }
                final f = File(path.join(coversDir.path, '${s.id}.jpg'));
                await f.writeAsBytes(art, flush: true);
                artPath = f.path;
              }
            } catch (_) {}
          }
          
          // âœ… CRITICAL FIX: Fallback to default cover if still no artwork
          if (artPath == null && _defaultCoverPath != null && _defaultCoverPath!.isNotEmpty) {
            artPath = _defaultCoverPath;
          }
          
          // Update cache
          _cachedWidgetArtSongId = s.id;
          _cachedWidgetArtPath = artPath;
        }
      }
      final shuffleEnabled = player.shuffleModeEnabled;
      final repeat = player.loopMode;
      final repeatMode = repeat == LoopMode.all
          ? 'all'
          : repeat == LoopMode.one
              ? 'one'
              : 'off';
      await _nativeChannel.invokeMethod('updateHomeWidgets', {
        'title': title,
        'artist': artist,
        'album': s?.album ?? '',
        'isPlaying': player.playing,
        'progress': progress,
        'positionMs': posMs,
        'durationMs': durMs,
        if (artPath != null) 'artPath': artPath,
        'shuffleEnabled': shuffleEnabled,
        'repeatMode': repeatMode,
        'isFavorite': state.favorites.contains(s?.id ?? -1),
      });
    } catch (_) {}
  }

  Future<void> toggleShuffle() async {
    try {
      final enabled = !player.shuffleModeEnabled;
      await player.setShuffleModeEnabled(enabled);
      await _pushWidgetUpdate();
    } catch (_) {}
  }
  
  // âœ… New Audio Features Methods
  
  Future<void> setCrossfadeDuration(int seconds) async {
    // Note: just_audio direct crossfade support is limited.
    // Ideally this would configure a crossfade between tracks if supported or custom implementation.
    // For now we store the preference.
    emit(state.copyWith(crossfadeDuration: seconds));
    await _savePlayerState();
  }

  Future<void> toggleGapless() async {
    final newValue = !state.gaplessEnabled;
    emit(state.copyWith(gaplessEnabled: newValue));
    
    // Map "Gapless" to Skip Silence for tangible effect, as ConcatenatingAudioSource is already gapless.
    try {
      await player.setSkipSilenceEnabled(newValue);
    } catch (e) {
      debugPrint('Error setting skip silence: $e');
    }
    
    await _savePlayerState();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    emit(state.copyWith(playbackSpeed: speed));
    try {
      await player.setSpeed(speed);
    } catch (e) {
      debugPrint('Error setting playback speed: $e');
    }
    await _savePlayerState();
  }

  Future<void> cycleRepeatMode() async {
    try {
      final current = player.loopMode;
      final next = current == LoopMode.off
          ? LoopMode.all
          : current == LoopMode.all
              ? LoopMode.one
              : LoopMode.off;
      await player.setLoopMode(next);
      await _pushWidgetUpdate();
    } catch (_) {}
  }

  // Toggle favorite for the current song (used by home screen widget heart button)
  Future<void> toggleFavorite() async {
    try {
      final s = currentSong;
      if (s == null) return;
      final next = Set<int>.from(state.favorites);
      if (next.contains(s.id)) {
        next.remove(s.id);
      } else {
        next.add(s.id);
      }
      emit(state.copyWith(favorites: next));
      await _persistFavorites();
      await _pushWidgetUpdate();
    } catch (_) {}
  }

  /// Remove multiple songs from the queue AND the player
  Future<void> removeSongsById(List<int> ids) async {
    if (ids.isEmpty) return;
    final idsSet = ids.toSet();
    
    // 1. Filter lists for UI state
    final currentSongs = List<SongModel>.from(state.songs);
    // Find indices to remove (descending order to safe remove)
    final indicesToRemove = <int>[];
    for (int i = 0; i < currentSongs.length; i++) {
        if (idsSet.contains(currentSongs[i].id)) {
            indicesToRemove.add(i);
        }
    }
    // Sort descending
    indicesToRemove.sort((a, b) => b.compareTo(a));

    // 2. Remove from player source (using direct AudioPlayer methods)
    try {
        for (final idx in indicesToRemove) {
            await player.removeAudioSourceAt(idx);
        }
    } catch (e) {
        debugPrint("Error removing from playlist: $e");
    }

    // 3. Remove from UI Model
    final newSongs = state.songs.where((s) => !idsSet.contains(s.id)).toList();
    final newAllSongs = state.allSongs.where((s) => !idsSet.contains(s.id)).toList();
    
    // 4. Recalculate Index
    // If the playlist was modified correctly by removeAt, just_audio generally keeps the current index
    // stable unless the current item itself was removed.
    // If current item removed, just_audio moves to next.
    // We just need to sync our state index with just_audio's new index.
    int? newIndex = player.currentIndex; 
    
    // Safety check if empty
    if (newSongs.isEmpty) {
        newIndex = null;
        await player.stop();
    }
    
    // 5. Update state
    final currentSongId = (newIndex != null && newIndex < newSongs.length) ? newSongs[newIndex].id : null;
    
    emit(state.copyWith(
      songs: newSongs, 
      allSongs: newAllSongs,
      currentIndex: newIndex,
      currentSongId: currentSongId,
    ));
    
    // 6. Update AudioHandler Queue
    if (_audioHandler != null) {
        final mediaItems = newSongs.map((s) => _createMediaItemWithArtwork(s)).toList();
        _audioHandler!.setQueueItems(mediaItems);
    }
  }

  // -----------------------------
  // Metadata overrides (persistence + helpers)
  // -----------------------------
  Future<void> _loadMetadataOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('metadata_overrides');
      if (raw == null || raw.isEmpty) return;
      final decoded = json.decode(raw);
      final map = <int, LocalMetadataOverrides>{};
      if (decoded is Map<String, dynamic>) {
        for (final entry in decoded.entries) {
          final key = int.tryParse(entry.key);
          if (key == null) continue;
          final val = entry.value;
          if (val is Map<String, dynamic>) {
            map[key] = LocalMetadataOverrides.fromJson(val);
          } else if (val is Map) {
            map[key] = LocalMetadataOverrides.fromJson(val.cast<String, dynamic>());
          }
        }
      }
      if (map.isNotEmpty) {
        emit(state.copyWith(metadataOverrides: map));
      }
    } catch (_) {}
  }

  Future<void> _persistMetadataOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final asStringMap = <String, Map<String, dynamic>>{
        for (final e in state.metadataOverrides.entries) e.key.toString(): e.value.toJson(),
      };
      await prefs.setString('metadata_overrides', json.encode(asStringMap));
    } catch (_) {}
  }

  /// Apply local overrides to a given SongModel and return a new instance.
  /// Always returns a safe SongModel with non-null strings for title/artist/album.
  SongModel applyOverrides(SongModel s) {
    final o = state.metadataOverrides[s.id];

    // Defensively read fields from SongModel, as some getters in the plugin
    // may cast nulls to non-null types and throw. Wrap each access.
    String? safeString(String? Function() getter) {
      try {
        return getter();
      } catch (_) {
        return null;
      }
    }

    int? safeInt(int? Function() getter) {
      try {
        return getter();
      } catch (_) {
        return null;
      }
    }

    final baseTitle = o?.title ?? safeString(() => s.title);
    final baseArtist = o?.artist ?? safeString(() => s.artist);
    final baseAlbum = o?.album ?? safeString(() => s.album);

    final dispName = safeString(() => s.displayName);
    final uri = safeString(() => s.uri) ?? safeString(() => s.data) ?? '';
    final duration = safeInt(() => s.duration) ?? 0;
    final size = safeInt(() => s.size) ?? 0;
    final dateAdded = safeInt(() => s.dateAdded) ?? 0;
    final dateModified = safeInt(() => s.dateModified) ?? 0;
    final albumId = safeInt(() => s.albumId) ?? 0;
    final artistId = safeInt(() => s.artistId) ?? 0;

    // Prefer explicit overrides, then original values; ensure non-null strings
    final finalTitle = (baseTitle ?? dispName ?? path.basename(uri)).trim();
    final finalArtist = (baseArtist ?? '').trim();
    final finalAlbum = (baseAlbum ?? '').trim();
    final finalDisplayName = (dispName ?? finalTitle).trim();

    return SongModel({
      '_id': s.id,
      'title': finalTitle,
      'artist': finalArtist,
      'album': finalAlbum,
      '_uri': uri,
      'duration': duration,
      'display_name': finalDisplayName,
      'size': size,
      'date_added': dateAdded,
      'date_modified': dateModified,
      'album_id': albumId,
      'artist_id': artistId,
    });
  }

  /// Set or merge local metadata overrides for a song and refresh it in the queue if present.
  Future<void> setMetadataOverride(int songId, LocalMetadataOverrides overrides) async {
    final map = Map<int, LocalMetadataOverrides>.from(state.metadataOverrides);
    final prev = map[songId];
    final merged = prev?.copyWith(
          title: overrides.title,
          artist: overrides.artist,
          album: overrides.album,
          genre: overrides.genre,
          year: overrides.year,
        ) ??
        overrides;
    map[songId] = merged;
    emit(state.copyWith(metadataOverrides: map));
    await _persistMetadataOverrides();

    // Update the song in the current queue (use the current value as base)
    final idx = state.songs.indexWhere((s) => s.id == songId);
    if (idx != -1) {
      final base = state.songs[idx];
      // Extraire les valeurs en sÃ©curitÃ© (les getters peuvent crasher si null)
      final titleValue = merged.title ?? base.title;
      final artistValue = merged.artist ?? base.artist ?? 'Unknown';
      final albumValue = merged.album ?? base.album ?? '';
      
      // AccÃ©der aux donnÃ©es brutes du map pour Ã©viter les getters qui crashent
      final baseMap = base.getMap;
      final uriValue = baseMap['_uri'] ?? '';
      final durationValue = baseMap['duration'] ?? 0;
      final sizeValue = baseMap['size'] ?? 0;
      final dateAddedValue = baseMap['date_added'] ?? 0;
      final dateModifiedValue = baseMap['date_modified'] ?? 0;
      final albumIdValue = baseMap['album_id'];
      final artistIdValue = baseMap['artist_id'];
      
      final updated = SongModel({
        '_id': base.id,
        'title': titleValue,
        'artist': artistValue,
        'album': albumValue,
        '_uri': uriValue,
        'duration': durationValue,
        'display_name': titleValue,
        'size': sizeValue,
        'date_added': dateAddedValue,
        'date_modified': dateModifiedValue,
        'album_id': albumIdValue,
        'artist_id': artistIdValue,
      });
      await updateSongInQueue(songId, updated);
    }
  }

  Future<void> clearMetadataOverride(int songId) async {
    if (!state.metadataOverrides.containsKey(songId)) return;
    final map = Map<int, LocalMetadataOverrides>.from(state.metadataOverrides);
    map.remove(songId);
    emit(state.copyWith(metadataOverrides: map));
    await _persistMetadataOverrides();
  }

  /// Force UI widgets to rebuild by emitting a new state with updated references.
  /// Call this after saving cover/metadata when the visual changes might not be picked up.
  void forceArtworkRefresh(int songId) {
    // Create a new list reference to force BlocBuilder to rebuild
    final songs = List<SongModel>.from(state.songs);
    // Create a new map reference for custom artwork paths
    final artworkPaths = Map<int, String>.from(state.customArtworkPaths);
    emit(state.copyWith(songs: songs, customArtworkPaths: artworkPaths));
  }

  // -----------------------------
  // Soft delete (local only)
  // -----------------------------
  bool isSoftDeleted(int songId) => state.deletedSongIds.contains(songId);

  Future<void> _loadSoftDeletedSongIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('soft_deleted_ids') ?? const <String>[];
      final set = ids.map((e) => int.tryParse(e)).whereType<int>().toSet();
      emit(state.copyWith(deletedSongIds: set));
    } catch (_) {}
  }

  Future<void> _persistSoftDeletedSongIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'soft_deleted_ids',
        state.deletedSongIds.map((e) => e.toString()).toList(),
      );
    } catch (_) {}
  }

  /// Mark a song as soft-deleted locally and remove it from the current queue.
  Future<void> softDeleteSong(int songId) async {
    if (state.deletedSongIds.contains(songId)) return;
    final next = Set<int>.from(state.deletedSongIds)..add(songId);
    emit(state.copyWith(deletedSongIds: next));
    await _persistSoftDeletedSongIds();

    // Remove from current queue if present
    await removeSongById(songId);
  }

  /// Restore a soft-deleted song locally.
  Future<void> restoreSoftDeletedSong(int songId) async {
    if (!state.deletedSongIds.contains(songId)) return;
    final next = Set<int>.from(state.deletedSongIds)..remove(songId);
    emit(state.copyWith(deletedSongIds: next));
    await _persistSoftDeletedSongIds();
  }

  // âœ… BasÃ© sur currentSongId pour Ã©viter les dÃ©synchronisations pendant drag/drop
  SongModel? get currentSong {
    // D'abord essayer avec l'ID (plus fiable)
    if (state.currentSongId != null) {
      try {
        return state.songs.firstWhere((s) => s.id == state.currentSongId);
      } catch (_) {
        // Si l'ID n'existe plus dans songs, fallback sur l'index
      }
    }
    // Fallback sur l'index
    if (state.currentIndex != null && 
        state.currentIndex! >= 0 && 
        state.currentIndex! < state.songs.length) {
      return state.songs[state.currentIndex!];
    }
    return null;
  }

  Future<void> setQueueAndPlay(List<SongModel> allSongs, int targetUiIndex) async {
    try {
      // Filter only songs with valid URI and build sources
      final filtered = <SongModel>[];
      final sources = <AudioSource>[];
      int? targetPlIndex;

      for (final s in allSongs) {
        // Skip songs from hidden folders (safety in case caller didn't filter)
        try {
          if (isPathInHiddenFolder(s.data)) continue;
        } catch (_) {}
        // Skip soft-deleted songs
        if (isSoftDeleted(s.id)) continue;
        // Apply local overrides for consistent metadata across the app
        final sOver = applyOverrides(s);
        final uri = s.uri;
        if (uri == null || uri.isEmpty) continue;

        if (filtered.length == targetUiIndex) {
          // Note: this relies on traversal matching the UI ordering
          targetPlIndex = filtered.length;
        }

        filtered.add(sOver);
        sources.add(
          AudioSource.uri(
            Uri.parse(uri),
            tag: _createMediaItemWithArtwork(s), // âœ… Use helper for consistent metadata
          ),
        );
      }

      if (filtered.isEmpty) {
        return;
      }
      targetPlIndex ??= (targetUiIndex.clamp(0, filtered.length - 1));

      // Update state BEFORE setting audio sources to avoid listener conflicts
      // âœ… Toujours Ã©mettre currentSongId avec songs et currentIndex
      final currentSongId = (targetPlIndex < filtered.length) 
          ? filtered[targetPlIndex].id 
          : null;
      emit(state.copyWith(songs: filtered, currentIndex: targetPlIndex, currentSongId: currentSongId));
      
      // AVANT de jouer : Charger et optimiser la pochette de la chanson courante
      if (targetPlIndex < filtered.length) {
        final currentSong = filtered[targetPlIndex];
        String? artworkPath;
        
        // 1. Custom
        final custom = state.customArtworkPaths[currentSong.id];
        if (custom != null && custom.isNotEmpty) {
          try { if (await File(custom).exists()) artworkPath = custom; } catch (_) {}
        }
        
        // 2. Cache
        if (artworkPath == null) {
          try {
            final docs = await getApplicationDocumentsDirectory();
            final cached = File(path.join(docs.path, 'covers', '${currentSong.id}.jpg'));
            if (await cached.exists()) {
              artworkPath = cached.path;
            }
          } catch (_) {}
        }
        
        // 3. Fallback par dÃ©faut
        artworkPath ??= await _getDefaultCoverPath();
        
        // CRUCIAL : Optimiser l'image pour Android (PNG 512x512)
        if (artworkPath.isNotEmpty) {
          final optimized = await _optimizeArtworkForNotification(artworkPath);
          if (optimized != null) artworkPath = optimized;
        }
        
        // Mettre Ã  jour la source audio avec la pochette optimisÃ©e
        if (artworkPath.isNotEmpty && targetPlIndex < sources.length) {
          final source = sources[targetPlIndex];
          if (source is UriAudioSource && source.tag is MediaItem) {
            final oldItem = source.tag as MediaItem;
            // RecrÃ©er le source avec la pochette optimisÃ©e
            sources[targetPlIndex] = AudioSource.uri(
              Uri.parse(oldItem.id),
              tag: oldItem.copyWith(artUri: Uri.file(artworkPath)),
            );
          }
        }
      }
      
      // Ignore ALL index changes for the next second to avoid conflicts
      _ignoreIndexChangesUntil = DateTime.now().add(const Duration(milliseconds: 1000));
      
      // Mettre Ã  jour l'AudioHandler avec les MediaItem AVANT de jouer
      if (_audioHandler != null && sources.isNotEmpty) {
        final mediaItems = sources
            .where((s) => s is UriAudioSource && s.tag is MediaItem)
            .map((s) => (s as UriAudioSource).tag as MediaItem)
            .toList();
        _audioHandler!.setQueueItems(mediaItems);
        
        // Mettre Ã  jour le MediaItem courant avec l'Ã©tat "aimÃ©" AVANT play()
        if (targetPlIndex < mediaItems.length) {
          final currentMediaItem = mediaItems[targetPlIndex];
          final songId = currentMediaItem.extras?['songId'] as int?;
          final isLiked = songId != null && state.favorites.contains(songId);
          _audioHandler!.setMediaItemWithLikedState(currentMediaItem, isLiked);
        }
      }
      
      // Now set the audio sources and play
      await player.setAudioSources(sources, initialIndex: targetPlIndex, initialPosition: Duration.zero);
      await player.play();
    } catch (e) {
      // Log error silently and continue
      rethrow;
    }
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= state.songs.length) return;
    await player.seek(Duration.zero, index: index);
    await player.play();
    // Background refresh of artwork for current track
    Future.microtask(_refreshCurrentArtworkIfNeeded);
  }

  Future<void> toggle() async {
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> next() async {
    try {
      await player.seekToNext();
    } catch (_) {}
  }

  Future<void> previous() async {
    try {
      await player.seekToPrevious();
    } catch (_) {}
  }

  // -----------------------------
  // Queue maintenance
  // -----------------------------

  /// âœ… Helper: Create MediaItem with artwork fallback to default cover
  /// This ensures notifications ALWAYS show an image, even for songs without embedded artwork
  MediaItem _createMediaItemWithArtwork(SongModel song) {
    final overridden = applyOverrides(song);
    
    // Try to get custom artwork first
    Uri? artUri;
    final customPath = state.customArtworkPaths[song.id];
    if (customPath != null && customPath.isNotEmpty) {
      artUri = Uri.file(customPath);
    }
    
    // Fallback to default cover
    if (artUri == null) {
       if (_defaultCoverPath != null && _defaultCoverPath!.isNotEmpty) {
          artUri = Uri.file(_defaultCoverPath!);
       }
    }
    
    return MediaItem(
      id: song.uri ?? song.id.toString(), // âœ… URI as ID, fallback to ID string
      title: overridden.title,
      artist: overridden.artist ?? 'Artiste inconnu',
      album: overridden.album ?? 'Album inconnu',
      artUri: artUri,
      duration: Duration(milliseconds: song.duration ?? 0),
      extras: {
        'songId': song.id,
        'isLiked': state.favorites.contains(song.id),
      },
    );
  }

  /// Ensure the current track has an artwork file and update notification in background if needed.
  Future<void> _refreshCurrentArtworkIfNeeded() async {
    if (_artRefreshInProgress) return;
    _artRefreshInProgress = true;
    try {
      final s = currentSong;
      if (s == null) return;
      final idx = state.currentIndex;
      if (idx == null || idx < 0 || idx >= state.songs.length) return;

      String? targetPath;
      // Prefer custom cover saved locally
      final custom = state.customArtworkPaths[s.id];
      if (custom != null && custom.isNotEmpty) {
        try { if (await File(custom).exists()) targetPath = custom; } catch (_) {}
      }

      // Else use cached cover in documents
      if (targetPath == null) {
        try {
          final docs = await getApplicationDocumentsDirectory();
          final coversDir = Directory(path.join(docs.path, 'covers'));
          final cached = File(path.join(coversDir.path, '${s.id}.jpg'));
          if (!await cached.exists()) {
            try {
              final art = await OnAudioQuery().queryArtwork(
                s.id,
                ArtworkType.AUDIO,
                size: 1024,
                quality: 100,
              );
              if (art != null && art.isNotEmpty) {
                if (!await coversDir.exists()) { await coversDir.create(recursive: true); }
                await cached.writeAsBytes(art, flush: true);
              }
            } catch (_) {}
          }
          if (await cached.exists()) {
            targetPath = cached.path;
          }
        } catch (_) {}
      }
      
      // Si toujours rien, utiliser la pochette par dÃ©faut
      targetPath ??= await _getDefaultCoverPath();

      if (targetPath.isNotEmpty) {
        // Optimiser pour Android
        final optimized = await _optimizeArtworkForNotification(targetPath);
        if (optimized != null) targetPath = optimized;
        
        // Mettre Ã  jour UNIQUEMENT le MediaItem courant sans toucher au player
        if (_audioHandler != null) {
          final isLiked = state.favorites.contains(s.id);
          final mediaItem = MediaItem(
            id: s.uri ?? '',
            title: s.title,
            artist: s.artist ?? 'Artiste inconnu',
            album: s.album ?? 'Album inconnu',
            artUri: Uri.file(targetPath),
            duration: Duration(milliseconds: s.duration ?? 0),
            extras: {'songId': s.id},
          );
          _audioHandler!.setMediaItemWithLikedState(mediaItem, isLiked);
        }
        

        
        // âœ… Update widget cache immediately
        _cachedWidgetArtSongId = s.id;
        _cachedWidgetArtPath = targetPath;
      }

      // Refresh widgets as well
      await _pushWidgetUpdate();
    } catch (_) {
      // ignore
    } finally {
      _artRefreshInProgress = false;
    }
  }
  Future<void> removeSongById(int songId) async {
    final current = List<SongModel>.from(state.songs);
    final idx = current.indexWhere((s) => s.id == songId);
    if (idx == -1) return;

    // 1. Remove from local list
    current.removeAt(idx);

    if (current.isEmpty) {
      // Stop playback and clear state if queue is empty
      await player.stop();
      emit(state.copyWith(songs: <SongModel>[], currentIndex: null, currentSongId: null));
      return;
    }

    // 2. Determine next index relative to current
    int? cur = state.currentIndex;
    int? nextIndex;
    
    if (cur == null) {
      nextIndex = 0;
    } else if (idx < cur) {
      // Removed item was BEFORE current -> current index shifts down
      nextIndex = (cur - 1).clamp(0, current.length - 1);
    } else if (idx == cur) {
      // Removed item was CURRENT -> index stays same (points to next), or last if at end
      nextIndex = cur.clamp(0, current.length - 1);
    } else {
      // Removed item was AFTER current -> current index unchanged
      nextIndex = cur;
    }

    // 3. âœ… OPTIMIZATION: Remove from player directly without rebuilding
    try {
      await player.removeAudioSourceAt(idx);
    } catch (e) {
      // Fallback
      await _updateQueue(current, nextIndex, preservePosition: true);
    }

    // 4. Update state
    final currentSongId = (nextIndex < current.length) 
        ? current[nextIndex].id 
        : null;
        
    emit(state.copyWith(songs: current, currentIndex: nextIndex, currentSongId: currentSongId));
    
    // Update AudioHandler queue
    if (_audioHandler != null) {
       final mediaItems = current.map((s) => _createMediaItemWithArtwork(s)).toList();
       _audioHandler!.setQueueItems(mediaItems);
    }
  }

  // -----------------------------
  // Favorites (in-memory for now)
  // -----------------------------
  bool isFavorite(int songId) => state.favorites.contains(songId);

  void toggleFavoriteCurrent() {
    final s = currentSong;
    if (s == null) return;
    final next = Set<int>.from(state.favorites);
    if (next.contains(s.id)) {
      next.remove(s.id);
    } else {
      next.add(s.id);
    }
    emit(state.copyWith(favorites: next));
    // Defer persistence to avoid blocking UI.
  }

  // -----------------------------
  // Sleep Timer
  // -----------------------------
  // -----------------------------
  // Sleep Timer
  // -----------------------------
  bool _isSleepTimerFadeStarted = false;

  void startSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepEndTime = DateTime.now().add(duration);
    _isSleepTimerFadeStarted = false;
    
    final newState = state.copyWith(
      sleepTimerEndTime: _sleepEndTime,
    );
    emit(newState);
    
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now();
      if (_sleepEndTime == null) {
        timer.cancel();
        return;
      }
      
      if (now.isAfter(_sleepEndTime!)) {
        await _stopFromSleepTimer();
      }
    });
  }

  Future<void> _stopFromSleepTimer() async {
    await player.pause();
    cancelSleepTimer();
    player.setVolume(1.0); // Reset volume for next use
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepEndTime = null;
    _isSleepTimerFadeStarted = false;
    player.setVolume(1.0);
    emit(state.copyWith(clearSleepTimer: true));
  }



  // -----------------------------
  // Equalizer Controls
  // -----------------------------
  
  Future<void> toggleEqualizer(bool enabled) async {
    emit(state.copyWith(equalizerEnabled: enabled));
    await _equalizer.setEnabled(enabled);
    _savePlayerState();
  }

  Future<void> setEqualizerBand(int bandIndex, double gain) async {
    final bands = List<double>.from(state.equalizerBands);
    if (bandIndex < bands.length) {
      bands[bandIndex] = gain;
      emit(state.copyWith(equalizerBands: bands));
      
      final parameters = await _equalizer.parameters;
      final band = parameters.bands[bandIndex];
      await band.setGain(gain);
      _savePlayerState();
    }
  }

  Future<void> _initEqualizer() async {
    try {
      final parameters = await _equalizer.parameters;
      final bandsCount = parameters.bands.length;
      
      List<double> savedBands = state.equalizerBands;
      if (savedBands.length != bandsCount) {
        savedBands = List.filled(bandsCount, 0.0);
      }
      
      emit(state.copyWith(equalizerBands: savedBands));
      await _equalizer.setEnabled(state.equalizerEnabled);
      
      for (int i = 0; i < bandsCount; i++) {
        await parameters.bands[i].setGain(savedBands[i]);
      }
    } catch (e) {
      debugPrint('Error initializing equalizer: $e');
    }
  }

  // -----------------------------
  // Play statistics (counts & last played)
  // -----------------------------

  Future<void> _loadPlayStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final countsStr = prefs.getString('play_counts');
      if (countsStr != null && countsStr.isNotEmpty) {
        final decoded = json.decode(countsStr) as Map<String, dynamic>;
        final counts = <int, int>{};
        decoded.forEach((k, v) {
          final ki = int.tryParse(k);
          final vi = (v is int) ? v : (v is num ? v.toInt() : null);
          if (ki != null && vi != null) counts[ki] = vi;
        });
        if (counts.isNotEmpty) {
          emit(state.copyWith(playCounts: counts));
        }
      }

      final lastStr = prefs.getString('last_played');
      if (lastStr != null && lastStr.isNotEmpty) {
        final decoded = json.decode(lastStr) as Map<String, dynamic>;
        final last = <int, int>{};
        decoded.forEach((k, v) {
          final ki = int.tryParse(k);
          final vi = (v is int) ? v : (v is num ? v.toInt() : null);
          if (ki != null && vi != null) last[ki] = vi;
        });
        
        // Enforce 100 item limit on load
        if (last.length > 100) {
          final sortedKeys = last.keys.toList()
            ..sort((a, b) => last[b]!.compareTo(last[a]!)); // Sort desc (newest first)
          
          final truncated = <int, int>{};
          for (var i = 0; i < 100; i++) {
            final key = sortedKeys[i];
            truncated[key] = last[key]!;
          }
          emit(state.copyWith(lastPlayed: truncated));
        } else if (last.isNotEmpty) {
          emit(state.copyWith(lastPlayed: last));
        }
      }
    } catch (_) {}
  }

  Future<void> _persistPlayStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final counts = <String, int>{
        for (final e in state.playCounts.entries) e.key.toString(): e.value,
      };
      final last = <String, int>{
        for (final e in state.lastPlayed.entries) e.key.toString(): e.value,
      };
      await prefs.setString('play_counts', json.encode(counts));
      await prefs.setString('last_played', json.encode(last));
    } catch (_) {}
  }

  // Remove a song from lastPlayed history and persist
  void removeFromHistory(int songId) {
    final last = Map<int, int>.from(state.lastPlayed);
    if (last.containsKey(songId)) {
      last.remove(songId);
      emit(state.copyWith(lastPlayed: last));
      _persistPlayStats();
    }
  }

  // Clear all lastPlayed history and persist
  Future<void> clearHistory() async {
    emit(state.copyWith(lastPlayed: <int, int>{}));
    await _persistPlayStats();
  }

  void toggleFavoriteById(int songId) {
    final next = Set<int>.from(state.favorites);
    final isLiked = !next.contains(songId);
    if (next.contains(songId)) {
      next.remove(songId);
    } else {
      next.add(songId);
    }
    emit(state.copyWith(favorites: next));
    _persistFavorites();
    
    // Mettre Ã  jour l'AudioHandler si c'est la chanson courante
    if (_audioHandler != null) {
      final currentSongId = currentSong?.id;
      if (currentSongId == songId) {
        _audioHandler!.updateLikedState(isLiked);
      }
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('favorites_ids') ?? const <String>[];
      final set = ids.map((e) => int.tryParse(e)).whereType<int>().toSet();
      if (set.isNotEmpty) {
        emit(state.copyWith(favorites: set));
      }

      // Charger les dossiers masquÃ©s
      final hiddenFoldersJson = prefs.getString('hidden_folders');
      if (hiddenFoldersJson != null) {
        try {
          final List<dynamic> list = jsonDecode(hiddenFoldersJson);
          emit(state.copyWith(hiddenFolders: list.cast<String>().toList()));
        } catch (e) {
          debugPrint('Error loading hidden folders: $e');
        }
      }
      
      // Load show hidden folders setting
      final showHiddenFolders = prefs.getBool('show_hidden_folders') ?? false;
      emit(state.copyWith(showHiddenFolders: showHiddenFolders));
    } catch (_) {}
  }

  Future<void> _persistFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'favorites_ids',
        state.favorites.map((e) => e.toString()).toList(),
      );
    } catch (_) {}
  }

  // -----------------------------
  // UI Prefs: hide metadata save warning
  // -----------------------------
  Future<void> _loadHideMetadataSaveWarning() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool('hide_meta_warning') ?? false;
      if (v != state.hideMetadataSaveWarning) {
        emit(state.copyWith(hideMetadataSaveWarning: v));
      }
    } catch (_) {}
  }

  Future<void> setHideMetadataSaveWarning(bool hide) async {
    emit(state.copyWith(hideMetadataSaveWarning: hide));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hide_meta_warning', hide);
    } catch (_) {}
  }
  
  // Persist hidden folders to SharedPreferences
  Future<void> _persistHiddenFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hidden_folders', jsonEncode(state.hiddenFolders));
    } catch (e) {
      debugPrint('Error saving hidden folders: $e');
    }
  }
  
  // VÃ©rifie si un fichier est dans un dossier masquÃ©
  bool isPathInHiddenFolder(String filePath) {
    if (state.hiddenFolders.isEmpty) return false;
    
    // Normaliser les chemins pour la comparaison
    final normalizedFilePath = path.normalize(filePath);
    final dir = path.dirname(normalizedFilePath);
    
    // VÃ©rifier si le fichier est dans un dossier masquÃ©
    for (final hidden in state.hiddenFolders) {
      final normalizedHidden = path.normalize(hidden);
      
      // VÃ©rifier si le dossier du fichier est le dossier masquÃ© ou un sous-dossier
      if (dir == normalizedHidden || 
          path.isWithin(normalizedHidden, dir) ||
          path.isWithin(normalizedHidden, normalizedFilePath)) {
        return true;
      }
    }
    
    return false;
  }
  
  // Met Ã  jour la liste des dossiers masquÃ©s
  Future<void> updateHiddenFolders(List<String> folders) async {
    emit(state.copyWith(hiddenFolders: folders));
    await _persistHiddenFolders();

    // Refiltrer la file de lecture actuelle pour retirer les titres masquÃ©s
    final current = List<SongModel>.from(state.songs);
    if (current.isEmpty) return;

    final curIdx = state.currentIndex;
    final curSong = (curIdx != null && curIdx >= 0 && curIdx < current.length)
        ? current[curIdx]
        : null;

    final newSongs = <SongModel>[];
    int? newCurrentIndex;
    for (final s in current) {
      if (!isPathInHiddenFolder(s.data)) {
        if (curSong != null && s.id == curSong.id) {
          newCurrentIndex = newSongs.length;
        }
        newSongs.add(s);
      }
    }

    if (newSongs.length != current.length) {
      // Si la chanson en cours a Ã©tÃ© masquÃ©e, choisir un index proche
      newCurrentIndex ??= newSongs.isEmpty
          ? null
          : (curIdx == null ? 0 : curIdx.clamp(0, newSongs.length - 1));

      await _updateQueue(newSongs, newCurrentIndex, preservePosition: true);
    }
  }

  /// Met Ã  jour la file d'attente avec une nouvelle liste.
  /// Cette mÃ©thode est publique pour Ãªtre utilisÃ©e par l'UI (ex: suppression multiple).
  Future<void> updateQueue(List<SongModel> newQueue) async {
      // Calculer le nouvel index de la chanson en cours
      final currentId = state.currentSongId;
      int? newIndex;
      if (currentId != null) {
          newIndex = newQueue.indexWhere((s) => s.id == currentId);
          if (newIndex == -1) newIndex = null;
      }
      
      // Si on a perdu la chanson en cours, on repart de 0 ou null
      newIndex ??= newQueue.isEmpty ? null : 0;

      await _updateQueue(newQueue, newIndex, preservePosition: true);
  }
  
  // Toggle pour afficher/masquer les dossiers masquÃ©s
  Future<void> toggleShowHiddenFolders() async {
    emit(state.copyWith(showHiddenFolders: !state.showHiddenFolders));
    await _persistShowHiddenFolders();
  }
  
  // Persist show hidden folders setting
  Future<void> _persistShowHiddenFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_hidden_folders', state.showHiddenFolders);
    } catch (e) {
      debugPrint('Error saving show hidden folders setting: $e');
    }
  }
  
  // Filtre les chansons en excluant celles des dossiers masquÃ©s
  List<SongModel> filterSongs(List<SongModel> songs) {
    if (state.hiddenFolders.isEmpty) {
      return List<SongModel>.from(songs);
    }
    
    // Filter out songs with null data (path) to avoid crashes
    final filtered = songs.where((song) {
      try {
        // Accessing .data might throw if it's null but typed as String
        // ignore: unnecessary_null_comparison
        // if (song.data == null) return false;
        return !isPathInHiddenFolder(song.data);
      } catch (e) {
        return false;
      }
    }).toList();
    return filtered;
  }

  // -----------------------------
  // Custom Artwork (persistence + handlers)
  // -----------------------------
  Future<void> _loadCustomArtworkPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('custom_artwork_paths');
      if (raw == null || raw.isEmpty) return;
      final decoded = json.decode(raw);
      final map = <int, String>{};
      if (decoded is Map<String, dynamic>) {
        for (final entry in decoded.entries) {
          final key = int.tryParse(entry.key);
          final value = entry.value?.toString() ?? '';
          if (key != null && value.isNotEmpty) {
            // Keep only existing files to avoid stale entries
            try {
              if (await File(value).exists()) {
                map[key] = value;
              }
            } catch (_) {}
          }
        }
      }
      if (map.isNotEmpty) {
        emit(state.copyWith(customArtworkPaths: map));
      }
    } catch (_) {}
  }

  Future<void> _persistCustomArtworkPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final asStringMap = <String, String>{
        for (final e in state.customArtworkPaths.entries) e.key.toString(): e.value,
      };
      await prefs.setString('custom_artwork_paths', json.encode(asStringMap));
    } catch (_) {}
  }

  /// Copy [sourcePath] to app documents under covers/[songId].[ext] and update state.
  Future<void> setCustomArtwork(int songId, String sourcePath) async {
    try {
      // Debug logs to diagnose potential crashes when copying artwork files
      debugPrint('[setCustomArtwork] songId=$songId sourcePath=$sourcePath');
      final docs = await getApplicationDocumentsDirectory();
      final coversDir = Directory(path.join(docs.path, 'covers'));
      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }

      final ext = path.extension(sourcePath);
      final safeExt = (ext.isNotEmpty ? ext : '.jpg');
      final targetPath = path.join(coversDir.path, '$songId$safeExt');
      debugPrint('[setCustomArtwork] targetPath=$targetPath');

      // Copy/overwrite
      final srcFile = File(sourcePath);
      final exists = await srcFile.exists();
      debugPrint('[setCustomArtwork] source exists=$exists');
      if (!exists) {
        // Some providers return temporary or virtual paths; attempt a streamed copy as a fallback
        // (still using File API here; logs will help determine if a content:// handling is needed)
      }
      await srcFile.copy(targetPath);
      debugPrint('[setCustomArtwork] copy succeeded');

      final next = Map<int, String>.from(state.customArtworkPaths);
      next[songId] = targetPath;
      emit(state.copyWith(customArtworkPaths: next));
      await _persistCustomArtworkPaths();

      // Si c'est la chanson en cours, mettre Ã  jour seulement le MediaItem courant
      final currentSongModel = currentSong;
      if (currentSongModel != null && currentSongModel.id == songId && _audioHandler != null) {
        final optimized = await _optimizeArtworkForNotification(targetPath);
        final artPath = optimized ?? targetPath;
        final isLiked = state.favorites.contains(songId);
        final mediaItem = MediaItem(
          id: currentSongModel.uri ?? '',
          title: currentSongModel.title,
          artist: currentSongModel.artist ?? 'Artiste inconnu',
          album: currentSongModel.album ?? 'Album inconnu',
          artUri: Uri.file(artPath),
          duration: Duration(milliseconds: currentSongModel.duration ?? 0),
          extras: {'songId': songId},
        );
        _audioHandler!.setMediaItemWithLikedState(mediaItem, isLiked);
      }
      
      // âœ… Update widget cache immediately
      if (_cachedWidgetArtSongId == songId) {
         _cachedWidgetArtPath = targetPath;
      }
    } catch (_) {}
  }

  /// Write [bytes] to app documents under covers/[songId].[ext] and update state.
  Future<void> setCustomArtworkBytes(int songId, Uint8List bytes, {String ext = '.jpg'}) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final coversDir = Directory(path.join(docs.path, 'covers'));
      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }

      final safeExt = ext.isNotEmpty && ext.startsWith('.') ? ext : (ext.isNotEmpty ? '.$ext' : '.jpg');
      final targetPath = path.join(coversDir.path, '$songId$safeExt');

      final f = File(targetPath);
      await f.writeAsBytes(bytes, flush: true);

      final next = Map<int, String>.from(state.customArtworkPaths);
      next[songId] = targetPath;
      emit(state.copyWith(customArtworkPaths: next));
      await _persistCustomArtworkPaths();

      // Si c'est la chanson en cours, mettre Ã  jour seulement le MediaItem courant
      final currentSongModel = currentSong;
      if (currentSongModel != null && currentSongModel.id == songId && _audioHandler != null) {
        final optimized = await _optimizeArtworkForNotification(targetPath);
        final artPath = optimized ?? targetPath;
        final isLiked = state.favorites.contains(songId);
        final mediaItem = MediaItem(
          id: currentSongModel.uri ?? '',
          title: currentSongModel.title,
          artist: currentSongModel.artist ?? 'Artiste inconnu',
          album: currentSongModel.album ?? 'Album inconnu',
          artUri: Uri.file(artPath),
          duration: Duration(milliseconds: currentSongModel.duration ?? 0),
          extras: {'songId': songId},
        );
        _audioHandler!.setMediaItemWithLikedState(mediaItem, isLiked);
      }
      
      // âœ… Update widget cache immediately
      if (_cachedWidgetArtSongId == songId) {
         _cachedWidgetArtPath = targetPath;
      }
    } catch (_) {}
  }

  /// Remove a custom artwork for [songId] and refresh notification if current song.
  Future<void> removeCustomArtwork(int songId) async {
    try {
      final prev = state.customArtworkPaths[songId];
      if (prev != null && prev.isNotEmpty) {
        try {
          final f = File(prev);
          if (await f.exists()) {
            await f.delete();
          }
        } catch (_) {}
      }

      final next = Map<int, String>.from(state.customArtworkPaths);
      next.remove(songId);
      emit(state.copyWith(customArtworkPaths: next));
      await _persistCustomArtworkPaths();

      // Si c'est la chanson en cours, rafraÃ®chir la pochette en arriÃ¨re-plan
      final currentSongModel = currentSong;
      if (currentSongModel != null && currentSongModel.id == songId) {
        // âœ… Invalidate cache
        if (_cachedWidgetArtSongId == songId) {
           _cachedWidgetArtPath = null;
        }
        Future.microtask(_refreshCurrentArtworkIfNeeded);
      }
    } catch (_) {}
  }

  // -----------------------------
  // User Playlists (CRUD + persistence)
  // -----------------------------
  Future<void> _loadUserPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Try new key first, then fall back to old key for migration
      var raw = prefs.getString('user_playlists_v2');
      if (raw == null || raw.isEmpty) {
        // Migration: try old key
        raw = prefs.getString('user_playlists');
        if (raw != null && raw.isNotEmpty) {
          // Migrate to new key
          await prefs.setString('user_playlists_v2', raw);
          debugPrint('[Playlists] Migrated from old key to user_playlists_v2');
        }
      }
      
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw);
        if (decoded is List) {
          final list = <UserPlaylist>[];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              list.add(UserPlaylist.fromJson(item));
            } else if (item is Map) {
              list.add(UserPlaylist.fromJson(item.cast<String, dynamic>()));
            }
          }
          emit(state.copyWith(userPlaylists: list));
          debugPrint('[Playlists] Loaded ${list.length} playlists');
        }
      } else {
        debugPrint('[Playlists] No playlists found in storage');
      }
    } catch (e) {
      debugPrint('[Playlists] Error loading: $e');
    }
  }

  Future<void> _persistUserPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = state.userPlaylists.map((p) => p.toJson()).toList();
      await prefs.setString('user_playlists_v2', json.encode(list));
      debugPrint('[Playlists] Persisted ${list.length} playlists');
    } catch (e) {
      debugPrint('[Playlists] Error persisting: $e');
    }
  }

  String createUserPlaylist(String name) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = 'pl_$now';
    final p = UserPlaylist(id: id, name: name, songIds: <int>[], createdAtMillis: now);
    final next = List<UserPlaylist>.from(state.userPlaylists)..insert(0, p);
    emit(state.copyWith(userPlaylists: next));
    _persistUserPlaylists();
    return id;
  }

  void renameUserPlaylist(String id, String newName) {
    final next = state.userPlaylists
        .map((p) => p.id == id ? p.copyWith(name: newName) : p)
        .toList(growable: false);
    emit(state.copyWith(userPlaylists: next));
    _persistUserPlaylists();
  }

  void deleteUserPlaylist(String id) {
    final next = List<UserPlaylist>.from(state.userPlaylists)..removeWhere((p) => p.id == id);
    emit(state.copyWith(userPlaylists: next));
    _persistUserPlaylists();
  }

  void addSongToUserPlaylist(String id, int songId) {
    final next = state.userPlaylists.map((p) {
      if (p.id != id) return p;
      if (p.songIds.contains(songId)) return p;
      final updated = List<int>.from(p.songIds)..add(songId);
      return p.copyWith(songIds: updated);
    }).toList(growable: false);
    emit(state.copyWith(userPlaylists: next));
    _persistUserPlaylists();
  }

  void removeSongFromUserPlaylist(String id, int songId) {
    final next = state.userPlaylists.map((p) {
      if (p.id != id) return p;
      final updated = List<int>.from(p.songIds)..remove(songId);
      return p.copyWith(songIds: updated);
    }).toList(growable: false);
    emit(state.copyWith(userPlaylists: next));
    _persistUserPlaylists();
  }

  /// RÃ©organise l'ordre des titres dans une playlist utilisateur
  void reorderUserPlaylist(String id, int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final list = List<UserPlaylist>.from(state.userPlaylists);
    final idx = list.indexWhere((p) => p.id == id);
    if (idx == -1) return;

    final p = list[idx];
    if (oldIndex < 0 || oldIndex >= p.songIds.length) return;
    // Lorsque newIndex vient de ReorderableListView, il est dÃ©jÃ  ajustÃ© (l'API Flutter
    // fournit newIndex tel quel). On applique l'ajustement standard: si newIndex > oldIndex,
    // insÃ©rer Ã  newIndex - 1 pour conserver la sÃ©mantique.
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    target = target.clamp(0, p.songIds.length - 1);

    final updatedIds = List<int>.from(p.songIds);
    final moved = updatedIds.removeAt(oldIndex);
    updatedIds.insert(target, moved);

    list[idx] = p.copyWith(songIds: updatedIds);
    emit(state.copyWith(userPlaylists: list));
    _persistUserPlaylists();
  }

  /// MÃ©lange la file d'attente en maintenant la chanson en cours
  Future<void> shuffleQueue() async {
    if (state.songs.length <= 1) return;
    
    final currentIndex = state.currentIndex;
    if (currentIndex == null) return;
    
    // Sauvegarder la chanson actuelle
    final currentSong = state.songs[currentIndex];
    
    // CrÃ©er une nouvelle liste sans la chanson actuelle
    final newSongs = List<SongModel>.from(state.songs)..removeAt(currentIndex);
    
    // MÃ©langer le reste
    newSongs.shuffle();
    
    // Reconstruire la liste avec la chanson actuelle en premiÃ¨re position
    newSongs.insert(0, currentSong);
    
    // Mettre Ã  jour la file d'attente
    await _updateQueue(newSongs, 0);
  }
  
  /// Vide la file d'attente sauf la chanson en cours de lecture
  Future<void> clearQueue() async {
    final currentIndex = state.currentIndex;
    if (currentIndex == null || state.songs.length <= 1) return;
    
    // Garder uniquement la chanson actuelle avec sa position de lecture actuelle
    final currentSong = state.songs[currentIndex];
    await _updateQueue([currentSong], 0, preservePosition: true);
  }
  
  /// Supprime une chanson de la file d'attente
  Future<void> removeFromQueue(int position) async {
    if (position < 0 || position >= state.songs.length) return;
    
    final newSongs = List<SongModel>.from(state.songs);
    newSongs.removeAt(position);
    
    if (newSongs.isEmpty) {
      await player.stop();
      emit(state.copyWith(songs: const [], currentIndex: null, currentSongId: null));
      return;
    }
    
    // Ajuster l'index courant si nÃ©cessaire
    int? newIndex = state.currentIndex;
    final isRemovingCurrentSong = position == state.currentIndex;
    
    if (newIndex != null) {
      if (position < newIndex) {
        newIndex--;
      } else if (position == newIndex) {
        // Si on supprime la chanson en cours, garder l'index (pointe maintenant vers la suivante)
        newIndex = newIndex < newSongs.length ? newIndex : newSongs.length - 1;
      }
    }
    
    // âœ… OPTIMISATION: Si on ne supprime PAS la chanson en cours, juste retirer de la sÃ©quence
    if (!isRemovingCurrentSong) {
      try {
        await player.removeAudioSourceAt(position);
          
          // Mettre Ã  jour uniquement l'Ã©tat (sans recharger le player)
          final currentSongId = (newIndex != null && newIndex < newSongs.length) ? newSongs[newIndex].id : null;
          emit(state.copyWith(
            songs: newSongs,
            currentIndex: newIndex,
            currentSongId: currentSongId,
          ));
          
          // Mettre Ã  jour les MediaItems dans l'AudioHandler
          if (_audioHandler != null) {
            final allMediaItems = newSongs.map((s) => _createMediaItemWithArtwork(s)).toList();
            _audioHandler!.setQueueItems(allMediaItems);
          }
          return;
        } catch (e) {
          // Fallback si la suppression Ã©choue
      }
    }
    
    // Si on supprime la chanson en cours OU si l'optimisation a Ã©chouÃ©, recharger tout
    await _updateQueue(newSongs, newIndex, preservePosition: !isRemovingCurrentSong);
  }
  
  /// RÃ©organise la file d'attente
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex || 
        oldIndex < 0 || 
        newIndex < 0 || 
        oldIndex >= state.songs.length || 
        newIndex >= state.songs.length) {
      return;
    }
    
    final newSongs = List<SongModel>.from(state.songs);
    final item = newSongs.removeAt(oldIndex);
    newSongs.insert(newIndex, item);

    // Mettre Ã  jour l'index courant si nÃ©cessaire
    int? newCurrentIndex = state.currentIndex;
    
    if (newCurrentIndex != null) {
      if (oldIndex == newCurrentIndex) {
        newCurrentIndex = newIndex;
      } else if (oldIndex < newCurrentIndex && newIndex >= newCurrentIndex) {
        newCurrentIndex--;
      } else if (oldIndex > newCurrentIndex && newIndex <= newCurrentIndex) {
        newCurrentIndex++;
      }
    }

    // Ignore index changes from player for a short time to prevent race conditions/glitches
    _ignoreIndexChangesUntil = DateTime.now().add(const Duration(milliseconds: 500));

    // Update state IMMEDIATELY to avoid visual glitch (flashing)
    final currentSongId = (newCurrentIndex != null && newCurrentIndex < newSongs.length)
        ? newSongs[newCurrentIndex].id
        : null;
        
    emit(state.copyWith(
      songs: newSongs,
      currentIndex: newCurrentIndex,
      currentSongId: currentSongId,
    ));

    // âœ… OPTIMISATION: Utiliser removeAudioSourceAt directement sur le player
    try {
      await player.moveAudioSource(oldIndex, newIndex);
    } catch (e) {
      // Fallback: rebuild if move fails
      await _updateQueue(newSongs, newCurrentIndex, preservePosition: true);
      return;
    }
    
    // Mettre Ã  jour la queue du AudioHandler pour les notifications
    // Mettre Ã  jour la queue du AudioHandler pour les notifications
    // âœ… OPTIMISATION: Faire cela en background pour ne pas bloquer l'UI pendant le drag & drop
    if (_audioHandler != null) {
      Future.microtask(() {
        final mediaItems = newSongs.map((s) {
          final overridden = applyOverrides(s);
          return MediaItem(
            id: s.uri ?? '',
            title: overridden.title,
            artist: overridden.artist ?? 'Unknown',
            album: overridden.album ?? '',
            extras: {'songId': s.id},
          );
        }).toList();
        _audioHandler!.setQueueItems(mediaItems);
      });
    }
  }
  
  /// Ajoute des chansons Ã  la file d'attente sans interrompre la lecture.
  /// Si [playNext] est vrai, insÃ¨re les titres juste aprÃ¨s la chanson en cours.
  Future<void> addToQueue(List<SongModel> songsToAdd, {bool playNext = false}) async {
    if (songsToAdd.isEmpty) return;

    // Filtrer uniquement les chansons avec une URI valide
    final valid = songsToAdd
        .where((s) => s.uri != null && s.uri!.isNotEmpty)
        .where((s) => !isSoftDeleted(s.id))
        .toList();
    if (valid.isEmpty) return;

    final current = List<SongModel>.from(state.songs);
    int? cur = state.currentIndex;
    
    // CrÃ©er les nouvelles sources audio pour les chansons ajoutÃ©es
    final newSources = <AudioSource>[];
    for (final s in valid) {
      Uri? artUri;
      final customPath = state.customArtworkPaths[s.id];
      if (customPath != null && customPath.isNotEmpty) {
        artUri = Uri.file(customPath);
      }
      
      newSources.add(
        AudioSource.uri(
          Uri.parse(s.uri!),
          tag: MediaItem(
            id: s.uri!,
            title: s.title,
            artist: s.artist ?? 'Artiste inconnu',
            album: s.album ?? 'Album inconnu',
            artUri: artUri,
            duration: Duration(milliseconds: s.duration ?? 0),
            extras: <String, dynamic>{'songId': s.id},
          ),
        ),
      );
    }

    // Ajouter Ã  la liste de chansons
    if (playNext && cur != null) {
      final insertAt = (cur + 1).clamp(0, current.length);
      current.insertAll(insertAt, valid);
      
      // InsÃ©rer dans la playlist du lecteur (sans stopper la lecture)
      try {
        await player.insertAudioSources(insertAt, newSources);
      } catch (e) {
        // Fallback si l'insertion Ã©choue
        await _updateQueue(current, cur, preservePosition: true);
        return;
      }
    } else {
      current.addAll(valid);
      
      // Ajouter Ã  la fin de la playlist (sans stopper la lecture)
      try {
        await player.addAudioSources(newSources);
      } catch (e) {
        // Fallback si l'ajout Ã©choue
        await _updateQueue(current, cur, preservePosition: true);
        return;
      }
    }
    
    // Mettre Ã  jour uniquement l'Ã©tat (sans recharger le player)
    final currentSongId = (cur != null && cur < current.length) ? current[cur].id : null;
    emit(state.copyWith(
      songs: current,
      currentIndex: cur,
      currentSongId: currentSongId,
    ));
    
    // Mettre Ã  jour les MediaItems dans l'AudioHandler
    if (_audioHandler != null) {
      final allMediaItems = current.map((s) {
        Uri? artUri;
        final customPath = state.customArtworkPaths[s.id];
        if (customPath != null && customPath.isNotEmpty) {
          artUri = Uri.file(customPath);
        }
        return MediaItem(
          id: s.uri!,
          title: s.title,
          artist: s.artist ?? 'Artiste inconnu',
          album: s.album ?? 'Album inconnu',
          artUri: artUri,
          duration: Duration(milliseconds: s.duration ?? 0),
          extras: <String, dynamic>{'songId': s.id},
        );
      }).toList();
      _audioHandler!.setQueueItems(allMediaItems);
    }
  }

  /// Met Ã  jour une chanson existante dans la file d'attente (ex: mÃ©tadonnÃ©es).
  /// PrÃ©serve la position de lecture si la chanson en cours n'est pas changÃ©e.
  Future<void> updateSongInQueue(int songId, SongModel updated) async {
    final idx = state.songs.indexWhere((s) => s.id == songId);
    if (idx == -1) return;

    final current = List<SongModel>.from(state.songs);
    final oldVersion = current[idx];
    current[idx] = updated;

    // âœ… OPTIMISATION : Modification de mÃ©tadonnÃ©es sans changement d'URI
    // Au lieu de recharger le player (ce qui cause une coupure), on maj l'Ã©tat et l'AudioHandler
    if (oldVersion.uri == updated.uri) {
      // 1. Mettre Ã  jour l'Ã©tat (UI)
      emit(state.copyWith(songs: current));
      
      // 2. Mettre Ã  jour l'AudioHandler (Notification)
      if (_audioHandler != null) {
        Uri? artUri;
        final customPath = state.customArtworkPaths[updated.id];
        if (customPath != null && customPath.isNotEmpty) {
          artUri = Uri.file(customPath);
        } else if (_defaultCoverPath != null) {
          artUri = Uri.file(_defaultCoverPath!);
        }

        final newItem = MediaItem(
          id: updated.uri!,
          title: updated.title,
          artist: updated.artist ?? 'Artiste inconnu',
          album: updated.album ?? 'Album inconnu',
          artUri: artUri,
          duration: Duration(milliseconds: updated.duration ?? 0),
          extras: <String, dynamic>{
            'songId': updated.id,
          },
        );

        final queue = _audioHandler!.queue.value;
        if (idx < queue.length) {
           final newQueue = List<MediaItem>.from(queue);
           newQueue[idx] = newItem;
           _audioHandler!.setQueueItems(newQueue);
           
           if (idx == state.currentIndex) {
              _audioHandler!.setMediaItemWithLikedState(newItem, state.favorites.contains(songId));
           }
        }
      }
      return; 
    }

    await _updateQueue(current, state.currentIndex, preservePosition: idx == state.currentIndex);
  }

  /// RÃ©insÃ¨re une chanson dans la file d'attente Ã  l'index donnÃ©.
  /// UtilisÃ© notamment pour l'action "Annuler" aprÃ¨s une suppression.
  /// Conserve la piste en cours et la position de lecture.
  Future<void> insertIntoQueueAt(SongModel song, int index) async {
    // Valider le titre (URI requise et non supprimÃ© localement)
    if (song.uri == null || song.uri!.isEmpty) return;
    if (isSoftDeleted(song.id)) return;

    final current = List<SongModel>.from(state.songs);
    // Borner l'index d'insertion entre 0 et longueur courante
    final insertAt = index.clamp(0, current.length);
    current.insert(insertAt, song);

    // Ajuster l'index courant pour conserver la mÃªme piste en cours
    int? newCurrentIndex = state.currentIndex;
    if (newCurrentIndex != null && insertAt <= newCurrentIndex) {
      newCurrentIndex += 1;
    }

    // âœ… OPTIMIZATION: Insert directly into player
    // Use explicit _playlist reference
    if (song.uri != null) {
      try {
        // Prepare source
        Uri? artUri;
        final customPath = state.customArtworkPaths[song.id];
        if (customPath != null && customPath.isNotEmpty) {
          artUri = Uri.file(customPath);
        }
        
        final source = AudioSource.uri(
          Uri.parse(song.uri!),
          tag: MediaItem(
            id: song.uri!,
            title: song.title,
            artist: song.artist ?? 'Artiste inconnu',
            album: song.album ?? 'Album inconnu',
            artUri: artUri,
            duration: Duration(milliseconds: song.duration ?? 0),
            extras: <String, dynamic>{'songId': song.id},
          ),
        );
        
        await player.insertAudioSource(insertAt, source);
        
        // Update state
        final currentSongId = (newCurrentIndex != null && newCurrentIndex < current.length) 
            ? current[newCurrentIndex].id 
            : null;
            
        emit(state.copyWith(
          songs: current,
          currentIndex: newCurrentIndex,
          currentSongId: currentSongId,
        ));
        
        // Update AudioHandler
        if (_audioHandler != null) {
          final mediaItems = current.map((s) => _createMediaItemWithArtwork(s)).toList();
          _audioHandler!.setQueueItems(mediaItems);
        }
        return;
      } catch (e) {
        // Fallback
      }
    }

    await _updateQueue(current, newCurrentIndex, preservePosition: true);
  }

  /// Met Ã  jour la file d'attente avec une nouvelle liste de chansons
  Future<void> _updateQueue(List<SongModel> newSongs, int? newCurrentIndex, {bool preservePosition = false}) async {
    if (newSongs.isEmpty) {
      await player.stop();
      emit(state.copyWith(songs: const [], currentIndex: null, currentSongId: null));
      return;
    }
    
    // S'assurer que l'index est valide
    final currentIndex = newCurrentIndex ?? state.currentIndex ?? 0;
    final safeIndex = currentIndex.clamp(0, newSongs.length - 1);
    final wasPlaying = player.playing;
    final currentPos = preservePosition ? player.position : Duration.zero;
    
    // CrÃ©er les sources audio avec pochettes pour TOUTES les chansons
    final sources = <AudioSource>[];
    
    // âœ… Cache directory path for reuse
    String? coversDirPath;
    try {
      final docs = await getApplicationDocumentsDirectory();
      coversDirPath = path.join(docs.path, 'covers');
    } catch (_) {}

    // âœ… Optimisation : Charger uniquement les pochettes custom dÃ©jÃ  vÃ©rifiÃ©es
    for (var idx = 0; idx < newSongs.length; idx++) {
      final s = newSongs[idx];
      if (s.uri != null && s.uri!.isNotEmpty) {
        Uri? artUri;
        
        // 1. Uniquement les pochettes custom (pas de File.exists bloquant)
        final customPath = state.customArtworkPaths[s.id];
        if (customPath != null && customPath.isNotEmpty) {
          artUri = Uri.file(customPath);
        } else {
          // 2. Check for cached high-res artwork (File.exists is fast enough for <100 items usually, 
          // but we can optimize if needed. For now, it's safer to check.)
          if (coversDirPath != null) {
            final cachedFile = File(path.join(coversDirPath, '${s.id}.jpg'));
            if (await cachedFile.exists()) {
               artUri = Uri.file(cachedFile.path);
            }
          }
        }
        
        // 3. Fallback to standard album art URI if no cache
        if (artUri == null && _defaultCoverPath != null) {
          // âœ… Fallback to generated default cover if no albumId
          artUri = Uri.file(_defaultCoverPath!);
        }
        
        // Les pochettes du cache seront chargÃ©es en arriÃ¨re-plan par _refreshCurrentArtworkIfNeeded

        sources.add(
          AudioSource.uri(
            Uri.parse(s.uri!), 
            tag: MediaItem(
              id: s.uri!,
              title: s.title,
              artist: s.artist ?? 'Artiste inconnu',
              album: s.album ?? 'Album inconnu',
              artUri: artUri,
              duration: Duration(milliseconds: s.duration ?? 0),
              extras: <String, dynamic>{
                'songId': s.id,
              },
            ),
          ),
        );
      }
    }
    
    // Mettre Ã  jour l'Ã©tat AVANT le lecteur
    final currentSongId = (safeIndex < newSongs.length) ? newSongs[safeIndex].id : null;
    emit(state.copyWith(
      songs: newSongs,
      currentIndex: safeIndex,
      currentSongId: currentSongId,
    ));
    
    // Ignore index changes for next second
    _ignoreIndexChangesUntil = DateTime.now().add(const Duration(milliseconds: 1000));
    
    // Mettre Ã  jour l'AudioHandler avec les MediaItem AVANT de jouer
    if (_audioHandler != null && sources.isNotEmpty) {
      final mediaItems = sources
          .where((s) => s is UriAudioSource && s.tag is MediaItem)
          .map((s) => (s as UriAudioSource).tag as MediaItem)
          .toList();
      _audioHandler!.setQueueItems(mediaItems);
      
      // Mettre Ã  jour le MediaItem courant avec l'Ã©tat "aimÃ©" AVANT play()
      if (safeIndex < mediaItems.length) {
        final currentMediaItem = mediaItems[safeIndex];
        final songId = currentMediaItem.extras?['songId'] as int?;
        final isLiked = songId != null && state.favorites.contains(songId);
        _audioHandler!.setMediaItemWithLikedState(currentMediaItem, isLiked);
      }
    }
    
    // Mettre Ã  jour le lecteur (passez la position initiale pour limiter les coupures)
    try {
      await player.setAudioSources(
        sources,
        initialIndex: safeIndex,
        initialPosition: preservePosition ? currentPos : Duration.zero,
      );
      
      // Reprendre la lecture immÃ©diatement sans await pour rÃ©duire la pause
      if (wasPlaying) {
        player.play();
      }
    } catch (e) {
      debugPrint('âŒ Erreur setAudioSource dans _updateQueue: $e');
      if (wasPlaying) {
        player.play();
      }
    }
    
    // Trigger background pre-caching for upcoming tracks
    Future.microtask(_preCacheArtworkForNextSongs);
  }

  // âœ… Smart Pre-caching for Next Songs
  // Fetches high-res artwork for the next few songs in the queue to ensure
  // notifications show sharp images when user skips tracks.
  Future<void> _preCacheArtworkForNextSongs() async {
    try {
      if (state.songs.isEmpty) return;
      
      final currentIndex = state.currentIndex ?? 0;
      // Pre-cache next 3 songs
      final songsToCache = <SongModel>[];
      for (int i = 1; i <= 3; i++) {
        final nextIndex = (currentIndex + i) % state.songs.length;
        songsToCache.add(state.songs[nextIndex]);
      }
      
      final docs = await getApplicationDocumentsDirectory();
      final coversDir = Directory(path.join(docs.path, 'covers'));
      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }

      bool newCacheCreated = false;

      for (final s in songsToCache) {
        // Skip if custom art exists
        if (state.customArtworkPaths.containsKey(s.id)) continue;

        try {
          final cachedFile = File(path.join(coversDir.path, '${s.id}.jpg'));
          if (!await cachedFile.exists()) {
             // Cache miss - Fetch High-Res
             final art = await OnAudioQuery().queryArtwork(
               s.id,
               ArtworkType.AUDIO,
               size: 1024,
               quality: 100,
               format: ArtworkFormat.PNG, // Force PNG for quality
             );
             
             if (art != null && art.isNotEmpty) {
               await cachedFile.writeAsBytes(art, flush: true);
               
               // Optimize for notification usage immediately
               final optimized = await _optimizeArtworkForNotification(cachedFile.path);
               if (optimized != null && optimized != cachedFile.path) {
                 // Replace original with optimized if different? 
                 // Actually _optimize... creates a new file. 
                 // Let's just keep the original as master cache.
               }
               
               newCacheCreated = true;
             }
          }
        } catch (_) {}
      }
      
      // If we cached new artwork, update the audio handler queue silenttly 
      // so it picks up the new high-res file URIs
      if (newCacheCreated && _audioHandler != null) {
        // Re-generate media items with the newly cached files
        final mediaItems = <MediaItem>[];
        for (final s in state.songs) {
           mediaItems.add(_createMediaItemWithArtwork(s));
        }
        _audioHandler!.setQueueItems(mediaItems);
      }
      
    } catch (_) {}
  }
  
  // âœ… Sleep Timer - DÃ©marrer le minuteur




  // âœ… Sleep Timer - Temps restant
  Duration? get sleepTimeRemaining {
    if (_sleepEndTime == null) return null;
    final remaining = _sleepEndTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // âœ… Sleep Timer - Est actif ?
  bool get isSleepTimerActive => _sleepTimer?.isActive ?? false;

  Future<void> _savePlayerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save Shuffle
      await prefs.setBool(_keyShuffleMode, player.shuffleModeEnabled);
      
      // Save Loop
      String loopModeStr = 'off';
      if (player.loopMode == LoopMode.one) loopModeStr = 'one';
      if (player.loopMode == LoopMode.all) loopModeStr = 'all';
      await prefs.setString(_keyLoopMode, loopModeStr);
      
      // Save New Audio Features
      await prefs.setInt(_keyCrossfade, state.crossfadeDuration);
      await prefs.setBool(_keyGapless, state.gaplessEnabled);
      await prefs.setDouble(_keyPlaybackSpeed, state.playbackSpeed);
      
      // Save Equalizer
      await prefs.setBool(_keyEqEnabled, state.equalizerEnabled);
      await prefs.setStringList(_keyEqBands, state.equalizerBands.map((e) => e.toString()).toList());
      
      // Save Last Song ID and Metadata for quick notification restore
      if (state.currentSongId != null) {
        await prefs.setInt(_keyLastSongId, state.currentSongId!);
        
        // Save metadata for immediate notification display
        final song = currentSong;
        if (song != null) {
          await prefs.setString(_keyLastSongTitle, song.title);
          await prefs.setString(_keyLastSongArtist, song.artist ?? '');
          
          // Save artwork path if available
          final artPath = state.customArtworkPaths[state.currentSongId!] ?? _defaultCoverPath;
          if (artPath != null) {
            await prefs.setString(_keyLastSongArtPath, artPath);
          }
          
          // Save URI and duration for quick playback restore
          if (song.uri != null && song.uri!.isNotEmpty) {
            await prefs.setString(_keyLastSongUri, song.uri!);
            await prefs.setInt(_keyLastSongDuration, song.duration ?? 0);
          }
        }
      }
    } catch (e) {
      debugPrint('âŒ Error saving player state: $e');
    }
  }

  Future<void> _restorePlayerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Restore Shuffle
      final shuffle = prefs.getBool(_keyShuffleMode) ?? false;
      if (shuffle != player.shuffleModeEnabled) {
        await player.setShuffleModeEnabled(shuffle);
      }
      
      // Restore Loop
      final loopStr = prefs.getString(_keyLoopMode) ?? 'off';
      LoopMode loop = LoopMode.off;
      if (loopStr == 'one') loop = LoopMode.one;
      if (loopStr == 'all') loop = LoopMode.all;
      if (loop != player.loopMode) {
        await player.setLoopMode(loop);
      }
      
      // Restore New Audio Features
      final crossfade = prefs.getInt(_keyCrossfade) ?? 0;
      final gapless = prefs.getBool(_keyGapless) ?? false;
      final speed = prefs.getDouble(_keyPlaybackSpeed) ?? 1.0;
      
      // Restore Equalizer
      final eqEnabled = prefs.getBool(_keyEqEnabled) ?? false;
      final eqBandsStr = prefs.getStringList(_keyEqBands);
      List<double> eqBands = [];
      if (eqBandsStr != null) {
        eqBands = eqBandsStr.map((e) => double.tryParse(e) ?? 0.0).toList();
      }
      

      
      emit(state.copyWith(
        crossfadeDuration: crossfade,
        gaplessEnabled: gapless,
        playbackSpeed: speed, // 1.0 = normal
        equalizerEnabled: eqEnabled,
        equalizerBands: eqBands,
      ));
      
      // Apply restored settings
      try {
        if (gapless != player.skipSilenceEnabled) {
             await player.setSkipSilenceEnabled(gapless);
        }
        if (speed != 1.0) {
          await player.setSpeed(speed);
        }
      } catch (e) {
        debugPrint('Error applying restored audio settings: $e');
      }
      
      // Restore Last Song
      if (player.playing || state.songs.isEmpty) return;
      
      final lastSongId = prefs.getInt(_keyLastSongId);
      if (lastSongId != null) {
        final index = state.songs.indexWhere((s) => s.id == lastSongId);
          if (index != -1) {
            debugPrint('ðŸ”„ Restoring last played song: ${state.songs[index].title}');
            
            // âœ… INSTANT UPDATE: Emit immediately so the UI (MiniPlayer) shows the song
            emit(state.copyWith(
              currentIndex: index,
              currentSongId: lastSongId,
            ));
            _pushWidgetUpdate();

            // âœ… Build sources in background
            final sources = <AudioSource>[];
            for (final s in state.songs) {
              if (s.uri != null && s.uri!.isNotEmpty) {
                Uri? artUri;
                final customPath = state.customArtworkPaths[s.id];
                if (customPath != null && customPath.isNotEmpty) {
                  artUri = Uri.file(customPath);
                } else if (_defaultCoverPath != null) {
                  artUri = Uri.file(_defaultCoverPath!);
                }
                
                sources.add(AudioSource.uri(
                  Uri.parse(s.uri!),
                  tag: MediaItem(
                    id: s.uri!, // âœ… Use URI as ID (consistent with _updateQueue)
                    album: s.album ?? '',
                    title: s.title,
                    artist: s.artist ?? '',
                    artUri: artUri,
                    duration: Duration(milliseconds: s.duration ?? 0),
                    extras: {'songId': s.id},
                  ),
                ));
              }
            }
            
            if (sources.isEmpty) {
              debugPrint('â Œ No valid sources for restore');
              return;
            }
          
          // Trigger artwork load in background
          Future.microtask(_refreshCurrentArtworkIfNeeded);

          await player.setAudioSources(
            sources,
            initialIndex: index,
            initialPosition: Duration.zero,
          );
          
          // âœ… FORCE UI UPDATE to ensure MiniPlayer shows up
          _pushWidgetUpdate();
          debugPrint('âœ… Last song restored and UI update pushed.');
          
          // Update AudioHandler with the current MediaItem
          if (_audioHandler != null && index < sources.length) {
            final currentItem = (sources[index] as UriAudioSource).tag as MediaItem;
            final isLiked = state.favorites.contains(lastSongId);
            _audioHandler!.setMediaItemWithLikedState(currentItem, isLiked);
            
            // Also set the full queue for notification
            final mediaItems = sources
                .where((s) => s is UriAudioSource && s.tag is MediaItem)
                .map((s) => (s as UriAudioSource).tag as MediaItem)
                .toList();
            _audioHandler!.setQueueItems(mediaItems);
          }
          
          // Ensure we don't auto-play
          if (player.playing) await player.pause();
        }
      }
    } catch (e) {
      debugPrint('âŒ Error restoring player state: $e');
    }
  }

  @override
  Future<void> close() async {
    _sleepTimer?.cancel();
    _widgetUpdateTimer?.cancel();
    await player.dispose();
    return super.close();
  }
  // -----------------------------
  // Data Restore & Smart Migration
  // -----------------------------
  Future<void> restoreData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Restore Simple Preferences directly
      if (data['play_counts'] != null) await prefs.setString('play_counts', data['play_counts']);
      if (data['last_played'] != null) await prefs.setString('last_played', data['last_played']);
      if (data['hidden_folders'] != null) await prefs.setString('hidden_folders', data['hidden_folders']);
      if (data['show_hidden_folders'] != null) await prefs.setBool('show_hidden_folders', data['show_hidden_folders']);
      if (data['custom_artwork_paths'] != null) await prefs.setString('custom_artwork_paths', data['custom_artwork_paths']);
      if (data['metadata_overrides'] != null) await prefs.setString('metadata_overrides', data['metadata_overrides']);
      if (data['hide_meta_warning'] != null) await prefs.setBool('hide_meta_warning', data['hide_meta_warning']);

      debugPrint('[Restore] Backup keys: ${data.keys.toList()}');
      debugPrint('[Restore] allSongs count: ${state.allSongs.length}');
      debugPrint('[Restore] user_playlists in backup: ${data['user_playlists'] != null ? 'YES' : 'NO'}');
      debugPrint('[Restore] favorites in backup: ${data['favorites']?.length ?? 0}');

      // 2. Load "Smart Metadata Cache" for migration
      final metadataCache = data['song_metadata_cache'] as Map<String, dynamic>? ?? {};
      
      // Map OldID -> NewID
      final idMap = <String, int>{};
      
      if (metadataCache.isNotEmpty && state.allSongs.isNotEmpty) {
        for (final entry in metadataCache.entries) {
          final oldId = entry.key;
          final meta = entry.value;
          if (meta is Map) {
             final title = (meta['t'] as String? ?? '').toLowerCase().trim();
             final artist = (meta['a'] as String? ?? '').toLowerCase().trim();
             // Search in current library (match by title and artist, case-insensitive)
             for (final s in state.allSongs) {
               final sTitle = s.title.toLowerCase().trim();
               final sArtist = (s.artist ?? '').toLowerCase().trim();
               if (sTitle == title && sArtist == artist) {
                 idMap[oldId] = s.id;
                 break;
               }
             }
          }
        }
        debugPrint('[Restore] idMap created with ${idMap.length} mappings');
      }

      // 3. Migrate Favorites
      if (data['favorites'] != null) {
        final List<dynamic> oldFavs = data['favorites'];
        final newFavs = <String>[];
        debugPrint('[Restore] Processing ${oldFavs.length} favorites');
        
        for (final oldId in oldFavs) {
           final oldIdStr = oldId.toString();
           // Try mapped ID first (smart migration)
           if (idMap.containsKey(oldIdStr)) {
             newFavs.add(idMap[oldIdStr].toString());
           } else {
             // Fallback: If ID exists in current library (same device), keep it
             final oldInt = int.tryParse(oldIdStr);
             if (oldInt != null && state.allSongs.any((s) => s.id == oldInt)) {
               newFavs.add(oldIdStr);
             }
           }
        }
        debugPrint('[Restore] Restored ${newFavs.length} favorites');
        await prefs.setStringList('favorites_ids', newFavs);
      }

      // 4. Migrate Playlists
      if (data['user_playlists'] != null) {
         final rawPlaylists = data['user_playlists'] as String;
         try {
           final decoded = jsonDecode(rawPlaylists);
           if (decoded is List) {
              final migratedPlaylists = <Map<String, dynamic>>[];
              for (final item in decoded) {
                 if (item is Map<String, dynamic>) {
                    final oldIds = (item['songIds'] as List?) ?? [];
                    final newSongIds = <int>[];
                    
                    for (final oid in oldIds) {
                       final oidStr = oid.toString();
                       if (idMap.containsKey(oidStr)) {
                         newSongIds.add(idMap[oidStr]!);
                       } else {
                          final oldInt = int.tryParse(oidStr);
                          if (oldInt != null && state.allSongs.any((s) => s.id == oldInt)) {
                             newSongIds.add(oldInt);
                          }
                       }
                    }
                    
                    item['songIds'] = newSongIds;
                    migratedPlaylists.add(item);
                    debugPrint('[Restore] Playlist "${item['name']}": ${oldIds.length} -> ${newSongIds.length} songs');
                 }
              }
              await prefs.setString('user_playlists_v2', jsonEncode(migratedPlaylists));
              debugPrint('[Restore] Saved ${migratedPlaylists.length} playlists');
           }
         } catch (e) {
           debugPrint('[Restore] Error migrating playlists: $e');
         }
      }

      // 5. Reload State
      await _loadFavorites();
      await _loadUserPlaylists();
      await _loadPlayStats();
      await _loadCustomArtworkPaths();
      await _loadHideMetadataSaveWarning();
      
      debugPrint('[Restore] Data restoration complete!');
      
    } catch (e) {
      debugPrint('[Restore] Error restoring data: $e');
    }
  }

  /// Restore notification immediately with cached metadata (before songs are loaded)
  Future<void> _restoreNotificationQuickly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final lastTitle = prefs.getString(_keyLastSongTitle);
      final lastArtist = prefs.getString(_keyLastSongArtist);
      final lastArtPath = prefs.getString(_keyLastSongArtPath);
      final lastUri = prefs.getString(_keyLastSongUri);
      final lastDuration = prefs.getInt(_keyLastSongDuration) ?? 0;
      
      if (lastTitle == null || _audioHandler == null) return;
      
      debugPrint('[PlayerCubit] Quick restore: $lastTitle by $lastArtist');
      
      // Create the MediaItem with full info
      final mediaItem = MediaItem(
        id: lastUri ?? 'temp_restore',
        title: lastTitle,
        artist: lastArtist ?? '',
        artUri: lastArtPath != null ? Uri.file(lastArtPath) : null,
        duration: Duration(milliseconds: lastDuration),
      );
      
      // Update notification immediately
      _audioHandler!.setMediaItemWithLikedState(mediaItem, false);
      
      // If we have a valid URI, set up the audio source for playback
      if (lastUri != null && lastUri.isNotEmpty) {
        try {
          await player.setAudioSource(
            AudioSource.uri(
              Uri.parse(lastUri),
              tag: mediaItem,
            ),
          );
          debugPrint('[PlayerCubit] Quick restore: Audio source ready');
          
          // Update widget with current state
          await _pushWidgetUpdate();
        } catch (e) {
          debugPrint('[PlayerCubit] Quick restore audio source error: $e');
        }
      }
    } catch (e) {
      debugPrint('[PlayerCubit] Quick notification restore error: $e');
    }
  }
}





