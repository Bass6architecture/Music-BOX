import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../player/player_cubit.dart';
import 'package:music_box/generated/app_localizations.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.customEqualizer, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.caretLeft, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<PlayerCubit, PlayerStateModel>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.equalizerEnabled,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: state.equalizerEnabled,
                      onChanged: (value) {
                        context.read<PlayerCubit>().toggleEqualizer(value);
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Opacity(
                  opacity: state.equalizerEnabled ? 1.0 : 0.4,
                  child: AbsorbPointer(
                    absorbing: !state.equalizerEnabled,
                    child: Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(state.equalizerBands.length, (index) {
                                return _buildSlider(context, state, index);
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.equalizerPresets,
                              style: TextStyle(
                               color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPresets(context),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlider(BuildContext context, PlayerStateModel state, int index) {
    final theme = Theme.of(context);
    final gain = state.equalizerBands[index];
    // Labels frequencies (approximative for common 5-band EQ)
    final frequencies = ['60', '230', '910', '4k', '14k'];
    final label = index < frequencies.length ? frequencies[index] : '';

    return Column(
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                thumbColor: theme.colorScheme.primary,
              ),
              child: Slider(
                value: gain,
                min: -10.0,
                max: 10.0,
                onChanged: (value) {
                  context.read<PlayerCubit>().setEqualizerBand(index, value);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPresets(BuildContext context) {
    final theme = Theme.of(context);
    final presets = {
      'Flat': [0.0, 0.0, 0.0, 0.0, 0.0],
      'Bass Boost': [6.0, 3.0, 0.0, 0.0, 0.0],
      'Rock': [4.0, 2.0, -1.0, 2.0, 4.0],
      'Pop': [-1.0, 2.0, 4.0, 2.0, -1.0],
      'Classical': [4.0, 3.0, 0.0, 3.0, 4.0],
      'Jazz': [3.0, 1.0, 2.0, 1.0, 3.0],
    };

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: presets.length,
        itemBuilder: (context, index) {
          final name = presets.keys.elementAt(index);
          final values = presets[name]!;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ActionChip(
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              label: Text(name, style: TextStyle(color: theme.colorScheme.onSurface)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () async {
                final cubit = context.read<PlayerCubit>();
                for (int i = 0; i < values.length; i++) {
                  await cubit.setEqualizerBand(i, values[i]);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
