package com.balebelajar.bale_belajar_app

import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import java.util.Locale
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
  // Render bitmap + WallpaperManager.setBitmap berat (ratusan ms - detik).
  // Kalau jalan di main thread, UI Flutter macet saat resume -> layar putih.
  private val wallpaperExecutor = Executors.newSingleThreadExecutor()
  private val mainHandler = Handler(Looper.getMainLooper())
  private var koreanSpeech: TextToSpeech? = null
  private var speechReady = false
  private var initializingSpeech = false

  private fun speakKorean(text: String, result: MethodChannel.Result) {
    if (text.isBlank()) { result.error("EMPTY_TEXT", "Teks listening tidak tersedia.", null); return }
    if (initializingSpeech) { result.error("TTS_BUSY", "Suara sedang disiapkan. Coba lagi.", null); return }
    if (!speechReady) {
      initializingSpeech = true
      koreanSpeech = TextToSpeech(this) { status ->
        mainHandler.post {
          initializingSpeech = false
          speechReady = status == TextToSpeech.SUCCESS
          if (speechReady) speakKorean(text, result)
          else result.error("TTS_UNAVAILABLE", "Aktifkan mesin Text-to-speech dan instal voice pack Korea di pengaturan Android.", null)
        }
      }
      return
    }
    val language = koreanSpeech!!.setLanguage(Locale.KOREAN)
    if (language == TextToSpeech.LANG_MISSING_DATA || language == TextToSpeech.LANG_NOT_SUPPORTED) {
      result.error("KOREAN_VOICE_MISSING", "Instal voice pack Korea di pengaturan Text-to-speech Android, lalu coba lagi.", null)
      return
    }
    koreanSpeech!!.setSpeechRate(0.9f)
    val outcome = koreanSpeech!!.speak(text, TextToSpeech.QUEUE_FLUSH, null, "korean-lesson")
    if (outcome == TextToSpeech.ERROR) result.error("TTS_FAILED", "Suara tidak dapat diputar. Periksa mesin Text-to-speech Android.", null)
    else result.success(true)
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
      "com.balebelajar.bale_belajar_app/korean_speech").setMethodCallHandler { call, result ->
      when (call.method) {
        "speak" -> speakKorean(call.argument<String>("text") ?: "", result)
        "stop" -> { koreanSpeech?.stop(); result.success(null) }
        else -> result.notImplemented()
      }
    }
    MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        "com.balebelajar.bale_belajar_app/vocab_lock_wallpaper",
    ).setMethodCallHandler { call, result ->
      try {
        when (call.method) {
          "setCurrent" -> {
            val wordsJson = call.argument<String>("wordsJson")
            val appContext = applicationContext
            wallpaperExecutor.execute {
              try {
                if (!wordsJson.isNullOrBlank()) {
                  VocabLockScreenWallpaper.saveWords(appContext, wordsJson)
                }
                val changed = VocabLockScreenWallpaper.renderCurrent(appContext)
                if (changed) VocabLockScreenWallpaper.scheduleHourly(appContext)
                mainHandler.post { result.success(changed) }
              } catch (error: Exception) {
                mainHandler.post {
                  result.error("VOCAB_WALLPAPER_FAILED", error.message, null)
                }
              }
            }
          }
          "scheduleHourly" -> {
            VocabLockScreenWallpaper.scheduleHourly(this)
            result.success(true)
          }
          "cancelHourly" -> {
            VocabLockScreenWallpaper.cancelHourly(this)
            result.success(true)
          }
          else -> result.notImplemented()
        }
      } catch (error: Exception) {
        result.error("VOCAB_WALLPAPER_FAILED", error.message, null)
      }
    }
  }

  override fun onPause() { koreanSpeech?.stop(); super.onPause() }
  override fun onDestroy() { koreanSpeech?.stop(); koreanSpeech?.shutdown(); super.onDestroy() }
}
