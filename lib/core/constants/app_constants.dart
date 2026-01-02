class AppConstants {
  // App Info
  static const String appName = 'Music Box';
  static const String appVersion = '2.0.0';
  
  // Notification
  static const String notificationChannelId = 'com.synergydev.music_box.channel.audio';
  static const String notificationChannelName = 'Music playback';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  static const Duration splashDuration = Duration(milliseconds: 6000);
  
  // Layout
  static const double miniPlayerHeight = 72.0;
  static const double borderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 24.0;
  
  // Padding & Margins
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Cache
  static const int maxCacheSize = 100;
  static const Duration cacheExpiration = Duration(hours: 24);
}
