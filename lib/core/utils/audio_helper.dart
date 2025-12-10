import 'package:on_audio_query/on_audio_query.dart';

class AudioHelper {
  static String formatDuration(int? milliseconds) {
    if (milliseconds == null) return '0:00';
    
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  
  static String formatTotalDuration(List<SongModel> songs) {
    final totalMs = songs.fold<int>(
      0, 
      (total, song) => total + (song.duration ?? 0),
    );
    
    final duration = Duration(milliseconds: totalMs);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours h $minutes min';
    } else {
      return '$minutes minutes';
    }
  }
  
  static String formatFileSize(int? bytes) {
    if (bytes == null) return '';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }
  
  static String getArtistDisplay(String? artist) {
    return artist?.isNotEmpty == true ? artist! : 'Artiste inconnu';
  }
  
  static String getAlbumDisplay(String? album) {
    return album?.isNotEmpty == true ? album! : 'Album inconnu';
  }
}
