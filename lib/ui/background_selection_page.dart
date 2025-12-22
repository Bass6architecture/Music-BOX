import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../generated/app_localizations.dart';
import '../core/background/background_cubit.dart';


class BackgroundSelectionPage extends StatefulWidget {
  const BackgroundSelectionPage({super.key});

  @override
  State<BackgroundSelectionPage> createState() => _BackgroundSelectionPageState();
}

class _BackgroundSelectionPageState extends State<BackgroundSelectionPage> {
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _isAdShowing = false; // Hide AppBar during ad
  final String _adUnitId = 'ca-app-pub-9535801913153032/6103998986'; // User provided reward unit ID

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _loadRewardedAd(VoidCallback onLoaded) {
    setState(() => _isAdLoading = true);
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          _rewardedAd = ad;
          setState(() => _isAdLoading = false);
          onLoaded();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          setState(() => _isAdLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur pub: ${error.message}')),
            );
          }
        },
      ),
    );
  }

  void _showRewardedAd(BackgroundType type) {
    if (_rewardedAd == null) {
      _loadRewardedAd(() => _showRewardedAd(type));
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        setState(() => _isAdShowing = true);
      },
      onAdDismissedFullScreenContent: (ad) {
        setState(() => _isAdShowing = false);
        ad.dispose();
        _rewardedAd = null;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erreur affichage: ${error.message}')),
        );
      },
    );

    // Immersive mode hides system bars (Status/Navigation) for true full-screen experience
    _rewardedAd!.setImmersiveMode(true);

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        // Unlock logic
        if (!mounted) return;
        final cubit = context.read<BackgroundCubit>();
        await cubit.unlockBackground(type);
        await cubit.setBackground(type);
        
        setState(() {}); // Rebuild to update lock icons
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.watch<BackgroundCubit>();
    
    // Define the list of backgrounds to show
    final backgrounds = [
      _BackgroundOption(BackgroundType.none, l10n.backgroundNone),
      _BackgroundOption(BackgroundType.gradientDark, "Dark Sky"),
      _BackgroundOption(BackgroundType.gradientMusical, "Aurora Rhythm"),
      _BackgroundOption(BackgroundType.abstractDark, "Abstract Night"),
      _BackgroundOption(BackgroundType.vinylSunset, "Vinyl Sunset"),
      _BackgroundOption(BackgroundType.particles, "Stardust"),
      _BackgroundOption(BackgroundType.waves, "Ocean Waves"),
      _BackgroundOption(BackgroundType.deepSpace, "Deep Space"),
      _BackgroundOption(BackgroundType.midnightCity, "Midnight City"),
      _BackgroundOption(BackgroundType.obsidianFlow, "Obsidian Flow"),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _isAdShowing || _isAdLoading ? null : AppBar(
        title: Text(l10n.background),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 0: Current Background Visualization
          BlocBuilder<BackgroundCubit, BackgroundType>(
            builder: (context, currentBackground) {
              final assetPath = BackgroundCubit.getAssetPathForType(currentBackground);
              if (assetPath != null) {
                return Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                );
              } else {
                return Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                );
              }
            },
          ),
          
          // Layer 0.5: Dimming Overlay
          Container(color: Colors.black.withValues(alpha: 0.6)),

          // Layer 1: Grid Content
          BlocBuilder<BackgroundCubit, BackgroundType>(
            builder: (context, currentBackground) {
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 110, 20, 40),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.65, // Taller for app mockup
                ),
                itemCount: backgrounds.length,
                itemBuilder: (context, index) {
                   final opt = backgrounds[index];
                   final isUnlocked = cubit.isUnlocked(opt.type);
                   final isLocked = !isUnlocked;
                   
                   return _BackgroundTile(
                      backgroundType: opt.type,
                      isSelected: currentBackground == opt.type,
                      isLocked: isLocked,
                      title: opt.name,
                      onTap: () {
                        if (isLocked) {
                          _showRewardedAd(opt.type);
                        } else {
                          context.read<BackgroundCubit>().setBackground(opt.type);
                        }
                      },
                   );
                },
              );
            },
          ),
          
          // Layer 2: Loading Overlay
          if (_isAdLoading)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 24),
                    Text("Chargement de la publicitÃ©...", style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BackgroundOption {
  final BackgroundType type;
  final String name;
  _BackgroundOption(this.type, this.name);
}

class _BackgroundTile extends StatelessWidget {
  final BackgroundType backgroundType;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;
  final String title;

  const _BackgroundTile({
    required this.backgroundType,
    required this.isSelected,
    this.isLocked = false,
    required this.onTap,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? theme.primaryColor : Colors.white24, 
                  width: isSelected ? 3 : 1
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [
                        const BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        )
                      ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Live App Preview (Simulation)
                  _AppMockup(
                    backgroundType: backgroundType,
                    isLocked: isLocked,
                  ),

                  // AD Badge (User requested text AD)
                  if (isLocked)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amberAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "AD",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                  // Checkmark
                  if (isSelected)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (backgroundType == BackgroundType.none) ...[
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppMockup extends StatelessWidget {
  final BackgroundType backgroundType;
  final bool isLocked;

  const _AppMockup({
    required this.backgroundType,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = BackgroundCubit.getAssetPathForType(backgroundType);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        if (assetPath != null)
          Image.asset(assetPath, fit: BoxFit.cover)
        else
          Container(color: const Color(0xFF121212)),

        // Content Simulation (Cloning Songs Page mini)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
            ),
          ),
          // The original line was: color: Colors.black.withValues(alpha: isLocked ? 0.2 : 0.3), // Reduced darkening
          // The instruction and provided "Code Edit" seem to indicate a change to a gradient.
          // The "ha:" part in the provided "Code Edit" was syntactically incorrect and has been removed.
          // The `isLocked` logic for alpha is now applied to the gradient's first color's alpha.
          // The original comment "Reduced darkening" is kept.
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mini Header
              Row(
                children: [
                  Container(width: 14, height: 2.5, decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(1))),
                  const Spacer(),
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle)),
                ],
              ),
              const SizedBox(height: 12),
              // "Songs" Title mini
              Container(width: 45, height: 6, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(1.5))),
              const SizedBox(height: 14),
              // List item simulation
              for (int i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 50, height: 3.5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(1))),
                            const SizedBox(height: 4),
                            Container(width: 30, height: 2.5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(1))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(width: 3, height: 10, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(0.5))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}




