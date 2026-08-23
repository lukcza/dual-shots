package com.example.dual_shots

import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CAPABILITY_CHANNEL = "com.example.dual_shots/camera_capabilities"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize Native Dual Camera Controller
        NativeDualCameraController.init(this, flutterEngine.dartExecutor.binaryMessenger)

        // Register Native Platform View for Dual Camera Views
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.example.dual_shots/camera_view",
            DualCameraPlatformViewFactory()
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CAPABILITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isConcurrentCameraSupported" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        val isSupported = packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_CONCURRENT)
                        result.success(isSupported)
                    } else {
                        result.success(false)
                    }
                }
                "isMultiCamSupported" -> {
                    result.success(false)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        NativeDualCameraController.disposeAll()
        super.onDestroy()
    }
}
