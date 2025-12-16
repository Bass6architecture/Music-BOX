import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:image_picker/image_picker.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:music_box/generated/app_localizations.dart';
// Cover Art
import 'package:path_provider/path_provider.dart';
import 'cover_art_search_page.dart';

import '../player/player_cubit.dart';
import '../widgets/optimized_artwork.dart';

// Channel for native actions we still use (ringtone, delete notifications)
const MethodChannel _nativeChannel = MethodChannel('com.synergydev.music_box/native');
bool _coverCallbacksInitialized = false;

void _ensureCoverCallbacks(BuildContext context) {
  if (_coverCallbacksInitialized) {
    debugPrint('🔄 Callbacks déjà initialisés');
    return;
  }
  debugPrint('🔄 Initialisation des callbacks...');
  _nativeChannel.setMethodCallHandler((call) async {
    debugPrint('🔔 Callback reçu: ${call.method} avec arguments: ${call.arguments}');
    switch (call.method) {
      case 'onDeleteCompleted':
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.fileDeleted)),
          );
        }
        break;
      case 'onAlbumArtWritten':
        final success = call.arguments['success'] as bool?;
        debugPrint('🔔 onAlbumArtWritten: success=$success, context.mounted=${context.mounted}');
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          if (success == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${l10n.coverSaved}'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${l10n.coverFailed}'),
              ),
            );
          }
        }
        break;
      case 'onMetadataWritten':
        final success = call.arguments['success'] as bool?;
        debugPrint('🔔 onMetadataWritten: success=$success, context.mounted=${context.mounted}');
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          if (success == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${l10n.metadataSaved}'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${l10n.metadataFailed}'),
              ),
            );
          }
        }
      case 'onRequestPermissionResult':
        // Just log for now, or use if we keep the callback approach.
        // But better to switch to Future-based approach.
        debugPrint('🔔 Authorization result: ${call.arguments}');
        break;
    }
  });
  _coverCallbacksInitialized = true;
  debugPrint('✅ Callbacks initialisés');
}

// System-wide metadata updates removed on user request (Android 14/15 restrictions).

Widget _buildActionTile({
  required ThemeData theme,
  required IconData icon,
  required Color iconColor,
  required String title,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> openSongActionsSheet(BuildContext context, SongModel song) async {
  // Initialiser les callbacks dès l'ouverture
  _ensureCoverCallbacks(context);
  
  final cubit = context.read<PlayerCubit>();
  final theme = Theme.of(context);
  final artist = (song.artist ?? '').trim();
  final album = (song.album ?? '').trim();
  final isFav = cubit.isFavorite(song.id);

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: false,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // FIXED HEADER: Handle personnalisé
              const SizedBox(height: 12),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              // FIXED HEADER: Artwork et info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: OptimizedArtwork.square(
                            id: song.id,
                            type: ArtworkType.AUDIO,
                            size: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (artist.isNotEmpty)
                            Text(
                              artist,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (album.isNotEmpty)
                            Text(
                              album,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 4),

              // SCROLLABLE ACTIONS LIST
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Section: File d'attente (sauf si chanson en cours)
                      if (cubit.state.currentSongId != song.id) ...[
                        _buildActionTile(
                          theme: theme,
                          icon: Icons.playlist_play_rounded,
                          iconColor: theme.colorScheme.onSurfaceVariant,
                          title: AppLocalizations.of(context)!.playNext,
                          onTap: () async {
                            Navigator.pop(ctx);
                            await cubit.addToQueue([song], playNext: true);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.scheduledNext)),
                              );
                            }
                          },
                        ),
                        _buildActionTile(
                          theme: theme,
                          icon: Icons.queue_music_rounded,
                          iconColor: theme.colorScheme.onSurfaceVariant,
                          title: AppLocalizations.of(context)!.addToQueueFull,
                          onTap: () async {
                            Navigator.pop(ctx);
                            await cubit.addToQueue([song]);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.addedToQueue)),
                              );
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                        ),
                      ],

                      // Section: Personnalisation
                      _buildActionTile(
                        theme: theme,
                        icon: Icons.playlist_add_rounded,
                        iconColor: theme.colorScheme.onSurfaceVariant,
                        title: AppLocalizations.of(context)!.addToPlaylist,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _openAddToPlaylist(context, cubit, song);
                        },
                      ),
                      _buildActionTile(
                        theme: theme,
                        icon: Icons.image_rounded,
                        iconColor: theme.colorScheme.onSurfaceVariant,
                        title: AppLocalizations.of(context)!.changeCover,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _changeCover(context, cubit, song);
                        },
                      ),
                        _buildActionTile(
                          theme: theme,
                          icon: Icons.edit_rounded,
                          iconColor: theme.colorScheme.onSurfaceVariant,
                          title: AppLocalizations.of(context)!.editMetadata,
                          onTap: () async {
                            Navigator.pop(ctx);
                            // Pre-request permission (Android 10+)
                            if (Platform.isAndroid) {
                              try {
                                await _nativeChannel.invokeMethod('requestWritePermission', {'audioId': song.id});
                                // If we don't await the result from native properly (if strict await implemented),
                                // we might want to delay slightly or just proceed.
                                // Current impl returns immediately, so this is "fire and forget" or "fire and hope it blocks".
                                // To block, I need to update MainActivity.kt first.
                                // For now, I'll add the call.
                              } catch (_) {}
                            }
                            await _editMetadata(context, cubit, song);
                          },
                        ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      
                      // Section: Actions
                      _buildActionTile(
                        theme: theme,
                        icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        iconColor: isFav ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        title: isFav ? AppLocalizations.of(context)!.removeFromFavorites : AppLocalizations.of(context)!.addToFavorites,
                        onTap: () {
                          Navigator.pop(ctx);
                          cubit.toggleFavoriteById(song.id);
                        },
                      ),
                      _buildActionTile(
                        theme: theme,
                        icon: Icons.share_rounded,
                        iconColor: theme.colorScheme.onSurfaceVariant,
                        title: AppLocalizations.of(context)!.share,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _shareSong(context, song);
                        },
                      ),
                      _buildActionTile(
                        theme: theme,
                        icon: Icons.folder_open_rounded,
                        iconColor: theme.colorScheme.onSurfaceVariant,
                        title: AppLocalizations.of(context)!.goToAlbum,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _openInFiles(context, song);
                        },
                      ),
                      if (Platform.isAndroid)
                        _buildActionTile(
                          theme: theme,
                          icon: Icons.notifications_rounded,
                          iconColor: theme.colorScheme.onSurfaceVariant,
                          title: AppLocalizations.of(context)!.setAsRingtone,
                          onTap: () async {
                            Navigator.pop(ctx);
                            await _setAsRingtone(context, song);
                          },
                        ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, thickness: 1.5, color: theme.colorScheme.error.withValues(alpha: 0.2)),
                      ),
                      
                      // Action dangereuse
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Material(
                          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await _deleteAudioFile(context, cubit, song);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.delete_forever_rounded,
                                      color: theme.colorScheme.error,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!.deleteSong,
                                          style: TextStyle(
                                            color: theme.colorScheme.error,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          AppLocalizations.of(context)!.confirmDeleteSong,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.error.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _openAddToPlaylist(BuildContext context, PlayerCubit cubit, SongModel song) async {
  final playlists = cubit.state.userPlaylists;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: false,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(AppLocalizations.of(context)!.createPlaylist),
            onTap: () async {
              Navigator.pop(ctx);
              final l10n = AppLocalizations.of(context)!;
              final name = await _promptForText(context, title: l10n.createPlaylist, hint: l10n.playlistNameHint);
              if (name != null && name.trim().isNotEmpty) {
                final id = cubit.createUserPlaylist(name.trim());
                cubit.addSongToUserPlaylist(id, song.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.songAdded)));
                }
              }
            },
          ),
          const Divider(height: 1),
          SizedBox(
            height: math.min(MediaQuery.of(context).size.height * 0.5, 420),
            child: ListView.builder(
              itemCount: playlists.length,
              itemBuilder: (_, i) {
                final p = playlists[i];
                return ListTile(
                  leading: const Icon(Icons.queue_music),
                  title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(AppLocalizations.of(context)!.songCount(p.songIds.length)),
                  onTap: () {
                    cubit.addSongToUserPlaylist(p.id, song.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.songAdded)));
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}


Future<void> _changeCover(BuildContext context, PlayerCubit cubit, SongModel song) async {
  // Initialiser les callbacks en premier
  _ensureCoverCallbacks(context);
  
  try {
    // Cache theme before async gaps
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // 1. Ask for source: Gallery or Web
    final source = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.selectSource,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(l10n.localGallery),
              onTap: () => Navigator.pop(ctx, 0), // 0 = Gallery
            ),
            ListTile(
              leading: const Icon(Icons.public_rounded),
              title: Text(l10n.searchOnInternet),
              onTap: () => Navigator.pop(ctx, 1), // 1 = Web
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return; // Cancelled

    String? sourcePath;

    if (source == 0) {
      // Gallery
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 4096, maxHeight: 4096, imageQuality: 95);
      if (picked != null) sourcePath = picked.path;
    } else {
      // Web Search
      if (context.mounted) {
        final imageBytes = await Navigator.push<Uint8List>(
          context, 
          MaterialPageRoute(
            builder: (_) => CoverArtSearchPage(
              artist: song.artist ?? '',
              title: song.title,
            ),
          ),
        );

        if (imageBytes != null) {
          // Write to temp file
          final temp = await getTemporaryDirectory();
          final file = File('${temp.path}/web_cover_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await file.writeAsBytes(imageBytes);
          sourcePath = file.path;
        }
      }
    }

    if (sourcePath == null) return; // No image selected
    if (!context.mounted) return;

    // Pre-request permission (Android 10+)
    if (Platform.isAndroid) {
       try {
         await _nativeChannel.invokeMethod('requestWritePermission', {'audioId': song.id});
       } catch (_) {}
    }

    // Laisser l'utilisateur recadrer en 1:1 (UI native), pas d'autres ratios
    CroppedFile? cropped;
    try {
      cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 92,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: l10n.crop,
            toolbarColor: theme.colorScheme.surface,
            toolbarWidgetColor: theme.colorScheme.primary,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
        ],
      );
    } catch (_) {}

    final path = (cropped?.path ?? sourcePath);
    final bytes = await File(path).readAsBytes();

    // D'abord appliquer localement dans l'app
    await cubit.setCustomArtworkBytes(song.id, bytes, ext: '.jpg');
    
    // Vider le cache d'images pour forcer le rafraîchissement
    if (context.mounted) {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    }
    
    // Enregistrer directement dans le système (pas de choix)
    if (context.mounted && Platform.isAndroid) {
      try {
        debugPrint('📸 Appel writeAlbumArt pour song.id=${song.id}');
        final success = await _nativeChannel.invokeMethod('writeAlbumArt', {
          'audioId': song.id,
          'imagePath': path,
        });
        
        debugPrint('📸 Résultat writeAlbumArt: $success');
        
        // Si success == false, échec immédiat
        if (context.mounted && success == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.requiresAndroid10),
              backgroundColor: Colors.orange,
            ),
          );
        }
        // Si success == null, on attend la permission (le callback affichera le message)
      } catch (e) {
        debugPrint('❌ Erreur lors de l\'écriture de la cover');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.imageUpdated)),
      );
    }
  } catch (e) {
    // Silencieux: en local seulement, pas d'erreur intrusive
  }
} // End _changeCover

// plus de recadrage automatique — l'utilisateur choisit la zone en 1:1 via ImageCropper

Future<void> _shareSong(BuildContext context, SongModel song) async {
  try {
    // Get the URI from MediaStore (Android 10+ doesn't provide file paths)
    final uri = song.uri;
    if (uri == null || uri.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.uriNotFound)),
        );
      }
      return;
    }
    
    if (!Platform.isAndroid) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.androidOnly)),
        );
      }
      return;
    }
    
    // Use native method channel to share with proper permissions
    const platform = MethodChannel('com.synergydev.music_box/native');
    await platform.invokeMethod('shareAudioFile', {
      'uri': uri,
      'title': song.title,
    });
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: ${e.toString()}')),
      );
    }
  }
}

Future<void> _openInFiles(BuildContext context, SongModel song) async {
  if (!Platform.isAndroid) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.androidOnly)));
    return;
  }
  
  final uri = song.uri;
  if (uri == null || uri.isEmpty || !uri.startsWith('content://')) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.error)));
    }
    return;
  }
  
  // Extraire le chemin du dossier depuis l'URI
  try {
    // Obtenir le chemin réel via le canal natif
    final realPath = await _nativeChannel.invokeMethod<String>('getRealPath', {'uri': uri});
    
    if (realPath == null || realPath.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.error)),
        );
      }
      return;
    }
    
    // Obtenir le dossier parent
    final file = File(realPath);
    final folder = file.parent.path;
    
    debugPrint('📂 Ouverture du dossier: $folder');
    
    // Essayer d'ouvrir dans l'explorateur de fichiers
    bool intentLaunched = false;
    
    // Méthode 1: Utiliser ACTION_VIEW avec le fichier pour ouvrir son dossier
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'file://$realPath',
        type: 'audio/*',
        flags: <int>[0x10000000], // FLAG_ACTIVITY_NEW_TASK
      );
      await intent.launch();
      intentLaunched = true;
      debugPrint('✅ Dossier ouvert avec ACTION_VIEW');
    } catch (e1) {
      debugPrint('❌ Méthode 1 (VIEW) échouée: $e1');
      
      // Méthode 2: Construire l'URI Documents correctement
      try {
        // Encoder le chemin correctement pour Documents UI
        String documentPath = folder.replaceFirst('/storage/emulated/0/', '');
        // URL encoder le chemin pour éviter les problèmes avec les caractères spéciaux
        documentPath = Uri.encodeComponent(documentPath);
        
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'content://com.android.externalstorage.documents/document/primary:$documentPath',
          type: 'vnd.android.document/directory',
          flags: <int>[0x10000000, 0x00000001], // FLAG_ACTIVITY_NEW_TASK | FLAG_GRANT_READ_URI_PERMISSION
        );
        await intent.launch();
        intentLaunched = true;
        debugPrint('✅ Dossier ouvert avec Documents UI');
      } catch (e2) {
        debugPrint('❌ Méthode 2 (Documents) échouée: $e2');
        
        // Méthode 3: Ouvrir le gestionnaire de fichiers générique
        try {
          final intent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            type: 'resource/folder',
            flags: <int>[0x10000000],
          );
          await intent.launch();
          intentLaunched = true;
          debugPrint('✅ Gestionnaire de fichiers ouvert');
        } catch (e3) {
          debugPrint('❌ Méthode 3 (gestionnaire) échouée: $e3');
        }
      }
    }
    
    // Si aucun intent n'a marché, afficher le chemin
    if (!intentLaunched) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.openLocation}: ${folder.split('/').last}'),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.copyPath,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: folder));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.pathCopied)),
                );
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorOpeningFolder)),
      );
    }
  }
}

Future<void> _setAsRingtone(BuildContext context, SongModel song) async {
  if (!Platform.isAndroid) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.androidOnly)),
    );
    return;
  }
  
  // Show confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.ringtoneTitle),
      content: Text(AppLocalizations.of(context)!.setRingtoneConfirm(song.title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(AppLocalizations.of(context)!.confirm),
        ),
      ],
    ),
  );
  
  if (confirmed != true) return;
  
  try {
    final uri = song.uri;
    if (uri == null || uri.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.uriNotFound)),
        );
      }
      return;
    }
    
    // Use native channel to set ringtone
    await _nativeChannel.invokeMethod('setRingtone', {
      'uri': uri,
      'title': song.title,
      'type': 'ringtone',
    });
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.ringtoneSetSuccess)),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    }
  }
}

Future<void> _editMetadata(BuildContext context, PlayerCubit cubit, SongModel song) async {
  // Initialiser les callbacks en premier
  _ensureCoverCallbacks(context);
  
  // Avertissement supprimé: on ouvre directement l'éditeur (modification locale uniquement).

  // 1) Formulaire d'édition (pré-rempli)
  final applied = cubit.applyOverrides(song);
  final titleCtrl = TextEditingController(text: applied.title);
  final artistCtrl = TextEditingController(text: applied.artist);
  final albumCtrl = TextEditingController(text: applied.album);
  final genreCtrl = TextEditingController();
  final yearCtrl = TextEditingController();

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      
      return AnimatedPadding(
        padding: MediaQuery.of(ctx).viewInsets,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle personnalisé
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Artwork circulaire
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: OptimizedArtwork.square(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        size: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Titre
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    AppLocalizations.of(context)!.editArtistInfo,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Champs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.title,
                          prefixIcon: Icon(Icons.music_note_rounded, color: theme.colorScheme.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: artistCtrl,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.artist,
                          prefixIcon: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: albumCtrl,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.album,
                          prefixIcon: Icon(Icons.album_rounded, color: theme.colorScheme.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: genreCtrl,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.genreOptional,
                          prefixIcon: Icon(Icons.category_rounded, color: theme.colorScheme.secondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: yearCtrl,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.yearOptional,
                          prefixIcon: Icon(Icons.calendar_today_rounded, color: theme.colorScheme.secondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Boutons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(AppLocalizations.of(context)!.save),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
          ),
        );
    },
  );

  if (confirmed != true) return;

  // 2) Appliquer immédiatement dans l'app (fluide)
  final overrides = LocalMetadataOverrides(
    title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
    artist: artistCtrl.text.trim().isEmpty ? null : artistCtrl.text.trim(),
    album: albumCtrl.text.trim().isEmpty ? null : albumCtrl.text.trim(),
    genre: genreCtrl.text.trim().isEmpty ? null : genreCtrl.text.trim(),
    year: int.tryParse(yearCtrl.text.trim()),
  );
  await cubit.setMetadataOverride(song.id, overrides);

  // 3) Enregistrer directement dans le système (pas de choix)
  if (context.mounted && Platform.isAndroid) {
    try {
      debugPrint('📝 Appel writeMetadata pour song.id=${song.id}');
      final success = await _nativeChannel.invokeMethod('writeMetadata', {
        'audioId': song.id,
        'title': titleCtrl.text.trim(),
        'artist': artistCtrl.text.trim(),
        'album': albumCtrl.text.trim(),
        'genre': genreCtrl.text.trim(),
        'year': yearCtrl.text.trim(),
      });

      debugPrint('📝 Résultat writeMetadata: $success');

      if (context.mounted && success == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.android10Required),
            backgroundColor: Colors.orange,
          ),
        );
      }
      // Si success == null, on attend la permission (le callback affichera le message)
    } catch (e) {
      debugPrint('📝 Erreur writeMetadata: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorWithDetails(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.changesSaved)),
    );
  }
}

Future<String?> _promptForText(
  BuildContext context, {
  required String title,
  String? hint,
  String? initialValue,
}) async {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: hint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    ),
  );
}

Future<void> _deleteAudioFile(BuildContext context, PlayerCubit cubit, SongModel song) async {
  final theme = Theme.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Icon(
        Icons.delete_forever,
        color: theme.colorScheme.error,
        size: 48,
      ),
      title: Text(
        AppLocalizations.of(context)!.deletePermanently,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.deleteWarningMessage,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.music_note, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    song.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.deleteStorageWarning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(AppLocalizations.of(context)!.delete),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    // Utiliser le canal natif pour supprimer via MediaStore
    await _nativeChannel.invokeMethod('deleteAudio', {'audioId': song.id});
    
    // Retirer de la queue si présent et de la playlist (Robust)
    await cubit.removeSongsById([song.id]);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(AppLocalizations.of(context)!.fileDeletedPermanently)),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(_simplifyErrorMessage(e, context))),
            ],
          ),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

/// Simplifier les messages d'erreur techniques
String _simplifyErrorMessage(dynamic error, BuildContext context) {
  final errorStr = error.toString().toLowerCase();
  final l10n = AppLocalizations.of(context)!;
  
  if (errorStr.contains('permission') || errorStr.contains('denied')) {
    return l10n.errorPermissionDenied;
  }
  if (errorStr.contains('not found') || errorStr.contains('no such')) {
    return l10n.errorFileNotFound;
  }
  if (errorStr.contains('storage') || errorStr.contains('space')) {
    return l10n.errorInsufficientStorage;
  }
  if (errorStr.contains('network') || errorStr.contains('connection')) {
    return l10n.errorNetworkProblem;
  }
  if (errorStr.contains('format') || errorStr.contains('corrupt')) {
    return l10n.errorCorruptFile;
  }
  
  return l10n.errorGeneric;
}
