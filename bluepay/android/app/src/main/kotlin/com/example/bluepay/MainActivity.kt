package com.example.bluepay

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.MediaPlayer
import io.flutter.FlutterInjector

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.bluepay/audio"
    private var mediaPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
                    // Ignore if file doesn't exist yet
                    result.success(null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
