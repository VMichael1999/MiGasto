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

        /** Por dónde llegó un texto: el servicio de notificaciones, la accesibilidad o la pantalla. */
        const val ORIGIN_LISTENER = "listener"
        const val ORIGIN_ACCESS = "access"
        const val ORIGIN_SCREEN = "screen"

        private val duplicates = DuplicateGuard(DUPLICATE_WINDOW_MS)

        fun registerChannel(methodChannel: MethodChannel) {
            channel = methodChannel
        }

        fun getChannel(): MethodChannel? = channel
        fun getInstance(): MyAccessibilityService? = instance

        private fun isDuplicate(result: ParseResult, origin: String, app: String?): Boolean =
            duplicates.isDuplicate(
                DuplicateGuard.key(result.provider, result.type, result.amount, result.currency), origin, ORIGIN_LISTENER, app,
            )

        /** Lee un texto (notificación o pantalla) y, si es un pago, lo entrega. */
        fun handleText(
            context: Context,
            text: String,
            origin: String = ORIGIN_ACCESS,
            app: String? = null,
            /** Hora en que se publicó la notificación, si se lee tarde (recuperada). */
            recoveredAt: Long? = null,
        ) {
            val rules = ReaderRules.get(context)
            if (rules == null) { Log.d(TAG, "reglas no cargadas"); return }
            // De una pantalla solo cuenta la constancia: el inicio de Yape (saldo, movimientos)
            // no es un pago, aunque cambie cada vez que se toca "ver saldo".
            val isReceipt = origin != ORIGIN_SCREEN || rules.isScreenReceipt(text)
            val capture = NativeQueue.captureEnabled(context)
            if (!isReceipt && !capture) return
            val result = rules.parse(text, app)
            // Una constancia antigua abierta desde el historial de Yape se ve igual que la de un
            // pago recién hecho; su fecha dice que no lo es.
            val oldReceipt = origin == ORIGIN_SCREEN && isReceipt &&
                ReceiptTime.isOld(text, System.currentTimeMillis())
            // Modo captura (Ajustes): se guarda el texto y lo que entendió el lector.
            if (capture) {
                val reading = when {
                    !isReceipt -> "pantalla sin constancia" + (result?.let { " (habría leído ${describe(it)})" } ?: "")
                    result == null -> "sin pago"
                    oldReceipt -> "constancia antigua (habría leído ${describe(result)})"
                    else -> describe(result)
                }
                CaptureLog.of(context).add(app, viaName(origin), text, reading)
            }
            if (!isReceipt) return
            if (result == null) { Log.d(TAG, "texto sin pago (largo=${text.length})"); return }
            if (oldReceipt) { Log.d(TAG, "descartado: constancia antigua"); return }
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
            if (isDuplicate(result, origin, app)) {
                Log.d(TAG, "descartado: mismo monto, fuente y tipo hace menos de 2 minutos")
                return
            }

            // No se registra el texto completo: puede traer datos personales.
            Log.d(TAG, "Pago detectado: ${result.type} ${result.provider}")
            if (recoveredAt != null || result.currency != "PEN") {
                deliverRecovered(context, result, text.take(MAX_SCREEN_TEXT), recoveredAt ?: System.currentTimeMillis())
                return
            }
            deliver(context, result, text.take(MAX_SCREEN_TEXT))
        }

        /**
         * Sin ventana flotante, queda por confirmar y se avisa:
         * - un pago que llegó mientras el lector de notificaciones estaba desconectado (ya no es
         *   momento de la ventana), con la hora en que llegó;
         * - un cargo en dólares: su monto en soles es una estimación que el usuario revisa.
         */
        private fun deliverRecovered(context: Context, result: ParseResult, rawText: String, at: Long) {
            Log.d(TAG, "pago por confirmar sin ventana (${result.currency})")
            val ref = java.util.UUID.randomUUID().toString()
            val recovered = System.currentTimeMillis() - at > 60_000L
            NativeQueue.enqueue(
                context, result.amount, result.peer, result.provider, result.type, rawText,
                confirmed = false, ref = ref, at = at,
                origin = if (recovered) NativeQueue.ORIGIN_RECOVERED else NativeQueue.ORIGIN_ANDROID,
                currency = result.currency,
            )
            notifyFlutterSaved()
            PaymentNotifier.notify(
                context, result.amount, result.peer, result.provider, result.type,
                saved = false, ref = ref, currency = result.currency,
            )
        }

        fun simulateNotification(text: String, context: Context) = handleText(context, text)

        private fun describe(r: ParseResult) =
            "${r.type} ${if (r.currency == "USD") "US$" else "S/"} ${"%.2f".format(java.util.Locale.ROOT, r.amount)} · ${r.provider} · «${r.peer}»"

        private fun viaName(origin: String) = when (origin) {
            ORIGIN_LISTENER -> "notificación"
            ORIGIN_SCREEN -> "pantalla"
            else -> "accesibilidad"
        }

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

            // Sin ventana visible (pantalla apagada o bloqueada, o sin el permiso): queda por
            // confirmar, salvo que el usuario haya activado «Guardar gastos solos» o «Guardar
            // ingresos solos», y se avisa con una notificación (con Guardar e Ignorar si espera).
            val saved = if (result.type == "ingreso") {
                NativeQueue.autoSaveIncome(context)
            } else {
                NativeQueue.autoSaveExpense(context)
            }
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
                if (parcelableData is android.app.Notification &&
                    !PaymentNotificationListener.isGroupSummary(parcelableData)
                ) {
                    val extras = parcelableData.extras
                    val title = extras.getCharSequence(android.app.Notification.EXTRA_TITLE)?.toString() ?: ""
                    val text = extras.getCharSequence(android.app.Notification.EXTRA_TEXT)?.toString() ?: ""
                    val bigText = extras.getCharSequence(android.app.Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
                    handleText(
                        applicationContext,
                        "$title $text $bigText".trim(),
                        app = event.packageName?.toString(),
                    )
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
        val app = root.packageName?.toString()
        val builder = StringBuilder()
        collectText(root, builder)
        @Suppress("DEPRECATION")
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.TIRAMISU) root.recycle()
        if (builder.isNotEmpty()) handleText(applicationContext, builder.toString(), ORIGIN_SCREEN, app)
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
