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
    final theme = Theme.of(context);

    return MusicBoxScaffold(
      appBar: AppBar(
        title: Text(l10n.background),
        backgroundColor: Colors.transparent,
      ),
      body: BlocBuilder<BackgroundCubit, BackgroundType>(
        builder: (context, currentBackground) {
          return GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 9 / 16,
            children: [
              _BackgroundTile(
                backgroundType: BackgroundType.none,
                title: l10n.backgroundNone,
                isSelected: currentBackground == BackgroundType.none,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.none),
              ),
              _BackgroundTile(
                backgroundType: BackgroundType.gradientMusical,
                title: l10n.backgroundGradientMusical,
                isSelected: currentBackground == BackgroundType.gradientMusical,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.gradientMusical),
              ),
              _BackgroundTile(
                backgroundType: BackgroundType.gradientDark,
                title: l10n.backgroundGradientDark,
                isSelected: currentBackground == BackgroundType.gradientDark,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.gradientDark),
              ),
              _BackgroundTile(
                backgroundType: BackgroundType.particles,
                title: l10n.backgroundParticles,
                isSelected: currentBackground == BackgroundType.particles,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.particles),
               ),
              _BackgroundTile(
                backgroundType: BackgroundType.waves,
                title: l10n.backgroundWaves,
                isSelected: currentBackground == BackgroundType.waves,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.waves),
              ),
              _BackgroundTile(
                backgroundType: BackgroundType.neonCity,
                title: l10n.backgroundNeonCity,
                isSelected: currentBackground == BackgroundType.neonCity,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.neonCity),
              ),
              _BackgroundTile(
                backgroundType: BackgroundType.vinylSunset,
                title: l10n.backgroundVinylSunset,
                isSelected: currentBackground == BackgroundType.vinylSunset,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.vinylSunset),
              ),
              _BackgroundTile(
                backgroundType: BackgroundType.auroraRhythm,
                title: l10n.backgroundAuroraRhythm,
                isSelected: currentBackground == BackgroundType.auroraRhythm,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.auroraRhythm),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BackgroundTile extends StatelessWidget {
  final BackgroundType backgroundType;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _BackgroundTile({
    required this.backgroundType,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<BackgroundCubit>();

    // Get asset path for preview
    String? previewImage;
    if (backgroundType != BackgroundType.none) {
      final tempState = cubit.state;
      cubit.emit(backgroundType);
      previewImage = cubit.assetPath;
      cubit.emit(tempState);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background preview
              if (backgroundType == BackgroundType.none)
                Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.block_rounded,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                )
              else
                Image.asset(
                  previewImage!,
                  fit: BoxFit.cover,
                ),

              // Gradient overlay for title
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Selected indicator
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
