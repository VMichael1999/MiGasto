package com.example.mi_gasto

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.plugin.common.MethodChannel

class MyAccessibilityService : AccessibilityService() {

    // Debounce: ignora cambios de contenido de ventana a menos de 500 ms del anterior.
    private var lastProcessedTime: Long = 0L
    private val debounceMs: Long = 500L

    companion object {
        private const val TAG = "MyAccessibilityService"
        private const val DUPLICATE_WINDOW_MS = 2 * 60 * 1000L
        private const val MAX_SCREEN_TEXT = 400

        private var channel: MethodChannel? = null
        private var instance: MyAccessibilityService? = null

        // Mismo monto, fuente y tipo dentro de 2 minutos = el mismo pago (por ejemplo,
        // llega por la notificación y por la pantalla de confirmación).
        private val recent = LinkedHashMap<String, Long>()

        fun registerChannel(methodChannel: MethodChannel) {
            channel = methodChannel
        }

        fun getChannel(): MethodChannel? = channel
        fun getInstance(): MyAccessibilityService? = instance

        @Synchronized
        private fun isDuplicate(result: ParseResult): Boolean {
            val now = System.currentTimeMillis()
            recent.entries.removeAll { now - it.value > DUPLICATE_WINDOW_MS }
            val key = "${result.provider}|${result.type}|${"%.2f".format(result.amount)}"
            if (recent.containsKey(key)) return true
            recent[key] = now
            return false
        }

        /** Lee un texto (notificación o pantalla) y, si es un pago, lo entrega. */
        fun handleText(context: Context, text: String, fromScreen: Boolean = false) {
            val rules = ReaderRules.get(context)
            if (rules == null) { Log.d(TAG, "reglas no cargadas"); return }
            // De una pantalla solo cuenta la constancia: el inicio de Yape (saldo, movimientos)
            // no es un pago, aunque cambie cada vez que se toca "ver saldo".
            if (fromScreen && !rules.isScreenReceipt(text)) return
            val result = rules.parse(text)
            if (result == null) { Log.d(TAG, "texto sin pago (largo=${text.length})"); return }
            if (!NativeQueue.isProviderEnabled(context, result.provider)) {
                Log.d(TAG, "descartado: ${result.provider} está apagado en Ajustes")
                return
            }
            // La constancia de Yape trae un número de operación: si ya se leyó, es la misma pantalla
            // vista otra vez (por ejemplo, al reiniciarse el servicio), no un pago nuevo.
            rules.operationId(text)?.let { id ->
                if (!HandledStore.markHandled(context, "op|$id")) {
                    Log.d(TAG, "descartado: constancia ya leída (número de operación)")
                    return
                }
            }
            // Si el número de operación no está a la vista, la fecha y hora de la constancia
            // identifican igual el mismo pago (mismo monto y misma persona en el mismo minuto).
            rules.operationStamp(text)?.let { stamp ->
                val key = "st|${result.provider}|${result.type}|${"%.2f".format(result.amount)}|$stamp"
                if (!HandledStore.markHandled(context, key)) {
                    Log.d(TAG, "descartado: constancia ya leída (fecha y hora)")
                    return
                }
            }
            if (isDuplicate(result)) {
                Log.d(TAG, "descartado: mismo monto, fuente y tipo hace menos de 2 minutos")
                return
            }

            // No se registra el texto completo: puede traer datos personales.
            Log.d(TAG, "Pago detectado: ${result.type} ${result.provider}")
            deliver(context, result, text.take(MAX_SCREEN_TEXT))
        }

        fun simulateNotification(text: String, context: Context) = handleText(context, text)

        private fun deliver(context: Context, result: ParseResult, rawText: String) {
            // Con el teléfono en uso y desbloqueado se muestra la ventana flotante.
            val overlay = PaymentNotifier.canShowOverlay(context)
            Log.d(TAG, "ventana flotante posible: $overlay")
            if (overlay) {
                val category = ReaderRules.get(context)?.classify(
                    rawText, result.peer, result.type, NativeQueue.categoryOverrides(context),
                ) ?: "otros"
                val intent = Intent(context, OverlayService::class.java).apply {
                    putExtra("amount", result.amount)
                    putExtra("merchant", result.peer)
                    putExtra("provider", result.provider)
                    putExtra("type", result.type)
                    putExtra("category", category)
                    putExtra("rawText", rawText)
                }
                try {
                    context.startService(intent)
                    return
                } catch (e: Exception) {
                    // Android puede negar iniciar el servicio desde segundo plano.
                    Log.w(TAG, "No se pudo mostrar la ventana flotante", e)
                }
            }

            // Sin ventana visible (pantalla apagada o bloqueada, o sin el permiso): se guarda según
            // las reglas de siempre (un gasto se guarda; un ingreso, solo si el usuario lo activó)
            // y se avisa con una notificación.
            val saved = result.type != "ingreso" || NativeQueue.autoSaveIncome(context)
            Log.d(TAG, "sin ventana: se guarda=$saved y se avisa con notificación")
            val ref = java.util.UUID.randomUUID().toString()
            NativeQueue.enqueue(
                context, result.amount, result.peer, result.provider, result.type, rawText,
                confirmed = saved, ref = ref,
            )
            notifyFlutterSaved()
            PaymentNotifier.notify(context, result.amount, result.peer, result.provider, result.type, saved, ref)
        }

        /** Avisa a Flutter (si está abierto) que hay pagos en la cola. */
        fun notifyFlutterSaved() {
            Handler(Looper.getMainLooper()).post {
                channel?.invokeMethod("onTransactionSaved", null)
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
                    val title = extras.getCharSequence(android.app.Notification.EXTRA_TITLE)?.toString() ?: ""
                    val text = extras.getCharSequence(android.app.Notification.EXTRA_TEXT)?.toString() ?: ""
                    val bigText = extras.getCharSequence(android.app.Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
                    handleText(applicationContext, "$title $text $bigText".trim())
                }
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                val now = System.currentTimeMillis()
                if (now - lastProcessedTime < debounceMs) return
                lastProcessedTime = now
                inspectActiveWindow()
            }
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> inspectActiveWindow()
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }

    /**
     * Junta el texto de la pantalla de la app de pagos (solo las apps de
     * `accessibility_service_config.xml`) y lo lee como una sola frase: el monto
     * y "¡Yapeaste!" están en vistas distintas.
     */
    private fun inspectActiveWindow() {
        val root = rootInActiveWindow ?: return
        val builder = StringBuilder()
        collectText(root, builder)
        @Suppress("DEPRECATION")
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.TIRAMISU) root.recycle()
        if (builder.isNotEmpty()) handleText(applicationContext, builder.toString(), fromScreen = true)
    }

    private fun collectText(node: AccessibilityNodeInfo?, out: StringBuilder) {
        if (node == null || out.length >= MAX_SCREEN_TEXT) return
        val text = node.text?.toString()
        if (!text.isNullOrBlank()) {
            if (out.isNotEmpty()) out.append(' ')
            out.append(text)
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            collectText(child, out)
            @Suppress("DEPRECATION")
            if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.TIRAMISU) child?.recycle()
        }
    }
}
