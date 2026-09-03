package com.nova.universal

import android.content.Context
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
            if (call.method == "transmit") {
                val frequency = call.argument<Int>("frequency") ?: 38000
                val patternList = call.argument<List<Int>>("pattern")
                
                val irManager = getSystemService(Context.CONSUMER_IR_SERVICE) as? ConsumerIrManager

                if (irManager != null && irManager.hasIrEmitter()) {
                    if (patternList != null) {
                        val pattern = patternList.map { it.toInt() }.toIntArray()
                        irManager.transmit(frequency, pattern)
                        result.success(true)
                    } else {
                        result.error("INVALID_PATTERN", "IR Pattern was null", null)
                    }
                } else {
                    result.error("NO_IR_EMITTER", "Device does not have an IR Blaster", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
