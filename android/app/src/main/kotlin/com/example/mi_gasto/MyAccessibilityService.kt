package com.example.mi_gasto

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.plugin.common.MethodChannel
import java.util.regex.Pattern

class MyAccessibilityService : AccessibilityService() {

    // Debounce: skip WINDOW_CONTENT_CHANGED events within 500ms of the previous one
    private var lastProcessedTime: Long = 0L
    private val debounceMs: Long = 500L

    // Deduplication: skip if same text hash arrives within 2 seconds
    private var lastTextHash: Int = 0
    private var lastTextTime: Long = 0L
    private val deduplicationMs: Long = 2000L

    companion object {
        private const val TAG = "MyAccessibilityService"
        private var channel: MethodChannel? = null
        private var instance: MyAccessibilityService? = null
        
        fun registerChannel(methodChannel: MethodChannel) {
            channel = methodChannel
        }

        fun getChannel(): MethodChannel? = channel
        fun getInstance(): MyAccessibilityService? = instance

        data class ParseResult(val amount: Double, val peer: String, val provider: String)

        fun parseText(text: String): ParseResult? {
            Log.d(TAG, "Parsing text: $text")
            
            // 1. Identify provider
            val provider = when {
                text.contains("yape", ignoreCase = true) -> "yape"
                text.contains("plin", ignoreCase = true) -> "plin"
                text.contains("google pay", ignoreCase = true) || 
                text.contains("gpay", ignoreCase = true) || 
                text.contains("googlepay", ignoreCase = true) -> "googlePay"
                else -> return null
            }

            // 2. Find amount (Peruvian Soles prefix: S/ or S/. followed by number)
            val amountRegex = Regex("(?i)s/\\.?\\s*(\\d+(?:\\.\\d{1,2})?)")
            val match = amountRegex.find(text) ?: return null
            val amount = match.groupValues[1].toDoubleOrNull() ?: return null

            // 3. Find peer/merchant name
            val amountStart = match.range.first
            val amountEnd = match.range.last + 1

            var peer = ""
            val afterText = text.substring(amountEnd).trim()
            
            // Try finding preposition after the amount
            val prepPattern = Regex("(?i)^\\s*(a|de|en|por|para)\\b(.*)")
            val prepMatch = prepPattern.find(afterText)
            if (prepMatch != null) {
                val potentialPeer = prepMatch.groupValues[2].trim()
                peer = cleanName(potentialPeer)
            }

            // If peer is still empty, look at beforeText
            if (peer.isEmpty()) {
                val beforeText = text.substring(0, amountStart).trim()
                peer = cleanName(beforeText)
            }

            if (peer.isEmpty()) {
                peer = "Desconocido"
            }

            Log.d(TAG, "Parsing success: amount=$amount, peer=$peer, provider=$provider")
            return ParseResult(amount, peer, provider)
        }

        private fun cleanName(input: String): String {
            var temp = input.trim()
            val phrases = listOf(
                "has recibido un yape de",
                "compra por",
                "te yapeó", "te yapeo",
                "te envió", "te envio",
                "pago de", "compra de",
                "yapeaste", "yapeó", "yapeo",
                "enviaste", "recibiste",
                "envió", "envio", "pagaste",
                "yape", "plin", "gpay", "google pay", "googlepay"
            )
            for (phrase in phrases) {
                temp = temp.replace(Regex("(?i)\\b" + Regex.escape(phrase) + "\\b"), "")
            }
            temp = temp.replace(Regex("(?i)^\\s*(a|de|en|por|para)\\b"), "")
            temp = temp.replace(Regex("(?i)\\b(a|de|en|por|para)\\s*$"), "")
            
            // Clean common boundary punctuation and symbols
            temp = temp.trim { it <= ' ' || it == ':' || it == ',' || it == '-' || it == '¡' || it == '!' || it == '.' || it == '*' || it == '_' }
            return temp
        }

        fun simulateNotification(text: String, context: Context) {
            val result = parseText(text) ?: return
            val activeInstance = instance
            
            if (activeInstance != null && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M && android.provider.Settings.canDrawOverlays(activeInstance)) {
                val intent = Intent(activeInstance, OverlayService::class.java).apply {
                    putExtra("amount", result.amount)
                    putExtra("merchant", result.peer)
                    putExtra("provider", result.provider)
                    putExtra("rawText", text)
                }
                activeInstance.startService(intent)
            } else {
                Handler(Looper.getMainLooper()).post {
                    channel?.invokeMethod("onTransactionDetected", mapOf(
                        "amount" to result.amount,
                        "peerName" to result.peer,
                        "provider" to result.provider,
                        "rawText" to text
                    ))
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "Accessibility Service Created")
    }

    override fun onDestroy() {
        instance = null
        Log.d(TAG, "Accessibility Service Destroyed")
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED -> {
                val parcelableData = event.parcelableData
                if (parcelableData is android.app.Notification) {
                    val extras = parcelableData.extras
                    val title = extras.getString(android.app.Notification.EXTRA_TITLE) ?: ""
                    val text = extras.getCharSequence(android.app.Notification.EXTRA_TEXT)?.toString() ?: ""
                    val bigText = extras.getCharSequence(android.app.Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
                    val fullText = "$title $text $bigText"
                    
                    parseAndSendNotification(fullText)
                }
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                // Debounce: skip if within 500ms of last processed event
                val now = System.currentTimeMillis()
                if (now - lastProcessedTime < debounceMs) return
                lastProcessedTime = now

                val rootNode = rootInActiveWindow ?: return
                inspectNode(rootNode)
                rootNode.recycle()
            }
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val rootNode = rootInActiveWindow ?: return
                inspectNode(rootNode)
                rootNode.recycle()
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }

    private fun inspectNode(node: AccessibilityNodeInfo?) {
        if (node == null) return
        val text = node.text?.toString() ?: ""
        if (text.isNotEmpty()) {
            parseAndSendScreenText(text)
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            inspectNode(child)
            child?.recycle()
        }
    }

    private fun parseAndSendNotification(text: String) {
        val result = parseText(text) ?: return
        sendToFlutter(result.amount, result.peer, result.provider, text)
    }

    private fun parseAndSendScreenText(text: String) {
        if (text.contains("¡Yapeaste!", ignoreCase = true) || text.contains("Pago Exitoso", ignoreCase = true)) {
            // Deduplication: skip if same text hash within 2 seconds
            val textHash = text.hashCode()
            val now = System.currentTimeMillis()
            if (textHash == lastTextHash && now - lastTextTime < deduplicationMs) return
            lastTextHash = textHash
            lastTextTime = now

            val amountPattern = Pattern.compile("s/\\.?\\s*(\\d+(?:\\.\\d{2})?)", Pattern.CASE_INSENSITIVE)
            val matcher = amountPattern.matcher(text)
            if (matcher.find()) {
                val amount = matcher.group(1)?.toDoubleOrNull() ?: return
                sendToFlutter(amount, "Pantalla activa", "yape", text)
            }
        }
    }

    private fun sendToFlutter(amount: Double, peer: String, provider: String, rawText: String) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M && android.provider.Settings.canDrawOverlays(this)) {
            val intent = Intent(this, OverlayService::class.java).apply {
                putExtra("amount", amount)
                putExtra("merchant", peer)
                putExtra("provider", provider)
                putExtra("rawText", rawText)
            }
            startService(intent)
        } else {
            Handler(Looper.getMainLooper()).post {
                channel?.invokeMethod("onTransactionDetected", mapOf(
                    "amount" to amount,
                    "peerName" to peer,
                    "provider" to provider,
                    "rawText" to rawText
                ))
            }
        }
    }
}
