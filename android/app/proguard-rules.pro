# ✅ Règles ProGuard pour audio_service (CRITIQUE)
-keep class com.ryanheise.audioservice.** { *; }
-keep class androidx.media.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn com.ryanheise.audioservice.**

# AudioService - BaseAudioHandler
-keep class * extends com.ryanheise.audioservice.BaseAudioHandler { *; }
-keepclassmembers class * extends com.ryanheise.audioservice.BaseAudioHandler {
    public <methods>;
}

# ✅ Garder les ressources de notification
-keep class **.R$drawable { *; }
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Just Audio (CRITIQUE pour notifications)
-keep class com.google.android.exoplayer2.** { *; }
-keep class com.ryanheise.just_audio.** { *; }
-dontwarn com.google.android.exoplayer2.**
-dontwarn com.ryanheise.just_audio.**

# MediaSession et MediaItem
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.** { *; }
-keep interface androidx.media.** { *; }

# AdMob (éviter crashes WebView)
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# ✅ Google Play Core (pour Flutter deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
