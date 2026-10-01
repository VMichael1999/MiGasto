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

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null || sbn.packageName !in PACKAGES) return
        // Al reiniciar el servicio o reinstalar la app el sistema vuelve a entregar
        // las notificaciones que siguen en la barra: no son pagos nuevos.
        val age = System.currentTimeMillis() - sbn.postTime
        if (age > STALE_MS) {
            Log.d(TAG, "ignorada: notificación antigua (${age / 1000} s)")
            return
        }
        if (!HandledStore.markHandled(applicationContext, "n|${sbn.key}|${sbn.postTime}")) {
            Log.d(TAG, "ignorada: esta notificación ya se leyó")
            return
        }
        val extras = sbn.notification?.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        Log.d(TAG, "notificación de ${sbn.packageName}, llegó ${System.currentTimeMillis() - sbn.postTime} ms después de publicarse")
        MyAccessibilityService.handleText(applicationContext, "$title $text $bigText".trim())
    }

    companion object {
        private const val TAG = "PaymentNotifListener"
        private const val STALE_MS = 3 * 60 * 1000L

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
