package com.simlogrs.simlog_mobile

import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Activity utama aplikasi Android SIMLOG RS.
 * Mengaktifkan proteksi layar (FLAG_SECURE) dan menyediakan channel native untuk pemeriksaan root.
 */
class MainActivity : FlutterActivity() {
    private val securityChannel = "com.simlogrs.simlog_mobile/security"

    /**
     * Dipanggil saat activity dibuat; mengaktifkan FLAG_SECURE agar layar tidak bisa
     * di-screenshot dan tampilan di daftar aplikasi terbaru disamarkan.
     * Dilewati pada build debug supaya layar bisa di-screenshot/di-mirror saat pengembangan.
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val isDebuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (!isDebuggable) {
            // [L-02] Proteksi Anti-Screenshot dan Task Snapshot Masking (hanya build rilis)
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        }
    }

    /**
     * Mendaftarkan MethodChannel keamanan ke engine Flutter.
     * Method "isDeviceRooted" dijawab dengan hasil [checkRootEnvironment]; method lain tidak diimplementasikan.
     */
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

    /**
     * Mendeteksi perangkat yang di-root: mencari biner `su`/Superuser.apk di path umum
     * dan memeriksa Build.TAGS berisi "test-keys". Mengembalikan true bila terindikasi root.
     */
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
