package com.synergydev.music_box.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.os.Bundle
import android.widget.RemoteViews
import com.synergydev.music_box.MainActivity
import com.synergydev.music_box.R
import java.io.File

class SimpleAdaptiveWidget : AppWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            "com.synergydev.music_box.PLAY_PAUSE" -> {
                android.util.Log.d("SimpleAdaptiveWidget", "Play/Pause button clicked")
                sendMediaCommand(context, "play_pause")
            }
            "com.synergydev.music_box.NEXT" -> {
                android.util.Log.d("SimpleAdaptiveWidget", "Next button clicked")
                sendMediaCommand(context, "next")
            }
            "com.synergydev.music_box.PREVIOUS" -> {
                android.util.Log.d("SimpleAdaptiveWidget", "Previous button clicked")
                sendMediaCommand(context, "previous")
            }
            "com.synergydev.music_box.FAVORITE" -> {
                android.util.Log.d("SimpleAdaptiveWidget", "Favorite button clicked")
                sendBroadcastCommand(context, "favorite")
            }
            "com.synergydev.music_box.SHUFFLE" -> {
                android.util.Log.d("SimpleAdaptiveWidget", "Shuffle button clicked")
                sendBroadcastCommand(context, "shuffle")
            }
            "com.synergydev.music_box.REPEAT" -> {
                android.util.Log.d("SimpleAdaptiveWidget", "Repeat button clicked")
                sendBroadcastCommand(context, "repeat")
            }
            "com.synergydev.music_box.UPDATE_WIDGET" -> {
                updateAllWidgets(context)
            }
        }
    }
    
    /**
     * Send media command using MediaSession for reliability (play/pause, next, previous).
     * Falls back to broadcast if MediaSession is unavailable.
     */
    private fun sendMediaCommand(context: Context, command: String) {
        val controller = getActiveMediaController(context)
        
        if (controller != null) {
            android.util.Log.d("SimpleAdaptiveWidget", "Using MediaSession for: $command")
            when (command) {
                "play_pause" -> {
                    val state = controller.playbackState
                    if (state != null && state.state == android.media.session.PlaybackState.STATE_PLAYING) {
                        controller.transportControls.pause()
                    } else {
                        controller.transportControls.play()
                    }
                }
                "next" -> controller.transportControls.skipToNext()
                "previous" -> controller.transportControls.skipToPrevious()
            }
        } else {
            sendBroadcastCommand(context, command)
            // Don't launch app - just send the broadcast silently
        }
    }
    
    /**
     * Send command via broadcast (for favorite, shuffle, repeat which require Flutter).
     */
    private fun sendBroadcastCommand(context: Context, command: String) {
        android.util.Log.d("SimpleAdaptiveWidget", "Sending broadcast for: $command")
        val flutterIntent = Intent("com.synergydev.music_box.WIDGET_COMMAND").apply {
            putExtra("command", command)
            setPackage(context.packageName)
        }
        context.sendBroadcast(flutterIntent)
    }
    
    private fun getActiveMediaController(context: Context): MediaController? {
        return try {
            val sessionManager = context.getSystemService(Context.MEDIA_SESSION_SERVICE) as? MediaSessionManager
            val controllers = sessionManager?.getActiveSessions(null)
            controllers?.firstOrNull { it.packageName == context.packageName }
        } catch (e: Exception) {
            android.util.Log.w("SimpleAdaptiveWidget", "Could not get MediaController: ${e.message}")
            null
        }
    }
    
    private fun launchAppIfNeeded(context: Context) {
        try {
            val intent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            android.util.Log.w("SimpleAdaptiveWidget", "Could not launch app: ${e.message}")
        }
    }
    
    private fun updateAllWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, SimpleAdaptiveWidget::class.java)
        )
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
    
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    companion object {
        private fun getWidgetSize(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int): Int {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
            val maxHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
            val currentHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
            
            android.util.Log.d("SimpleAdaptiveWidget", "Widget height - min: $minHeight, max: $maxHeight, current: $currentHeight")
            
            // Decide between compact (4x1) and simple (4x2) layouts only. Never 4x4.
            // Use the provided minHeight to infer which widget instance this is.
            // Typical values: ~40dp for 4x1, ~110dp for 4x2
            return if (minHeight <= 60) {
                R.layout.widget_compact_simple
            } else {
                R.layout.widget_adaptive_simple
            }
        }
        
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val layoutId = getWidgetSize(context, appWidgetManager, appWidgetId)
            val views = try {
                RemoteViews(context.packageName, layoutId)
            } catch (e: Exception) {
                android.util.Log.e("SimpleAdaptiveWidget", "Error creating RemoteViews with layout $layoutId", e)
                RemoteViews(context.packageName, R.layout.widget_adaptive_simple)
            }
            // Compute widget px sizes for high-quality assets without exceeding binder limits
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val density = context.resources.displayMetrics.density
            val minWdp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).coerceAtLeast(200)
            val minHdp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT).coerceAtLeast(100)
            val widgetWpx = (minWdp * density).toInt()
            val widgetHpx = (minHdp * density).toInt()
            // Keep background bitmap under ~175k pixels (~700KB ARGB) to stay below binder limit
            val maxPixels = 175_000
            val currentPixels = (widgetWpx.toLong() * widgetHpx.toLong()).coerceAtLeast(1)
            val scale = kotlin.math.min(1.0, kotlin.math.sqrt(maxPixels.toDouble() / currentPixels.toDouble()))
            val bgW = kotlin.math.max(300.0, widgetWpx * scale).toInt()
            val bgH = kotlin.math.max(150.0, widgetHpx * scale).toInt()
            // Album art target (crisp): 80dp view -> scale to ~1.5x px, cap at 256px
            val albumTargetPx = ((80 * density) * 1.5f).toInt().coerceAtLeast(160).coerceAtMost(256)
            
            // Get saved data
            val prefs = context.getSharedPreferences("widget_data", Context.MODE_PRIVATE)
            val title = prefs.getString("title", "Music Box") ?: "Music Box"
            val artist = prefs.getString("artist", "Artist") ?: "Artist"
            val isPlaying = prefs.getBoolean("isPlaying", false)
            val isFavorite = prefs.getBoolean("isFavorite", false)
            val artPath = prefs.getString("artPath", null)
            
            // Set text with safe try-catch
            try {
                views.setTextViewText(R.id.song_title, title)
            } catch (e: Exception) {
                android.util.Log.w("SimpleAdaptiveWidget", "song_title not found in layout")
            }
            
            try {
                views.setTextViewText(R.id.artist_name, artist)
            } catch (e: Exception) {
                android.util.Log.w("SimpleAdaptiveWidget", "artist_name not found in layout")
            }
            
            // Set album name if exists in layout
            // Album view not available in simple layouts
            // try {
            //     val album = prefs.getString("album", "Album") ?: "Album"
            //     views.setTextViewText(R.id.album_name, album)
            // } catch (e: Exception) {
            //     // Album name not in this layout
            // }
            
            // Set play/pause icon
            views.setImageViewResource(
                R.id.btn_play_pause,
                if (isPlaying) R.drawable.ic_widget_pause_modern else R.drawable.ic_widget_play_modern
            )
            
            // Set favorite icon (may not exist in some layouts)
            try {
                views.setImageViewResource(
                    R.id.btn_favorite,
                    if (isFavorite) R.drawable.ic_widget_heart_filled else R.drawable.ic_widget_heart_outline
                )
                // Apply color: red when favorite, white otherwise
                val favColor = if (isFavorite) android.graphics.Color.parseColor("#FF1744") else android.graphics.Color.WHITE
                views.setInt(R.id.btn_favorite, "setColorFilter", favColor)
            } catch (e: Exception) {
                android.util.Log.w("SimpleAdaptiveWidget", "btn_favorite not found in this layout")
            }
            
            // Set shuffle and repeat icons if they exist in layout
            try {
                val shuffleEnabled = prefs.getBoolean("shuffleEnabled", false)
                views.setImageViewResource(
                    R.id.btn_shuffle,
                    if (shuffleEnabled) R.drawable.ic_widget_shuffle_on else R.drawable.ic_widget_shuffle_off
                )
            } catch (e: Exception) {
                // Shuffle button not in this layout
            }
            
            try {
                val repeatMode = prefs.getString("repeatMode", "off") ?: "off"
                val repeatIcon = when (repeatMode) {
                    "all" -> R.drawable.ic_widget_repeat_all
                    "one" -> R.drawable.ic_widget_repeat_one
                    else -> R.drawable.ic_widget_repeat_off
                }
                views.setImageViewResource(R.id.btn_repeat, repeatIcon)
            } catch (e: Exception) {
                // Repeat button not in this layout
            }
            
            // Set progress bar if exists
            try {
                val progress = prefs.getInt("progress", 0)
                views.setProgressBar(R.id.progress_bar, 100, progress, false)
            } catch (e: Exception) {
                // Progress bar not in this layout
            }

            // Set time text if view exists
            try {
                val pos = prefs.getInt("positionMs", 0)
                val dur = prefs.getInt("durationMs", 0)
                fun fmt(ms: Int): String {
                    val totalSec = (ms / 1000).coerceAtLeast(0)
                    val m = totalSec / 60
                    val s = totalSec % 60
                    return String.format("%d:%02d", m, s)
                }
                if (dur > 0) {
                    views.setTextViewText(R.id.time_text, fmt(pos) + " / " + fmt(dur))
                }
            } catch (e: Exception) {
                // time_text not in this layout
            }
            
            // Set album art (crisp) and background overlay (smooth blur)
            if (artPath != null && File(artPath).exists()) {
                try {
                    val opts = BitmapFactory.Options().apply {
                        inPreferredConfig = Bitmap.Config.ARGB_8888
                        inDither = false
                        inScaled = false
                    }
                    val bitmap = BitmapFactory.decodeFile(artPath, opts)
                    if (bitmap != null) {
                        val minDim = kotlin.math.min(bitmap.width, bitmap.height)
                        val artBitmap = if (minDim > albumTargetPx) {
                            Bitmap.createScaledBitmap(bitmap, albumTargetPx, albumTargetPx, true)
                        } else {
                            bitmap
                        }
                        views.setImageViewBitmap(R.id.album_art, artBitmap)
                        // Background overlay: scale towards widget size but keep under binder limit, then blur
                        try {
                            val base = Bitmap.createScaledBitmap(bitmap, bgW, bgH, true)
                            val blurred = boxBlur(base, 10)
                            views.setImageViewBitmap(R.id.bg_overlay, blurred)
                        } catch (e: Exception) {
                            // bg_overlay not present in this layout
                        }
                        // No recycle here to avoid recycling if reused above
                    }
                } catch (e: Exception) {
                    views.setImageViewResource(R.id.album_art, R.drawable.ic_widget_music_default)
                    try { views.setImageViewResource(R.id.bg_overlay, R.drawable.ic_widget_music_default) } catch (_: Exception) {}
                }
            } else {
                views.setImageViewResource(R.id.album_art, R.drawable.ic_widget_music_default)
                try { views.setImageViewResource(R.id.bg_overlay, R.drawable.ic_widget_music_default) } catch (_: Exception) {}
            }

            // Set click intents (inside function)
            val playPauseIntent = PendingIntent.getBroadcast(
                context,
                10,
                Intent(context, SimpleAdaptiveWidget::class.java).apply {
                    action = "com.synergydev.music_box.PLAY_PAUSE"
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_play_pause, playPauseIntent)

            val nextIntent = PendingIntent.getBroadcast(
                context,
                11,
                Intent(context, SimpleAdaptiveWidget::class.java).apply {
                    action = "com.synergydev.music_box.NEXT"
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_next, nextIntent)

            val previousIntent = PendingIntent.getBroadcast(
                context,
                12,
                Intent(context, SimpleAdaptiveWidget::class.java).apply {
                    action = "com.synergydev.music_box.PREVIOUS"
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_previous, previousIntent)

            try {
                val favoriteIntent = PendingIntent.getBroadcast(
                    context,
                    13,
                    Intent(context, SimpleAdaptiveWidget::class.java).apply {
                        action = "com.synergydev.music_box.FAVORITE"
                    },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.btn_favorite, favoriteIntent)
            } catch (_: Exception) {
                // favorite not in this layout
            }

            // Shuffle and repeat if present
            try {
                val shuffleIntent = PendingIntent.getBroadcast(
                    context,
                    14,
                    Intent(context, SimpleAdaptiveWidget::class.java).apply {
                        action = "com.synergydev.music_box.SHUFFLE"
                    },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.btn_shuffle, shuffleIntent)
            } catch (_: Exception) {}

            try {
                val repeatIntent = PendingIntent.getBroadcast(
                    context,
                    15,
                    Intent(context, SimpleAdaptiveWidget::class.java).apply {
                        action = "com.synergydev.music_box.REPEAT"
                    },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.btn_repeat, repeatIntent)
            } catch (_: Exception) {}

            // Open app
            val appIntent = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.album_art, appIntent)

            // Apply update
            appWidgetManager.updateAppWidget(appWidgetId, views)

            // Helper: fast box blur (two-pass) for smooth background
            // Radius in pixels (suggest 6-12). This avoids pixelation vs heavy downscale.
        }

        // Simple two-pass box blur for ARGB_8888 bitmaps
        private fun boxBlur(src: Bitmap, radius: Int): Bitmap {
            if (radius <= 0) return src
            val w = src.width
            val h = src.height
            val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val pixels = IntArray(w * h)
            val temp = IntArray(w * h)
            src.getPixels(pixels, 0, w, 0, 0, w, h)

            val div = radius * 2 + 1

            // Horizontal pass
            var index = 0
            for (y in 0 until h) {
                var rSum = 0; var gSum = 0; var bSum = 0; var aSum = 0
                // initial window
                for (i in -radius..radius) {
                    val x = clamp(i, 0, w - 1)
                    val p = pixels[y * w + x]
                    aSum += p ushr 24
                    rSum += p shr 16 and 0xFF
                    gSum += p shr 8 and 0xFF
                    bSum += p and 0xFF
                }
                for (x in 0 until w) {
                    temp[index++] = (clamp(aSum / div, 0, 255) shl 24) or
                            (clamp(rSum / div, 0, 255) shl 16) or
                            (clamp(gSum / div, 0, 255) shl 8) or
                            clamp(bSum / div, 0, 255)
                    val xOut = x - radius
                    val xIn = x + radius + 1
                    val pOut = pixels[y * w + clamp(xOut, 0, w - 1)]
                    val pIn = pixels[y * w + clamp(xIn, 0, w - 1)]
                    aSum += (pIn ushr 24) - (pOut ushr 24)
                    rSum += (pIn shr 16 and 0xFF) - (pOut shr 16 and 0xFF)
                    gSum += (pIn shr 8 and 0xFF) - (pOut shr 8 and 0xFF)
                    bSum += (pIn and 0xFF) - (pOut and 0xFF)
                }
            }

            // Vertical pass
            index = 0
            for (x in 0 until w) {
                var rSum = 0; var gSum = 0; var bSum = 0; var aSum = 0
                for (i in -radius..radius) {
                    val y = clamp(i, 0, h - 1)
                    val p = temp[y * w + x]
                    aSum += p ushr 24
                    rSum += p shr 16 and 0xFF
                    gSum += p shr 8 and 0xFF
                    bSum += p and 0xFF
                }
                for (y in 0 until h) {
                    pixels[y * w + x] = (clamp(aSum / div, 0, 255) shl 24) or
                            (clamp(rSum / div, 0, 255) shl 16) or
                            (clamp(gSum / div, 0, 255) shl 8) or
                            clamp(bSum / div, 0, 255)
                    val yOut = y - radius
                    val yIn = y + radius + 1
                    val pOut = temp[clamp(yOut, 0, h - 1) * w + x]
                    val pIn = temp[clamp(yIn, 0, h - 1) * w + x]
                    aSum += (pIn ushr 24) - (pOut ushr 24)
                    rSum += (pIn shr 16 and 0xFF) - (pOut shr 16 and 0xFF)
                    gSum += (pIn shr 8 and 0xFF) - (pOut shr 8 and 0xFF)
                    bSum += (pIn and 0xFF) - (pOut and 0xFF)
                }
            }

            out.setPixels(pixels, 0, w, 0, 0, w, h)
            return out
        }

        private fun clamp(v: Int, min: Int, max: Int): Int = if (v < min) min else if (v > max) max else v
    }
}
