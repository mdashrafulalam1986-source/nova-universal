package com.nova.universal

import android.hardware.ConsumerIrManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.nova.universal/ir"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val irManager = getSystemService(CONSUMER_IR_SERVICE) as? ConsumerIrManager

            when (call.method) {
                "hasIrEmitter" -> {
                    if (irManager != null) {
                        result.success(irManager.hasIrEmitter())
                    } else {
                        result.success(false)
                    }
                }
                "transmit" -> {
                    if (irManager == null || !irManager.hasIrEmitter()) {
                        result.error("NO_IR", "IR Blaster hardware missing", null)
                        return@setMethodCallHandler
                    }

                    val frequency = call.argument<Int>("frequency") ?: 38000
                    val patternList = call.argument<List<Int>>("pattern")
                    
                    if (patternList != null) {
                        val pattern = patternList.map { it.toInt() }.toIntArray()
                        try {
                            irManager.transmit(frequency, pattern)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("TRANSMIT_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_PATTERN", "Pattern empty", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
