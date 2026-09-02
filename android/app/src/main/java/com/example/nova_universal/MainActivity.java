package com.example.nova_universal;

import android.content.Context;
import android.hardware.ConsumerIrManager;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.nova.universal/ir";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                    (call, result) -> {
                        if (call.method.equals("hasIrEmitter")) {
                            ConsumerIrManager irManager = (ConsumerIrManager) getSystemService(Context.CONSUMER_IR_SERVICE);
                            result.success(irManager != null && irManager.hasIrEmitter());
                        } else if (call.method.equals("transmit")) {
                            int frequency = call.argument("frequency");
                            int[] pattern = call.argument("pattern");
                            ConsumerIrManager irManager = (ConsumerIrManager) getSystemService(Context.CONSUMER_IR_SERVICE);
                            if (irManager != null && irManager.hasIrEmitter()) {
                                try {
                                    irManager.transmit(frequency, pattern);
                                    result.success(true);
                                } catch (Exception e) {
                                    result.error("IR_ERROR", e.getMessage(), null);
                                }
                            } else {
                                result.error("NO_IR", "Device has no IR emitter", null);
                            }
                        } else {
                            result.notImplemented();
                        }
                    }
                );
    }
}
