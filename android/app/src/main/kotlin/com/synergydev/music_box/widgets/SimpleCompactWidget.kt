package com.synergydev.music_box.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import com.synergydev.music_box.MainActivity
import com.synergydev.music_box.R
import java.io.File

class SimpleCompactWidget : AppWidgetProvider() {
    
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
                android.util.Log.d("SimpleCompactWidget", "Play/Pause button clicked")
                sendCommand(context, "play_pause")
            }
            "com.synergydev.music_box.NEXT" -> {
                android.util.Log.d("SimpleCompactWidget", "Next button clicked")
                sendCommand(context, "next")
            }
            "com.synergydev.music_box.PREVIOUS" -> {
                android.util.Log.d("SimpleCompactWidget", "Previous button clicked")
                sendCommand(context, "previous")
            }
            "com.synergydev.music_box.UPDATE_WIDGET" -> {
                // Throttle updates to prevent OOM from rapid-fire updates
                val now = System.currentTimeMillis()
                if (now - lastUpdateTime > UPDATE_THROTTLE_MS) {
                    lastUpdateTime = now
                    updateAllWidgets(context)
                }
            }
        }
    }
    
    /**
     * Send command via broadcast to Flutter
     */
    /**
     * Send command via standard MediaButton intent for Play/Pause, Next, Previous.
     * Use custom broadcast for others.
     */
    private fun sendCommand(context: Context, command: String) {
        android.util.Log.d("SimpleCompactWidget", "Sending command: $command")
        
        val keycode = when (command) {
            "play_pause" -> android.view.KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            "next" -> android.view.KeyEvent.KEYCODE_MEDIA_NEXT
            "previous" -> android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS
            else -> 0
        }
        
        if (keycode != 0) {
            // Send standard MediaButton intent to audio_service
            val intent = Intent(Intent.ACTION_MEDIA_BUTTON)
            intent.component = ComponentName(context, "com.ryanheise.audioservice.MediaButtonReceiver")
            intent.putExtra(Intent.EXTRA_KEY_EVENT, android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, keycode))
            context.sendBroadcast(intent)
            
            // Also send ACTION_UP for completeness, though many receivers trigger on DOWN
            val upIntent = Intent(Intent.ACTION_MEDIA_BUTTON)
            upIntent.component = ComponentName(context, "com.ryanheise.audioservice.MediaButtonReceiver")
            upIntent.putExtra(Intent.EXTRA_KEY_EVENT, android.view.KeyEvent(android.view.KeyEvent.ACTION_UP, keycode))
            context.sendBroadcast(upIntent)
        } else {
            // Fallback for custom commands (Favorite, Shuffle, Repeat)
            val flutterIntent = Intent("com.synergydev.music_box.WIDGET_COMMAND").apply {
                putExtra("command", command)
                setPackage(context.packageName)
            }
            context.sendBroadcast(flutterIntent)
        }
    }
    
    private fun updateAllWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, SimpleCompactWidget::class.java)
        )
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }


    companion object {
        // ✅ 50ms throttle for instant responsiveness
        private const val UPDATE_THROTTLE_MS = 50L 
        private var lastUpdateTime = 0L
        
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_compact_simple)

            // Compute safe pixel sizes to stay under Binder limit (~1MB)
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val density = context.resources.displayMetrics.density
            val minWdp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).coerceAtLeast(200)
            val minHdp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT).coerceAtLeast(40)
            val widgetWpx = (minWdp * density).toInt()
            val widgetHpx = (minHdp * density).toInt()
            val maxPixels = 175_000 // ~700KB ARGB_8888
            val currentPixels = (widgetWpx.toLong() * widgetHpx.toLong()).coerceAtLeast(1)
            val scale = kotlin.math.min(1.0, kotlin.math.sqrt(maxPixels.toDouble() / currentPixels.toDouble()))
            val bgW = kotlin.math.max(280.0, widgetWpx * scale).toInt()
            val bgH = kotlin.math.max(120.0, widgetHpx * scale).toInt()
            val albumTargetPx = ((48 * density) * 1.5f).toInt().coerceAtLeast(120).coerceAtMost(192)
            
            // Get saved data
            val prefs = context.getSharedPreferences("widget_data", Context.MODE_PRIVATE)
            val titleRaw = prefs.getString("title", null)
            // Use localized "No song" text if no title stored
            val title = if (titleRaw.isNullOrEmpty() || titleRaw == "Music Box") {
                context.getString(R.string.widget_no_song)
            } else {
                titleRaw
            }
            // Use localized "Tap to open" if artist is missing/default
            val artistRaw = prefs.getString("artist", null)
            val artist = if (artistRaw == "Artist" || artistRaw.isNullOrEmpty()) {
                context.getString(R.string.widget_tap_to_open)
            } else {
                artistRaw
            }
            val isPlaying = prefs.getBoolean("isPlaying", false)
            val artPath = prefs.getString("artPath", null)
            
            // Set text
            views.setTextViewText(R.id.song_title, title)
            views.setTextViewText(R.id.artist_name, artist)
            
            // Set play/pause icon
            views.setImageViewResource(
                R.id.btn_play_pause,
                if (isPlaying) R.drawable.ic_widget_pause_modern else R.drawable.ic_widget_play_modern
            )
            
            // Set album art (simplified - no blur to save memory)
            if (artPath != null && File(artPath).exists()) {
                try {
                    val opts = BitmapFactory.Options().apply {
                        inPreferredConfig = Bitmap.Config.RGB_565 // Use less memory
                        inSampleSize = 2 // Downsample for faster loading
                    }
                    val bitmap = BitmapFactory.decodeFile(artPath, opts)
                    if (bitmap != null) {
                        val artBitmap = if (bitmap.width > albumTargetPx || bitmap.height > albumTargetPx) {
                            Bitmap.createScaledBitmap(bitmap, albumTargetPx, albumTargetPx, false)
                        } else {
                            bitmap
                        }
                        views.setImageViewBitmap(R.id.album_art, artBitmap)
                        if (artBitmap !== bitmap) {
                            bitmap.recycle()
                        }
                    } else {
                        views.setImageViewResource(R.id.album_art, R.drawable.ic_widget_music_default)
                    }
                } catch (e: Exception) {
                    views.setImageViewResource(R.id.album_art, R.drawable.ic_widget_music_default)
                }
            } else {
                views.setImageViewResource(R.id.album_art, R.drawable.ic_widget_music_default)
            }
            
            // Set click intents
            val playPauseIntent = PendingIntent.getBroadcast(
                context,
                0,
                Intent(context, SimpleCompactWidget::class.java).apply {
                    action = "com.synergydev.music_box.PLAY_PAUSE"
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_play_pause, playPauseIntent)
            
            val nextIntent = PendingIntent.getBroadcast(
                context,
                1,
                Intent(context, SimpleCompactWidget::class.java).apply {
                    action = "com.synergydev.music_box.NEXT"
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_next, nextIntent)
            
            val previousIntent = PendingIntent.getBroadcast(
                context,
                2,
                Intent(context, SimpleCompactWidget::class.java).apply {
                    action = "com.synergydev.music_box.PREVIOUS"
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_previous, previousIntent)
            
            // Open app on widget click (ANYWHERE)
            val appIntent = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root_compact, appIntent)
            // Keep album_art listener just in case, but root covers it
            views.setOnClickPendingIntent(R.id.album_art, appIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
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
            var idx = 0
            for (y in 0 until h) {
                var rSum = 0; var gSum = 0; var bSum = 0; var aSum = 0
                for (i in -radius..radius) {
                    val x = clamp(i, 0, w - 1)
                    val p = pixels[y * w + x]
                    aSum += p ushr 24
                    rSum += p shr 16 and 0xFF
                    gSum += p shr 8 and 0xFF
                    bSum += p and 0xFF
                }
                for (x in 0 until w) {
                    temp[idx++] = (clamp(aSum / div, 0, 255) shl 24) or
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
