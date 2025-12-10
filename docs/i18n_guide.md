# Guide d'internationalisation (i18n) - Music Box

## 📖 Vue d'ensemble

Music Box utilise le système officiel Flutter pour l'internationalisation avec **flutter_localizations** et **intl**.

### Langues supportées
- ✅ **Français** (fr) - Par défaut
- ✅ **Anglais** (en)
- 🔜 Arabe (ar)
- 🔜 Espagnol (es)
- 🔜 Portugais (pt)
- 🔜 Hindi (hi)
- 🔜 Allemand (de)
- 🔜 Italien (it)
- 🔜 Russe (ru)
- 🔜 Chinois simplifié (zh)

---

## 🚀 Utilisation dans le code

### Méthode 1 : Via AppLocalizations
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  return Text(l10n.appName); // "Music Box"
  return Text(l10n.songs);   // "Chansons" ou "Songs"
}
```

### Méthode 2 : Via extension (recommandé)
```dart
import 'package:music_box/core/l10n/l10n_extensions.dart';

Widget build(BuildContext context) {
  return Text(context.l10n.albums);
  return Text(context.l10n.artists);
}
```

---

## 📝 Ajouter une nouvelle traduction

### 1. Ajouter dans `lib/l10n/app_fr.arb`
```json
{
  "myNewString": "Mon nouveau texte",
  "@myNewString": {
    "description": "Description optionnelle"
  }
}
```

### 2. Ajouter dans `lib/l10n/app_en.arb`
```json
{
  "myNewString": "My new text"
}
```

### 3. Régénérer les fichiers
```bash
flutter pub get
```

Les fichiers de localisation sont générés automatiquement dans `.dart_tool/flutter_gen/`.

---

## 🔄 Traductions avec paramètres

### Texte avec variable
```json
{
  "version": "Version {version}",
  "@version": {
    "placeholders": {
      "version": {
        "type": "String"
      }
    }
  }
}
```

Utilisation :
```dart
Text(l10n.version('1.0.1')) // "Version 1.0.1"
```

### Pluralisation
```json
{
  "songCount": "{count, plural, =0{Aucune chanson} =1{1 chanson} other{{count} chansons}}",
  "@songCount": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

Utilisation :
```dart
Text(l10n.songCount(0))  // "Aucune chanson"
Text(l10n.songCount(1))  // "1 chanson"
Text(l10n.songCount(10)) // "10 chansons"
```

---

## 🌍 Changer la langue

### Dans les paramètres
L'utilisateur peut changer la langue via **Réglages** → **Langue**.

### Programmatiquement
```dart
import 'package:music_box/core/l10n/locale_cubit.dart';

// Changer vers l'anglais
context.read<LocaleCubit>().setLocale(const Locale('en'));

// Changer vers le français
context.read<LocaleCubit>().setLocale(const Locale('fr'));
```

---

## ♻️ Redémarrage de l'app

Quand l'utilisateur change de langue, un dialogue propose de redémarrer l'app :
- **Redémarrer maintenant** : Force la fermeture de l'app
- **Plus tard** : Continue avec l'ancienne langue (changera au prochain démarrage)

Le redémarrage utilise :
```dart
SystemChannels.platform.invokeMethod('SystemNavigator.pop');
```

---

## 📂 Structure des fichiers

```
lib/
├── l10n/
│   ├── app_fr.arb         # Traductions françaises (template)
│   └── app_en.arb         # Traductions anglaises
├── core/
│   └── l10n/
│       ├── locale_cubit.dart      # Gestion de la locale
│       └── l10n_extensions.dart   # Extension helper
l10n.yaml                  # Configuration
```

---

## ⚠️ Bonnes pratiques

1. **Ne jamais hardcoder du texte** visible par l'utilisateur
   ```dart
   // ❌ Mauvais
   Text('Chansons')
   
   // ✅ Bon
   Text(l10n.songs)
   ```

2. **Toujours ajouter les traductions dans TOUS les fichiers ARB**
   - Si une langue manque une traduction, l'app crashera

3. **Utiliser des descriptions** pour les clés complexes
   ```json
   {
     "myKey": "Texte",
     "@myKey": {
       "description": "Explication du contexte d'utilisation"
     }
   }
   ```

4. **Tester dans toutes les langues** après chaque ajout

---

## 🔧 Ajouter une nouvelle langue

### 1. Créer le fichier ARB
Créer `lib/l10n/app_es.arb` pour l'espagnol :
```json
{
  "@@locale": "es",
  "appName": "Music Box",
  "songs": "Canciones",
  ...
}
```

### 2. Ajouter dans LocaleCubit
```dart
static const List<Locale> supportedLocales = [
  Locale('fr'),
  Locale('en'),
  Locale('es'), // ← Ajouter ici
];

static const List<LocaleInfo> availableLocales = [
  // ...
  LocaleInfo(
    locale: Locale('es'),
    name: 'Español',
    flag: '🇪🇸',
    comingSoon: false, // ← Changer à false
  ),
];
```

### 3. Régénérer
```bash
flutter pub get
```

---

## 🐛 Dépannage

### Erreur: "No AppLocalizations found"
→ Relancez `flutter pub get`

### Erreur: "Invalid ARB resource name"
→ Les noms de clés doivent être en camelCase sans underscore au début

### Les traductions ne s'affichent pas
→ Vérifiez que `generate: true` est dans `pubspec.yaml`

---

## 📚 Ressources

- [Flutter Internationalization](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [ARB Format Specification](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [Intl Package](https://pub.dev/packages/intl)
