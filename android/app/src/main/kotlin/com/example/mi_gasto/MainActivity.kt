package com.example.mi_gasto

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import android.net.Uri

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.mi_gasto/accessibility"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        MyAccessibilityService.registerChannel(channel)

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "requestOverlayPermission" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "isOverlayPermissionGranted" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                "takeNativeQueue" -> {
                    // Pagos que el código nativo detectó mientras la app estaba cerrada.
                    result.success(NativeQueue.take(this))
                }
                "simulateNotification" -> {
                    val text = call.argument<String>("text") ?: ""
                    MyAccessibilityService.simulateNotification(text, this)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (intent.getStringExtra("action") == "edit_expense") {
            val amount = intent.getDoubleExtra("amount", 0.0)
            val merchant = intent.getStringExtra("merchant") ?: ""
            val provider = intent.getStringExtra("provider") ?: ""
            val type = intent.getStringExtra("type") ?: "gasto"
            val rawText = intent.getStringExtra("rawText") ?: ""

            // Validate inputs
            if (amount <= 0.0) return
            if (merchant.isBlank()) return

            // Send to Flutter to trigger the edit bottom sheet
            flutterEngine?.let { engine ->
                val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                channel.invokeMethod("onTransactionDetected", mapOf(
                    "amount" to amount,
                    "peerName" to merchant,
                    "provider" to provider,
                    "type" to type,
                    "rawText" to rawText
                ))
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val service = "$packageName/${MyAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.contains(service)
    }
}
