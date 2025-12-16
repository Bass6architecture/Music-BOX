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
                isSelected: currentBackground == BackgroundType.none,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.none),
              ),
              _BackgroundTile(
                backgroundType: BackgroundType.gradientMusical,
                isSelected: currentBackground == BackgroundType.gradientMusical,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.gradientMusical),
              ),
              _BackgroundTile(
                backgroundType: BackgroundType.gradientDark,
                isSelected: currentBackground == BackgroundType.gradientDark,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.gradientDark),
              ),
              _BackgroundTile(
                backgroundType: BackgroundType.particles,
                isSelected: currentBackground == BackgroundType.particles,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.particles),
               ),
              _BackgroundTile(
                backgroundType: BackgroundType.waves,
                isSelected: currentBackground == BackgroundType.waves,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.waves),
              ),
              _BackgroundTile(
                backgroundType: BackgroundType.vinylSunset,
                isSelected: currentBackground == BackgroundType.vinylSunset,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.vinylSunset),
              ),
              _BackgroundTile(
                backgroundType: BackgroundType.glassMorphism,
                isSelected: currentBackground == BackgroundType.glassMorphism,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.glassMorphism),
              ),
              _BackgroundTile(
                backgroundType: BackgroundType.abstractDark,
                isSelected: currentBackground == BackgroundType.abstractDark,
                onTap: () => context.read<BackgroundCubit>().setBackground(BackgroundType.abstractDark),
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
  final bool isSelected;
  final VoidCallback onTap;

  const _BackgroundTile({
    required this.backgroundType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<BackgroundCubit>();

    // Get asset path for preview
    String? previewImage = BackgroundCubit.getAssetPathForType(backgroundType);


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
