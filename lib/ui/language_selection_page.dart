import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/l10n/locale_cubit.dart';
import '../generated/app_localizations.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final localeCubit = context.watch<LocaleCubit>();
    final currentLocale = localeCubit.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ✅ Option "Système"
          ListTile(
            onTap: () async {
              await localeCubit.setLocale(null); // null = système
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            title: Text(
              l10n.languageSystem, // "Langue du système"
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: Text(
              l10n.languageSystemDesc, // "Suit la langue du téléphone"
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            leading: const Text(
              '📱',
              style: TextStyle(fontSize: 24),
            ),
            trailing: Radio<String?>(
              value: null, // null représente le choix "Système"
              groupValue: localeCubit.isSystemMode ? null : 'not_null', // Si mode système, on matche avec null
              onChanged: (value) async {
                 await localeCubit.setLocale(null);
                 if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
          const Divider(),
          ...LocaleCubit.availableLocales.map((localeInfo) {
          final isSelected = currentLocale.languageCode == localeInfo.locale.languageCode;
          final isAvailable = !localeInfo.comingSoon;
          
          return ListTile(
            onTap: isAvailable 
                ? () async {
                    if (!isSelected) {
                      await localeCubit.setLocale(localeInfo.locale);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  }
                : null,
            title: Text(
              localeInfo.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isAvailable ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            subtitle: !isAvailable 
                ? Text(
                    l10n.languageComingSoon,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.error,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : null,
            leading: Text(
              localeInfo.flag,
              style: TextStyle(
                fontSize: 24,
                color: isAvailable ? null : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            trailing: Radio<String>(
              value: localeInfo.locale.languageCode,
              // Si on est en mode système, aucun bouton radio manuel ne doit être coché
              groupValue: localeCubit.isSystemMode ? null : currentLocale.languageCode,
              onChanged: isAvailable 
                  ? (value) async {
                      if (value != null && (!isSelected || localeCubit.isSystemMode)) {
                        await localeCubit.setLocale(localeInfo.locale);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    }
                  : null,
              activeColor: theme.colorScheme.primary,
            ),
            shape: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          );
        }).toList(),
        ],
      ),
    );
  }
}
