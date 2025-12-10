import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Custom AudioHandler pour gérer les notifications avec boutons personnalisés
class MusicBoxAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player;
  
  // Callback pour le bouton "J'aime"
  Function(int songId)? onLikePressed;
  
  // Stocker l'état "aimé" de la chanson courante
  bool _isLiked = false;

  MusicBoxAudioHandler(this._player) {
    debugPrint('🎵 AudioHandler créé !');
    
    // Écouter TOUTES les mises à jour pour diffuser l'état
    _player.playbackEventStream.listen(_broadcastState);
    // ✅ Écouter aussi le changement d'état playing pour la barre de progression
    _player.playingStream.listen((_) => _broadcastState(null));
    
    // ✅ Throttle position updates - plus fréquent pour la barre de progression
    Duration lastPosition = Duration.zero;
    _player.positionStream.listen((pos) {
      // Mettre à jour si changement > 200ms pour fluidité
      if ((pos - lastPosition).abs() >= const Duration(milliseconds: 200)) {
        lastPosition = pos;
        _broadcastState(null);
      }
    });

    // ✅ Écouter les changements de séquence pour mettre à jour les métadonnées IMMÉDIATEMENT
    _player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState == null) return;
      final currentItem = sequenceState.currentSource;
      if (currentItem is UriAudioSource && currentItem.tag is MediaItem) {
        final item = currentItem.tag as MediaItem;
        // Ne mettre à jour que si différent pour éviter les boucles
        if (mediaItem.value != item) {
          debugPrint('🎵 AudioHandler: Sync metadata from player source: ${item.title}');
          mediaItem.add(item);
          // Récupérer l'état "aimé" depuis les extras si disponible
          if (item.extras != null && item.extras!.containsKey('isLiked')) {
             updateLikedState(item.extras!['isLiked'] as bool);
          }
          _broadcastState(null);
        }
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
      },
      androidCompactActionIndices: const [0, 2, 3],
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      repeatMode: AudioServiceRepeatMode.none,
      shuffleMode: AudioServiceShuffleMode.none,
    ));
    
    debugPrint('   PlaybackState initial diffusé');
  }
  
  /// Diffuse l'état complet pour la notification native
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
      // Bouton Précédent
      MediaControl.skipToPrevious,
      
      // Bouton J'aime (changera d'icône selon l'état)
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

  /// Mettre à jour l'état "aimé"
  void updateLikedState(bool isLiked) {
    debugPrint('🎵 updateLikedState: $_isLiked → $isLiked');
    _isLiked = isLiked;
    // Rafraîchir les boutons avec le nouvel état
    final currentState = playbackState.value;
    playbackState.add(currentState.copyWith(
      controls: _getControls(currentState.playing, isLiked),
    ));
    debugPrint('   Boutons mis à jour');
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
      debugPrint('🎵 Bouton cœur cliqué');
      // Récupérer le songId depuis le MediaItem actuel
      final item = mediaItem.value;
      if (item != null && item.extras != null) {
        final songId = item.extras!['songId'];
        if (songId != null && onLikePressed != null) {
          debugPrint('   SongId: $songId, État actuel: $_isLiked');
          // NE PAS basculer ici, laisser PlayerCubit gérer
          onLikePressed!(songId as int);
          // PlayerCubit va appeler setMediaItemWithLikedState avec le nouvel état
        }
      }
    }
    return super.customAction(name, extras);
  }

  /// Mettre à jour le MediaItem courant avec l'état "aimé"
  void setMediaItemWithLikedState(MediaItem item, bool isLiked) {
    debugPrint('🎵 AudioHandler.setMediaItemWithLikedState');
    debugPrint('   Title: ${item.title}');
    debugPrint('   ArtUri: ${item.artUri}');
    debugPrint('   Liked: $isLiked');
    
    mediaItem.add(item);
    updateLikedState(isLiked);
    
    // Diffuser l'état complet
    _broadcastState(null);
    
    debugPrint('   PlaybackState: playing=${playbackState.value.playing}, controls=${playbackState.value.controls.length}');
  }

  /// Mettre à jour la liste des chansons
  void setQueueItems(List<MediaItem> items) {
    queue.add(items);
  }
}
