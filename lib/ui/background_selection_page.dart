import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../generated/app_localizations.dart';
import '../core/background/background_cubit.dart';
import 'widgets/music_box_scaffold.dart';

class BackgroundSelectionPage extends StatelessWidget {
  const BackgroundSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Define the list of backgrounds to show
    final backgrounds = [
      BackgroundType.none,
      BackgroundType.abstractDark, // Free
      BackgroundType.glassMorphism, // Locked
      BackgroundType.cosmicBeats, // Locked
      BackgroundType.vinylSunset, // Locked
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.background),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: BlocBuilder<BackgroundCubit, BackgroundType>(
        builder: (context, currentBackground) {
          return GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 9 / 16,
            children: backgrounds.map((bgType) {
               // Check if user has unlocked this (mock logic: for now just check static lock)
               // Real app would check SharedPreferences for unlocked IDs.
               // Taking "Free" as literally free.
               final isLocked = bgType == BackgroundType.glassMorphism || bgType == BackgroundType.cosmicBeats || bgType == BackgroundType.vinylSunset;
               // Simple mock: If it is locked, show lock.
               
               return _BackgroundTile(
                  backgroundType: bgType,
                  isSelected: currentBackground == bgType,
                  isLocked: isLocked,
                  onTap: () {
                    if (isLocked) {
                      // Show Ad Dialog
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Débloquer ce fond'),
                          content: Text('Regardez une courte publicité pour débloquer cet arrière-plan.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(l10n.cancel),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                // Mock Ad Success
                                context.read<BackgroundCubit>().setBackground(bgType);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Arrière-plan débloqué !')),
                                );
                              },
                              child: Text('Regarder (Publicité)'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      context.read<BackgroundCubit>().setBackground(bgType);
                    }
                  },
               );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _BackgroundTile extends StatelessWidget {
  final BackgroundType backgroundType;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const _BackgroundTile({
    required this.backgroundType,
    required this.isSelected,
    this.isLocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = BackgroundCubit.getAssetPathForType(backgroundType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Theme.of(context).primaryColor, width: 3)
              : Border.all(color: Colors.white10, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Preview
            if (assetPath != null)
              Image.asset(
                assetPath,
                fit: BoxFit.cover,
                color: isLocked ? Colors.black.withOpacity(0.7) : null,
                colorBlendMode: isLocked ? BlendMode.darken : null,
              )
            else
              Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(Icons.block, color: Colors.white54, size: 48),
                ),
              ),

             // Lock Icon
             if (isLocked)
               Center(
                 child: Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: Colors.black54,
                     shape: BoxShape.circle,
                     border: Border.all(color: Colors.white24),
                   ),
                   child: const Icon(Icons.lock_rounded, color: Colors.white, size: 32),
                 ),
               ),

            // Selection Checkmark
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
