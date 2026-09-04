package com.nova.universal

import android.content.Context
import android.hardware.ConsumerIrManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.nova.universal/ir"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "transmitIR") {
                val command = call.argument<String>("command")
                val success = sendNecIrSignal(command)
                if (success) {
                    result.success("Signal Transmitted with Micro Timing")
                } else {
                    result.error("NO_IR_EMITTER", "Device does not have an active IR Blaster", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun sendNecIrSignal(command: String?): Boolean {
        val irManager = getSystemService(Context.CONSUMER_IR_SERVICE) as ConsumerIrManager?
        if (irManager != null && irManager.hasIrEmitter()) {
            val frequency = 38000
            val pattern = intArrayOf(
                9000, 4500,
                560, 1690, 560, 560, 560, 1690, 560, 560,
                560, 1690, 560, 1690, 560, 560, 560, 1690,
                560, 560, 560, 560, 560, 1690, 560, 560,
                560, 40000
            )
            irManager.transmit(frequency, pattern)
            return true
        }
        return false
    }
}
