// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Music Box';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get save => '保存';

  @override
  String get share => '共有';

  @override
  String get edit => '編集';

  @override
  String get add => '追加';

  @override
  String get remove => '削除';

  @override
  String get search => '検索';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラー';

  @override
  String get retry => '再試行';

  @override
  String get close => '閉じる';

  @override
  String get done => '完了';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get songs => '曲';

  @override
  String get playlists => 'プレイリスト';

  @override
  String get albums => 'アルバム';

  @override
  String get artists => 'アーティスト';

  @override
  String get folders => 'フォルダ';

  @override
  String get settings => '設定';

  @override
  String get nowPlaying => '再生中';

  @override
  String get yourPlaylists => 'マイプレイリスト';

  @override
  String get favorites => 'お気に入り';

  @override
  String get recentlyAdded => '最近追加';

  @override
  String get recentlyPlayed => '最近再生';

  @override
  String get mostPlayed => '人気';

  @override
  String get forYou => 'おすすめ';

  @override
  String get quickPlay => 'クイックプレイ';

  @override
  String get listeningHabits => 'リピート中';

  @override
  String get forgottenGems => '忘れ去られた名曲';

  @override
  String get allTimeHits => '時代を超えた名曲';

  @override
  String get explore => '見つける';

  @override
  String get settingsTitle => '設定';

  @override
  String get appearance => '外観';

  @override
  String get audio => 'オーディオ';

  @override
  String get library => 'ライブラリ';

  @override
  String get about => 'アプリについて';

  @override
  String get theme => 'テーマ';

  @override
  String get themeDescription => 'アプリのテーマ';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeSystemDesc => '端末の設定に従う';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeLightDesc => '常にライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeDarkDesc => '常にダーク';

  @override
  String get language => '言語';

  @override
  String get languageDescription => 'アプリの言語';

  @override
  String get currentLanguage => '日本語';

  @override
  String get languageSystem => 'システム言語';

  @override
  String get languageSystemDesc => '端末の言語に従う';

  @override
  String get languageAlreadySelected => '日本語が選択されています';

  @override
  String get languageComingSoon => '近日公開';

  @override
  String get languageChanged => '言語を変更しました';

  @override
  String get languageNeedsRestart => '再起動が必要です';

  @override
  String get restartNow => '今すぐ再起動';

  @override
  String get restartLater => '後で';

  @override
  String get equalizer => 'イコライザー';

  @override
  String get equalizerDesc => '音質を調整';

  @override
  String get equalizerEnabled => 'イコライザー有効';

  @override
  String get equalizerDisabled => 'イコライザー無効';

  @override
  String get noEqualizerFound => 'イコライザーが見つかりません';

  @override
  String get background => '背景';

  @override
  String get backgroundDesc => 'アプリの背景';

  @override
  String get backgroundNone => 'なし';

  @override
  String get backgroundGradientMusical => 'ミュージカルグラデーション';

  @override
  String get backgroundGradientDark => 'ダークグラデーション';

  @override
  String get backgroundParticles => 'パーティクル';

  @override
  String get backgroundWaves => 'サウンドウェーブ';

  @override
  String get backgroundNeonCity => 'ネオンシティ';

  @override
  String get backgroundVinylSunset => 'ビニールサンセット';

  @override
  String get backgroundAuroraRhythm => 'オーロラリズム';

  @override
  String get backgroundPlayback => 'バックグラウンド再生';

  @override
  String get backgroundPlaybackDesc => 'バッテリー最適化を無効化';

  @override
  String get batteryOptimizationTitle => '最適化を停止しますか？';

  @override
  String get batteryOptimizationMessage =>
      'バックグラウンドでの実行を許可します。バッテリー消費制限は解除されます。';

  @override
  String get batteryOptimizationEnabled => '✓ 最適化無効';

  @override
  String get batteryOptimizationDisabled => '⚠️ 最適化有効（途切れる可能性があります）';

  @override
  String get notifications => '通知';

  @override
  String get notificationsDesc => '通知設定';

  @override
  String get cannotOpenSettings => '設定を開けません';

  @override
  String get androidOnly => 'Androidのみ';

  @override
  String get scanMusic => '音楽をスキャン';

  @override
  String get scanMusicDesc => '曲が見つからない場合';

  @override
  String get hiddenFolders => '隠しフォルダ';

  @override
  String get hiddenFoldersDesc => '隠しフォルダの管理';

  @override
  String version(String version) {
    return 'バージョン $version';
  }

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get privacyPolicyDesc => 'ポリシーを確認';

  @override
  String get contact => 'お問い合わせ';

  @override
  String get contactDesc => 'synergydevv@gmail.com';

  @override
  String get cannotOpenPrivacyPolicy => '開けませんでした';

  @override
  String get cannotOpenEmail => 'メールアプリを開けませんでした';

  @override
  String get play => '再生';

  @override
  String get pause => '一時停止';

  @override
  String get next => '次へ';

  @override
  String get previous => '前へ';

  @override
  String get shuffle => 'シャッフル';

  @override
  String get repeat => 'リピート';

  @override
  String get playNext => '次に再生';

  @override
  String get playAll => 'すべて再生';

  @override
  String get addToQueue => 'キューに追加';

  @override
  String get addToQueueFull => '再生キューに追加';

  @override
  String get addToPlaylist => 'プレイリストに追加';

  @override
  String get addToMyPlaylists => 'プレイリストに追加';

  @override
  String get removeFromPlaylist => 'プレイリストから削除';

  @override
  String get removeFromHistory => '履歴から削除';

  @override
  String get addToFavorites => 'お気に入りに追加';

  @override
  String get removeFromFavorites => 'お気に入りから削除';

  @override
  String get goToAlbum => 'アルバムへ移動';

  @override
  String get goToArtist => 'アーティストへ移動';

  @override
  String get setAsRingtone => '着信音に設定';

  @override
  String get songDetails => '曲の詳細';

  @override
  String get editMetadata => '詳細を編集';

  @override
  String get selectAll => 'すべて選択';

  @override
  String get deleteSong => '曲を削除';

  @override
  String get confirmDeleteSong => '本当に削除しますか？';

  @override
  String get songAdded => '追加しました';

  @override
  String get createPlaylist => 'プレイリスト作成';

  @override
  String get playlistNameHint => 'マイプレイリスト';

  @override
  String get allSongs => '全曲';

  @override
  String get sortBy => '並び替え';

  @override
  String get sortAscending => '昇順';

  @override
  String get sortDescending => '降順';

  @override
  String get title => 'タイトル';

  @override
  String get artist => 'アーティスト';

  @override
  String get album => 'アルバム';

  @override
  String get duration => '時間';

  @override
  String get sortByDateAdded => '日付';

  @override
  String get noSongs => '曲がありません';

  @override
  String get grantPermission => '許可';

  @override
  String get openSettings => '設定';

  @override
  String get permissionRequired => '権限が必要です';

  @override
  String get permissionDenied => '拒否されました';

  @override
  String get permissionPermanentlyDenied => '拒否されました。';

  @override
  String get storagePermissionRequired => 'ストレージ権限が必要です';

  @override
  String get changeCover => 'カバーを変更';

  @override
  String get showLyrics => '歌詞を表示';

  @override
  String get hideLyrics => '歌詞を非表示';

  @override
  String get lyricsEdit => '歌詞を編集';

  @override
  String get lyricsDelete => '歌詞を削除';

  @override
  String get lyricsDeleteConfirm => '歌詞を削除しますか？';

  @override
  String get lyricsImportUrl => 'ファイルからインポート';

  @override
  String get lyricsImportClipboard => 'クリップボードから貼り付け';

  @override
  String get lyricsSaved => '歌詞を保存しました';

  @override
  String get lyricsDeleted => '歌詞を削除しました';

  @override
  String get lyricsPasteHint => 'ここに歌詞を入力...';

  @override
  String get unknownArtist => '不明なアーティスト';

  @override
  String get unknownAlbum => '不明なアルバム';

  @override
  String get unknownTitle => '不明なタイトル';

  @override
  String get noAlbums => 'アルバムがありません';

  @override
  String get noArtists => 'アーティストがいません';

  @override
  String get noPlaylists => 'プレイリストがありません';

  @override
  String get noFolders => 'フォルダがありません';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count曲',
      one: '1曲',
      zero: '曲なし',
    );
    return '$_temp0';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countアルバム',
      one: '1アルバム',
      zero: 'アルバムなし',
    );
    return '$_temp0';
  }

  @override
  String get playlistName => 'プレイリスト名';

  @override
  String get renamePlaylist => '名前を変更';

  @override
  String get deletePlaylist => 'プレイリストを削除';

  @override
  String get confirmDeletePlaylist => '本当に削除しますか？';

  @override
  String get emptyPlaylist => '空のプレイリスト';

  @override
  String get addSongs => '曲を追加';

  @override
  String get addSongsToPlaylistDesc => '曲を追加して始めましょう';

  @override
  String get playlistCreated => '作成しました';

  @override
  String get playlistDeleted => '削除しました';

  @override
  String get playlistRenamed => '変更しました';

  @override
  String get songAddedToPlaylist => 'リストに追加しました';

  @override
  String get songRemoved => '削除しました';

  @override
  String get selectPlaylist => 'リストを選択';

  @override
  String get noPlaylistsCreateOne => 'プレイリストがありません';

  @override
  String get newPlaylist => '新規プレイリスト';

  @override
  String get newPlaylistEllipsis => '新規作成...';

  @override
  String get create => '作成';

  @override
  String get scheduledNext => '次はこれを再生';

  @override
  String get addedToQueue => '追加しました';

  @override
  String get removedFromHistory => '履歴から削除しました';

  @override
  String get noFavorites => 'お気に入りがありません';

  @override
  String get addedToFavorites => 'お気に入りに追加しました';

  @override
  String get removedFromFavorites => '削除しました';

  @override
  String get queue => '再生キュー';

  @override
  String get clearQueue => 'クリア';

  @override
  String get queueEmpty => 'キューは空です';

  @override
  String get confirmClearQueue => 'キューをクリアしますか？';

  @override
  String get swipeToRemove => 'スワイプして削除';

  @override
  String get clearHistory => '履歴を削除';

  @override
  String get historyCleared => '履歴を削除しました';

  @override
  String get options => 'オプション';

  @override
  String get lyrics => '歌詞';

  @override
  String get lyricsFound => '歌詞が見つかりました';

  @override
  String get noLyrics => '歌詞がありません';

  @override
  String get searchingLyrics => '検索中...';

  @override
  String get lyricsNotFound => '見つかりません';

  @override
  String get lyricsError => 'エラー';

  @override
  String get retryLyrics => '再試行';

  @override
  String get lyricsDisplay => '表示設定';

  @override
  String get blurBackground => '背景ぼかし';

  @override
  String get blurBackgroundDesc => 'カバーアートを背景にする';

  @override
  String get alignment => '配置';

  @override
  String get alignLeft => '左揃え';

  @override
  String get alignCenter => '中央揃え';

  @override
  String get textSize => '文字サイズ';

  @override
  String get lineHeight => '行間';

  @override
  String get reset => 'リセット';

  @override
  String get copiedText => 'コピーしたテキストを検出';

  @override
  String get useAsLyrics => '歌詞として使用';

  @override
  String get webSearch => 'ウェブ検索';

  @override
  String get tip => 'ヒント';

  @override
  String get copyTip => 'ウェブで歌詞をコピーすると、ここに候補が表示されます。';

  @override
  String get lyricsCopied => 'コピーしました';

  @override
  String get scanningMusic => 'スキャン中...';

  @override
  String get scanComplete => '完了';

  @override
  String get scanFailed => '失敗';

  @override
  String foundSongs(int count) {
    return '$count曲見つかりました';
  }

  @override
  String get metadata => 'メタデータ';

  @override
  String get genre => 'ジャンル';

  @override
  String get year => '年';

  @override
  String get track => 'トラック';

  @override
  String get path => 'パス';

  @override
  String get size => 'サイズ';

  @override
  String get format => 'フォーマット';

  @override
  String get bitrate => 'ビットレート';

  @override
  String get sampleRate => 'サンプリングレート';

  @override
  String get metadataSaved => '保存しました';

  @override
  String get metadataFailed => '保存に失敗しました';

  @override
  String get coverSaved => '保存しました';

  @override
  String get coverFailed => '保存に失敗しました';

  @override
  String get confirmDelete => '削除の確認';

  @override
  String get fileDeleted => '削除しました';

  @override
  String get fileDeletionFailed => '削除できませんでした';

  @override
  String get crop => '切り抜き';

  @override
  String get requiresAndroid10 => 'Android 10以上が必要です';

  @override
  String get errorOpeningFolder => '開けません';

  @override
  String get imageUpdated => '更新しました';

  @override
  String get ringtoneSet => '設定しました';

  @override
  String get sortByName => '名前';

  @override
  String get sortByArtist => 'アーティスト';

  @override
  String get sortByAlbum => 'アルバム';

  @override
  String get sortByDuration => '時間';

  @override
  String get sortByPlayCount => '再生回数';

  @override
  String get shuffleAll => '全曲シャッフル';

  @override
  String get allow => '許可';

  @override
  String get filterDuration => '短い曲を除外';

  @override
  String get filterSize => '小さいファイルを除外';

  @override
  String get duration30s => '30秒';

  @override
  String get duration60s => '60秒';

  @override
  String get size50kb => '50 KB';

  @override
  String get size100kb => '100 KB';

  @override
  String get startScan => 'スキャン開始';

  @override
  String get scanningInProgress => 'スキャン中...';

  @override
  String get hideFolder => '隠す';

  @override
  String get folderHidden => '隠しました';

  @override
  String get unhideFolder => '表示';

  @override
  String get folderUnhidden => '表示しました';

  @override
  String get folderProperties => 'プロパティ';

  @override
  String get openLocation => '場所を開く';

  @override
  String get viewHiddenFolders => '隠しフォルダを表示';

  @override
  String get open => '開く';

  @override
  String get copyPath => 'パスをコピー';

  @override
  String get pathCopied => 'コピーしました';

  @override
  String get uriNotFound => 'URIが見つかりません';

  @override
  String get ringtoneTitle => '着信音';

  @override
  String setRingtoneConfirm(String title) {
    return '「$title」を着信音にしますか？';
  }

  @override
  String get confirm => '確認';

  @override
  String get ringtoneSetSuccess => '✓ 設定しました';

  @override
  String get changesSaved => '保存しました';

  @override
  String get fileDeletedPermanently => '完全に削除されました';

  @override
  String get editArtistInfo => 'アーティスト情報を編集';

  @override
  String get optional => '任意';

  @override
  String get genreOptional => 'ジャンル (任意)';

  @override
  String get yearOptional => '年 (任意)';

  @override
  String get deletePermanently => '完全に削除？';

  @override
  String get deleteWarningMessage => '元に戻せません。以下が削除されます:';

  @override
  String get deleteStorageWarning => '⚠️ ファイルは端末から削除されます';

  @override
  String folderLabel(String name) {
    return 'フォルダ: $name';
  }

  @override
  String get android10Required => '❌ Android 10+が必要';

  @override
  String errorWithDetails(String error) {
    return '❌ エラー: $error';
  }

  @override
  String get errorPermissionDenied => 'アクセス拒否';

  @override
  String get errorFileNotFound => '見つかりません';

  @override
  String get errorInsufficientStorage => '容量不足';

  @override
  String get errorNetworkProblem => 'ネットワークエラー';

  @override
  String get errorCorruptFile => 'ファイル破損';

  @override
  String get errorGeneric => 'エラーが発生しました';

  @override
  String get sleepTimer => 'スリープタイマー';

  @override
  String sleepTimerSet(String duration) {
    return '$durationに設定しました';
  }

  @override
  String get cancelTimer => 'キャンセル';

  @override
  String get customTimer => 'カスタム';

  @override
  String get customize => 'カスタム';

  @override
  String get setTimer => '設定';

  @override
  String get hours => '時間';

  @override
  String get minutes => '分';

  @override
  String get invalidDuration => '無効な時間です';

  @override
  String get stopMusicAfter => '音楽停止まで';

  @override
  String get start => '開始';

  @override
  String get min5 => '5分';

  @override
  String get min15 => '15分';

  @override
  String get min30 => '30分';

  @override
  String get min45 => '45分';

  @override
  String get hour1 => '1時間';

  @override
  String get hours2 => '2時間';

  @override
  String get upNext => '次は';

  @override
  String get undo => '元に戻す';

  @override
  String get permissionAudioTitle => 'オーディオ権限';

  @override
  String get permissionAudioDesc => '音楽を再生するために必要です';

  @override
  String get permissionNotificationTitle => '通知権限';

  @override
  String get permissionNotificationDesc => '再生コントロールに必要です';

  @override
  String get permissionBatteryTitle => 'バックグラウンド';

  @override
  String get permissionBatteryDesc => '再生が止まるのを防ぎます';

  @override
  String get permissionIntro => 'Music Boxを正常に動作させるには権限が必要です。';

  @override
  String get grant => '許可';

  @override
  String get enable => '有効化';

  @override
  String get accessApp => 'アプリへ';

  @override
  String get backupAndData => 'バックアップとデータ';

  @override
  String get exportData => 'エクスポート';

  @override
  String get exportDataDesc => 'お気に入りとリストを保存';

  @override
  String get importBackup => 'インポート';

  @override
  String get importBackupDesc => '.jsonから復元';

  @override
  String get attention => '注意';

  @override
  String get restoreWarning => '現在のデータが上書きされます。\n\n続けますか？';

  @override
  String get overwriteAndRestore => '上書きして復元';

  @override
  String get restoreSuccessTitle => '完了';

  @override
  String get restoreSuccessMessage => '復元しました。\n\n再起動してください。';

  @override
  String get backupReadError => 'ファイルを読み込めません。';

  @override
  String get sleepTimerTitle => 'スリープタイマー';

  @override
  String get sleepTimerDesc => '自動停止を設定';

  @override
  String get sleepTimerStoppingSoon => 'まもなく停止します...';

  @override
  String sleepTimerActive(int minutes) {
    return '有効: 残り$minutes分';
  }

  @override
  String get sleepTimerStopMusicAfter => '停止まであと...';

  @override
  String sleepTimerActiveRemaining(int minutes, String seconds) {
    return '残り: $minutes:$seconds';
  }

  @override
  String get deactivate => '無効化';

  @override
  String timerSetFor(String label) {
    return '設定: $label 🌙';
  }

  @override
  String get oneHour => '1時間';

  @override
  String get oneHourThirty => '1時間半';

  @override
  String get twoHours => '2時間';

  @override
  String get backupSubject => 'Music Box バックアップ';

  @override
  String backupBody(String date) {
    return '$dateのバックアップファイルです。';
  }

  @override
  String get contactSubject => 'Music Box サポート';

  @override
  String get sortNewest => '新しい順';

  @override
  String get sortOldest => '古い順';

  @override
  String get sortShortest => '短い順';

  @override
  String get sortLongest => '長い順';

  @override
  String get noConnectionMessage => '接続を確認して、もう一度お試しください';

  @override
  String get selectSource => 'ソースを選択';

  @override
  String get localGallery => 'ギャラリー';

  @override
  String get preview => 'プレビュー';

  @override
  String get useThisImageQuestion => 'この画像を使用しますか？';

  @override
  String get useImage => '画像を使用';

  @override
  String get searchOnInternet => 'インターネットで検索';
}
