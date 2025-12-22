import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../player/player_cubit.dart';
import 'package:music_box/generated/app_localizations.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.customEqualizer),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.caretLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<PlayerCubit, PlayerStateModel>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.equalizerEnabled,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: state.equalizerEnabled,
                      onChanged: (value) {
                        context.read<PlayerCubit>().toggleEqualizer(value);
                      },
                      activeColor: Colors.orange,
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
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 14,
                                textStyle: const TextStyle(letterSpacing: 1.2),
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
                activeTrackColor: Colors.orange,
                inactiveTrackColor: Colors.white10,
                thumbColor: Colors.white,
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
          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPresets(BuildContext context) {
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
              backgroundColor: Colors.white10,
              label: Text(name, style: const TextStyle(color: Colors.white)),
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
