import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Custom AudioHandler pour gÃ©rer les notifications avec boutons personnalisÃ©s
class MusicBoxAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player;
  
  // Callback pour le bouton "J'aime"
  Function(int songId)? onLikePressed;
  
  // Stocker l'Ã©tat "aimÃ©" de la chanson courante
  bool _isLiked = false;

  MusicBoxAudioHandler(this._player) {
    debugPrint('ðŸŽµ AudioHandler crÃ©Ã© !');
    
    // Restaurer l'Ã©tat depuis le stockage (pour affichage immÃ©diat en arriÃ¨re-plan)
    _restoreLastState();

    // Ã‰couter TOUTES les mises Ã  jour pour diffuser l'Ã©tat
    _player.playbackEventStream.listen(_broadcastState);
    // âœ… Ã‰couter aussi le changement d'Ã©tat playing pour la barre de progression
    _player.playingStream.listen((_) => _broadcastState(null));
    
    // âœ… Throttle position updates - plus frÃ©quent pour la barre de progression
    Duration lastPosition = Duration.zero;
    _player.positionStream.listen((pos) {
      // Mettre Ã  jour si changement > 200ms pour fluiditÃ©
      if ((pos - lastPosition).abs() >= const Duration(milliseconds: 200)) {
        lastPosition = pos;
        _broadcastState(null);
      }
    });

    // Initialiser le playback state avec systemActions
    playbackState.add(PlaybackState(
      playing: false,
      processingState: AudioProcessingState.idle,
      controls: _getControls(false, false),
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.stop, // âœ… Allow stopping handling
      },
      androidCompactActionIndices: const [0, 2, 3],
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      repeatMode: AudioServiceRepeatMode.none,
      shuffleMode: AudioServiceShuffleMode.none,
    ));
    
    debugPrint('   PlaybackState initial diffusÃ©');
  }

  /// Restaurer le dernier Ã©tat connu (chanson) pour Ã©viter la notification vide
  Future<void> _restoreLastState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSongId = prefs.getInt('last_song_id'); // Key from PlayerCubit
      
      debugPrint('ðŸŽµ AudioHandler: Attempting to restore last song ID: $lastSongId');

      if (lastSongId != null) {
        final onAudioQuery = OnAudioQuery();
        
        // Optimisation: Try to find specific song
        List<SongModel> songs = [];
        try {
           // On Android, this runs in main isolate so context should be implicit/valid
           songs = await onAudioQuery.querySongs(
            ignoreCase: true,
            orderType: OrderType.ASC_OR_SMALLER,
            sortType: null,
            uriType: UriType.EXTERNAL,
          );
        } catch (e) {
           debugPrint('âŒ AudioHandler: Query failed: $e');
        }

        try {
           final song = songs.firstWhere((s) => s.id == lastSongId, orElse: () => SongModel({}));
           
           if (song.id == 0) {
             debugPrint('âŒ AudioHandler: Song $lastSongId not found in library of ${songs.length} songs');
             return;
           }

           debugPrint('âœ… AudioHandler: Found song: ${song.title}');

           // Create MediaItem for notification
           final item = MediaItem(
              id: song.uri ?? song.id.toString(), // Use URI as ID if available
              title: song.title,
              artist: song.artist ?? 'Inconnu',
              album: song.album ?? '',
              artUri: Uri.parse('content://media/external/audio/media/${song.id}/albumart'),
              duration: Duration(milliseconds: song.duration ?? 0),
              extras: {'songId': song.id},
           );
           
           // âœ… Update MediaItem IMMEDIATELY for notification display
           mediaItem.add(item);
           
           // Update state to Ready (Paused) so notification appears correctly
           playbackState.add(playbackState.value.copyWith(
              processingState: AudioProcessingState.ready,
              playing: false,
              controls: _getControls(false, _isLiked),
              updatePosition: Duration.zero,
              bufferedPosition: Duration.zero,
           ));
           
           // âš ï¸ DO NOT set audio source here - let PlayerCubit handle it
           // to avoid race conditions and ensure _playlist is properly tracked.
           debugPrint('âœ… AudioHandler: MediaItem set for notification (source will be loaded by PlayerCubit)');
        } catch (e) {
           debugPrint('âŒ AudioHandler: Logic error: $e');
        }
      } else {
        debugPrint('â„¹ï¸ AudioHandler: No last song ID found');
      }
    } catch (e) {
      debugPrint('âŒ AudioHandler: Error restoring state: $e');
    }
  }
  
  /// Diffuse l'Ã©tat complet pour la notification native
  void _broadcastState(PlaybackEvent? event) {
    final playing = _player.playing;
    final processingState = _mapProcessingState(_player.processingState);
    final buffered = _player.bufferedPosition;
    final position = _player.position;
    
    playbackState.add(playbackState.value.copyWith(
      playing: playing,
      processingState: processingState,
      controls: _getControls(playing, _isLiked),
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 2, 3],
      updatePosition: position,
      bufferedPosition: buffered,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
      repeatMode: AudioServiceRepeatMode.none,
      shuffleMode: AudioServiceShuffleMode.none,
    ));
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  List<MediaControl> _getControls(bool playing, bool isLiked) {
    return [
      // Bouton PrÃ©cÃ©dent
      MediaControl.skipToPrevious,
      
      // Bouton J'aime (changera d'icÃ´ne selon l'Ã©tat)
      MediaControl.custom(
        androidIcon: isLiked ? 'drawable/ic_heart_filled' : 'drawable/ic_heart_outline',
        label: isLiked ? 'Ne plus aimer' : 'J\'aime',
        name: 'like',
      ),
      
      // Bouton Play/Pause
      playing ? MediaControl.pause : MediaControl.play,
      
      // Bouton Suivant
      MediaControl.skipToNext,
    ];
  }

  /// Mettre Ã  jour l'Ã©tat "aimÃ©"
  void updateLikedState(bool isLiked) {
    debugPrint('ðŸŽµ updateLikedState: $_isLiked â†’ $isLiked');
    _isLiked = isLiked;
    // RafraÃ®chir les boutons avec le nouvel Ã©tat
    final currentState = playbackState.value;
    playbackState.add(currentState.copyWith(
      controls: _getControls(currentState.playing, isLiked),
    ));
    debugPrint('   Boutons mis Ã  jour');
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'like') {
      debugPrint('ðŸŽµ Bouton cÅ“ur cliquÃ©');
      // RÃ©cupÃ©rer le songId depuis le MediaItem actuel
      final item = mediaItem.value;
      if (item != null && item.extras != null) {
        final songId = item.extras!['songId'];
        if (songId != null && onLikePressed != null) {
          debugPrint('   SongId: $songId, Ã‰tat actuel: $_isLiked');
          // NE PAS basculer ici, laisser PlayerCubit gÃ©rer
          onLikePressed!(songId as int);
          // PlayerCubit va appeler setMediaItemWithLikedState avec le nouvel Ã©tat
        }
      }
    }
    return super.customAction(name, extras);
  }

  /// Mettre Ã  jour le MediaItem courant avec l'Ã©tat "aimÃ©"
  void setMediaItemWithLikedState(MediaItem item, bool isLiked) {
    debugPrint('ðŸŽµ AudioHandler.setMediaItemWithLikedState');
    debugPrint('   Title: ${item.title}');
    debugPrint('   ArtUri: ${item.artUri}');
    debugPrint('   Liked: $isLiked');
    
    mediaItem.add(item);
    updateLikedState(isLiked);
    
    // Diffuser l'Ã©tat complet
    _broadcastState(null);
    
    debugPrint('   PlaybackState: playing=${playbackState.value.playing}, controls=${playbackState.value.controls.length}');
  }

  /// Mettre Ã  jour la file d'attente (pour les notifications/wearables)
  void setQueueItems(List<MediaItem> items) {
    queue.add(items);
  }

  /// âœ… CRITICAL FIX: NE PAS arrÃªter le service quand l'app est fermÃ©e depuis rÃ©cents !
  /// Laisser le foreground service continuer pour que la musique joue en arriÃ¨re-plan.
  /// Le service s'arrÃªtera seulement quand l'utilisateur appuie explicitement sur Stop
  /// ou quand la lecture se termine naturellement.
  @override
  Future<void> onTaskRemoved() async {
    debugPrint('ðŸŽµ AudioHandler.onTaskRemoved - App fermÃ©e, MAIS service audio continue !');
    // NE PAS appeler stop() ici ! Le service doit continuer Ã  jouer.
    // await stop(); â† SUPPRIMÃ‰ - c'Ã©tait la cause du bug !
  }

  // Les Ã©vÃ©nements headset/bluetooth (click, double click) sont mappÃ©s par Android en
  // MediaAction.play/pause/skipToNext...
  // audio_service gÃ¨re le mapping "Double Click -> skipToNext" automatiquement sur Android.
}


