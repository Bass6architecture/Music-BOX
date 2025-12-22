import 'package:flutter/services.dart';
import 'dart:io' as io;
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_box/generated/app_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:android_intent_plus/android_intent.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';


import '../player/player_cubit.dart';

import 'hidden_folders_page.dart';
import 'folder_songs_page.dart';

class FoldersPage extends StatefulWidget {
  const FoldersPage({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _loading = false;
  Map<String, int> _folderCounts = <String, int>{}; // folderPath -> song count
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }
  
  void _startLoading() {
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final allSongs = await _audioQuery.querySongs(
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      if (!mounted) return;
      final cubit = context.read<PlayerCubit>();
      // Filtrer via PlayerCubit pour respecter les dossiers masquÃ©s existants
      final visibleSongs = cubit.filterSongs(allSongs.where((s) => s.uri != null).toList());

      final counts = <String, int>{};
      for (final s in visibleSongs) {
        final path = s.data;
        if (path.isEmpty) continue;
        final dir = p.dirname(path);
        counts.update(dir, (v) => v + 1, ifAbsent: () => 1);
      }
      counts.removeWhere((k, v) => v <= 0);
      setState(() => _folderCounts = counts);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _hideFolder(String folder) async {
    final cubit = context.read<PlayerCubit>();
    final newHidden = {...cubit.state.hiddenFolders, folder}.toList();
    await cubit.updateHiddenFolders(newHidden);
    if (!mounted) return;
    setState(() => _folderCounts.remove(folder));

    // Snackbar avec Annuler / OK
    // âœ… SupprimÃ© : Plus de message SnackBar
    /*
    var canceled = false;
    final snack = SnackBar(
      content: Text(AppLocalizations.of(context)!.folderHidden),
      action: SnackBarAction(
        label: AppLocalizations.of(context)!.cancel,
        onPressed: () async {
          canceled = true;
          // Fermer immÃ©diatement toute snackbar visible (y compris la suivante si dÃ©jÃ  affichÃ©e)
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
          final revert = {...cubit.state.hiddenFolders}..remove(folder);
          await cubit.updateHiddenFolders(revert.toList());
          await _load();
        },
      ),
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);

    // AprÃ¨s la premiÃ¨re snackbar, proposer "Voir dossiers masquÃ©s"
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    // Ne pas montrer si l'utilisateur a annulÃ©, ou si le dossier n'est plus masquÃ©
    final stillHidden = context.read<PlayerCubit>().state.hiddenFolders.contains(folder);
    if (!canceled && stillHidden) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.viewHiddenFolders),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.open,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HiddenFoldersPage()),
              );
            },
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    */
  }

  void _showFolderMenu(String folder, int count) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: PhosphorIcon(PhosphorIcons.eyeSlash()),
                title: Text(AppLocalizations.of(context)!.hideFolder, style: GoogleFonts.outfit()),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _hideFolder(folder);
                },
              ),
              ListTile(
                leading: PhosphorIcon(PhosphorIcons.info()),
                title: Text(AppLocalizations.of(context)!.folderProperties, style: GoogleFonts.outfit()),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog<void>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: Text(AppLocalizations.of(context)!.folderProperties),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(folder),
                          const SizedBox(height: 8),
                          Text(AppLocalizations.of(context)!.songCount(count)),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(AppLocalizations.of(context)!.close)),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: PhosphorIcon(PhosphorIcons.folderOpen()),
                title: Text(AppLocalizations.of(context)!.openLocation, style: GoogleFonts.outfit()),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (!io.Platform.isAndroid) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.androidOnly)),
                      );
                    }
                    return;
                  }
                  
                  debugPrint('ðŸ“‚ Ouverture du dossier: $folder');
                  
                  // Essayer d'ouvrir dans l'explorateur
                  bool intentLaunched = false;
                  
                  // MÃ©thode 1: Construire l'URI Documents correctement
                  try {
                    // Encoder le chemin correctement pour Documents UI
                    String documentPath = folder.replaceFirst('/storage/emulated/0/', '');
                    // URL encoder le chemin pour Ã©viter les problÃ¨mes avec les caractÃ¨res spÃ©ciaux
                    documentPath = Uri.encodeComponent(documentPath);
                    
                    final intent = AndroidIntent(
                      action: 'android.intent.action.VIEW',
                      data: 'content://com.android.externalstorage.documents/document/primary:$documentPath',
                      type: 'vnd.android.document/directory',
                      flags: <int>[0x10000000, 0x00000001], // FLAG_ACTIVITY_NEW_TASK | FLAG_GRANT_READ_URI_PERMISSION
                    );
                    await intent.launch();
                    intentLaunched = true;
                    debugPrint('âœ… Dossier ouvert avec Documents UI');
                  } catch (e1) {
                    debugPrint('âŒ MÃ©thode 1 (Documents) Ã©chouÃ©e: $e1');
                    
                    // MÃ©thode 2: Ouvrir le gestionnaire de fichiers gÃ©nÃ©rique
                    try {
                      final intent = AndroidIntent(
                        action: 'android.intent.action.VIEW',
                        type: 'resource/folder',
                        flags: <int>[0x10000000],
                      );
                      await intent.launch();
                      intentLaunched = true;
                      debugPrint('âœ… Gestionnaire de fichiers ouvert');
                    } catch (e2) {
                      debugPrint('âŒ MÃ©thode 2 (gestionnaire) Ã©chouÃ©e: $e2');
                    }
                  }
                  
                  // Si aucun intent n'a marchÃ©, afficher le chemin
                  if (!intentLaunched) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${AppLocalizations.of(context)!.openLocation}: $folder'),
                          action: SnackBarAction(
                            label: AppLocalizations.of(context)!.copyPath,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: folder));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.pathCopied)),
                              );
                            },
                          ),
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = _loading
        ? const Center(child: CircularProgressIndicator())
        : _folderCounts.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    child: PhosphorIcon(PhosphorIcons.folder(), size: 56, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noFolders,
                      style: theme.textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HiddenFoldersPage()),
                        );
                      },
                      icon: PhosphorIcon(PhosphorIcons.eyeSlash()),
                      label: Text(AppLocalizations.of(context)!.viewHiddenFolders),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  if (!widget.embedded)
                    SliverAppBar(
                      expandedHeight: 120,
                      floating: false,
                      pinned: true,
                      stretch: true,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      surfaceTintColor: Colors.transparent,
                      actions: [
                        IconButton(
                          icon: PhosphorIcon(PhosphorIcons.eyeSlash()),
                          tooltip: AppLocalizations.of(context)!.viewHiddenFolders,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const HiddenFoldersPage()),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
                        title: Text(
                          AppLocalizations.of(context)!.folders,
                          style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                theme.colorScheme.surface,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // âœ… Barre visible vers dossiers masquÃ©s (toujours affichÃ©e)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HiddenFoldersPage()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              PhosphorIcon(PhosphorIcons.eyeSlash(), 
                                   size: 20, 
                                   color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!.hiddenFolders,
                                  style: GoogleFonts.outfit(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              PhosphorIcon(PhosphorIcons.caretRight(),
                                   color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final folderPaths = _folderCounts.keys.toList()..sort();
                          final folderPath = folderPaths[index];
                          final folderName = p.basename(folderPath);
                          final count = _folderCounts[folderPath] ?? 0;
                          
                          return _FolderTile(
                            name: folderName,
                            count: count,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<PlayerCubit>(),
                                    child: FolderSongsPage(
                                      folderName: folderName,
                                    ),
                                  ),
                                ),
                              );
                            },
                            onLongPress: () => _showFolderMenu(folderPath, count),
                          );
                        },
                        childCount: _folderCounts.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );

    final widgetToShow = widget.embedded ? content : Scaffold(body: content);

    return BlocListener<PlayerCubit, PlayerStateModel>(
        listenWhen: (prev, curr) =>
            prev.hiddenFolders != curr.hiddenFolders ||
            prev.showHiddenFolders != curr.showHiddenFolders ||
            prev.deletedSongIds != curr.deletedSongIds,
        listener: (context, state) {
          _load();
        },
        child: widgetToShow,
      );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.name,
    required this.count,
    required this.onTap,
    required this.onLongPress,
  });

  final String name;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PhosphorIcon(
                    PhosphorIcons.folder(PhosphorIconsStyle.fill),
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.songCount(count),
                        style: GoogleFonts.outfit(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: PhosphorIcon(
                    PhosphorIcons.dotsThreeVertical(),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onLongPress,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




