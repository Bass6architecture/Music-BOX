// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Music Box';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get share => 'Share';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get removeFromList => 'Remove from list';

  @override
  String get playlistSongRemoved => 'Song removed from playlist';

  @override
  String get search => 'Search';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get songs => 'Songs';

  @override
  String get playlists => 'Playlists';

  @override
  String get albums => 'Albums';

  @override
  String get artists => 'Artists';

  @override
  String get folders => 'Folders';

  @override
  String get settings => 'Settings';

  @override
  String get nowPlaying => 'Now Playing';

  @override
  String get yourPlaylists => 'Your Playlists';

  @override
  String get favorites => 'Favorites';

  @override
  String get recentlyAdded => 'Recently added';

  @override
  String get recentlyPlayed => 'Recently played';

  @override
  String get mostPlayed => 'Most played';

  @override
  String get forYou => 'For You';

  @override
  String get quickPlay => 'Quick Play';

  @override
  String get playMix => 'Play Mix';

  @override
  String songsReady(int count) {
    return '$count songs ready';
  }

  @override
  String get discover => 'Discover';

  @override
  String get listeningHabits => 'On Repeat';

  @override
  String get forgottenGems => 'Forgotten Gems';

  @override
  String get allTimeHits => 'Timeless';

  @override
  String get explore => 'Explore';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get audio => 'Audio';

  @override
  String get library => 'Library';

  @override
  String get about => 'About';

  @override
  String get theme => 'Theme';

  @override
  String get themeDescription => 'Application theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeSystemDesc => 'Follow phone theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeLightDesc => 'Always light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeDarkDesc => 'Always dark';

  @override
  String get language => 'Language';

  @override
  String get languageDescription => 'Application language';

  @override
  String get currentLanguage => 'English';

  @override
  String get languageSystem => 'System Language';

  @override
  String get languageSystemDesc => 'Follow system language';

  @override
  String get languageAlreadySelected => 'English already selected';

  @override
  String get languageComingSoon => 'Coming soon';

  @override
  String get languageChanged => 'Language changed';

  @override
  String get languageNeedsRestart => 'Restart required to apply language';

  @override
  String get restartNow => 'Restart now';

  @override
  String get restartLater => 'Later';

  @override
  String get equalizer => 'Equalizer';

  @override
  String get equalizerDesc => 'Adjust bass and treble';

  @override
  String get equalizerEnabled => 'Enable Equalizer';

  @override
  String get equalizerDisabled => 'Equalizer Disabled';

  @override
  String get noEqualizerFound => 'No equalizer found on this device';

  @override
  String get background => 'Background';

  @override
  String get backgroundDesc => 'Customize app background';

  @override
  String get backgroundNone => 'None';

  @override
  String get backgroundGradientMusical => 'Musical gradient';

  @override
  String get backgroundGradientDark => 'Dark gradient';

  @override
  String get backgroundParticles => 'Particles';

  @override
  String get backgroundWaves => 'Sound waves';

  @override
  String get backgroundNeonCity => 'Neon city';

  @override
  String get backgroundVinylSunset => 'Vinyl sunset';

  @override
  String get backgroundAuroraRhythm => 'Aurora rhythm';

  @override
  String get backgroundPlayback => 'Background playback';

  @override
  String get backgroundPlaybackDesc =>
      'Disable battery optimization for smooth playback';

  @override
  String get batteryOptimizationTitle => 'Stop battery optimization?';

  @override
  String get batteryOptimizationMessage =>
      'Music Box will be allowed to run in the background. Battery usage will not be restricted.';

  @override
  String get batteryOptimizationEnabled => '✓ Battery optimization disabled';

  @override
  String get batteryOptimizationDisabled =>
      '⚠️ Battery optimization enabled (may cause interruptions)';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsDesc => 'Notification settings';

  @override
  String get cannotOpenSettings => 'Cannot open settings';

  @override
  String get androidOnly => 'Android only';

  @override
  String get scanMusic => 'Scan music';

  @override
  String get scanMusicDesc => 'Detect missing tracks';

  @override
  String get hiddenFolders => 'Hidden folders';

  @override
  String get hiddenFoldersDesc => 'Manage hidden folders';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicyDesc => 'View our privacy policy';

  @override
  String get contact => 'Contact';

  @override
  String get contactDesc => 'synergydev.official@gmail.com';

  @override
  String get cannotOpenPrivacyPolicy => 'Cannot open privacy policy';

  @override
  String get cannotOpenEmail => 'Cannot open email app';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get repeat => 'Repeat';

  @override
  String get playNext => 'Play next';

  @override
  String get playAll => 'Play all';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get addToQueueFull => 'Add to queue';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get addToMyPlaylists => 'Add to MY playlists';

  @override
  String get removeFromPlaylist => 'Remove from playlist';

  @override
  String get removeFromHistory => 'Remove from history';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get goToAlbum => 'Go to album';

  @override
  String get goToArtist => 'Go to artist';

  @override
  String get setAsRingtone => 'Set as ringtone';

  @override
  String get songDetails => 'Song details';

  @override
  String get editMetadata => 'Edit metadata';

  @override
  String get selectAll => 'Select All';

  @override
  String get deleteSong => 'Delete song';

  @override
  String get confirmDeleteSong => 'Do you really want to delete this song?';

  @override
  String get songAdded => 'Song added';

  @override
  String get createPlaylist => 'Create playlist';

  @override
  String get playlistNameHint => 'My playlist';

  @override
  String get allSongs => 'All songs';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortAscending => 'Ascending';

  @override
  String get sortDescending => 'Descending';

  @override
  String get title => 'Title';

  @override
  String get artist => 'Artist';

  @override
  String get album => 'Album';

  @override
  String get duration => 'Duration';

  @override
  String get sortByDateAdded => 'Date added';

  @override
  String get noSongs => 'No songs';

  @override
  String get grantPermission => 'Grant';

  @override
  String get openSettings => 'Settings';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get permissionPermanentlyDenied =>
      'You have denied permissions. Please enable permissions manually in app settings.';

  @override
  String get storagePermissionRequired =>
      'Storage permission required to read music';

  @override
  String get changeCover => 'Change cover';

  @override
  String get showLyrics => 'Show lyrics';

  @override
  String get hideLyrics => 'Hide lyrics';

  @override
  String get lyricsEdit => 'Edit Lyrics';

  @override
  String get lyricsDelete => 'Delete Lyrics';

  @override
  String get lyricsDeleteConfirm => 'Delete lyrics for this song?';

  @override
  String get lyricsImportFile => 'Import file';

  @override
  String get lyricsImportClipboard => 'Paste from Clipboard';

  @override
  String get lyricsSaved => 'Lyrics saved';

  @override
  String get lyricsDeleted => 'Lyrics deleted';

  @override
  String get lyricsPasteHint => 'Paste or write lyrics here...';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get unknownAlbum => 'Unknown album';

  @override
  String get unknownTitle => 'Unknown title';

  @override
  String get noAlbums => 'No albums';

  @override
  String get noArtists => 'No artists';

  @override
  String get noPlaylists => 'No playlists';

  @override
  String get noFolders => 'No folders';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
      zero: 'No songs',
    );
    return '$_temp0';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
      zero: 'No albums',
    );
    return '$_temp0';
  }

  @override
  String get playlistName => 'Playlist name';

  @override
  String get renamePlaylist => 'Rename';

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String get confirmDeletePlaylist =>
      'Do you really want to delete this playlist?';

  @override
  String get emptyPlaylist => 'Empty playlist';

  @override
  String get addSongs => 'Add songs';

  @override
  String get addSongsToPlaylistDesc => 'Add songs to start listening';

  @override
  String get playlistCreated => 'Playlist created';

  @override
  String get playlistDeleted => 'Playlist deleted';

  @override
  String get playlistRenamed => 'Playlist renamed';

  @override
  String get songAddedToPlaylist => 'Added to playlist';

  @override
  String get songRemoved => 'Song removed';

  @override
  String get selectPlaylist => 'Select playlist';

  @override
  String get noPlaylistsCreateOne => 'No playlists. Create one.';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get newPlaylistEllipsis => 'New playlist…';

  @override
  String get create => 'Create';

  @override
  String get scheduledNext => 'Scheduled to play next';

  @override
  String get addedToQueue => 'Added to queue';

  @override
  String get removedFromHistory => 'Removed from history';

  @override
  String get noFavorites => 'No favorites';

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get queue => 'Queue';

  @override
  String get clearQueue => 'Clear queue';

  @override
  String get queueEmpty => 'Queue is empty';

  @override
  String get confirmClearQueue => 'Do you really want to clear the queue?';

  @override
  String get swipeToRemove => 'Swipe to remove';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get historyCleared => 'History cleared';

  @override
  String get options => 'Options';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get lyricsFound => 'Lyrics found';

  @override
  String get noLyrics => 'No lyrics available';

  @override
  String get searchingLyrics => 'Searching for lyrics...';

  @override
  String get lyricsNotFound => 'No lyrics found for this song';

  @override
  String get lyricsError => 'Error while searching';

  @override
  String get retryLyrics => 'Retry';

  @override
  String get lyricsDisplay => 'Lyrics display';

  @override
  String get blurBackground => 'Blurred artistic background';

  @override
  String get blurBackgroundDesc => 'Use cover art as blurred background';

  @override
  String get alignment => 'Alignment';

  @override
  String get alignLeft => 'Left';

  @override
  String get alignCenter => 'Center';

  @override
  String get textSize => 'Text size';

  @override
  String get lineHeight => 'Line height';

  @override
  String get reset => 'Reset';

  @override
  String get copiedText => 'Copied text detected';

  @override
  String get useAsLyrics => 'Use as lyrics';

  @override
  String get webSearch => 'Search on the Web';

  @override
  String get tip => 'Tip';

  @override
  String get copyTip =>
      'Select and copy lyrics on the page. They will be automatically proposed here.';

  @override
  String get lyricsCopied => 'Lyrics copied';

  @override
  String get scanningMusic => 'Scanning...';

  @override
  String get scanComplete => 'Scan complete';

  @override
  String get scanFailed => 'Scan failed';

  @override
  String foundSongs(int count) {
    return '$count songs found';
  }

  @override
  String get metadata => 'Metadata';

  @override
  String get genre => 'Genre';

  @override
  String get year => 'Year';

  @override
  String get track => 'Track';

  @override
  String get path => 'Path';

  @override
  String get size => 'Size';

  @override
  String get format => 'Format';

  @override
  String get bitrate => 'Bitrate';

  @override
  String get sampleRate => 'Sample rate';

  @override
  String get metadataSaved => 'Metadata saved';

  @override
  String get metadataFailed => 'Save failed';

  @override
  String get coverSaved => 'Cover saved';

  @override
  String get coverFailed => 'Save failed';

  @override
  String get confirmDelete => 'Confirm deletion';

  @override
  String get fileDeleted => 'File deleted';

  @override
  String get fileDeletionFailed => 'Deletion failed';

  @override
  String get crop => 'Crop';

  @override
  String get requiresAndroid10 => 'This feature requires Android 10+';

  @override
  String get errorOpeningFolder => 'Error opening folder';

  @override
  String get imageUpdated => 'Image updated';

  @override
  String get ringtoneSet => 'Set as ringtone';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByArtist => 'Artist';

  @override
  String get sortByAlbum => 'Album';

  @override
  String get sortByDuration => 'Duration';

  @override
  String get sortByPlayCount => 'Play count';

  @override
  String get shuffleAll => 'Shuffle all';

  @override
  String get allow => 'Allow';

  @override
  String get filterDuration => 'Ignore durations less than';

  @override
  String get filterSize => 'Ignore sizes less than';

  @override
  String get duration30s => '30 s';

  @override
  String get duration60s => '60 s';

  @override
  String get size50kb => '50 KB';

  @override
  String get size100kb => '100 KB';

  @override
  String get startScan => 'START SCAN';

  @override
  String get scanningInProgress => 'Scanning in progress...';

  @override
  String get hideFolder => 'Hide folder';

  @override
  String get folderHidden => 'Folder hidden';

  @override
  String get unhideFolder => 'Unhide';

  @override
  String get folderUnhidden => 'Folder unhidden';

  @override
  String get folderProperties => 'Folder properties';

  @override
  String get openLocation => 'Open location';

  @override
  String get viewHiddenFolders => 'View hidden folders';

  @override
  String get open => 'Open';

  @override
  String get copyPath => 'Copy path';

  @override
  String get pathCopied => 'Path copied';

  @override
  String get uriNotFound => 'File URI not found';

  @override
  String get ringtoneTitle => 'Ringtone';

  @override
  String setRingtoneConfirm(String title) {
    return 'Set \"$title\" as ringtone?';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get ringtoneSetSuccess => '✓ Set as ringtone';

  @override
  String get changesSaved => 'Changes saved';

  @override
  String get fileDeletedPermanently => 'File permanently deleted';

  @override
  String get editArtistInfo => 'Edit artist info';

  @override
  String get optional => 'Optional';

  @override
  String get genreOptional => 'Genre (Optional)';

  @override
  String get yearOptional => 'Year (Optional)';

  @override
  String get deletePermanently => 'Delete permanently?';

  @override
  String get deleteWarningMessage =>
      'This action is irreversible and will delete:';

  @override
  String get deleteStorageWarning =>
      '⚠️ The file will be deleted from your phone\'s storage';

  @override
  String folderLabel(String name) {
    return 'Folder: $name';
  }

  @override
  String get android10Required => '❌ This feature requires Android 10+';

  @override
  String errorWithDetails(String error) {
    return '❌ Error: $error';
  }

  @override
  String get errorPermissionDenied => 'Permission denied. Check app settings';

  @override
  String get errorFileNotFound => 'File not found';

  @override
  String get errorInsufficientStorage => 'Insufficient storage space';

  @override
  String get errorNetworkProblem => 'Connection problem';

  @override
  String get errorCorruptFile => 'Corrupted file or invalid format';

  @override
  String get errorGeneric => 'An error occurred';

  @override
  String get sleepTimer => 'Sleep Timer';

  @override
  String sleepTimerSet(String duration) {
    return 'Timer set to $duration';
  }

  @override
  String get cancelTimer => 'Cancel Timer';

  @override
  String get customTimer => 'Custom Timer';

  @override
  String get customize => 'Customize';

  @override
  String get setTimer => 'Set';

  @override
  String get hours => 'Hours';

  @override
  String get minutes => 'Minutes';

  @override
  String get invalidDuration => 'Please set a valid duration';

  @override
  String get stopMusicAfter => 'Stop music after';

  @override
  String get start => 'Start';

  @override
  String get min5 => '5 min';

  @override
  String get min15 => '15 min';

  @override
  String get min30 => '30 min';

  @override
  String get min45 => '45 min';

  @override
  String get hour1 => '1 hour';

  @override
  String get hours2 => '2 hours';

  @override
  String get upNext => 'Up Next';

  @override
  String get undo => 'Undo';

  @override
  String get permissionAudioTitle => 'Audio Access';

  @override
  String get permissionAudioDesc => 'To play your local music files';

  @override
  String get permissionNotificationTitle => 'Notifications';

  @override
  String get permissionNotificationDesc => 'For playback controls';

  @override
  String get permissionBatteryTitle => 'Background Playback';

  @override
  String get permissionBatteryDesc => 'Prevents cuts when screen is off';

  @override
  String get permissionIntro =>
      'To offer you the best musical experience, Music Box needs a few permissions.';

  @override
  String get grant => 'Grant';

  @override
  String get enable => 'Enable';

  @override
  String get accessApp => 'Access Music Box';

  @override
  String get backupAndData => 'Backup & Data';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportDataDesc => 'Save favorites, playlists, and stats';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get importBackupDesc => 'Restore from a .json file';

  @override
  String get attention => 'Warning';

  @override
  String get restoreWarning =>
      'Restore will overwrite your current favorites and playlists.\n\nDo you want to continue?';

  @override
  String get overwriteAndRestore => 'Overwrite and Restore';

  @override
  String get restoreSuccessTitle => 'Restoration Successful';

  @override
  String get restoreSuccessMessage =>
      'Your data has been successfully restored.\n\nPlease restart the app for all changes to take effect.';

  @override
  String get backupReadError => 'Unable to read the backup file.';

  @override
  String get sleepTimerTitle => 'Sleep Timer';

  @override
  String get sleepTimerDesc => 'Schedule music stop';

  @override
  String get sleepTimerStoppingSoon => 'Stopping soon...';

  @override
  String sleepTimerActive(int minutes) {
    return 'Active: Stops in $minutes min';
  }

  @override
  String get sleepTimerStopMusicAfter => 'Stop music after...';

  @override
  String sleepTimerActiveRemaining(int minutes, String seconds) {
    return 'Active: $minutes:$seconds remaining';
  }

  @override
  String get deactivate => 'Deactivate';

  @override
  String timerSetFor(String label) {
    return 'Timer set to $label 🌙';
  }

  @override
  String get oneHour => '1 hour';

  @override
  String get oneHourThirty => '1h 30';

  @override
  String get twoHours => '2 hours';

  @override
  String get backupSubject => 'Music Box Backup';

  @override
  String backupBody(String date) {
    return 'Here is my Music Box backup from $date.';
  }

  @override
  String get crossfade => 'Crossfade';

  @override
  String get crossfadeDesc => 'Smooth transition between songs';

  @override
  String get crossfadeDisabled => 'Disabled';

  @override
  String crossfadeSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get gaplessPlayback => 'Skip silence';

  @override
  String get gaplessPlaybackDesc =>
      'Automatically skip silent parts (experimental, may cause noise)';

  @override
  String get playbackSpeed => 'Playback Speed';

  @override
  String get playbackSpeedDesc => 'Adjust audio speed';

  @override
  String get defaultSpeed => 'Default Speed';

  @override
  String get contactSubject => 'Music Box Support';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortShortest => 'Shortest';

  @override
  String get sortLongest => 'Longest';

  @override
  String get noConnectionMessage =>
      'Please check your connection and try again';

  @override
  String get selectSource => 'Select source';

  @override
  String get localGallery => 'Gallery';

  @override
  String get preview => 'Preview';

  @override
  String get useThisImageQuestion => 'Use this image?';

  @override
  String get useImage => 'Use Image';

  @override
  String get searchOnInternet => 'Search on Internet';

  @override
  String get finishCurrentSong => 'Finish current song';

  @override
  String get sleepTimerFadeOut => 'Final fade out (15s)';

  @override
  String get customEqualizer => 'Equalizer';

  @override
  String get equalizerBands => 'Frequency Bands';

  @override
  String get equalizerPresets => 'Presets';
}
