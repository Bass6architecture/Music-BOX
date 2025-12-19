import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Music Box'**
  String get appName;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get remove;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @done.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get done;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @songs.
  ///
  /// In fr, this message translates to:
  /// **'Chansons'**
  String get songs;

  /// No description provided for @playlists.
  ///
  /// In fr, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No description provided for @albums.
  ///
  /// In fr, this message translates to:
  /// **'Albums'**
  String get albums;

  /// No description provided for @artists.
  ///
  /// In fr, this message translates to:
  /// **'Artistes'**
  String get artists;

  /// No description provided for @folders.
  ///
  /// In fr, this message translates to:
  /// **'Dossiers'**
  String get folders;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settings;

  /// No description provided for @nowPlaying.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get nowPlaying;

  /// No description provided for @yourPlaylists.
  ///
  /// In fr, this message translates to:
  /// **'Vos playlists'**
  String get yourPlaylists;

  /// No description provided for @favorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get favorites;

  /// No description provided for @recentlyAdded.
  ///
  /// In fr, this message translates to:
  /// **'Récemment ajoutés'**
  String get recentlyAdded;

  /// No description provided for @recentlyPlayed.
  ///
  /// In fr, this message translates to:
  /// **'Récemment joués'**
  String get recentlyPlayed;

  /// No description provided for @mostPlayed.
  ///
  /// In fr, this message translates to:
  /// **'Les plus joués'**
  String get mostPlayed;

  /// No description provided for @forYou.
  ///
  /// In fr, this message translates to:
  /// **'Pour Vous'**
  String get forYou;

  /// No description provided for @quickPlay.
  ///
  /// In fr, this message translates to:
  /// **'Lecture Rapide'**
  String get quickPlay;

  /// No description provided for @listeningHabits.
  ///
  /// In fr, this message translates to:
  /// **'En Boucle'**
  String get listeningHabits;

  /// No description provided for @forgottenGems.
  ///
  /// In fr, this message translates to:
  /// **'Pépites Oubliées'**
  String get forgottenGems;

  /// No description provided for @allTimeHits.
  ///
  /// In fr, this message translates to:
  /// **'Intemporel'**
  String get allTimeHits;

  /// No description provided for @explore.
  ///
  /// In fr, this message translates to:
  /// **'Explorer'**
  String get explore;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @audio.
  ///
  /// In fr, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @library.
  ///
  /// In fr, this message translates to:
  /// **'Bibliothèque'**
  String get library;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// No description provided for @themeDescription.
  ///
  /// In fr, this message translates to:
  /// **'Thème de l\'application'**
  String get themeDescription;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @themeSystemDesc.
  ///
  /// In fr, this message translates to:
  /// **'Suit le thème du téléphone'**
  String get themeSystemDesc;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeLightDesc.
  ///
  /// In fr, this message translates to:
  /// **'Toujours clair'**
  String get themeLightDesc;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @themeDarkDesc.
  ///
  /// In fr, this message translates to:
  /// **'Toujours sombre'**
  String get themeDarkDesc;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'application'**
  String get languageDescription;

  /// No description provided for @currentLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get currentLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In fr, this message translates to:
  /// **'Langue du système'**
  String get languageSystem;

  /// No description provided for @languageSystemDesc.
  ///
  /// In fr, this message translates to:
  /// **'Suit la langue du téléphone'**
  String get languageSystemDesc;

  /// No description provided for @languageAlreadySelected.
  ///
  /// In fr, this message translates to:
  /// **'Français déjà sélectionné'**
  String get languageAlreadySelected;

  /// No description provided for @languageComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get languageComingSoon;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoon;

  /// No description provided for @languageChanged.
  ///
  /// In fr, this message translates to:
  /// **'Langue changée'**
  String get languageChanged;

  /// No description provided for @languageNeedsRestart.
  ///
  /// In fr, this message translates to:
  /// **'Redémarrage nécessaire pour appliquer la langue'**
  String get languageNeedsRestart;

  /// No description provided for @restartNow.
  ///
  /// In fr, this message translates to:
  /// **'Redémarrer maintenant'**
  String get restartNow;

  /// No description provided for @restartLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get restartLater;

  /// No description provided for @equalizer.
  ///
  /// In fr, this message translates to:
  /// **'Égaliseur'**
  String get equalizer;

  /// No description provided for @equalizerDesc.
  ///
  /// In fr, this message translates to:
  /// **'Régler les basses et les aigus'**
  String get equalizerDesc;

  /// No description provided for @equalizerEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Égaliseur activé'**
  String get equalizerEnabled;

  /// No description provided for @equalizerDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Égaliseur désactivé'**
  String get equalizerDisabled;

  /// No description provided for @noEqualizerFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun égaliseur trouvé sur cet appareil'**
  String get noEqualizerFound;

  /// No description provided for @background.
  ///
  /// In fr, this message translates to:
  /// **'Arrière-plan'**
  String get background;

  /// No description provided for @backgroundDesc.
  ///
  /// In fr, this message translates to:
  /// **'Personnaliser l\'arrière-plan de l\'app'**
  String get backgroundDesc;

  /// No description provided for @backgroundNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get backgroundNone;

  /// No description provided for @backgroundGradientMusical.
  ///
  /// In fr, this message translates to:
  /// **'Dégradé musical'**
  String get backgroundGradientMusical;

  /// No description provided for @backgroundGradientDark.
  ///
  /// In fr, this message translates to:
  /// **'Dégradé sombre'**
  String get backgroundGradientDark;

  /// No description provided for @backgroundParticles.
  ///
  /// In fr, this message translates to:
  /// **'Particules'**
  String get backgroundParticles;

  /// No description provided for @backgroundWaves.
  ///
  /// In fr, this message translates to:
  /// **'Ondes sonores'**
  String get backgroundWaves;

  /// No description provided for @backgroundNeonCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville néon'**
  String get backgroundNeonCity;

  /// No description provided for @backgroundVinylSunset.
  ///
  /// In fr, this message translates to:
  /// **'Coucher de soleil vinyle'**
  String get backgroundVinylSunset;

  /// No description provided for @backgroundAuroraRhythm.
  ///
  /// In fr, this message translates to:
  /// **'Aurore boréale'**
  String get backgroundAuroraRhythm;

  /// No description provided for @backgroundPlayback.
  ///
  /// In fr, this message translates to:
  /// **'Lecture en arrière-plan'**
  String get backgroundPlayback;

  /// No description provided for @backgroundPlaybackDesc.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver l\'optimisation batterie pour une lecture fluide'**
  String get backgroundPlaybackDesc;

  /// No description provided for @batteryOptimizationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter optimisation utilisation batterie ?'**
  String get batteryOptimizationTitle;

  /// No description provided for @batteryOptimizationMessage.
  ///
  /// In fr, this message translates to:
  /// **'Music Box pourra être exécutée en arrière-plan. L\'utilisation de sa batterie ne sera pas limitée.'**
  String get batteryOptimizationMessage;

  /// No description provided for @batteryOptimizationEnabled.
  ///
  /// In fr, this message translates to:
  /// **'✓ Optimisation batterie désactivée'**
  String get batteryOptimizationEnabled;

  /// No description provided for @batteryOptimizationDisabled.
  ///
  /// In fr, this message translates to:
  /// **'⚠️ Optimisation batterie activée (peut causer des coupures)'**
  String get batteryOptimizationDisabled;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres de notification'**
  String get notificationsDesc;

  /// No description provided for @cannotOpenSettings.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir les paramètres'**
  String get cannotOpenSettings;

  /// No description provided for @androidOnly.
  ///
  /// In fr, this message translates to:
  /// **'Disponible uniquement sur Android'**
  String get androidOnly;

  /// No description provided for @scanMusic.
  ///
  /// In fr, this message translates to:
  /// **'Scanner la musique'**
  String get scanMusic;

  /// No description provided for @scanMusicDesc.
  ///
  /// In fr, this message translates to:
  /// **'Détecter les titres manquants'**
  String get scanMusicDesc;

  /// No description provided for @hiddenFolders.
  ///
  /// In fr, this message translates to:
  /// **'Dossiers masqués'**
  String get hiddenFolders;

  /// No description provided for @hiddenFoldersDesc.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les dossiers cachés'**
  String get hiddenFoldersDesc;

  /// No description provided for @version.
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyDesc.
  ///
  /// In fr, this message translates to:
  /// **'Voir notre politique de confidentialité'**
  String get privacyPolicyDesc;

  /// No description provided for @contact.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @contactDesc.
  ///
  /// In fr, this message translates to:
  /// **'synergydevv@gmail.com'**
  String get contactDesc;

  /// No description provided for @cannotOpenPrivacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir la politique de confidentialité'**
  String get cannotOpenPrivacyPolicy;

  /// No description provided for @cannotOpenEmail.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir l\'application mail'**
  String get cannotOpenEmail;

  /// No description provided for @play.
  ///
  /// In fr, this message translates to:
  /// **'Lire'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get previous;

  /// No description provided for @shuffle.
  ///
  /// In fr, this message translates to:
  /// **'Aléatoire'**
  String get shuffle;

  /// No description provided for @repeat.
  ///
  /// In fr, this message translates to:
  /// **'Répéter'**
  String get repeat;

  /// No description provided for @playNext.
  ///
  /// In fr, this message translates to:
  /// **'Lire ensuite'**
  String get playNext;

  /// No description provided for @playAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout lire'**
  String get playAll;

  /// No description provided for @addToQueue.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à la file'**
  String get addToQueue;

  /// No description provided for @addToQueueFull.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à la file d\'attente'**
  String get addToQueueFull;

  /// No description provided for @addToPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à une playlist'**
  String get addToPlaylist;

  /// No description provided for @addToMyPlaylists.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à MES playlists'**
  String get addToMyPlaylists;

  /// No description provided for @removeFromPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la playlist'**
  String get removeFromPlaylist;

  /// No description provided for @removeFromHistory.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de l\'historique'**
  String get removeFromHistory;

  /// No description provided for @addToFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get removeFromFavorites;

  /// No description provided for @goToAlbum.
  ///
  /// In fr, this message translates to:
  /// **'Aller à l\'album'**
  String get goToAlbum;

  /// No description provided for @goToArtist.
  ///
  /// In fr, this message translates to:
  /// **'Aller à l\'artiste'**
  String get goToArtist;

  /// No description provided for @setAsRingtone.
  ///
  /// In fr, this message translates to:
  /// **'Définir comme sonnerie'**
  String get setAsRingtone;

  /// No description provided for @songDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails du morceau'**
  String get songDetails;

  /// No description provided for @editMetadata.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les métadonnées'**
  String get editMetadata;

  /// No description provided for @selectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get selectAll;

  /// No description provided for @deleteSong.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la chanson'**
  String get deleteSong;

  /// No description provided for @confirmDeleteSong.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer ce morceau ?'**
  String get confirmDeleteSong;

  /// No description provided for @songAdded.
  ///
  /// In fr, this message translates to:
  /// **'Chanson ajoutée'**
  String get songAdded;

  /// No description provided for @createPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Créer une playlist'**
  String get createPlaylist;

  /// No description provided for @playlistNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ma playlist'**
  String get playlistNameHint;

  /// No description provided for @allSongs.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les chansons'**
  String get allSongs;

  /// No description provided for @sortBy.
  ///
  /// In fr, this message translates to:
  /// **'Trier par'**
  String get sortBy;

  /// No description provided for @sortAscending.
  ///
  /// In fr, this message translates to:
  /// **'Croissant'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In fr, this message translates to:
  /// **'Décroissant'**
  String get sortDescending;

  /// No description provided for @title.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get title;

  /// No description provided for @artist.
  ///
  /// In fr, this message translates to:
  /// **'Artiste'**
  String get artist;

  /// No description provided for @album.
  ///
  /// In fr, this message translates to:
  /// **'Album'**
  String get album;

  /// No description provided for @duration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get duration;

  /// No description provided for @sortByDateAdded.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'ajout'**
  String get sortByDateAdded;

  /// No description provided for @noSongs.
  ///
  /// In fr, this message translates to:
  /// **'Aucune chanson'**
  String get noSongs;

  /// No description provided for @grantPermission.
  ///
  /// In fr, this message translates to:
  /// **'Accorder'**
  String get grantPermission;

  /// No description provided for @openSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get openSettings;

  /// No description provided for @permissionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Permission Requise'**
  String get permissionRequired;

  /// No description provided for @permissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Permission refusée'**
  String get permissionDenied;

  /// No description provided for @permissionPermanentlyDenied.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez refusé les permissions. Veuillez activer manuellement les permissions dans les paramètres de l\'application.'**
  String get permissionPermanentlyDenied;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Permission de stockage requise pour lire la musique'**
  String get storagePermissionRequired;

  /// No description provided for @changeCover.
  ///
  /// In fr, this message translates to:
  /// **'Changer la pochette'**
  String get changeCover;

  /// No description provided for @showLyrics.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les paroles'**
  String get showLyrics;

  /// No description provided for @hideLyrics.
  ///
  /// In fr, this message translates to:
  /// **'Masquer les paroles'**
  String get hideLyrics;

  /// No description provided for @lyricsEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les paroles'**
  String get lyricsEdit;

  /// No description provided for @lyricsDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les paroles'**
  String get lyricsDelete;

  /// No description provided for @lyricsDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les paroles pour cette chanson ?'**
  String get lyricsDeleteConfirm;

  /// No description provided for @lyricsImportFile.
  ///
  /// In fr, this message translates to:
  /// **'Importer un fichier'**
  String get lyricsImportFile;

  /// No description provided for @lyricsImportClipboard.
  ///
  /// In fr, this message translates to:
  /// **'Coller depuis le presse-papier'**
  String get lyricsImportClipboard;

  /// No description provided for @lyricsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Paroles enregistrées'**
  String get lyricsSaved;

  /// No description provided for @lyricsDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Paroles supprimées'**
  String get lyricsDeleted;

  /// No description provided for @lyricsPasteHint.
  ///
  /// In fr, this message translates to:
  /// **'Collez ou écrivez les paroles ici...'**
  String get lyricsPasteHint;

  /// No description provided for @unknownArtist.
  ///
  /// In fr, this message translates to:
  /// **'Artiste inconnu'**
  String get unknownArtist;

  /// No description provided for @unknownAlbum.
  ///
  /// In fr, this message translates to:
  /// **'Album inconnu'**
  String get unknownAlbum;

  /// No description provided for @unknownTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre inconnu'**
  String get unknownTitle;

  /// No description provided for @noAlbums.
  ///
  /// In fr, this message translates to:
  /// **'Aucun album'**
  String get noAlbums;

  /// No description provided for @noArtists.
  ///
  /// In fr, this message translates to:
  /// **'Aucun artiste'**
  String get noArtists;

  /// No description provided for @noPlaylists.
  ///
  /// In fr, this message translates to:
  /// **'Aucune playlist'**
  String get noPlaylists;

  /// No description provided for @noFolders.
  ///
  /// In fr, this message translates to:
  /// **'Aucun dossier'**
  String get noFolders;

  /// No description provided for @songCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune chanson} =1{1 chanson} other{{count} chansons}}'**
  String songCount(int count);

  /// No description provided for @albumCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun album} =1{1 album} other{{count} albums}}'**
  String albumCount(int count);

  /// No description provided for @playlistName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la playlist'**
  String get playlistName;

  /// No description provided for @renamePlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get renamePlaylist;

  /// No description provided for @deletePlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la playlist'**
  String get deletePlaylist;

  /// No description provided for @confirmDeletePlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer cette playlist ?'**
  String get confirmDeletePlaylist;

  /// No description provided for @emptyPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Playlist vide'**
  String get emptyPlaylist;

  /// No description provided for @addSongs.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des chansons'**
  String get addSongs;

  /// No description provided for @addSongsToPlaylistDesc.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des chansons pour commencer l\'écoute'**
  String get addSongsToPlaylistDesc;

  /// No description provided for @playlistCreated.
  ///
  /// In fr, this message translates to:
  /// **'Playlist créée'**
  String get playlistCreated;

  /// No description provided for @playlistDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Playlist supprimée'**
  String get playlistDeleted;

  /// No description provided for @playlistRenamed.
  ///
  /// In fr, this message translates to:
  /// **'Playlist renommée'**
  String get playlistRenamed;

  /// No description provided for @songAddedToPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté à la playlist'**
  String get songAddedToPlaylist;

  /// No description provided for @songRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Chanson retirée'**
  String get songRemoved;

  /// No description provided for @selectPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une playlist'**
  String get selectPlaylist;

  /// No description provided for @noPlaylistsCreateOne.
  ///
  /// In fr, this message translates to:
  /// **'Aucune playlist. Créez-en une.'**
  String get noPlaylistsCreateOne;

  /// No description provided for @newPlaylist.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle playlist'**
  String get newPlaylist;

  /// No description provided for @newPlaylistEllipsis.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle playlist…'**
  String get newPlaylistEllipsis;

  /// No description provided for @create.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get create;

  /// No description provided for @scheduledNext.
  ///
  /// In fr, this message translates to:
  /// **'Programmée en lecture suivante'**
  String get scheduledNext;

  /// No description provided for @addedToQueue.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté à la file'**
  String get addedToQueue;

  /// No description provided for @removedFromHistory.
  ///
  /// In fr, this message translates to:
  /// **'Retirée de l\'historique'**
  String get removedFromHistory;

  /// No description provided for @noFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Aucun favori'**
  String get noFavorites;

  /// No description provided for @addedToFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté aux favoris'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Retiré des favoris'**
  String get removedFromFavorites;

  /// No description provided for @queue.
  ///
  /// In fr, this message translates to:
  /// **'File d\'attente'**
  String get queue;

  /// No description provided for @clearQueue.
  ///
  /// In fr, this message translates to:
  /// **'Vider la file'**
  String get clearQueue;

  /// No description provided for @queueEmpty.
  ///
  /// In fr, this message translates to:
  /// **'File d\'attente vide'**
  String get queueEmpty;

  /// No description provided for @confirmClearQueue.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vider la file d\'attente ?'**
  String get confirmClearQueue;

  /// No description provided for @swipeToRemove.
  ///
  /// In fr, this message translates to:
  /// **'Glisser pour supprimer'**
  String get swipeToRemove;

  /// No description provided for @clearHistory.
  ///
  /// In fr, this message translates to:
  /// **'Vider l\'historique'**
  String get clearHistory;

  /// No description provided for @historyCleared.
  ///
  /// In fr, this message translates to:
  /// **'Historique vidé'**
  String get historyCleared;

  /// No description provided for @options.
  ///
  /// In fr, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @lyrics.
  ///
  /// In fr, this message translates to:
  /// **'Paroles'**
  String get lyrics;

  /// No description provided for @lyricsFound.
  ///
  /// In fr, this message translates to:
  /// **'Paroles trouvées'**
  String get lyricsFound;

  /// No description provided for @noLyrics.
  ///
  /// In fr, this message translates to:
  /// **'Aucune parole disponible'**
  String get noLyrics;

  /// No description provided for @searchingLyrics.
  ///
  /// In fr, this message translates to:
  /// **'Recherche des paroles...'**
  String get searchingLyrics;

  /// No description provided for @lyricsNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune parole trouvée pour cette chanson'**
  String get lyricsNotFound;

  /// No description provided for @lyricsError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la recherche'**
  String get lyricsError;

  /// No description provided for @retryLyrics.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retryLyrics;

  /// No description provided for @lyricsDisplay.
  ///
  /// In fr, this message translates to:
  /// **'Affichage des paroles'**
  String get lyricsDisplay;

  /// No description provided for @blurBackground.
  ///
  /// In fr, this message translates to:
  /// **'Fond artistique flou'**
  String get blurBackground;

  /// No description provided for @blurBackgroundDesc.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser la pochette en arrière-plan avec un léger flou'**
  String get blurBackgroundDesc;

  /// No description provided for @alignment.
  ///
  /// In fr, this message translates to:
  /// **'Alignement'**
  String get alignment;

  /// No description provided for @alignLeft.
  ///
  /// In fr, this message translates to:
  /// **'Gauche'**
  String get alignLeft;

  /// No description provided for @alignCenter.
  ///
  /// In fr, this message translates to:
  /// **'Centré'**
  String get alignCenter;

  /// No description provided for @textSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille du texte'**
  String get textSize;

  /// No description provided for @lineHeight.
  ///
  /// In fr, this message translates to:
  /// **'Interligne'**
  String get lineHeight;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reset;

  /// No description provided for @copiedText.
  ///
  /// In fr, this message translates to:
  /// **'Texte copié détecté'**
  String get copiedText;

  /// No description provided for @useAsLyrics.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser comme paroles'**
  String get useAsLyrics;

  /// No description provided for @webSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher sur le Web'**
  String get webSearch;

  /// No description provided for @tip.
  ///
  /// In fr, this message translates to:
  /// **'Astuce'**
  String get tip;

  /// No description provided for @copyTip.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez et copiez les paroles sur la page. Elles seront proposées automatiquement ici.'**
  String get copyTip;

  /// No description provided for @lyricsCopied.
  ///
  /// In fr, this message translates to:
  /// **'Paroles copiées'**
  String get lyricsCopied;

  /// No description provided for @scanningMusic.
  ///
  /// In fr, this message translates to:
  /// **'Analyse en cours...'**
  String get scanningMusic;

  /// No description provided for @scanComplete.
  ///
  /// In fr, this message translates to:
  /// **'Analyse terminée'**
  String get scanComplete;

  /// No description provided for @scanFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'analyse'**
  String get scanFailed;

  /// No description provided for @foundSongs.
  ///
  /// In fr, this message translates to:
  /// **'{count} chansons trouvées'**
  String foundSongs(int count);

  /// No description provided for @metadata.
  ///
  /// In fr, this message translates to:
  /// **'Métadonnées'**
  String get metadata;

  /// No description provided for @genre.
  ///
  /// In fr, this message translates to:
  /// **'Genre'**
  String get genre;

  /// No description provided for @year.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get year;

  /// No description provided for @track.
  ///
  /// In fr, this message translates to:
  /// **'Piste'**
  String get track;

  /// No description provided for @path.
  ///
  /// In fr, this message translates to:
  /// **'Chemin'**
  String get path;

  /// No description provided for @size.
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get size;

  /// No description provided for @format.
  ///
  /// In fr, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @bitrate.
  ///
  /// In fr, this message translates to:
  /// **'Débit'**
  String get bitrate;

  /// No description provided for @sampleRate.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence d\'échantillonnage'**
  String get sampleRate;

  /// No description provided for @metadataSaved.
  ///
  /// In fr, this message translates to:
  /// **'Métadonnées enregistrées'**
  String get metadataSaved;

  /// No description provided for @metadataFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'enregistrement'**
  String get metadataFailed;

  /// No description provided for @coverSaved.
  ///
  /// In fr, this message translates to:
  /// **'Pochette enregistrée'**
  String get coverSaved;

  /// No description provided for @coverFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'enregistrement'**
  String get coverFailed;

  /// No description provided for @confirmDelete.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get confirmDelete;

  /// No description provided for @fileDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Fichier supprimé'**
  String get fileDeleted;

  /// No description provided for @fileDeletionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la suppression'**
  String get fileDeletionFailed;

  /// No description provided for @crop.
  ///
  /// In fr, this message translates to:
  /// **'Recadrer'**
  String get crop;

  /// No description provided for @requiresAndroid10.
  ///
  /// In fr, this message translates to:
  /// **'Cette fonctionnalité nécessite Android 10+'**
  String get requiresAndroid10;

  /// No description provided for @errorOpeningFolder.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'ouverture du dossier'**
  String get errorOpeningFolder;

  /// No description provided for @imageUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Image mise à jour'**
  String get imageUpdated;

  /// No description provided for @ringtoneSet.
  ///
  /// In fr, this message translates to:
  /// **'Défini comme sonnerie d\'appel'**
  String get ringtoneSet;

  /// No description provided for @sortByName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get sortByName;

  /// No description provided for @sortByArtist.
  ///
  /// In fr, this message translates to:
  /// **'Artiste'**
  String get sortByArtist;

  /// No description provided for @sortByAlbum.
  ///
  /// In fr, this message translates to:
  /// **'Album'**
  String get sortByAlbum;

  /// No description provided for @sortByDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get sortByDuration;

  /// No description provided for @sortByPlayCount.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de lectures'**
  String get sortByPlayCount;

  /// No description provided for @shuffleAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout lire aléatoirement'**
  String get shuffleAll;

  /// No description provided for @allow.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser'**
  String get allow;

  /// No description provided for @filterDuration.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer les durées inférieures à'**
  String get filterDuration;

  /// No description provided for @filterSize.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer les tailles inférieures à'**
  String get filterSize;

  /// No description provided for @duration30s.
  ///
  /// In fr, this message translates to:
  /// **'30 s'**
  String get duration30s;

  /// No description provided for @duration60s.
  ///
  /// In fr, this message translates to:
  /// **'60 s'**
  String get duration60s;

  /// No description provided for @size50kb.
  ///
  /// In fr, this message translates to:
  /// **'50 KB'**
  String get size50kb;

  /// No description provided for @size100kb.
  ///
  /// In fr, this message translates to:
  /// **'100 KB'**
  String get size100kb;

  /// No description provided for @startScan.
  ///
  /// In fr, this message translates to:
  /// **'DÉMARRER L\'ANALYSE'**
  String get startScan;

  /// No description provided for @scanningInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Analyse en cours...'**
  String get scanningInProgress;

  /// No description provided for @hideFolder.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le dossier'**
  String get hideFolder;

  /// No description provided for @folderHidden.
  ///
  /// In fr, this message translates to:
  /// **'Dossier masqué'**
  String get folderHidden;

  /// No description provided for @unhideFolder.
  ///
  /// In fr, this message translates to:
  /// **'Démasquer'**
  String get unhideFolder;

  /// No description provided for @folderUnhidden.
  ///
  /// In fr, this message translates to:
  /// **'Dossier démasqué'**
  String get folderUnhidden;

  /// No description provided for @folderProperties.
  ///
  /// In fr, this message translates to:
  /// **'Propriétés du dossier'**
  String get folderProperties;

  /// No description provided for @openLocation.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir l\'emplacement'**
  String get openLocation;

  /// No description provided for @viewHiddenFolders.
  ///
  /// In fr, this message translates to:
  /// **'Voir dossiers masqués'**
  String get viewHiddenFolders;

  /// No description provided for @open.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get open;

  /// No description provided for @copyPath.
  ///
  /// In fr, this message translates to:
  /// **'Copier chemin'**
  String get copyPath;

  /// No description provided for @pathCopied.
  ///
  /// In fr, this message translates to:
  /// **'Chemin copié'**
  String get pathCopied;

  /// No description provided for @uriNotFound.
  ///
  /// In fr, this message translates to:
  /// **'URI du fichier introuvable'**
  String get uriNotFound;

  /// No description provided for @ringtoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sonnerie d\'appel'**
  String get ringtoneTitle;

  /// No description provided for @setRingtoneConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Définir \"{title}\" comme sonnerie d\'appel ?'**
  String setRingtoneConfirm(String title);

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @ringtoneSetSuccess.
  ///
  /// In fr, this message translates to:
  /// **'✓ Défini comme sonnerie d\'appel'**
  String get ringtoneSetSuccess;

  /// No description provided for @changesSaved.
  ///
  /// In fr, this message translates to:
  /// **'Modifications enregistrées'**
  String get changesSaved;

  /// No description provided for @fileDeletedPermanently.
  ///
  /// In fr, this message translates to:
  /// **'Fichier supprimé définitivement'**
  String get fileDeletedPermanently;

  /// No description provided for @editArtistInfo.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les infos de l\'artiste'**
  String get editArtistInfo;

  /// No description provided for @optional.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif'**
  String get optional;

  /// No description provided for @genreOptional.
  ///
  /// In fr, this message translates to:
  /// **'Genre (Facultatif)'**
  String get genreOptional;

  /// No description provided for @yearOptional.
  ///
  /// In fr, this message translates to:
  /// **'Année (Facultatif)'**
  String get yearOptional;

  /// No description provided for @deletePermanently.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement ?'**
  String get deletePermanently;

  /// No description provided for @deleteWarningMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible et supprimera :'**
  String get deleteWarningMessage;

  /// No description provided for @deleteStorageWarning.
  ///
  /// In fr, this message translates to:
  /// **'⚠️ Le fichier sera supprimé du stockage de votre téléphone'**
  String get deleteStorageWarning;

  /// No description provided for @folderLabel.
  ///
  /// In fr, this message translates to:
  /// **'Dossier : {name}'**
  String folderLabel(String name);

  /// No description provided for @android10Required.
  ///
  /// In fr, this message translates to:
  /// **'❌ Cette fonctionnalité nécessite Android 10+'**
  String get android10Required;

  /// No description provided for @errorWithDetails.
  ///
  /// In fr, this message translates to:
  /// **'❌ Erreur : {error}'**
  String errorWithDetails(String error);

  /// No description provided for @errorPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Permission refusée. Vérifiez les paramètres de l\'application'**
  String get errorPermissionDenied;

  /// No description provided for @errorFileNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Fichier introuvable'**
  String get errorFileNotFound;

  /// No description provided for @errorInsufficientStorage.
  ///
  /// In fr, this message translates to:
  /// **'Espace de stockage insuffisant'**
  String get errorInsufficientStorage;

  /// No description provided for @errorNetworkProblem.
  ///
  /// In fr, this message translates to:
  /// **'Problème de connexion'**
  String get errorNetworkProblem;

  /// No description provided for @errorCorruptFile.
  ///
  /// In fr, this message translates to:
  /// **'Fichier corrompu ou format invalide'**
  String get errorCorruptFile;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get errorGeneric;

  /// No description provided for @sleepTimer.
  ///
  /// In fr, this message translates to:
  /// **'Minuteur de sommeil'**
  String get sleepTimer;

  /// No description provided for @sleepTimerSet.
  ///
  /// In fr, this message translates to:
  /// **'Minuteur réglé sur {duration}'**
  String sleepTimerSet(String duration);

  /// No description provided for @cancelTimer.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le minuteur'**
  String get cancelTimer;

  /// No description provided for @customTimer.
  ///
  /// In fr, this message translates to:
  /// **'Minuteur personnalisé'**
  String get customTimer;

  /// No description provided for @customize.
  ///
  /// In fr, this message translates to:
  /// **'Personnaliser'**
  String get customize;

  /// No description provided for @setTimer.
  ///
  /// In fr, this message translates to:
  /// **'Définir'**
  String get setTimer;

  /// No description provided for @hours.
  ///
  /// In fr, this message translates to:
  /// **'Heures'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In fr, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @invalidDuration.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez définir une durée valide'**
  String get invalidDuration;

  /// No description provided for @stopMusicAfter.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter la musique après'**
  String get stopMusicAfter;

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get start;

  /// No description provided for @min5.
  ///
  /// In fr, this message translates to:
  /// **'5 min'**
  String get min5;

  /// No description provided for @min15.
  ///
  /// In fr, this message translates to:
  /// **'15 min'**
  String get min15;

  /// No description provided for @min30.
  ///
  /// In fr, this message translates to:
  /// **'30 min'**
  String get min30;

  /// No description provided for @min45.
  ///
  /// In fr, this message translates to:
  /// **'45 min'**
  String get min45;

  /// No description provided for @hour1.
  ///
  /// In fr, this message translates to:
  /// **'1 heure'**
  String get hour1;

  /// No description provided for @hours2.
  ///
  /// In fr, this message translates to:
  /// **'2 heures'**
  String get hours2;

  /// No description provided for @upNext.
  ///
  /// In fr, this message translates to:
  /// **'À suivre'**
  String get upNext;

  /// No description provided for @undo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get undo;

  /// No description provided for @permissionAudioTitle.
  ///
  /// In fr, this message translates to:
  /// **'Accès Audio'**
  String get permissionAudioTitle;

  /// No description provided for @permissionAudioDesc.
  ///
  /// In fr, this message translates to:
  /// **'Pour lire vos fichiers musicaux locaux'**
  String get permissionAudioDesc;

  /// No description provided for @permissionNotificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get permissionNotificationTitle;

  /// No description provided for @permissionNotificationDesc.
  ///
  /// In fr, this message translates to:
  /// **'Pour les contrôles de lecture'**
  String get permissionNotificationDesc;

  /// No description provided for @permissionBatteryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lecture en arrière-plan'**
  String get permissionBatteryTitle;

  /// No description provided for @permissionBatteryDesc.
  ///
  /// In fr, this message translates to:
  /// **'Évite les coupures quand l\'écran est éteint'**
  String get permissionBatteryDesc;

  /// No description provided for @permissionIntro.
  ///
  /// In fr, this message translates to:
  /// **'Pour vous offrir la meilleure expérience musicale, Music Box a besoin de quelques autorisations.'**
  String get permissionIntro;

  /// No description provided for @grant.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser'**
  String get grant;

  /// No description provided for @enable.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get enable;

  /// No description provided for @accessApp.
  ///
  /// In fr, this message translates to:
  /// **'Accéder à Music Box'**
  String get accessApp;

  /// No description provided for @backupAndData.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde & Données'**
  String get backupAndData;

  /// No description provided for @exportData.
  ///
  /// In fr, this message translates to:
  /// **'Exporter les données'**
  String get exportData;

  /// No description provided for @exportDataDesc.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder favoris, playlists et stats'**
  String get exportDataDesc;

  /// No description provided for @importBackup.
  ///
  /// In fr, this message translates to:
  /// **'Importer une sauvegarde'**
  String get importBackup;

  /// No description provided for @importBackupDesc.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer depuis un fichier .json'**
  String get importBackupDesc;

  /// No description provided for @attention.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get attention;

  /// No description provided for @restoreWarning.
  ///
  /// In fr, this message translates to:
  /// **'La restauration va écraser vos favoris et playlists actuels.\n\nVoulez-vous continuer ?'**
  String get restoreWarning;

  /// No description provided for @overwriteAndRestore.
  ///
  /// In fr, this message translates to:
  /// **'Écraser et Restaurer'**
  String get overwriteAndRestore;

  /// No description provided for @restoreSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Restauration réussie'**
  String get restoreSuccessTitle;

  /// No description provided for @restoreSuccessMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vos données ont été restaurées avec succès.\n\nVeuillez redémarrer l\'application pour que tous les changements prennent effet.'**
  String get restoreSuccessMessage;

  /// No description provided for @backupReadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire le fichier de sauvegarde.'**
  String get backupReadError;

  /// No description provided for @sleepTimerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Minuteur de veille'**
  String get sleepTimerTitle;

  /// No description provided for @sleepTimerDesc.
  ///
  /// In fr, this message translates to:
  /// **'Programmer l\'arrêt de la musique'**
  String get sleepTimerDesc;

  /// No description provided for @sleepTimerStoppingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Arrêt imminent...'**
  String get sleepTimerStoppingSoon;

  /// No description provided for @sleepTimerActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif : Arrêt dans {minutes} min'**
  String sleepTimerActive(int minutes);

  /// No description provided for @sleepTimerStopMusicAfter.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter la musique après...'**
  String get sleepTimerStopMusicAfter;

  /// No description provided for @sleepTimerActiveRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Actif : {minutes}:{seconds} restants'**
  String sleepTimerActiveRemaining(int minutes, String seconds);

  /// No description provided for @deactivate.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get deactivate;

  /// No description provided for @timerSetFor.
  ///
  /// In fr, this message translates to:
  /// **'Minuteur réglé pour {label} 🌙'**
  String timerSetFor(String label);

  /// No description provided for @oneHour.
  ///
  /// In fr, this message translates to:
  /// **'1 heure'**
  String get oneHour;

  /// No description provided for @oneHourThirty.
  ///
  /// In fr, this message translates to:
  /// **'1h 30'**
  String get oneHourThirty;

  /// No description provided for @twoHours.
  ///
  /// In fr, this message translates to:
  /// **'2 heures'**
  String get twoHours;

  /// No description provided for @backupSubject.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde Music Box'**
  String get backupSubject;

  /// No description provided for @backupBody.
  ///
  /// In fr, this message translates to:
  /// **'Voici ma sauvegarde Music Box du {date}.'**
  String backupBody(String date);

  /// No description provided for @contactSubject.
  ///
  /// In fr, this message translates to:
  /// **'Support Music Box'**
  String get contactSubject;

  /// No description provided for @sortNewest.
  ///
  /// In fr, this message translates to:
  /// **'Récent'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In fr, this message translates to:
  /// **'Ancien'**
  String get sortOldest;

  /// No description provided for @sortShortest.
  ///
  /// In fr, this message translates to:
  /// **'Court'**
  String get sortShortest;

  /// No description provided for @sortLongest.
  ///
  /// In fr, this message translates to:
  /// **'Long'**
  String get sortLongest;

  /// No description provided for @noConnectionMessage.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vérifier votre connexion et réessayer'**
  String get noConnectionMessage;

  /// No description provided for @selectSource.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner la source'**
  String get selectSource;

  /// No description provided for @localGallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get localGallery;

  /// No description provided for @preview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get preview;

  /// No description provided for @useThisImageQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser cette image ?'**
  String get useThisImageQuestion;

  /// No description provided for @useImage.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser l\'image'**
  String get useImage;

  /// No description provided for @searchOnInternet.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher sur Internet'**
  String get searchOnInternet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
