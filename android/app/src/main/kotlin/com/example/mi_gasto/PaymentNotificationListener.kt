package com.example.mi_gasto

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.content.Context
import android.util.Log
import org.json.JSONArray

/**
 * Lee las notificaciones de las apps de pago y las pasa al mismo lector de reglas
 * que usa la pantalla (`MyAccessibilityService.handleText`), que ya evita duplicados.
 *
 * Es la vía principal: el sistema entrega la notificación completa aunque el
 * servicio de Accesibilidad no reciba el aviso (pasa en algunos Samsung).
 */
class PaymentNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null || sbn.packageName !in PACKAGES) return
        // Al reiniciar el servicio o reinstalar la app el sistema vuelve a entregar
        // las notificaciones que siguen en la barra: no son pagos nuevos.
        if (System.currentTimeMillis() - sbn.postTime > STALE_MS) return
        if (!markHandled(applicationContext, "${sbn.key}|${sbn.postTime}")) return
        val extras = sbn.notification?.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        Log.d(TAG, "notificación de ${sbn.packageName}")
        MyAccessibilityService.handleText(applicationContext, "$title $text $bigText".trim())
    }

    companion object {
        private const val TAG = "PaymentNotifListener"
        private const val STALE_MS = 3 * 60 * 1000L
        private const val STATE_PREFS = "migasto_native_state"
        private const val KEY_HANDLED = "handled_notifications"
        private const val MAX_HANDLED = 100
        private val lock = Any()

        /** Guarda que esta notificación ya se leyó; `false` si ya estaba. Sobrevive a reinicios. */
        private fun markHandled(context: Context, id: String): Boolean = synchronized(lock) {
            val prefs = context.getSharedPreferences(STATE_PREFS, Context.MODE_PRIVATE)
            val ids = try {
                JSONArray(prefs.getString(KEY_HANDLED, "[]") ?: "[]")
            } catch (e: Exception) {
                JSONArray()
            }
            for (i in 0 until ids.length()) if (ids.optString(i) == id) return false
            val kept = JSONArray()
            for (i in maxOf(0, ids.length() - (MAX_HANDLED - 1)) until ids.length()) kept.put(ids.optString(i))
            kept.put(id)
            prefs.edit().putString(KEY_HANDLED, kept.toString()).commit()
            true
        }

        // Las mismas apps que escucha accessibility_service_config.xml.
        private val PACKAGES = setOf(
            "com.bcp.innovacxion.yapeapp",
            "com.google.android.apps.walletnfcrel",
            "com.bbva.bbvacontigo",
            "pe.com.interbank.mobilebanking",
            "pe.com.scotiabank.blpm.android.client",
            "com.banbif.plin",
        )
    }
}
