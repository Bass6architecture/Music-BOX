import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_box/generated/app_localizations.dart';
import 'package:path/path.dart' as p;

import '../player/player_cubit.dart';

class HiddenFoldersPage extends StatefulWidget {
  const HiddenFoldersPage({super.key});

  @override
  State<HiddenFoldersPage> createState() => _HiddenFoldersPageState();
}

class _HiddenFoldersPageState extends State<HiddenFoldersPage> {
  Future<void> _unhideFolder(String folder) async {
    final cubit = context.read<PlayerCubit>();
    final list = [...cubit.state.hiddenFolders];
    list.remove(folder);
    await cubit.updateHiddenFolders(list);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.folderUnhidden)),
    );
    setState(() {});
  }

  Future<void> _removeFolder(String folder) async {
    // Pour cette app, "Supprimer définitivement de la liste" signifie
    // simplement retirer ce chemin de la liste des dossiers masqués.
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete),
        content: Text('${AppLocalizations.of(context)!.confirmDelete}: ${p.basename(folder)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
          FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await _unhideFolder(folder);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hidden = context.watch<PlayerCubit>().state.hiddenFolders;
    final items = hidden.toList()..sort();

    final body = items.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_off, size: 56),
                  SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.noFolders),
                ],
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final folder = items[i];
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.folder_off_rounded,
                            color: theme.colorScheme.onErrorContainer,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.basename(folder),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                folder,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () => _unhideFolder(folder),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(AppLocalizations.of(context)!.unhideFolder),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.hiddenFolders)),
      body: body,
    );
  }
}
