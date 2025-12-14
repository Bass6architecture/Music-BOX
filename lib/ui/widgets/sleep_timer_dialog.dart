import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_box/player/player_cubit.dart';
import 'package:music_box/generated/app_localizations.dart';

class SleepTimerDialog extends StatelessWidget {
  const SleepTimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Glassmorphism style
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Dialog(
       backgroundColor: Colors.transparent,
       elevation: 0,
       insetPadding: const EdgeInsets.all(20),
       child: Container(
         decoration: BoxDecoration(
           color: (isDark ? const Color(0xFF1E1E1E) : Colors.white).withValues(alpha: 0.95),
           borderRadius: BorderRadius.circular(24),
           border: Border.all(
             color: Colors.white.withValues(alpha: 0.1),
             width: 1,
           ),
           boxShadow: [
             BoxShadow(
               color: Colors.black.withValues(alpha: 0.2),
               blurRadius: 20,
               offset: const Offset(0, 10),
             ),
           ],
         ),
         child: Padding(
           padding: const EdgeInsets.all(24.0),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               // Header
               Row(
                 children: [
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: colorScheme.primary.withValues(alpha: 0.1),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(
                       Icons.timer_outlined,
                       color: colorScheme.primary,
                       size: 28,
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           l10n.sleepTimerTitle,
                           style: TextStyle(
                             fontSize: 20,
                             fontWeight: FontWeight.bold,
                             color: isDark ? Colors.white : Colors.black87,
                           ),
                         ),
                          BlocBuilder<PlayerCubit, PlayerStateModel>(
                            builder: (context, state) {
                              if (state.sleepTimerEndTime == null) {
                                return Text(
                                  l10n.sleepTimerStopMusicAfter,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                );
                              } else {
                                return StreamBuilder(
                                  stream: Stream.periodic(const Duration(seconds: 1)),
                                  builder: (context, snapshot) {
                                    final remaining = state.sleepTimerEndTime!.difference(DateTime.now());
                                    if (remaining.isNegative) {
                                       return Text(
                                        l10n.sleepTimerStoppingSoon,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    }
                                    final minutes = remaining.inMinutes;
                                    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
                                    return Text(
                                      l10n.sleepTimerActiveRemaining(minutes, seconds),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  }
                                );
                              }
                            },
                          ),
                       ],
                     ),
                   ),
                 ],
               ),
               
               const SizedBox(height: 24),
               
               // Options Grid
               GridView.count(
                 shrinkWrap: true,
                 crossAxisCount: 2,
                 mainAxisSpacing: 12,
                 crossAxisSpacing: 12,
                 childAspectRatio: 2.5,
                 physics: const NeverScrollableScrollPhysics(),
                 children: [
                   _buildOption(context, 15, l10n.min15),
                   _buildOption(context, 30, l10n.min30),
                   _buildOption(context, 45, l10n.min45),
                   _buildOption(context, 60, l10n.oneHour),
                   _buildOption(context, 90, l10n.oneHourThirty),
                   _buildOption(context, 120, l10n.twoHours),
                 ],
               ),
               
                const SizedBox(height: 12),

                // Customize Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(Icons.edit_rounded, size: 20, color: colorScheme.primary),
                    label: Text(
                      l10n.customize,
                      style: TextStyle(
                         color: colorScheme.primary,
                         fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _showCustomDurationPicker(context),
                  ),
                ),

                const SizedBox(height: 24),
                
                // Actions
                BlocBuilder<PlayerCubit, PlayerStateModel>(
                  builder: (context, state) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel),
                        ),
                        if (state.sleepTimerEndTime != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                              ),
                              onPressed: () {
                                context.read<PlayerCubit>().cancelSleepTimer();
                                Navigator.pop(context);
                              },
                              child: Text(l10n.deactivate),
                            ),
                          ),
                      ],
                    );
                  },
                ),
             ],
           ),
         ),
       ),
    );
  }

  void _showCustomDurationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CustomTimerPicker(
        onDurationSelected: (duration) {
          context.read<PlayerCubit>().startSleepTimer(duration);
          Navigator.pop(ctx); // Close BottomSheet
          Navigator.pop(context); // Close SleepTimerDialog
          
          final l10n = AppLocalizations.of(context)!;
          final label = '${duration.inHours > 0 ? '${duration.inHours}h ' : ''}${duration.inMinutes % 60}min';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.timerSetFor(label),
                style: const TextStyle(color: Colors.white),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF212121),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOption(BuildContext context, int minutes, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<PlayerCubit>().startSleepTimer(Duration(minutes: minutes));
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.timerSetFor(label),
                style: const TextStyle(color: Colors.white),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF212121),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomTimerPicker extends StatefulWidget {
  final Function(Duration) onDurationSelected;
  
  const _CustomTimerPicker({required this.onDurationSelected});

  @override
  State<_CustomTimerPicker> createState() => _CustomTimerPickerState();
}

class _CustomTimerPickerState extends State<_CustomTimerPicker> {
  int _selectedHours = 0;
  int _selectedMinutes = 30;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.customTimer,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hours
              Column(
                children: [
                  Text(l10n.hours, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                  SizedBox(
                    height: 120,
                    width: 70,
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) => setState(() => _selectedHours = i),
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          final isSelected = index == _selectedHours;
                          return Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: isSelected ? 24 : 18,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected 
                                    ? colorScheme.primary 
                                    : (isDark ? Colors.white38 : Colors.black38),
                              ),
                            ),
                          );
                        },
                        childCount: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              Text(
                ":", 
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white24 : Colors.black26
                )
              ),
              const SizedBox(width: 32),
              // Minutes
              Column(
                children: [
                  Text(l10n.minutes, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                  SizedBox(
                    height: 120,
                    width: 70,
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(initialItem: 30),
                      onSelectedItemChanged: (i) => setState(() => _selectedMinutes = i),
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          final isSelected = index == _selectedMinutes;
                          return Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: isSelected ? 24 : 18,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected 
                                    ? colorScheme.primary 
                                    : (isDark ? Colors.white38 : Colors.black38),
                              ),
                            ),
                          );
                        },
                        childCount: 60,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final duration = Duration(hours: _selectedHours, minutes: _selectedMinutes);
                if (duration.inSeconds > 0) {
                   widget.onDurationSelected(duration);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(l10n.setTimer, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16), // Bottom padding
        ],
      ),
    );
  }
}
