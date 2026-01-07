import 'widgets/music_box_scaffold.dart';
import 'package:flutter/material.dart';

import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_box/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'scan_music_page.dart';
import 'hidden_folders_page.dart';
import 'language_selection_page.dart';
import 'internal_browser_page.dart';
import 'background_selection_page.dart';
import '../core/theme/theme_cubit.dart';
import '../core/l10n/locale_cubit.dart';
import '../core/background/background_cubit.dart';
import '../player/player_cubit.dart';
import '../services/battery_optimization_service.dart';
import '../services/data_backup_service.dart';

import 'widgets/sleep_timer_dialog.dart';
import 'screens/equalizer_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isIgnoringBatteryOptimizations = false;

  @override
  void initState() {
    super.initState();
    _checkBatteryOptimization();
  }

  Future<void> _checkBatteryOptimization() async {
    final isIgnoring = await BatteryOptimizationService.isIgnoringBatteryOptimizations();
    if (mounted) {
      setState(() {
        _isIgnoringBatteryOptimizations = isIgnoring;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final localeCubit = context.watch<LocaleCubit>();
    
    final content = ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      children: [
        // Section: Apparence
        _buildSectionHeader(context, l10n.appearance),
        _buildSection(context, [
          BlocBuilder<BackgroundCubit, BackgroundType>(
            builder: (context, backgroundType) {
              final hasCustomBackground = backgroundType != BackgroundType.none;
              
              return BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  String themeLabel;
                  if (hasCustomBackground) {
                    themeLabel = '${l10n.themeDark} (${l10n.backgroundDesc})';
                  } else {
                    switch (themeMode) {
                      case ThemeMode.system:
                        themeLabel = l10n.themeSystem;
                        break;
                      case ThemeMode.light:
                        themeLabel = l10n.themeLight;
                        break;
                      case ThemeMode.dark:
                        themeLabel = l10n.themeDark;
                        break;
                    }
                  }
                  
                  return _buildSettingTile(
                    context,
                    icon: context.read<ThemeCubit>().themeModeIcon,
                    title: l10n.theme,
                    subtitle: themeLabel,
                    onTap: hasCustomBackground 
                        ? null // Disabled when custom background is active
                        : () => _showThemeDialog(context),
                  );
                },
              );
            },
          ),
          _buildSettingTile(
            context,
            icon: PhosphorIcons.image(),
            title: l10n.background,
            subtitle: l10n.backgroundDesc,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BackgroundSelectionPage(),
              ),
            ),
          ),
          BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return _buildSettingTile(
                context,
                icon: PhosphorIcons.sun(),
                title: l10n.language,
                subtitle: localeCubit.getLocaleName(locale),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LanguageSelectionPage(),
                  ),
                ),
                showDivider: false, // Last item
              );
            },
          ),
        ]),
        
        const SizedBox(height: 24),


        // Section: Audio
        _buildSectionHeader(context, l10n.audio),
        _buildSection(context, [
          // ✅ Sleep Timer Tile
          BlocBuilder<PlayerCubit, PlayerStateModel>(
            builder: (context, state) {
              String subtitle = l10n.sleepTimerDesc;
              if (state.sleepTimerEndTime != null) {
                final remaining = state.sleepTimerEndTime!.difference(DateTime.now());
                if (remaining.isNegative) {
                   subtitle = l10n.sleepTimerStoppingSoon;
                } else {
                   final min = remaining.inMinutes;
                   subtitle = l10n.sleepTimerActive(min + 1);
                }
              }
              
              return _buildSettingTile(
                context,
                icon: PhosphorIcons.timer(),
                title: l10n.sleepTimerTitle,
                subtitle: subtitle,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const SleepTimerDialog(),
                  );
                },
              );
            },
          ),
          _buildSettingTile(
            context,
            icon: PhosphorIcons.equalizer(),
            title: l10n.customEqualizer,
            subtitle: l10n.equalizerDesc,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EqualizerScreen()),
              );
            },
          ),
          if (!_isIgnoringBatteryOptimizations && Platform.isAndroid)
            _buildSettingTile(
              context,
              icon: PhosphorIcons.batteryChargingVertical(),
              title: l10n.backgroundPlayback,
              subtitle: l10n.backgroundPlaybackDesc,
              onTap: () async {
                try {
                  await BatteryOptimizationService.requestIgnoreBatteryOptimizations();
                  await Future.delayed(const Duration(milliseconds: 500));
                  await _checkBatteryOptimization();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.cannotOpenSettings)),
                    );
                  }
                }
              },
            ),

          // ✅ Crossfade
          BlocBuilder<PlayerCubit, PlayerStateModel>(
            builder: (context, state) {
              final seconds = state.crossfadeDuration;
              return _buildSettingTile(
                context,
                icon: PhosphorIcons.faders(),
                title: l10n.crossfade,
                subtitle: seconds == 0 ? l10n.crossfadeDisabled : l10n.crossfadeSeconds(seconds),
                onTap: () {
                   _showCrossfadeDialog(context, seconds);
                },
              );
            },
          ),

          // ✅ Gapless Playback
          BlocBuilder<PlayerCubit, PlayerStateModel>(
            builder: (context, state) {
              return SwitchListTile(
                 activeColor: Theme.of(context).colorScheme.primary,
                 title: Text(l10n.gaplessPlayback, style: TextStyle(fontWeight: FontWeight.w500)),
                 subtitle: Text(l10n.gaplessPlaybackDesc, style: TextStyle(fontSize: 12)),
                 secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: PhosphorIcon(PhosphorIcons.link(), 
                      color: Theme.of(context).colorScheme.onSurfaceVariant, 
                      size: 20
                    ),
                 ),
                 value: state.gaplessEnabled,
                 onChanged: (value) {
                    context.read<PlayerCubit>().toggleGapless();
                 },
              );
            },
          ),

          // ✅ Default Playback Speed
          BlocBuilder<PlayerCubit, PlayerStateModel>(
            builder: (context, state) {
              return _buildSettingTile(
                context,
                icon: PhosphorIcons.speedometer(),
                title: l10n.defaultSpeed,
                subtitle: '${state.playbackSpeed}x',
                onTap: () {
                   _showSpeedDialog(context, state.playbackSpeed);
                },
              );
            },
          ),
          _buildSettingTile(
            context,
            icon: PhosphorIcons.bell(),
            title: l10n.notifications,
            subtitle: l10n.notificationsDesc,
            onTap: () async {
              if (Platform.isAndroid) {
                try {
                  final intent = AndroidIntent(
                    action: 'android.settings.APP_NOTIFICATION_SETTINGS',
                    arguments: <String, dynamic>{
                      'android.provider.extra.APP_PACKAGE': 'com.synergydev.music_box',
                    },
                    flags: <int>[0x10000000],
                  );
                  await intent.launch();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.cannotOpenSettings)),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.androidOnly)),
                );
              }
            },
            showDivider: false,
          ),
        ]),
        
        const SizedBox(height: 24),

        const SizedBox(height: 24),

        // Section: Sauvegarde
        _buildSectionHeader(context, l10n.backupAndData),
        _buildSection(context, [
          _buildSettingTile(
            context,
            icon: PhosphorIcons.export(),
            title: l10n.exportData,
            subtitle: l10n.exportDataDesc,
            onTap: () async {
              final success = await DataBackupService.createBackup(context);
              if (context.mounted && !success) {
                 // Share API might return "dismissed" as not success on some Android versions, 
                 // but typically it doesn't crash.
                 // We rely on the system share sheet.
              }
            },
          ),
          _buildSettingTile(
            context,
            icon: PhosphorIcons.arrowClockwise(), // replaced restore which was missing
            title: l10n.importBackup,
            subtitle: l10n.importBackupDesc,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.attention),
                  content: Text(
                    l10n.restoreWarning
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true), 
                      child: Text(l10n.overwriteAndRestore),
                    ),
                  ],
                ),
              );
              
              if (confirm == true && context.mounted) {
                // Return data without writing to prefs yet (we delegate to Cubit)
                final data = await DataBackupService.pickBackupFile();
                
                if (data != null && context.mounted) {
                  // Perform Smart Restore & Migration
                  await context.read<PlayerCubit>().restoreData(data);
                  
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.restoreSuccessTitle),
                        content: Text(
                          l10n.restoreSuccessMessage,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                            }, 
                            child: Text(l10n.ok)
                          ),
                        ],
                      ),
                    );
                  }
                } else if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.backupReadError)),
                   );
                }
              }
            },
            showDivider: false,
          ),
        ]),
        
        const SizedBox(height: 24),

        // Section: Bibliothèque
        _buildSectionHeader(context, l10n.library),
        _buildSection(context, [
          _buildSettingTile(
            context,
            icon: PhosphorIcons.scan(),
            title: l10n.scanMusic,
            subtitle: l10n.scanMusicDesc,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScanMusicPage()),
              );
            },
          ),
          _buildSettingTile(
            context,
            icon: PhosphorIcons.folderMinus(),
            title: l10n.hiddenFolders,
            subtitle: l10n.hiddenFoldersDesc,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HiddenFoldersPage()),
              );
            },
            showDivider: false,
          ),
        ]),
        
        const SizedBox(height: 24),

        // Section: À propos
        _buildSectionHeader(context, l10n.about),
        _buildSection(context, [
          _buildSettingTile(
            context,
            icon: PhosphorIcons.musicNote(),
            title: l10n.appName,
            subtitle: l10n.version('1.0.1'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Music Box',
                applicationVersion: '1.0.1',
                applicationIcon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: PhosphorIcon(PhosphorIcons.musicNote(), color: theme.colorScheme.onPrimaryContainer, size: 32),
                ),
              );
            },
          ),
          _buildSettingTile(
            context,
            icon: PhosphorIcons.shieldCheck(),
            title: l10n.privacyPolicy,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InternalBrowserPage(
                    url: 'https://bass6architecture.github.io/Music-BOX/?lang=${Localizations.localeOf(context).languageCode}',
                    title: l10n.privacyPolicy,
                  ),
                ),
              );
            },
          ),
          _buildSettingTile(
            context,
            icon: PhosphorIcons.envelope(),
            title: l10n.contact,
            subtitle: 'synergydev.official@gmail.com',
            onTap: () async {
              final emailUri = Uri.parse('mailto:synergydev.official@gmail.com?subject=${Uri.encodeComponent(l10n.contactSubject)}');
              try {
                await launchUrl(emailUri);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.cannotOpenEmail)),
                  );
                }
              }
            },
            showDivider: false,
          ),
        ]),
        const SizedBox(height: 40),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return MusicBoxScaffold(
      appBar: AppBar(
        title: Text(l10n.settings, style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: content,
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
  
  Widget _buildSection(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap, // Now nullable for disabled state
    bool showDivider = true,
  }) {
    final theme = Theme.of(context);
    final isDisabled = onTap == null;
    
    return Column(
      children: [
        Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: ListTile(
            enabled: !isDisabled,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: PhosphorIcon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
            ),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12)) : null,
            trailing: isDisabled 
                ? null 
                : PhosphorIcon(PhosphorIcons.caretRight(), color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5), size: 18),
            onTap: onTap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
      ],
    );
  }
  
  void _showCrossfadeDialog(BuildContext context, int currentSeconds) {
    final l10n = AppLocalizations.of(context)!;
    int selected = currentSeconds;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.crossfade, style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selected == 0 ? l10n.crossfadeDisabled : l10n.crossfadeSeconds(selected),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: selected.toDouble(),
                  min: 0,
                  max: 12,
                  divisions: 12,
                  onChanged: (value) {
                    setState(() {
                      selected = value.round();
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  context.read<PlayerCubit>().setCrossfadeDuration(selected);
                  Navigator.pop(ctx);
                },
                child: Text(l10n.ok),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showSpeedDialog(BuildContext context, double currentSpeed) {
    final l10n = AppLocalizations.of(context)!;
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.playbackSpeed, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: speeds.map((speed) {
            return RadioListTile<double>(
              title: Text('${speed}x', style: TextStyle()),
              value: speed,
              groupValue: currentSpeed,
              onChanged: (value) {
                if (value != null) {
                  context.read<PlayerCubit>().setPlaybackSpeed(value);
                  Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
        actions: [
           TextButton(
             onPressed: () => Navigator.pop(ctx),
             child: Text(l10n.cancel),
           ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.themeDescription, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.themeSystem, style: TextStyle()),
              subtitle: Text(l10n.themeSystemDesc, style: TextStyle()),
              leading: PhosphorIcon(PhosphorIcons.sun()),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.system,
                // ignore: deprecated_member_use
                groupValue: themeCubit.state,
                // ignore: deprecated_member_use
                onChanged: (mode) {
                  if (mode != null) {
                    themeCubit.setThemeMode(mode);
                    Navigator.pop(ctx);
                  }
                },
              ),
              onTap: () {
                themeCubit.setThemeMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.themeLight, style: TextStyle()),
              subtitle: Text(l10n.themeLightDesc, style: TextStyle()),
              leading: PhosphorIcon(PhosphorIcons.sun()),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.light,
                // ignore: deprecated_member_use
                groupValue: themeCubit.state,
                // ignore: deprecated_member_use
                onChanged: (mode) {
                  if (mode != null) {
                    themeCubit.setThemeMode(mode);
                    Navigator.pop(ctx);
                  }
                },
              ),
              onTap: () {
                themeCubit.setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.themeDark, style: TextStyle()),
              subtitle: Text(l10n.themeDarkDesc, style: TextStyle()),
              leading: PhosphorIcon(PhosphorIcons.moon()),
              trailing: Radio<ThemeMode>(
                value: ThemeMode.dark,
                // ignore: deprecated_member_use
                groupValue: themeCubit.state,
                // ignore: deprecated_member_use
                onChanged: (mode) {
                  if (mode != null) {
                    themeCubit.setThemeMode(mode);
                    Navigator.pop(ctx);
                  }
                },
              ),
              onTap: () {
                themeCubit.setThemeMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}  



