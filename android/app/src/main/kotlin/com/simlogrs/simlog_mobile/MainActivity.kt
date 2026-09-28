package com.simlogrs.simlog_mobile

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val securityChannel = "com.simlogrs.simlog_mobile/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // [L-02] Proteksi Anti-Screenshot dan Task Snapshot Masking
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // [L-01] Pemeriksaan Integritas Lingkungan Root
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, securityChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDeviceRooted" -> result.success(checkRootEnvironment())
                else -> result.notImplemented()
            }
        }
    }

    private fun checkRootEnvironment(): Boolean {
        val rootPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )
        for (path in rootPaths) {
            if (File(path).exists()) return true
        }
        val buildTags = Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }
}
