import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:music_box/generated/app_localizations.dart';
import '../../player/player_cubit.dart';
import '../../player/mini_player.dart';
import '../../core/constants/app_constants.dart';
import '../../services/ad_service.dart';
import '../playlists_page.dart';
import '../albums_page.dart';
import '../artists_page.dart';
import '../settings_page.dart';
import '../search_page.dart';
// import '../now_playing_page.dart'; // replaced by immersive sheet
import '../now_playing_next_gen.dart';
import '../folders_page.dart';
import 'songs_screen.dart';
import 'for_you_page.dart';
import '../widgets/music_box_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> 
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: AppConstants.shortAnimation,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    // Charger la bannière publicitaire
    AdService().loadBanner();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<_NavigationItem> _getNavigationItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _NavigationItem(
        icon: Icons.auto_awesome_outlined,
        selectedIcon: Icons.auto_awesome,
        label: l10n.forYou,
        page: const ForYouPage(),
      ),
      _NavigationItem(
        icon: Icons.music_note_outlined,
        selectedIcon: Icons.music_note_rounded,
        label: l10n.songs,
        page: const SongsScreen(),
      ),
      _NavigationItem(
        icon: Icons.queue_music_outlined,
        selectedIcon: Icons.queue_music_rounded,
        label: l10n.playlists,
        page: const PlaylistsPage(embedded: true),
      ),
      _NavigationItem(
        icon: Icons.album_outlined,
        selectedIcon: Icons.album_rounded,
        label: l10n.albums,
        page: const AlbumsPage(embedded: true),
      ),
      _NavigationItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: l10n.artists,
        page: const ArtistsPage(embedded: true),
      ),
      _NavigationItem(
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder_rounded,
        label: l10n.folders,
        page: const FoldersPage(embedded: true),
      ),
    ];
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  bool _isSelectionMode = false;

  void toggleSelectionMode(bool value) {
     if (_isSelectionMode != value) {
       setState(() {
         _isSelectionMode = value;
       });
     }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerCubit = context.watch<PlayerCubit>();
    final hasCurrentSong = playerCubit.currentSong != null;
    final navigationItems = _getNavigationItems(context);

    // If selection mode is active, we hide everything around the main content
    return MusicBoxScaffold(
      body: Stack(
        children: [
          
          // Contenu principal
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // AppBar personnalisé - Masqué en mode sélection
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _isSelectionMode 
                      ? CrossFadeState.showSecond 
                      : CrossFadeState.showFirst,
                  secondChild: const SizedBox(height: 0),
                  firstChild: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding,
                      vertical: AppConstants.smallPadding,
                    ),
                    child: Row(
                      children: [
                        // Logo et titre
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppConstants.appName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        
                        // Search Button
                         _buildActionButton(
                          icon: Icons.search_rounded,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SearchPage()),
                          ),
                          tooltip: AppLocalizations.of(context)!.search,
                        ),
                        const SizedBox(width: 8),

                        // Actions (search removed)
                        if (hasCurrentSong) ...[
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.queue_music_rounded,
                            onPressed: () => _navigateToNowPlaying(context),
                            tooltip: AppLocalizations.of(context)!.nowPlaying,
                            highlighted: true,
                          ),
                        ],
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.settings_outlined,
                          onPressed: () => _navigateToSettings(context),
                          tooltip: AppLocalizations.of(context)!.settings,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Pages avec animation
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    // Physics forbidden in selection mode to avoid easy swipe away?
                    // Or keep it? Usually better to disable swipe if we have checkboxes
                    physics: _isSelectionMode ? const NeverScrollableScrollPhysics() : null,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    itemCount: navigationItems.length,
                    itemBuilder: (context, index) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: navigationItems[index].page,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // Navigation Bar moderne - Hide all in selection mode
      bottomNavigationBar: _isSelectionMode 
        ? Column(mainAxisSize: MainAxisSize.min, children: [ AdService().getBannerWidget() ]) 
        : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini Player (visible en profile/release si une chanson est en cours)
          if (hasCurrentSong) const MiniPlayer(),
          
          // Bannière publicitaire (visible dans toutes les pages sauf Settings)
          AdService().getBannerWidget(),
          
          // Navigation
          Container(
            decoration: BoxDecoration(
              // In dev (debug/profile) keep transparent and no shadow to avoid any visible surface
              color: kReleaseMode ? theme.colorScheme.surface : Colors.transparent,
              boxShadow: kReleaseMode
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ]
                  : const [],
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              height: 80,
              elevation: 0,
              backgroundColor: Colors.transparent,
              indicatorColor: theme.colorScheme.primary,
              destinations: navigationItems.map((item) {
                return NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(
                    item.selectedIcon,
                    color: Colors.white,
                  ),
                  label: item.label,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool highlighted = false,
  }) {
    final theme = Theme.of(context);
    
    return Material(
      color: highlighted 
          ? theme.colorScheme.primary
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: highlighted
                ? Colors.white
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  void _navigateToNowPlaying(BuildContext context) {
    HapticFeedback.lightImpact();
    // Open Next Gen Now Playing
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => openNextGenNowPlaying(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
        opaque: false, // ✅ Transparent pour voir l'écran derrière
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: AppConstants.mediumAnimation,
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;

  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
  });
}
