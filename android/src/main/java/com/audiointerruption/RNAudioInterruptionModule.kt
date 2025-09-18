package com.audiointerruption

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.telecom.TelecomManager
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule.RCTDeviceEventEmitter

class RNAudioInterruptionModule(private val reactCtx: ReactApplicationContext)
  : ReactContextBaseJavaModule(reactCtx) {

  override fun getName() = "RNAudioInterruption"

  private var audioManager: AudioManager? = null
  private var focusRequest: AudioFocusRequest? = null

  private val listener = AudioManager.OnAudioFocusChangeListener { change ->
    val state = when (change) {
      AudioManager.AUDIOFOCUS_LOSS -> "loss"
      AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> "loss_transient"
      AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> "duck"
      AudioManager.AUDIOFOCUS_GAIN -> "gain"
      else -> return@OnAudioFocusChangeListener
    }
    emit("android", state)
  }

  @ReactMethod
  fun start(mode: String) {
    audioManager = (reactCtx.getSystemService(Context.AUDIO_SERVICE) as? AudioManager)

    val usage = if (mode == "record") AudioAttributes.USAGE_VOICE_COMMUNICATION
                else AudioAttributes.USAGE_MEDIA
    val content = if (mode == "record") AudioAttributes.CONTENT_TYPE_SPEECH
                  else AudioAttributes.CONTENT_TYPE_MUSIC

    if (Build.VERSION.SDK_INT >= 26) {
      val attrs = AudioAttributes.Builder().setUsage(usage).setContentType(content).build()
      focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
        .setOnAudioFocusChangeListener(listener)
        .setAudioAttributes(attrs)
        .setWillPauseWhenDucked(true)
        .build()
      audioManager?.requestAudioFocus(focusRequest!!)
    } else {
      @Suppress("DEPRECATION")
      audioManager?.requestAudioFocus(
        listener,
        if (mode == "record") AudioManager.STREAM_VOICE_CALL else AudioManager.STREAM_MUSIC,
        AudioManager.AUDIOFOCUS_GAIN
      )
    }
  }

  @ReactMethod
  fun stop() {
    audioManager?.let { am ->
      if (Build.VERSION.SDK_INT >= 26) {
        focusRequest?.let { am.abandonAudioFocusRequest(it) }
      } else {
        @Suppress("DEPRECATION") am.abandonAudioFocus(listener)
      }
    }
    focusRequest = null
  }

  @ReactMethod
  fun isBusy(promise: Promise) {
    val am = (reactCtx.getSystemService(Context.AUDIO_SERVICE) as? AudioManager)
    if (am == null) {
      promise.reject("unavailable", "AudioManager unavailable")
      return
    }

    val mode = am.mode
    var busy = mode == AudioManager.MODE_IN_CALL ||
      mode == AudioManager.MODE_IN_COMMUNICATION ||
      mode == AudioManager.MODE_RINGTONE

    if (!busy && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      val telecom = reactCtx.getSystemService(TelecomManager::class.java)
      if (telecom != null) {
        try {
          busy = telecom.isInCall
        } catch (_: SecurityException) {
          // No permission, ignore and fallback to audio mode
        }
      }
    }

    promise.resolve(busy)
  }

  private fun emit(platform: String, state: String) {
    val map = Arguments.createMap().apply {
      putString("platform", platform)
      putString("state", state)
    }
    reactCtx.getJSModule(RCTDeviceEventEmitter::class.java)
      .emit("audioInterruption", map)
  }
}
