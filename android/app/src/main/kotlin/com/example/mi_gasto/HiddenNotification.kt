package com.example.mi_gasto

import android.content.res.Resources

/**
 * Android 15 o más oculta a las apps como MiGasto las notificaciones que el sistema considera
 * sensibles (las que parecen traer un código). En lugar del aviso, el lector de notificaciones
 * recibe como título el nombre de la app («Yape») y como texto un mensaje fijo del sistema
 * (`R.string.redacted_notification_message` en `NotificationManagerService.redactStatusBarNotification`).
 *
 * La Accesibilidad sí recibe el aviso completo con el teléfono desbloqueado
 * (`NotificationAttentionHelper.sendAccessibilityEvent`); bloqueado, solo la versión pública.
 */
object HiddenNotification {
    /** Lo que se anota en el modo captura en lugar del texto (que Android no entregó). */
    const val MARK = "(Android ocultó el contenido de este aviso)"

    /** El mensaje del sistema en inglés y en español (España y Latinoamérica), por si no se puede leer el recurso. */
    private val knownTexts = setOf(
        "sensitive notification content hidden",
        "contenido sensible de la notificación oculto",
        "se ocultó contenido sensible de la notificación",
    )

    /** El mensaje que usa este teléfono, en su idioma. `null` si el sistema no lo tiene (Android 14 o menos). */
    private val systemText: String? by lazy {
        try {
            val res = Resources.getSystem()
            val id = res.getIdentifier("redacted_notification_message", "string", "android")
            if (id != 0) res.getString(id) else null
        } catch (e: Exception) {
            null
        }
    }

    /** Si [text] (el texto de la notificación) es el que deja Android al ocultar un aviso. */
    fun isHidden(text: String, systemMessage: String? = systemText): Boolean {
        val t = normalize(text)
        if (t.isEmpty()) return false
        if (systemMessage != null && t == normalize(systemMessage)) return true
        return t in knownTexts
    }

    private fun normalize(s: String) = s.trim().trimEnd('.').lowercase().replace(Regex("\\s+"), " ")
}
