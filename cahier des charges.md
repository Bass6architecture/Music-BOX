
# Cahier des Charges Complet : Music Box 🎵

## 1. Vue d'Ensemble du Projet

### 1.1. Description Générale
**Music Box** est une application mobile native, développée en **Flutter**, pour offrir une expérience de lecture musicale locale de haute qualité. L'application gère exclusivement les fichiers audio stockés sur l'appareil de l'utilisateur, fonctionnant sans connexion internet.

### 1.2. Caractéristiques Clés
* **Nom** : Music Box
* **Plateformes** : Android (API 21+) & iOS (iOS 12+)
* **Framework** : Flutter avec Dart
* **Modèle Économique** : Freemium avec publicités
* **Objectifs** :
    * Expérience utilisateur fluide pour la gestion musicale locale.
    * Performance et ergonomie supérieures aux concurrents.
    * Fonctionnalités avancées de personnalisation.
    * Création de revenus stables via la publicité.

### 1.3. Public Cible
* **Profils** : Audiophiles, utilisateurs avec connectivité limitée, personnes soucieuses de la confidentialité.
* **Démographie** : 16-45 ans, avec une familiarité technologique intermédiaire à avancée.

---

## 2. Analyse du Marché et Positionnement

### 2.1. Concurrence
* **Concurrents directs** : Poweramp, VLC Media Player, BlackPlayer, Musicolet.
* **Avantages de Music Box** : Interface moderne en Flutter, animations fluides, système de tri avancé, gestion intuitive des playlists, performance optimisée pour les grandes bibliothèques.

### 2.2. Positionnement Stratégique
Music Box se positionne comme le lecteur musical local **premium et moderne**, alliant simplicité et fonctionnalités avancées pour les utilisateurs exigeants.

---

## 3. Spécifications Techniques

### 3.1. Technologies et Dépendances
* **Framework** : Flutter
* **Langage** : Dart
* **SDKs** : Android API 21+ (cible 34), iOS 12+ (cible 17)
* **Dépendances clés** : `just_audio`, `audio_service`, `sqflite`, `hive`, `flutter_bloc`, `google_mobile_ads`.

### 3.2. Architecture
L'application suivra une **architecture en couches** inspirée de la **Clean Architecture** :
* **Présentation** : Widgets, pages, thèmes.
* **Logique Métier** : Gestion d'état avec **BLoC**, services, cas d'usage.
* **Données** : Repositories et sources de données (locale, système de fichiers).
* **Core** : Utilitaires et injection de dépendances.

---

## 4. Spécifications Fonctionnelles Détaillées

### 4.1. Scan et Indexation
* **Fonctionnalités** : Scan automatique/manuel, scan incrémental, support multi-formats (MP3, FLAC, etc.).
* **Performance** : Moins d'une seconde pour 100 fichiers, utilisation mémoire < 50MB.

### 4.2. Lecture Audio
* **Contrôles** : Play/Pause, Suivant/Précédent, barre de progression interactive.
* **Modes** : Normal, aléatoire (Fisher-Yates), répétition (un/toute la playlist).
* **Gestion des interruptions** : Pause automatique lors d'appels, notifications, déconnexion des écouteurs.

### 4.3. Gestion des Playlists
* **Fonctions** : Création, modification, suppression, duplication.
* **Contenu** : Ajout/suppression de chansons (sélection multiple, drag & drop), réorganisation, tri automatique.
* **Playlists intelligentes** : Récemment ajoutées, plus écoutées, favorites, par genre.

### 4.4. Recherche et Métadonnées
* **Recherche** : Textuelle (titre, artiste, album), phonétique, filtres combinés.
* **Extraction** : Tags ID3 (v1, v2.3, v2.4), informations techniques (bitrate, durée).
* **Édition** : Interface pour la modification manuelle des champs, sauvegarde en base de données locale.

---

## 5. Design et Expérience Utilisateur

### 5.1. Principes de Design
* **Design System** : Un système de design cohérent sera utilisé pour assurer une expérience utilisateur native et une interface claire sur Android et iOS.
* **Thèmes** : Prise en charge des thèmes clair et sombre avec une palette de couleurs définie.
* **Accessibilité** : Conforme WCAG AA pour le contraste et la prise en charge des lecteurs d'écran.

### 5.2. Spécifications des Pages
* **Accueil** : Barre de recherche rapide, filtres, liste virtualisée des chansons, mini-lecteur flottant et bannière publicitaire.
* **Lecture** : Affichage de la pochette, informations de la chanson, barre de progression, contrôles de lecture et actions secondaires.
* **Playlists** : Bouton de création, liste des playlists avec aperçu, et options de tri.
* **Recherche** : Champ de recherche principal, filtres rapides, historique et résultats organisés par catégorie.

### 5.3. Animations et Micro-interactions
Transitions de pages fluides, animations de liste (ajout, suppression), effets visuels (ripple, morphing d'icônes) et retours haptiques pour une expérience riche et dynamique.

---

## 6. Gestion et Sécurité des Données

### 6.1. Base de Données Locale
* **Technologies** : **SQLite** (`sqflite`) pour les données structurées et **Hive** pour le stockage rapide clé-valeur.
* **Schéma** : Tables pour les chansons, les playlists, et une table de liaison pour les relations.
* **Optimisation** : Indexation des données pour une recherche rapide.

### 6.2. Permissions
* **Android** : `READ_MEDIA_AUDIO` (Android 13+), `READ_EXTERNAL_STORAGE`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `INTERNET`.
* **iOS** : Descriptions d'usage pour l'accès à la bibliothèque musicale.
* **Sécurité** : Base de données chiffrée avec SQLCipher, validation des entrées utilisateur.

---

## 7. Monétisation et Performance

### 7.1. Stratégie Publicitaire
* **Configuration AdMob** :
    * **ID Application** : `ca-app-pub-9535801913153032~9005375360`
    * **ID Bannière** : `ca-app-pub-9535801913153032/3435168691`
    * **ID Interstitiel** : `ca-app-pub-9535801913153032/2128141673`
* **Placement** : Bannière en bas de page d'accueil, interstitiel toutes les 5 chansons.
* **Objectif de revenus** : eCPM cible de **2-5$**.

### 7.2. KPIs et Analytics
* **Outil** : **Firebase Analytics** pour le suivi des événements et propriétés utilisateur.
* **KPIs Principaux** :
    * **Rétention** : J1 > 70%, J7 > 40%, J30 > 20%
    * **Engagement** : Sessions/jour > 3, durée > 15 min
    * **Monétisation** : ARPU > $1/mois, eCPM > $2
    * **Performance** : Crash rate < 1%, ANR < 0.5%

---

## 8. Plan de Développement

* **Phase 1 (4 semaines)** : Fondations (Setup, architecture, scan et lecture audio de base).
* **Phase 2 (6 semaines)** : Fonctionnalités Principales (UI, playlists, recherche et métadonnées).
* **Phase 3 (4 semaines)** : Fonctionnalités Avancées (Personnalisation, intégration de la monétisation).

---

**Note importante :** Il est impératif de **ne pas modifier le fichier `build.gradle`** ni les configurations de projet liées à Gradle, sous peine de provoquer des erreurs de compilation et de rendre l'application inutilisable.