// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Music Box';

  @override
  String get ok => 'ОК';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get save => 'Сохранить';

  @override
  String get share => 'Поделиться';

  @override
  String get edit => 'Изменить';

  @override
  String get add => 'Добавить';

  @override
  String get remove => 'Убрать';

  @override
  String get search => 'Поиск';

  @override
  String get loading => 'Загрузка...';

  @override
  String get error => 'Ошибка';

  @override
  String get retry => 'Повторить';

  @override
  String get close => 'Закрыть';

  @override
  String get done => 'Готово';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get songs => 'Песни';

  @override
  String get playlists => 'Плейлисты';

  @override
  String get albums => 'Альбомы';

  @override
  String get artists => 'Исполнители';

  @override
  String get folders => 'Папки';

  @override
  String get settings => 'Настройки';

  @override
  String get nowPlaying => 'Сейчас играет';

  @override
  String get yourPlaylists => 'Ваши плейлисты';

  @override
  String get favorites => 'Избранное';

  @override
  String get recentlyAdded => 'Недавно добавленные';

  @override
  String get recentlyPlayed => 'Недавно прослушанные';

  @override
  String get mostPlayed => 'Популярные';

  @override
  String get forYou => 'Для вас';

  @override
  String get quickPlay => 'Быстрый старт';

  @override
  String get listeningHabits => 'На повторе';

  @override
  String get forgottenGems => 'Забытые жемчужины';

  @override
  String get allTimeHits => 'Вне времени';

  @override
  String get explore => 'Обзор';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get audio => 'Аудио';

  @override
  String get library => 'Библиотека';

  @override
  String get about => 'О приложении';

  @override
  String get theme => 'Тема';

  @override
  String get themeDescription => 'Тема приложения';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeSystemDesc => 'Как в системе';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeLightDesc => 'Всегда светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeDarkDesc => 'Всегда тёмная';

  @override
  String get language => 'Язык';

  @override
  String get languageDescription => 'Язык приложения';

  @override
  String get currentLanguage => 'Русский';

  @override
  String get languageSystem => 'Системный язык';

  @override
  String get languageSystemDesc => 'Как в телефоне';

  @override
  String get languageAlreadySelected => 'Русский уже выбран';

  @override
  String get languageComingSoon => 'Скоро';

  @override
  String get languageChanged => 'Язык изменён';

  @override
  String get languageNeedsRestart => 'Требуется перезапуск';

  @override
  String get restartNow => 'Перезапустить сейчас';

  @override
  String get restartLater => 'Позже';

  @override
  String get equalizer => 'Эквалайзер';

  @override
  String get equalizerDesc => 'Настройка частот';

  @override
  String get equalizerEnabled => 'Эквалайзер включен';

  @override
  String get equalizerDisabled => 'Эквалайзер выключен';

  @override
  String get noEqualizerFound => 'Эквалайзер не найден';

  @override
  String get background => 'Фон';

  @override
  String get backgroundDesc => 'Настройка фона';

  @override
  String get backgroundNone => 'Нет';

  @override
  String get backgroundGradientMusical => 'Музыкальный градиент';

  @override
  String get backgroundGradientDark => 'Тёмный градиент';

  @override
  String get backgroundParticles => 'Частицы';

  @override
  String get backgroundWaves => 'Звуковые волны';

  @override
  String get backgroundNeonCity => 'Неоновый город';

  @override
  String get backgroundVinylSunset => 'Виниловый закат';

  @override
  String get backgroundAuroraRhythm => 'Северное сияние';

  @override
  String get backgroundPlayback => 'Фоновое воспроизведение';

  @override
  String get backgroundPlaybackDesc => 'Откл. экономию заряда';

  @override
  String get batteryOptimizationTitle => 'Отключить оптимизацию?';

  @override
  String get batteryOptimizationMessage =>
      'Разрешить Music Box работать в фоне без ограничений.';

  @override
  String get batteryOptimizationEnabled => '✓ Оптимизация отключена';

  @override
  String get batteryOptimizationDisabled =>
      '⚠️ Оптимизация включена (возможны сбои)';

  @override
  String get notifications => 'Уведомления';

  @override
  String get notificationsDesc => 'Настройки уведомлений';

  @override
  String get cannotOpenSettings => 'Не удалось открыть настройки';

  @override
  String get androidOnly => 'Только Android';

  @override
  String get scanMusic => 'Сканировать музыку';

  @override
  String get scanMusicDesc => 'Поиск новых треков';

  @override
  String get hiddenFolders => 'Скрытые папки';

  @override
  String get hiddenFoldersDesc => 'Управление скрытыми папками';

  @override
  String version(String version) {
    return 'Версия $version';
  }

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get privacyPolicyDesc => 'Читать политику';

  @override
  String get contact => 'Связаться';

  @override
  String get contactDesc => 'synergydevv@gmail.com';

  @override
  String get cannotOpenPrivacyPolicy => 'Ошибка открытия политики';

  @override
  String get cannotOpenEmail => 'Ошибка открытия почты';

  @override
  String get play => 'Играть';

  @override
  String get pause => 'Пауза';

  @override
  String get next => 'Далее';

  @override
  String get previous => 'Назад';

  @override
  String get shuffle => 'Перемешать';

  @override
  String get repeat => 'Повтор';

  @override
  String get playNext => 'Играть следующим';

  @override
  String get playAll => 'Играть всё';

  @override
  String get addToQueue => 'В очередь';

  @override
  String get addToQueueFull => 'Добавить в очередь';

  @override
  String get addToPlaylist => 'В плейлист';

  @override
  String get addToMyPlaylists => 'В МОИ плейлисты';

  @override
  String get removeFromPlaylist => 'Убрать из плейлиста';

  @override
  String get removeFromHistory => 'Убрать из истории';

  @override
  String get addToFavorites => 'В избранное';

  @override
  String get removeFromFavorites => 'Убрать из избранного';

  @override
  String get goToAlbum => 'К альбому';

  @override
  String get goToArtist => 'К исполнителю';

  @override
  String get setAsRingtone => 'На звонок';

  @override
  String get songDetails => 'О треке';

  @override
  String get editMetadata => 'Изменить теги';

  @override
  String get selectAll => 'Выбрать всё';

  @override
  String get deleteSong => 'Удалить трек';

  @override
  String get confirmDeleteSong => 'Удалить этот трек?';

  @override
  String get songAdded => 'Песня добавлена';

  @override
  String get createPlaylist => 'Создать плейлист';

  @override
  String get playlistNameHint => 'Мой плейлист';

  @override
  String get allSongs => 'Все песни';

  @override
  String get sortBy => 'Сортировка';

  @override
  String get sortAscending => 'А-Я';

  @override
  String get sortDescending => 'Я-А';

  @override
  String get title => 'Название';

  @override
  String get artist => 'Исполнитель';

  @override
  String get album => 'Альбом';

  @override
  String get duration => 'Длительность';

  @override
  String get sortByDateAdded => 'Дата';

  @override
  String get noSongs => 'Нет песен';

  @override
  String get grantPermission => 'Дать доступ';

  @override
  String get openSettings => 'Настройки';

  @override
  String get permissionRequired => 'Нужны разрешения';

  @override
  String get permissionDenied => 'Отказано';

  @override
  String get permissionPermanentlyDenied => 'Отказано навсегда.';

  @override
  String get storagePermissionRequired => 'Нужен доступ к памяти';

  @override
  String get changeCover => 'Сменить обложку';

  @override
  String get showLyrics => 'Показать текст';

  @override
  String get hideLyrics => 'Скрыть текст';

  @override
  String get lyricsEdit => 'Редактировать текст';

  @override
  String get lyricsDelete => 'Удалить текст';

  @override
  String get lyricsDeleteConfirm => 'Удалить текст песни?';

  @override
  String get lyricsImportUrl => 'Из файла';

  @override
  String get lyricsImportClipboard => 'Из буфера обмена';

  @override
  String get lyricsSaved => 'Текст сохранен';

  @override
  String get lyricsDeleted => 'Текст удален';

  @override
  String get lyricsPasteHint => 'Вставьте или напишите текст...';

  @override
  String get unknownArtist => 'Неизвестный исполнитель';

  @override
  String get unknownAlbum => 'Неизвестный альбом';

  @override
  String get unknownTitle => 'Без названия';

  @override
  String get noAlbums => 'Нет альбомов';

  @override
  String get noArtists => 'Нет исполнителей';

  @override
  String get noPlaylists => 'Нет плейлистов';

  @override
  String get noFolders => 'Нет папок';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песен',
      one: '1 песня',
      zero: 'Нет песен',
    );
    return '$_temp0';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count альбомов',
      one: '1 альбом',
      zero: 'Нет альбомов',
    );
    return '$_temp0';
  }

  @override
  String get playlistName => 'Название плейлиста';

  @override
  String get renamePlaylist => 'Переименовать';

  @override
  String get deletePlaylist => 'Удалить плейлист';

  @override
  String get confirmDeletePlaylist => 'Удалить этот плейлист?';

  @override
  String get emptyPlaylist => 'Плейлист пуст';

  @override
  String get addSongs => 'Добавить песни';

  @override
  String get addSongsToPlaylistDesc => 'Добавьте песни для начала';

  @override
  String get playlistCreated => 'Плейлист создан';

  @override
  String get playlistDeleted => 'Плейлист удален';

  @override
  String get playlistRenamed => 'Плейлист переименован';

  @override
  String get songAddedToPlaylist => 'Добавлено в плейлист';

  @override
  String get songRemoved => 'Песня удалена';

  @override
  String get selectPlaylist => 'Выбрать плейлист';

  @override
  String get noPlaylistsCreateOne => 'Нет плейлистов. Создайте.';

  @override
  String get newPlaylist => 'Новый плейлист';

  @override
  String get newPlaylistEllipsis => 'Новый плейлист…';

  @override
  String get create => 'Создать';

  @override
  String get scheduledNext => 'Будет играть далее';

  @override
  String get addedToQueue => 'Добавлено в очередь';

  @override
  String get removedFromHistory => 'Убрано из истории';

  @override
  String get noFavorites => 'Нет избранного';

  @override
  String get addedToFavorites => 'Добавлено в избранное';

  @override
  String get removedFromFavorites => 'Убрано из избранного';

  @override
  String get queue => 'Очередь';

  @override
  String get clearQueue => 'Очистить';

  @override
  String get queueEmpty => 'Очередь пуста';

  @override
  String get confirmClearQueue => 'Очистить очередь?';

  @override
  String get swipeToRemove => 'Свайп для удаления';

  @override
  String get clearHistory => 'Очистить историю';

  @override
  String get historyCleared => 'История очищена';

  @override
  String get options => 'Опции';

  @override
  String get lyrics => 'Текст';

  @override
  String get lyricsFound => 'Текст найден';

  @override
  String get noLyrics => 'Нет текста';

  @override
  String get searchingLyrics => 'Поиск текста...';

  @override
  String get lyricsNotFound => 'Текст не найден';

  @override
  String get lyricsError => 'Ошибка поиска';

  @override
  String get retryLyrics => 'Повторить';

  @override
  String get lyricsDisplay => 'Отображение текста';

  @override
  String get blurBackground => 'Размытый фон';

  @override
  String get blurBackgroundDesc => 'Обложка как фон';

  @override
  String get alignment => 'Выравнивание';

  @override
  String get alignLeft => 'Слева';

  @override
  String get alignCenter => 'По центру';

  @override
  String get textSize => 'Размер текста';

  @override
  String get lineHeight => 'Межстрочный инт.';

  @override
  String get reset => 'Сброс';

  @override
  String get copiedText => 'Найден скопированный текст';

  @override
  String get useAsLyrics => 'Использовать как текст';

  @override
  String get webSearch => 'Поиск в Web';

  @override
  String get tip => 'Совет';

  @override
  String get copyTip => 'Скопируйте текст на сайте, он появится здесь.';

  @override
  String get lyricsCopied => 'Текст скопирован';

  @override
  String get scanningMusic => 'Сканирование...';

  @override
  String get scanComplete => 'Сканирование завершено';

  @override
  String get scanFailed => 'Ошибка сканирования';

  @override
  String foundSongs(int count) {
    return 'Найдено $count песен';
  }

  @override
  String get metadata => 'Метаданные';

  @override
  String get genre => 'Жанр';

  @override
  String get year => 'Год';

  @override
  String get track => 'Трек';

  @override
  String get path => 'Путь';

  @override
  String get size => 'Размер';

  @override
  String get format => 'Формат';

  @override
  String get bitrate => 'Битрейт';

  @override
  String get sampleRate => 'Частота';

  @override
  String get metadataSaved => 'Сохранено';

  @override
  String get metadataFailed => 'Ошибка сохранения';

  @override
  String get coverSaved => 'Обложка сохранена';

  @override
  String get coverFailed => 'Ошибка сохранения';

  @override
  String get confirmDelete => 'Подтверждение';

  @override
  String get fileDeleted => 'Файл удален';

  @override
  String get fileDeletionFailed => 'Ошибка удаления';

  @override
  String get crop => 'Обрезать';

  @override
  String get requiresAndroid10 => 'Нужен Android 10+';

  @override
  String get errorOpeningFolder => 'Ошибка открытия папки';

  @override
  String get imageUpdated => 'Обновлено';

  @override
  String get ringtoneSet => 'Установлено как рингтон';

  @override
  String get sortByName => 'Имя';

  @override
  String get sortByArtist => 'Исполнитель';

  @override
  String get sortByAlbum => 'Альбом';

  @override
  String get sortByDuration => 'Длительность';

  @override
  String get sortByPlayCount => 'Прослушивания';

  @override
  String get shuffleAll => 'Перемешать всё';

  @override
  String get allow => 'Разрешить';

  @override
  String get filterDuration => 'Игнорировать короче чем';

  @override
  String get filterSize => 'Игнорировать меньше чем';

  @override
  String get duration30s => '30 с';

  @override
  String get duration60s => '60 с';

  @override
  String get size50kb => '50 КБ';

  @override
  String get size100kb => '100 КБ';

  @override
  String get startScan => 'НАЧАТЬ СКАН';

  @override
  String get scanningInProgress => 'Сканирование...';

  @override
  String get hideFolder => 'Скрыть папку';

  @override
  String get folderHidden => 'Папка скрыта';

  @override
  String get unhideFolder => 'Показать';

  @override
  String get folderUnhidden => 'Папка показана';

  @override
  String get folderProperties => 'Свойства папки';

  @override
  String get openLocation => 'Открыть расположение';

  @override
  String get viewHiddenFolders => 'Показать скрытые';

  @override
  String get open => 'Открыть';

  @override
  String get copyPath => 'Копировать путь';

  @override
  String get pathCopied => 'Путь скопирован';

  @override
  String get uriNotFound => 'URI не найден';

  @override
  String get ringtoneTitle => 'Рингтон';

  @override
  String setRingtoneConfirm(String title) {
    return 'Установить \"$title\" на звонок?';
  }

  @override
  String get confirm => 'Подтвердить';

  @override
  String get ringtoneSetSuccess => '✓ Установлено на звонок';

  @override
  String get changesSaved => 'Изменения сохранены';

  @override
  String get fileDeletedPermanently => 'Файл удален навсегда';

  @override
  String get editArtistInfo => 'Изменить инфо артиста';

  @override
  String get optional => 'Опционально';

  @override
  String get genreOptional => 'Жанр (опц.)';

  @override
  String get yearOptional => 'Год (опц.)';

  @override
  String get deletePermanently => 'Удалить навсегда?';

  @override
  String get deleteWarningMessage => 'Это действие необратимо удалит:';

  @override
  String get deleteStorageWarning => '⚠️ Файл удалится из памяти телефона';

  @override
  String folderLabel(String name) {
    return 'Папка: $name';
  }

  @override
  String get android10Required => '❌ Нужен Android 10+';

  @override
  String errorWithDetails(String error) {
    return '❌ Ошибка: $error';
  }

  @override
  String get errorPermissionDenied => 'Нет доступа';

  @override
  String get errorFileNotFound => 'Файл не найден';

  @override
  String get errorInsufficientStorage => 'Нет места';

  @override
  String get errorNetworkProblem => 'Нет сети';

  @override
  String get errorCorruptFile => 'Файл поврежден';

  @override
  String get errorGeneric => 'Ошибка';

  @override
  String get sleepTimer => 'Таймер сна';

  @override
  String sleepTimerSet(String duration) {
    return 'Таймер на $duration';
  }

  @override
  String get cancelTimer => 'Отмена таймера';

  @override
  String get customTimer => 'Свой таймер';

  @override
  String get customize => 'Настроить';

  @override
  String get setTimer => 'Установить';

  @override
  String get hours => 'Часов';

  @override
  String get minutes => 'Минут';

  @override
  String get invalidDuration => 'Неверная длительность';

  @override
  String get stopMusicAfter => 'Стоп музыки через';

  @override
  String get start => 'Старт';

  @override
  String get min5 => '5 мин';

  @override
  String get min15 => '15 мин';

  @override
  String get min30 => '30 мин';

  @override
  String get min45 => '45 мин';

  @override
  String get hour1 => '1 час';

  @override
  String get hours2 => '2 часа';

  @override
  String get upNext => 'Далее';

  @override
  String get undo => 'Вернуть';

  @override
  String get permissionAudioTitle => 'Доступ к аудио';

  @override
  String get permissionAudioDesc => 'Чтобы играть музыку';

  @override
  String get permissionNotificationTitle => 'Уведомления';

  @override
  String get permissionNotificationDesc => 'Для управления плеером';

  @override
  String get permissionBatteryTitle => 'Фоновая работа';

  @override
  String get permissionBatteryDesc => 'Чтобы не прерывалось';

  @override
  String get permissionIntro => 'Music Box нужны разрешения для работы.';

  @override
  String get grant => 'Дать';

  @override
  String get enable => 'Включить';

  @override
  String get accessApp => 'Войти в Music Box';

  @override
  String get backupAndData => 'Бэкап и Данные';

  @override
  String get exportData => 'Экспорт данных';

  @override
  String get exportDataDesc => 'Сохранить избранное и плейлисты';

  @override
  String get importBackup => 'Импорт бэкапа';

  @override
  String get importBackupDesc => 'Восстановить из .json';

  @override
  String get attention => 'Внимание';

  @override
  String get restoreWarning => 'Это перезапишет текущие данные.\n\nПродолжить?';

  @override
  String get overwriteAndRestore => 'Перезаписать';

  @override
  String get restoreSuccessTitle => 'Успешно';

  @override
  String get restoreSuccessMessage =>
      'Данные восстановлены.\n\nПерезапустите приложение.';

  @override
  String get backupReadError => 'Ошибка чтения файла.';

  @override
  String get sleepTimerTitle => 'Таймер сна';

  @override
  String get sleepTimerDesc => 'Авто-стоп музыки';

  @override
  String get sleepTimerStoppingSoon => 'Скоро выключится...';

  @override
  String sleepTimerActive(int minutes) {
    return 'Активен: Стоп через $minutes мин';
  }

  @override
  String get sleepTimerStopMusicAfter => 'Выключить через...';

  @override
  String sleepTimerActiveRemaining(int minutes, String seconds) {
    return 'Осталось: $minutes:$seconds';
  }

  @override
  String get deactivate => 'Выкл';

  @override
  String timerSetFor(String label) {
    return 'Таймер на $label 🌙';
  }

  @override
  String get oneHour => '1 час';

  @override
  String get oneHourThirty => '1ч 30';

  @override
  String get twoHours => '2 часа';

  @override
  String get backupSubject => 'Music Box Бэкап';

  @override
  String backupBody(String date) {
    return 'Мой бэкап от $date.';
  }

  @override
  String get contactSubject => 'Поддержка Music Box';

  @override
  String get sortNewest => 'Новые';

  @override
  String get sortOldest => 'Старые';

  @override
  String get sortShortest => 'Короткие';

  @override
  String get sortLongest => 'Длинные';

  @override
  String get noConnectionMessage =>
      'Пожалуйста, проверьте соединение и попробуйте снова';

  @override
  String get selectSource => 'Выберите источник';

  @override
  String get localGallery => 'Галерея';

  @override
  String get preview => 'Предпросмотр';

  @override
  String get useThisImageQuestion => 'Использовать это изображение?';

  @override
  String get useImage => 'Использовать';

  @override
  String get searchOnInternet => 'Поиск в Интернете';
}
