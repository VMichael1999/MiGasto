package com.example.mi_gasto

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * Lee las notificaciones de las apps de pago y las pasa al mismo lector de reglas
 * que usa la pantalla (`MyAccessibilityService.handleText`), que ya evita duplicados.
 *
 * Es la vía principal: el sistema entrega la notificación completa aunque el
 * servicio de Accesibilidad no reciba el aviso (pasa en algunos Samsung).
 */
class PaymentNotificationListener : NotificationListenerService() {

    override fun onListenerConnected() {
        super.onListenerConnected()
        // Lo que llegó mientras el lector estaba desconectado sigue en la barra: se lee ahora.
        val now = System.currentTimeMillis()
        val lastSeen = state().getLong(KEY_LAST_SEEN, 0L)
        markListening(now)
        val active = try {
            activeNotifications ?: emptyArray()
        } catch (e: Exception) {
            Log.w(TAG, "no se pudieron leer las notificaciones de la barra", e)
            return
        }
        val missed = active.filter { ListenerCatchUp.shouldRead(it.postTime, now, lastSeen) }.sortedBy { it.postTime }
        if (missed.isNotEmpty()) Log.d(TAG, "revisando ${missed.size} notificaciones que llegaron sin lector")
        for (sbn in missed) read(sbn, recovered = true)
    }

    override fun onListenerDisconnected() {
        markListening(System.currentTimeMillis())
        super.onListenerDisconnected()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        // Cualquier notificación (de cualquier app) prueba que el lector estaba escuchando.
        markListening(System.currentTimeMillis())
        read(sbn, recovered = false)
    }

    /** [recovered]: la notificación se lee al reconectarse, no cuando llegó. */
    private fun read(sbn: StatusBarNotification, recovered: Boolean) {
        // Las apps que se escuchan están en assets/reader_rules.json ("apps").
        val apps = ReaderRules.get(applicationContext)?.apps ?: return
        if (sbn.packageName !in apps) return
        val notification = sbn.notification ?: return
        // El resumen de un grupo repite el último aviso del grupo: no es otro pago.
        if (isGroupSummary(notification)) {
            Log.d(TAG, "ignorada: resumen de grupo")
            return
        }
        // Al reiniciar el servicio o reinstalar la app el sistema vuelve a entregar
        // las notificaciones que siguen en la barra: no son pagos nuevos. (Las que
        // llegaron sin lector se recuperan en onListenerConnected.)
        val age = System.currentTimeMillis() - sbn.postTime
        if (age > STALE_MS && !recovered) {
            Log.d(TAG, "ignorada: notificación antigua (${age / 1000} s)")
            return
        }
        if (!HandledStore.markHandled(applicationContext, "n|${sbn.key}|${sbn.postTime}")) {
            Log.d(TAG, "ignorada: esta notificación ya se leyó")
            return
        }
        val extras = notification.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        // Si la app vuelve a publicar la misma notificación con el mismo texto (una
        // actualización), la hora cambia pero el pago es el mismo.
        // Android 15 o más pudo ocultar el aviso (parece traer un código). Si la Accesibilidad
        // lo lee completo, no pasa nada; si no, se avisa al usuario.
        if (HiddenNotification.isHidden(text)) {
            onHidden(sbn.packageName, title.ifBlank { sbn.packageName })
            return
        }
        val content = "$title|$text|$bigText"
        if (!HandledStore.markRecent(applicationContext, "c|${sbn.key}|${content.hashCode()}", UPDATE_WINDOW_MS)) {
            Log.d(TAG, "ignorada: la misma notificación actualizada")
            return
        }
        Log.d(TAG, "notificación de ${sbn.packageName}, llegó $age ms después de publicarse")
        MyAccessibilityService.handleText(
            applicationContext,
            "$title $text $bigText".trim(),
            MyAccessibilityService.ORIGIN_LISTENER,
            sbn.packageName,
            // Recién llegada, aunque se lea al reconectarse, va como cualquier otra.
            recoveredAt = if (age > STALE_MS) sbn.postTime else null,
        )
    }

    /**
     * Un aviso de [app] llegó oculto. Se espera unos segundos: con el teléfono desbloqueado la
     * Accesibilidad recibe el aviso completo y lo registra. Si no llegó ningún pago de esa app,
     * se anota (Flutter lo muestra en Resumen) y se avisa al usuario.
     */
    private fun onHidden(app: String, label: String) {
        val at = System.currentTimeMillis()
        Log.d(TAG, "aviso oculto por Android ($app)")
        val context = applicationContext
        if (NativeQueue.captureEnabled(context)) {
            CaptureLog.of(context).add(app, "notificación", HiddenNotification.MARK, "oculto por Android")
        }
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            if (MyAccessibilityService.lastPaymentFrom(app) >= at - HIDDEN_GRACE_MS) {
                Log.d(TAG, "el aviso oculto se leyó por accesibilidad")
                return@postDelayed
            }
            NativeQueue.recordHidden(context, label, at)
            PaymentNotifier.notifyHidden(context, label, MyAccessibilityService.getInstance() != null)
        }, HIDDEN_GRACE_MS)
    }

    private fun state() = applicationContext.getSharedPreferences(STATE_PREFS, MODE_PRIVATE)

    private fun markListening(now: Long) {
        state().edit().putLong(KEY_LAST_SEEN, now).apply()
    }

    companion object {
        private const val TAG = "PaymentNotifListener"
        private const val STALE_MS = 3 * 60 * 1000L
        private const val UPDATE_WINDOW_MS = 60 * 1000L
        private const val HIDDEN_GRACE_MS = 6 * 1000L
        private const val STATE_PREFS = "migasto_native_state"
        private const val KEY_LAST_SEEN = "listener_last_seen"

        fun isGroupSummary(notification: Notification): Boolean =
            notification.flags and Notification.FLAG_GROUP_SUMMARY != 0
    }
}
