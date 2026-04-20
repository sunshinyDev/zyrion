package com.example.streamhub

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.streamhub/player"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLowLatencyConfig" -> {
                        // Return recommended buffer config for low-latency live
                        result.success(
                            mapOf(
                                "minBufferMs" to 1000,      // 1s min buffer
                                "maxBufferMs" to 3000,      // 3s max buffer
                                "bufferForPlaybackMs" to 500,
                                "bufferForPlaybackAfterRebufferMs" to 1000
                            )
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
