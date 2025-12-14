import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:music_box/generated/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_box/player/player_cubit.dart';

class DataBackupService {
  
  static const String _backupVersion = '1.0';

  /// Créer une sauvegarde et proposer de la partager/sauvegarder
  static Future<bool> createBackup(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Access Cubit for smart backup (metadata)
      // ignore: use_build_context_synchronously
      final cubit = BlocProvider.of<PlayerCubit>(context);
      final allSongs = cubit.state.allSongs;
      
      // Build metadata cache for smart restoration (migration across devices)
      final metadataCache = <String, Map<String, dynamic>>{};
      for (final s in allSongs) {
        metadataCache[s.id.toString()] = {
          't': s.title,
          'a': s.artist,
          'al': s.album,
        };
      }

      final allData = <String, dynamic>{
        'version': _backupVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'favorites': prefs.getStringList('favorites_ids') ?? [],
        'play_counts': prefs.getString('play_counts'),
        'last_played': prefs.getString('last_played'),
        'user_playlists': prefs.getString('user_playlists_v2'),
        'hidden_folders': prefs.getString('hidden_folders'),
        'show_hidden_folders': prefs.getBool('show_hidden_folders'),
        'custom_artwork_paths': prefs.getString('custom_artwork_paths'),
        'metadata_overrides': prefs.getString('metadata_overrides'),
        'hide_meta_warning': prefs.getBool('hide_meta_warning'),
        'song_metadata_cache': metadataCache, // ✅ Added for migration
      };

      final jsonString = jsonEncode(allData);
      
      // Sauvegarder dans un fichier temporaire
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'MusicBox_Backup_$dateStr.json';
      final file = File('${tempDir.path}/$fileName');
      
      await file.writeAsString(jsonString);

      // Partager le fichier (permet de l'enregistrer dans Drive, Gmail, ou localement)
      // ignore: use_build_context_synchronously
      final l10n = AppLocalizations.of(context)!;
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: l10n.backupSubject,
        text: l10n.backupBody(dateStr),
      );
      
      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('Backup error: $e');
      return false;
    }
  }

  /// Lire une sauvegarde depuis un fichier (sans l'appliquer)
  static Future<Map<String, dynamic>?> pickBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return null;

      final path = result.files.single.path;
      if (path == null) return null;

      final file = File(path);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);
      
      // Basic validation
      if (data is! Map<String, dynamic> || !data.containsKey('version')) {
        throw Exception('Invalid backup file format');
      }

      return data;
    } catch (e) {
      debugPrint('Restore error: $e');
      return null;
    }
  }
}
