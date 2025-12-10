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
        children: LocaleCubit.availableLocales.map((localeInfo) {
          final isSelected = currentLocale.languageCode == localeInfo.locale.languageCode;
          final isAvailable = !localeInfo.comingSoon;
          
          return ListTile(
            onTap: isAvailable 
                ? () async {
                    if (!isSelected) {
                      await localeCubit.setLocale(localeInfo.locale);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.languageChanged),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
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
              // ignore: deprecated_member_use
              groupValue: currentLocale.languageCode,
              // ignore: deprecated_member_use
              onChanged: isAvailable 
                  ? (value) async {
                      if (value != null && !isSelected) {
                        await localeCubit.setLocale(localeInfo.locale);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.languageChanged),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
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
      ),
    );
  }
}
