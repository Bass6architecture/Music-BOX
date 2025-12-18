import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../generated/app_localizations.dart';
import '../core/background/background_cubit.dart';
import 'widgets/music_box_scaffold.dart';

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
      BackgroundType.none,
      BackgroundType.gradientDark, // Free
      BackgroundType.gradientMusical, // Locked
      BackgroundType.abstractDark, // Locked
      BackgroundType.vinylSunset, // Locked
      BackgroundType.particles, // Locked
      BackgroundType.waves, // Locked
      BackgroundType.deepSpace, // New (Locked)
      BackgroundType.midnightCity, // New (Locked)
      BackgroundType.obsidianFlow, // New (Locked)
    ];

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show Stack background
      appBar: _isAdShowing || _isAdLoading ? null : AppBar(
        title: Text(l10n.background),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 0: Current Background Visualization (Fixes "Fusion" and "Transparency")
          BlocBuilder<BackgroundCubit, BackgroundType>(
            builder: (context, currentBackground) {
              final assetPath = BackgroundCubit.getAssetPathForType(currentBackground);
              if (assetPath != null) {
                return Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                );
              } else {
                // Return Theme Background if None
                return Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                );
              }
            },
          ),
          
          // Layer 0.5: Dimming Overlay for readability
          Container(color: Colors.black.withOpacity(0.6)),

          // Layer 1: Grid Content
          BlocBuilder<BackgroundCubit, BackgroundType>(
            builder: (context, currentBackground) {
              return GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 9 / 16,
                children: backgrounds.map((bgType) {
                   // Check unlock status from Cubit
                   final isUnlocked = cubit.isUnlocked(bgType);
                   final isLocked = !isUnlocked;
                   
                   return _BackgroundTile(
                      backgroundType: bgType,
                      isSelected: currentBackground == bgType,
                      isLocked: isLocked,
                      title: _getBackgroundName(bgType, l10n),
                      onTap: () {
                        if (isLocked) {
                          _showRewardedAd(bgType);
                        } else {
                          context.read<BackgroundCubit>().setBackground(bgType);
                        }
                      },
                   );
                }).toList(),
              );
            },
          ),
          
          // Layer 2: Loading Overlay
          if (_isAdLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  String _getBackgroundName(BackgroundType type, AppLocalizations l10n) {
     if (type == BackgroundType.none) return l10n.backgroundNone;
     return '';
  }
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
    this.title = '',
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
                // Less dimming for reward/locked items so they look appealing
                color: isLocked ? Colors.black.withOpacity(0.3) : null,
                colorBlendMode: isLocked ? BlendMode.darken : null,
              )
            else if (backgroundType == BackgroundType.none)
               Container(color: Colors.black)
            else
              Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.white54, size: 48),
                ),
              ),

             // Lock / Reward Icon
             if (isLocked)
               Center(
                 child: Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: Colors.black54, // Semi-transparent
                     shape: BoxShape.circle,
                     border: Border.all(color: Colors.white24),
                     boxShadow: const [
                       BoxShadow(
                         color: Colors.black26,
                         blurRadius: 8,
                         offset: Offset(0, 4),
                       )
                     ]
                   ),
                   // User requested a "Reward" icon (Gift/Video) instead of Lock
                   child: const Icon(Icons.card_giftcard_rounded, color: Colors.amberAccent, size: 32),
                 ),
               ),

            // Title Overlay (Only if title is provided)
            if (title.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14, 
                      fontWeight: FontWeight.w500,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
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
