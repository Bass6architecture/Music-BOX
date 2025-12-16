 package com.synergydev.music_box

import android.app.RecoverableSecurityException
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.widget.RemoteViews
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.BitmapShader
import android.graphics.Shader
import java.io.File
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity
import android.content.Context
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.os.Bundle
import android.os.PowerManager


class MainActivity : AudioServiceActivity() {
  companion object {
    private const val CHANNEL = "com.synergydev.music_box/native"
    private const val REQ_DELETE = 1001
    private const val REQ_WRITE = 1002
    private const val REQ_WRITE_METADATA = 1003
    private const val REQ_PERMISSION_ONLY = 1004
  }

  private fun getDominantColor(bmp: Bitmap): Int {
  // Fast average color sampling on a 8x8 grid
  var r = 0L; var g = 0L; var b = 0L; var count = 0
  val stepX = (bmp.width / 8).coerceAtLeast(1)
  val stepY = (bmp.height / 8).coerceAtLeast(1)
  var y = 0
  while (y < bmp.height) {
    var x = 0
    while (x < bmp.width) {
      val c = bmp.getPixel(x, y)
      r += Color.red(c); g += Color.green(c); b += Color.blue(c)
      count++
      x += stepX
    }
    y += stepY
  }
  if (count == 0) return Color.parseColor("#3D5AFE")
  var rr = (r / count).toInt(); var gg = (g / count).toInt(); var bb = (b / count).toInt()
  // Boost saturation and brightness a bit
  val hsv = FloatArray(3)
  Color.RGBToHSV(rr, gg, bb, hsv)
  hsv[1] = (hsv[1] * 1.2f).coerceIn(0f, 1f)
  hsv[2] = (hsv[2] * 1.15f).coerceIn(0f, 1f)
  // clamp to avoid too dark
  if (hsv[2] < 0.4f) hsv[2] = 0.4f
  // prefer bluish accent if very dull
  return Color.HSVToColor(hsv)
  }

  private fun composePlayButton(accent: Int, isPlaying: Boolean, sizePx: Int): Bitmap {
  val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
  val canvas = Canvas(bmp)
  val paint = Paint(Paint.ANTI_ALIAS_FLAG)
  // Circle
  paint.color = accent
  canvas.drawCircle(sizePx / 2f, sizePx / 2f, sizePx / 2f, paint)
  // Icon (white)
  paint.color = Color.WHITE
  if (isPlaying) {
    // Draw pause: two rounded rects
    val barW = sizePx * 0.16f
    val gap = sizePx * 0.10f
    val top = sizePx * 0.26f
    val bottom = sizePx * 0.74f
    val left1 = sizePx * 0.5f - gap/2 - barW
    val right1 = left1 + barW
    val left2 = sizePx * 0.5f + gap/2
    val right2 = left2 + barW
    val r = sizePx * 0.06f
    canvas.drawRoundRect(RectF(left1, top, right1, bottom), r, r, paint)
    canvas.drawRoundRect(RectF(left2, top, right2, bottom), r, r, paint)
  } else {
    // Draw play triangle
    val path = android.graphics.Path()
    val cx = sizePx * 0.45f
    val y1 = sizePx * 0.30f
    val y2 = sizePx * 0.70f
    val x2 = sizePx * 0.70f
    path.moveTo(cx, y1)
    path.lineTo(cx, y2)
    path.lineTo(x2, sizePx * 0.50f)
    path.close()
    canvas.drawPath(path, paint)
  }
  return bmp
  }

  private var pendingDeleteUri: Uri? = null
  private var pendingWriteData: Pair<String, String>? = null  // audioUri, imagePath
  private var pendingMetadataData: Pair<String, Map<String, String>>? = null  // audioUri, metadata
  private var pendingPermissionResult: MethodChannel.Result? = null // For generic permission request
  private var methodChannel: MethodChannel? = null
  private var widgetCommandReceiver: BroadcastReceiver? = null
  
  override fun onCreate(savedInstanceState: android.os.Bundle?) {
    super.onCreate(savedInstanceState)
    
    // Register broadcast receiver for widget commands
    widgetCommandReceiver = object : BroadcastReceiver() {
      override fun onReceive(context: Context?, intent: Intent?) {
        val command = intent?.getStringExtra("command")
        android.util.Log.d("MainActivity", "Widget command received: $command")
        
        // Check if methodChannel is ready before sending commands
        val channel = methodChannel
        if (channel == null) {
          android.util.Log.w("MainActivity", "MethodChannel not ready, ignoring widget command: $command")
          return
        }
        
        try {
          when (command) {
            "play_pause" -> {
              android.util.Log.d("MainActivity", "Sending widgetPlayPause to Flutter")
              channel.invokeMethod("widgetPlayPause", null)
            }
            "next" -> {
              android.util.Log.d("MainActivity", "Sending widgetNext to Flutter")
              channel.invokeMethod("widgetNext", null)
            }
            "previous" -> {
              android.util.Log.d("MainActivity", "Sending widgetPrevious to Flutter")
              channel.invokeMethod("widgetPrevious", null)
            }
            "favorite" -> {
              android.util.Log.d("MainActivity", "Sending widgetFavorite to Flutter")
              channel.invokeMethod("widgetFavorite", null)
            }
            "shuffle" -> {
              android.util.Log.d("MainActivity", "Sending widgetShuffle to Flutter")
              channel.invokeMethod("widgetShuffle", null)
            }
            "repeat" -> {
              android.util.Log.d("MainActivity", "Sending widgetRepeat to Flutter")
              channel.invokeMethod("widgetRepeat", null)
            }
          }
        } catch (e: Exception) {
          android.util.Log.e("MainActivity", "Error invoking widget command: $command", e)
        }
      }
    }
    
    val filter = IntentFilter("com.synergydev.music_box.WIDGET_COMMAND")
    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
      registerReceiver(widgetCommandReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
    } else {
      registerReceiver(widgetCommandReceiver, filter)
    }
  }
  
  override fun onDestroy() {
    super.onDestroy()
    widgetCommandReceiver?.let {
      unregisterReceiver(it)
    }
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    methodChannel?.setMethodCallHandler {
      call, result ->
      when (call.method) {
        "isEqualizerAvailable" -> {
          val intent = Intent("android.media.action.DISPLAY_AUDIO_EFFECT_CONTROL_PANEL")
          val available = intent.resolveActivity(packageManager) != null
          result.success(available)
        }
        "isIgnoringBatteryOptimizations" -> {
          try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            val isIgnoring = powerManager.isIgnoringBatteryOptimizations(packageName)
            result.success(isIgnoring)
          } catch (e: Exception) {
            result.success(false)
          }
        }
        "requestIgnoreBatteryOptimizations" -> {
          try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
              data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
            result.success(true)
          } catch (e: Exception) {
            result.success(false)
          }
        }
        "deleteAudio" -> {
          val audioId = call.argument<Int>("audioId")
          if (audioId == null) {
            result.error("ARG_ERROR", "Missing audioId", null)
            return@setMethodCallHandler
          }
          val uri = android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
          val audioUri = Uri.withAppendedPath(uri, audioId.toString())
          try {
            val rows = contentResolver.delete(audioUri, null, null)
            result.success(rows > 0)
          } catch (e: RecoverableSecurityException) {
            pendingDeleteUri = audioUri
            try {
              startIntentSenderForResult(
                e.userAction.actionIntent.intentSender,
                REQ_DELETE,
                null,
                0,
                0,
                0
              )
              result.success(false)
            } catch (ex: Exception) {
              result.error("DELETE_ERROR", ex.message, null)
            }
          } catch (e: Exception) {
            result.error("DELETE_ERROR", e.message, null)
          }
        }
        "deleteAudioList" -> {
          val audioIds = call.argument<List<Int>>("audioIds")
          if (audioIds == null || audioIds.isEmpty()) {
            result.error("ARG_ERROR", "Missing audioIds", null)
            return@setMethodCallHandler
          }

          val uri = android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
          val urisToDelete = audioIds.map { Uri.withAppendedPath(uri, it.toString()) }

          if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
             // Si on a l'accès complet aux fichiers (MANAGE_EXTERNAL_STORAGE), on peut supprimer direct
             if (android.os.Environment.isExternalStorageManager()) {
                var success = true
                for (u in urisToDelete) {
                  try {
                    contentResolver.delete(u, null, null)
                  } catch (e: Exception) {
                    success = false
                  }
                }
                result.success(success)
                return@setMethodCallHandler
             }

             // Sinon, on utilise createDeleteRequest pour grouper la demande
             try {
               val pi = android.provider.MediaStore.createDeleteRequest(contentResolver, urisToDelete)
               startIntentSenderForResult(pi.intentSender, REQ_DELETE, null, 0, 0, 0)
               result.success(true) 
             } catch (e: Exception) {
               result.error("DELETE_ERROR", e.message, null)
             }
          } else {
             // Android < 11: Loop delete or legacy
             // If Android 10 (Q), we assume RecoverableSecurityException per file (bad) or try to delete.
             // But usually on < 11 we don't need batched permissions if we have WRITE_EXTERNAL_STORAGE.
             // Let's try simple loop.
             var success = true
             for (u in urisToDelete) {
               try {
                 contentResolver.delete(u, null, null)
               } catch (e: Exception) {
                 success = false // If one fails, we might get exception.
                 // If RecoverableSecurityException, we are stuck.
                 // We will just try best effort.
               }
             }
             result.success(success)
          }
        }
        "deleteAudioByUri" -> {
          val uriStr = call.argument<String>("uri")
          if (uriStr.isNullOrEmpty()) {
            result.error("ARG_ERROR", "Missing uri", null)
            return@setMethodCallHandler
          }
          val uri = Uri.parse(uriStr)
          try {
            val rows = contentResolver.delete(uri, null, null)
            result.success(rows > 0)
          } catch (e: RecoverableSecurityException) {
            pendingDeleteUri = uri
            try {
              startIntentSenderForResult(
                e.userAction.actionIntent.intentSender,
                REQ_DELETE,
                null,
                0,
                0,
                0
              )
              result.success(false)
            } catch (ex: Exception) {
              result.error("DELETE_ERROR", ex.message, null)
            }
          } catch (e: Exception) {
            result.error("DELETE_ERROR", e.message, null)
          }
        }
        "setAsDefaultRingtone" -> {
          val uriStr = call.argument<String>("uri")
          if (uriStr.isNullOrEmpty()) {
            result.error("ARG_ERROR", "Missing uri", null)
            return@setMethodCallHandler
          }
          val canWrite = Settings.System.canWrite(this)
          if (!canWrite) {
            try {
              val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
              }
              startActivity(intent)
            } catch (_: Exception) {}
            result.success(false)
            return@setMethodCallHandler
          }
          try {
            val uri = Uri.parse(uriStr)
            RingtoneManager.setActualDefaultRingtoneUri(this, RingtoneManager.TYPE_RINGTONE, uri)
            result.success(true)
          } catch (e: Exception) {
            result.error("RINGTONE_ERROR", e.message, null)
          }
        }
        "setAsDefaultAlarm" -> {
          val uriStr = call.argument<String>("uri")
          if (uriStr.isNullOrEmpty()) {
            result.error("ARG_ERROR", "Missing uri", null)
            return@setMethodCallHandler
          }
          val canWrite = Settings.System.canWrite(this)
          if (!canWrite) {
            try {
              val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
              }
              startActivity(intent)
            } catch (_: Exception) {}
            result.success(false)
            return@setMethodCallHandler
          }
          try {
            val uri = Uri.parse(uriStr)
            RingtoneManager.setActualDefaultRingtoneUri(this, RingtoneManager.TYPE_ALARM, uri)
            result.success(true)
          } catch (e: Exception) {
            result.error("ALARM_ERROR", e.message, null)
          }
        }
        "setRingtone" -> {
          val uriStr = call.argument<String>("uri")
          val type = call.argument<String>("type") ?: "ringtone"
          
          if (uriStr.isNullOrEmpty()) {
            result.error("ARG_ERROR", "Missing uri", null)
            return@setMethodCallHandler
          }
          
          // Check write settings permission
          val canWrite = Settings.System.canWrite(this)
          if (!canWrite) {
            try {
              val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
              }
              startActivity(intent)
            } catch (_: Exception) {}
            result.error("PERMISSION_ERROR", "Need WRITE_SETTINGS permission", null)
            return@setMethodCallHandler
          }
          
          try {
            val uri = Uri.parse(uriStr)
            val ringtoneType = if (type == "alarm") RingtoneManager.TYPE_ALARM else RingtoneManager.TYPE_RINGTONE
            RingtoneManager.setActualDefaultRingtoneUri(this, ringtoneType, uri)
            result.success(true)
          } catch (e: Exception) {
            result.error("RINGTONE_ERROR", e.message, null)
          }
        }
        "updateMediaStoreMetadata" -> {
          // Disabled per user request: metadata changes are app-local only now.
          // Always return false (no system update performed) without prompting the user.
          result.success(false)
        }
        "updateHomeWidgets" -> {
          val title = call.argument<String>("title")
          val artist = call.argument<String>("artist")
          val album = call.argument<String>("album")
          val isPlaying = call.argument<Boolean>("isPlaying") ?: false
          val progress = call.argument<Int>("progress") ?: 0
          val positionMs = call.argument<Int>("positionMs") ?: 0
          val durationMs = call.argument<Int>("durationMs") ?: 0
          val artPath = call.argument<String>("artPath")
          val shuffleEnabled = call.argument<Boolean>("shuffleEnabled") ?: false
          val repeatMode = call.argument<String>("repeatMode") ?: "off"
          val isFavorite = call.argument<Boolean>("isFavorite") ?: false
          
          updateHomeWidgets(title, artist, album, isPlaying, progress, positionMs, durationMs, artPath, shuffleEnabled, repeatMode, isFavorite)
          result.success(null)
        }
        "playPause" -> {
          // Handle widget play/pause action
          result.success("play_pause")
        }
        "next" -> {
          // Handle widget next action
          result.success("next")
        }
        "previous" -> {
          // Handle widget previous action
          result.success("previous")
        }
        "favorite" -> {
          // Handle widget favorite action
          result.success("favorite")
        }
        "shuffle" -> {
          // Handle widget shuffle action
          result.success("shuffle")
        }
        "repeat" -> {
          // Handle widget repeat action
          result.success("repeat")
        }
        "writeAlbumArt" -> {
          val audioId = call.argument<Int>("audioId")
          val imagePath = call.argument<String>("imagePath")
          
          if (audioId == null || imagePath.isNullOrEmpty()) {
            result.error("ARG_ERROR", "Missing audioId or imagePath", null)
            return@setMethodCallHandler
          }
          
          try {
            val audioUri = android.content.ContentUris.withAppendedId(
              android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
              audioId.toLong()
            )
            val imageFile = File(imagePath)
            if (!imageFile.exists()) {
              result.error("FILE_ERROR", "Image file not found", null)
              return@setMethodCallHandler
            }
            
            // Check permission by trying to open stream
            var hasPermission = false
            try {
                // Try to open for "w" (write) doesn't always throw on R if you don't write.
                // But "rwt" usually triggers check.
                // Or just try the full write operation? No, that's heavy.
                // Just relying on startIntentSender if R is safe, BUT we want to skip it if authorized.
                // If we check `checkUriPermission`, it might not work for Scoped Storage.
                // Best check: try to open output stream.
                contentResolver.openOutputStream(audioUri, "rwt")?.close()
                hasPermission = true
            } catch (e: Exception) {
                // Ignore, we need permission
                hasPermission = false
            }

            if (hasPermission) {
                 // Do the write immediately
                 val success = performAlbumArtWrite(audioUri, imagePath)
                 methodChannel?.invokeMethod("onAlbumArtWritten", mapOf("success" to success))
                 result.success(null)
            } else {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                  try {
                    val uris = listOf(audioUri)
                    val pi = android.provider.MediaStore.createWriteRequest(contentResolver, uris)
                    pendingWriteData = Pair(audioUri.toString(), imagePath)
                    startIntentSenderForResult(pi.intentSender, REQ_WRITE, null, 0, 0, 0)
                    result.success(null)
                  } catch (e: Exception) {
                    result.success(false)
                  }
                } else {
                  result.success(false)
                }
            }
          } catch (e: Exception) {
            result.error("WRITE_ERROR", e.message, null)
          }
        }
        "writeMetadata" -> {
          val audioId = call.argument<Int>("audioId")
          val title = call.argument<String>("title") ?: ""
          val artist = call.argument<String>("artist") ?: ""
          val album = call.argument<String>("album") ?: ""
          val genre = call.argument<String>("genre") ?: ""
          val year = call.argument<String>("year") ?: ""
          
          if (audioId == null) {
            result.error("ARG_ERROR", "Missing audioId", null)
            return@setMethodCallHandler
          }
          
          try {
            val audioUri = android.content.ContentUris.withAppendedId(
              android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
              audioId.toLong()
            )
            
            val metadata = mapOf(
                  "title" to title,
                  "artist" to artist,
                  "album" to album,
                  "genre" to genre,
                  "year" to year
            )

            var hasPermission = false
            try {
                contentResolver.openOutputStream(audioUri, "rwt")?.close()
                hasPermission = true
            } catch (e: Exception) {
                hasPermission = false
            }

            if (hasPermission) {
                 val success = performMetadataWrite(audioUri, metadata)
                 methodChannel?.invokeMethod("onMetadataWritten", mapOf("success" to success))
                 result.success(null)
            } else {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                  try {
                    val uris = listOf(audioUri)
                    val pi = android.provider.MediaStore.createWriteRequest(contentResolver, uris)
                    pendingMetadataData = Pair(audioUri.toString(), metadata)
                    startIntentSenderForResult(pi.intentSender, REQ_WRITE_METADATA, null, 0, 0, 0)
                    result.success(null)
                  } catch (e: Exception) {
                    result.success(false)
                  }
                } else {
                  result.success(false)
                }
            }
          } catch (e: Exception) {
            result.error("WRITE_ERROR", e.message, null)
          }
        }
        "shareAudioFile" -> {
          val uriStr = call.argument<String>("uri")
          val title = call.argument<String>("title")
          
          if (uriStr.isNullOrEmpty()) {
            result.error("ARG_ERROR", "Missing uri", null)
            return@setMethodCallHandler
          }
          
          try {
            val uri = Uri.parse(uriStr)
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
              type = "audio/*"
              putExtra(Intent.EXTRA_STREAM, uri)
              if (!title.isNullOrEmpty()) {
                putExtra(Intent.EXTRA_SUBJECT, title)
              }
              addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
              addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            
            val chooser = Intent.createChooser(shareIntent, "Partager")
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(chooser)
            result.success(true)
          } catch (e: Exception) {
            result.error("SHARE_ERROR", e.message, null)
          }
        }
        "getRealPath" -> {
          val uriStr = call.argument<String>("uri")
          if (uriStr.isNullOrEmpty()) {
            result.error("ARG_ERROR", "Missing uri", null)
            return@setMethodCallHandler
          }
          
          try {
            val uri = Uri.parse(uriStr)
            val projection = arrayOf(android.provider.MediaStore.Audio.Media.DATA)
            val cursor = contentResolver.query(uri, projection, null, null, null)
            
            val path = cursor?.use {
              if (it.moveToFirst()) {
                val columnIndex = it.getColumnIndexOrThrow(android.provider.MediaStore.Audio.Media.DATA)
                it.getString(columnIndex)
              } else null
            }
            
            result.success(path)
          } catch (e: Exception) {
            result.error("PATH_ERROR", e.message, null)
          }
        }
        "requestWritePermission" -> {
          val audioId = call.argument<Int>("audioId")
          if (audioId == null) {
            result.error("ARG_ERROR", "Missing audioId", null)
            return@setMethodCallHandler
          }
          
          if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
            try {
              val audioUri = android.content.ContentUris.withAppendedId(
                android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                audioId.toLong()
              )
              val uris = listOf(audioUri)
              val pi = android.provider.MediaStore.createWriteRequest(contentResolver, uris)
              
              pendingPermissionResult = result
              startIntentSenderForResult(pi.intentSender, REQ_PERMISSION_ONLY, null, 0, 0, 0)
              // We do not call result.success here, we wait for onActivityResult
            } catch (e: Exception) {
              result.success(false)
            }
          } else {
            // Android < 11
            result.success(true)
          }
        }
        else -> result.notImplemented()
      }
    }
  }
  

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    if (requestCode == REQ_PERMISSION_ONLY) {
        val res = pendingPermissionResult
        if (res != null) {
            if (resultCode == RESULT_OK) {
                res.success(true)
            } else {
                res.success(false)
            }
            pendingPermissionResult = null
        }
        return
    }

    // Gère d'abord notre requête de suppression et évite d'appeler super pour REQ_DELETE
    if (requestCode == REQ_DELETE) {
      val uri = pendingDeleteUri
      if (uri != null) {
        try {
          contentResolver.delete(uri, null, null)
          methodChannel?.invokeMethod("onDeleteCompleted", mapOf("uri" to uri.toString()))
        } catch (_: Exception) {
        } finally {
          pendingDeleteUri = null
        }
      }
      return
    }
    // Gère la requête d'écriture (pochette système)
    // Gère la requête d'écriture (pochette système)
    if (requestCode == REQ_WRITE) {
      if (resultCode == RESULT_OK && pendingWriteData != null) {
        val (audioUriStr, imagePath) = pendingWriteData!!
        val audioUri = Uri.parse(audioUriStr)
        val success = performAlbumArtWrite(audioUri, imagePath)
        methodChannel?.invokeMethod("onAlbumArtWritten", mapOf("success" to success))
      } else {
        methodChannel?.invokeMethod("onAlbumArtWritten", mapOf("success" to false))
      }
      pendingWriteData = null
      return
    }
    // Gère la requête d'écriture des métadonnées
    if (requestCode == REQ_WRITE_METADATA) {
      if (resultCode == RESULT_OK && pendingMetadataData != null) {
        val (audioUriStr, metadata) = pendingMetadataData!!
        val audioUri = Uri.parse(audioUriStr)
        val success = performMetadataWrite(audioUri, metadata)
        methodChannel?.invokeMethod("onMetadataWritten", mapOf("success" to success))
      } else {
        methodChannel?.invokeMethod("onMetadataWritten", mapOf("success" to false))
      }
      pendingMetadataData = null
      return
    }
          

          

          

    // Évite le double reply du plugin image_cropper lorsque uCrop est annulé (RESULT_CANCELED)
    // UCrop.REQUEST_CROP = 69
    if (requestCode == 69 && resultCode == RESULT_CANCELED) {
      return
    }
    // Pour tous les autres codes (ex: image_cropper), délègue normalement aux plugins Flutter
    super.onActivityResult(requestCode, resultCode, data)
  }

  private fun updateHomeWidgets(
    title: String?,
    artist: String?,
    album: String?,
    isPlaying: Boolean,
    progress: Int,
    positionMs: Int,
    durationMs: Int,
    artPath: String?,
    shuffleEnabled: Boolean,
    repeatMode: String,
    isFavorite: Boolean
  ) {
    // Save widget data to SharedPreferences
    val prefs = getSharedPreferences("widget_data", MODE_PRIVATE)
    prefs.edit().apply {
      putString("title", title ?: "Music Box")
      putString("artist", artist ?: "")
      putString("album", album ?: "")
      putBoolean("isPlaying", isPlaying)
      putInt("progress", progress)
      putInt("positionMs", positionMs)
      putInt("durationMs", durationMs)
      putString("artPath", artPath)
      putBoolean("shuffleEnabled", shuffleEnabled)
      putString("repeatMode", repeatMode)
      putBoolean("isFavorite", isFavorite)
      apply()
    }

    // Send update broadcast to new modern widget providers
    val updateIntent = Intent("com.synergydev.music_box.UPDATE_WIDGET").apply {
      setPackage(packageName)
    }
    sendBroadcast(updateIntent)
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    handleWidgetAction(intent.action)
  }

  private fun handleWidgetAction(action: String?) {
    when (action) {
      // no-op (only media buttons are active)
    }
  }

  // Global cover write removed (app-local covers only)
  
  private fun roundedBitmap(src: Bitmap, radius: Float): Bitmap {
    val output = Bitmap.createBitmap(src.width, src.height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(output)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    val rect = RectF(0f, 0f, src.width.toFloat(), src.height.toFloat())
    val shader = BitmapShader(src, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
    paint.shader = shader
    canvas.drawRoundRect(rect, radius, radius, paint)
    return output
  }

  private fun performAlbumArtWrite(audioUri: Uri, imagePath: String): Boolean {
    var tempInput: File? = null
    var tempOutput: File? = null
    return try {
      tempInput = File(cacheDir, "temp_input_${System.currentTimeMillis()}.mp3")
      contentResolver.openInputStream(audioUri)?.use { input ->
        tempInput!!.outputStream().use { output ->
          input.copyTo(output)
        }
      }
      
      val mp3File = com.mpatric.mp3agic.Mp3File(tempInput.absolutePath)
      val imageFile = File(imagePath)
      val imageBytes = imageFile.readBytes()
      
      val tag = if (mp3File.hasId3v2Tag()) {
        mp3File.id3v2Tag
      } else {
        com.mpatric.mp3agic.ID3v24Tag()
      }
      
      tag.setAlbumImage(imageBytes, "image/jpeg")
      mp3File.id3v2Tag = tag
      
      tempOutput = File(cacheDir, "temp_output_${System.currentTimeMillis()}.mp3")
      mp3File.save(tempOutput.absolutePath)
      
      if (tempOutput.exists()) {
        contentResolver.openOutputStream(audioUri)?.use { output ->
          tempOutput!!.inputStream().use { input ->
            input.copyTo(output)
          }
        }
        true
      } else {
        false
      }
    } catch (e: Exception) {
      e.printStackTrace()
      false
    } finally {
      try { tempInput?.delete() } catch(_:Exception){}
      try { tempOutput?.delete() } catch(_:Exception){}
    }
  }

  private fun performMetadataWrite(audioUri: Uri, metadata: Map<String, String>): Boolean {
    var tempInput: File? = null
    var tempOutput: File? = null
    return try {
      tempInput = File(cacheDir, "temp_input_meta_${System.currentTimeMillis()}.mp3")
      contentResolver.openInputStream(audioUri)?.use { input ->
        tempInput!!.outputStream().use { output ->
          input.copyTo(output)
        }
      }
      
      val mp3File = com.mpatric.mp3agic.Mp3File(tempInput.absolutePath)
      val tag = if (mp3File.hasId3v2Tag()) {
        mp3File.id3v2Tag
      } else {
        com.mpatric.mp3agic.ID3v24Tag()
      }
      
      metadata["title"]?.let { if (it.isNotEmpty()) tag.title = it }
      metadata["artist"]?.let { if (it.isNotEmpty()) tag.artist = it }
      metadata["album"]?.let { if (it.isNotEmpty()) tag.album = it }
      metadata["genre"]?.let { if (it.isNotEmpty()) {
         val genreInt = it.toIntOrNull()
         if (genreInt != null) tag.genre = genreInt
      }}
      metadata["year"]?.let { if (it.isNotEmpty()) tag.year = it }
      
      mp3File.id3v2Tag = tag
      
      tempOutput = File(cacheDir, "temp_output_meta_${System.currentTimeMillis()}.mp3")
      mp3File.save(tempOutput.absolutePath)
      
      if (tempOutput.exists()) {
        contentResolver.openOutputStream(audioUri)?.use { output ->
          tempOutput!!.inputStream().use { input ->
            input.copyTo(output)
          }
        }
        true
      } else {
        false
      }
    } catch (e: Exception) {
      e.printStackTrace()
      false
    } finally {
      try { tempInput?.delete() } catch(_:Exception){}
      try { tempOutput?.delete() } catch(_:Exception){}
    }
  }
}
