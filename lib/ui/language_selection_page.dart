import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/l10n/locale_cubit.dart';
import '../generated/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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
        title: Text(l10n.language, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
              l10n.languageSystem,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.languageSystemDesc,
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: PhosphorIcon(PhosphorIcons.translate(), color: theme.colorScheme.primary),
            ),
            trailing: Radio<String?>(
              value: null,
              // ignore: deprecated_member_use
              groupValue: localeCubit.isSystemMode ? null : 'not_null',
              // ignore: deprecated_member_use
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
              style: GoogleFonts.outfit(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isAvailable ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            subtitle: !isAvailable 
                ? Text(
                    l10n.languageComingSoon,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: theme.colorScheme.error,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : null,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                localeInfo.flag,
                style: TextStyle(
                  fontSize: 20,
                  color: isAvailable ? null : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            trailing: Radio<String>(
              value: localeInfo.locale.languageCode,
              // ignore: deprecated_member_use
              groupValue: localeCubit.isSystemMode ? null : currentLocale.languageCode,
              // ignore: deprecated_member_use
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
        }),
        ],
      ),
    );
  }
}
