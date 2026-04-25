package com.example.bluepay

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.media.MediaPlayer
import io.flutter.FlutterInjector

class MainActivity: FlutterActivity() {
    private val AUDIO_CHANNEL  = "com.example.bluepay/audio"
    private val SYSTEM_CHANNEL = "com.example.bluepay/system"
    private val SMS_EVENT_CHANNEL = "com.example.bluepay/sms_events"
    private var mediaPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Audio channel ──────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "playSuccessSound") {
                    try {
                        val loader = FlutterInjector.instance().flutterLoader()
                        val key = loader.getLookupKeyForAsset("assets/audio/success.mp3")
                        val afd = context.assets.openFd(key)
                        mediaPlayer?.release()
                        mediaPlayer = MediaPlayer()
                        mediaPlayer?.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                        mediaPlayer?.prepare()
                        mediaPlayer?.start()
                        afd.close()
                        result.success(null)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                } else {
                    result.notImplemented()
                }
            }

        // ── System channel ─────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAirplaneModeOn" -> {
                        val isOn = Settings.Global.getInt(
                            context.contentResolver,
                            Settings.Global.AIRPLANE_MODE_ON,
                            0
                        ) != 0
                        result.success(isOn)
                    }
                    else -> result.notImplemented()
                }
            }

        // ── SMS balance-update EventChannel ───────────────────────────────
        // SmsBalanceReceiver (BroadcastReceiver) calls SmsEventStreamHandler.emit()
        // whenever a BPAY SMS arrives. Flutter listens here to sync balances.
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_EVENT_CHANNEL)
            .setStreamHandler(SmsEventStreamHandler)
    }
}

