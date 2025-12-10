import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:music_box/generated/app_localizations.dart';
import '../ui/screens/home_screen.dart';
import '../services/battery_optimization_service.dart';

class PermissionWrapper extends StatefulWidget {
  const PermissionWrapper({super.key});

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  PermissionStatus _audioStatus = PermissionStatus.denied;
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  bool _isBatteryOptimized = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions(); // Check immediately
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  late final _AppLifecycleObserver _lifecycleObserver = _AppLifecycleObserver(
    onResume: _checkPermissions,
  );

  Future<void> _checkPermissions() async {
    final audio = await Permission.audio.status;
    final notification = await Permission.notification.status;
    final battery = await BatteryOptimizationService.isIgnoringBatteryOptimizations();
    
    // On older Android, audio might be granted via storage
    final storage = await Permission.storage.status;
    final effectiveAudio = audio.isGranted ? audio : storage;

    if (mounted) {
      setState(() {
        _audioStatus = effectiveAudio;
        _notificationStatus = notification;
        _isBatteryOptimized = battery;
        _isLoading = false;
      });
      
      // Auto-redirect removed based on user feedback. 
      // User wants to explicitly acknowledge permissions or handle notifications.
      // if (_areMandatoryGranted()) {
      //   _navigateToHome();
      // }
    }
  }

  bool _areMandatoryGranted() {
    // Audio is mandatory. Notification is highly recommended but we can proceed without it if user insists?
    // User request: "une fois ces permission d'access au audio et autoriser... le bouton permettre sera plus actif"
    // This implies Audio is the blocker.
    return (_audioStatus.isGranted || _audioStatus.isLimited);
  }

  Future<void> _requestAudio() async {
    // If we think it's permanently denied, or if previous request failed effectively
    if (_audioStatus.isPermanentlyDenied) {
      final opened = await openAppSettings();
      if (opened) {
         // Wait a bit for user to potentially change settings then check
         // Actually didChangeAppLifecycleState will handle this on resume.
      }
      return;
    }

    // Request audio (or storage on older devices)
    final status = await Permission.audio.request();
    
    PermissionStatus finalStatus = status;
    if (!status.isGranted && !status.isPermanentlyDenied) {
       // Fallback for older Android (storage)
       final storageStatus = await Permission.storage.request();
       if (storageStatus.isGranted) finalStatus = storageStatus;
    }

    if (mounted) {
      setState(() => _audioStatus = finalStatus);
    }
  }

  Future<void> _requestNotification() async {
    if (_notificationStatus.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    final status = await Permission.notification.request();
    if (mounted) {
      setState(() => _notificationStatus = status);
    }
  }

  Future<void> _requestBattery() async {
    await BatteryOptimizationService.requestIgnoreBatteryOptimizations();
    // The result comes back async, we might need to check again when app resumes
    // But we can also check immediately after a delay
    await Future.delayed(const Duration(seconds: 1));
    final battery = await BatteryOptimizationService.isIgnoringBatteryOptimizations();
    if (mounted) {
      setState(() => _isBatteryOptimized = battery);
    }
  }
  
  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                  theme.colorScheme.secondary.withValues(alpha: 0.6),
                  theme.colorScheme.surface,
                ],
              ),
            ),
          ),
          
          // Glassmorphism Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: theme.colorScheme.surface.withValues(alpha: 0.7),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),
                  
                  // Header
                  Text(
                    l10n.appName.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      letterSpacing: 3,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.permissionRequired,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.permissionIntro,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  
                  const Spacer(flex: 1),
                  
                  // Permission Items
                  _buildPermissionItem(
                    context,
                    icon: Icons.music_note_rounded,
                    title: l10n.permissionAudioTitle,
                    description: l10n.permissionAudioDesc,
                    status: _audioStatus,
                    onPressed: _requestAudio,
                    isMandatory: true,
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionItem(
                    context,
                    icon: Icons.notifications_active_rounded,
                    title: l10n.permissionNotificationTitle,
                    description: l10n.permissionNotificationDesc,
                    status: _notificationStatus,
                    onPressed: _requestNotification,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Optional Battery Optimization
                  // "A coter pas comme les autre" -> Different style
                  _buildBatteryItem(context),

                  const Spacer(flex: 2),
                  
                  // Access Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      // Only navigation here, no auto-jump
                      onPressed: _areMandatoryGranted() ? _navigateToHome : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _areMandatoryGranted() ? theme.colorScheme.primary : theme.disabledColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _areMandatoryGranted() ? 8 : 0,
                        shadowColor: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      child: Text(
                        l10n.accessApp,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required PermissionStatus status,
    required VoidCallback onPressed,
    bool isMandatory = false,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isGranted = status.isGranted || status.isLimited;
    // Android doesn't always performantly deny nicely. If requests return denied multiple times, it is effectively permanent.
    // We rely on isPermanentlyDenied flag from package.
    final isPermanentlyDenied = status.isPermanentlyDenied;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // Show red if mandatory, not granted, AND (permanently denied OR simply denied to highlight attention)
          color: isMandatory && !isGranted 
              ? (isPermanentlyDenied ? theme.colorScheme.error : theme.colorScheme.primary.withValues(alpha: 0.5))
              : theme.colorScheme.outline.withValues(alpha: 0.1),
           width: isMandatory && !isGranted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGranted 
                  ? theme.colorScheme.primaryContainer 
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isGranted 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(width: 8),
          if (isGranted)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            )
          else
            OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isPermanentlyDenied ? theme.colorScheme.error : theme.colorScheme.primary,
                  width: isPermanentlyDenied ? 2.0 : 1.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(isPermanentlyDenied ? l10n.openSettings : l10n.grant),
            ),
        ],
      ),
    );
  }

  Widget _buildBatteryItem(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isGranted = _isBatteryOptimized;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent, // "Pas comme les autres" -> Transparent
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.battery_saver_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.permissionBatteryTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.permissionBatteryDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isGranted)
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
          else
            TextButton(
              onPressed: _requestBattery,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(60, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.enable),
            ),
        ],
      ),
    );
  }
}



class _AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;

  _AppLifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
