package com.example.mi_gasto

/**
 * Decide si un pago leído es el mismo que otro que ya llegó por OTRA vía (por ejemplo, la
 * notificación y la pantalla de la constancia, o Google Wallet y la app del banco), dentro de
 * [windowMs].
 *
 * Dos notificaciones de la MISMA app que llegan por el servicio de notificaciones nunca se frenan
 * entre sí: cada una ya se descarta sola si se repite, así que dos yapes del mismo monto seguidos
 * valen los dos.
 */
class DuplicateGuard(
    private val windowMs: Long,
    private val clock: () -> Long = System::currentTimeMillis,
) {
    private data class Seen(val at: Long, val origin: String, val app: String?)

    private val recent = LinkedHashMap<String, Seen>()

    @Synchronized
    fun isDuplicate(key: String, origin: String, listenerOrigin: String, app: String? = null): Boolean {
        val now = clock()
        recent.entries.removeAll { now - it.value.at > windowMs }
        val previous = recent[key]
        val sameAppFromListener = previous != null && previous.origin == listenerOrigin &&
            origin == listenerOrigin && previous.app == app
        if (previous != null && !sameAppFromListener) return true
        recent[key] = Seen(now, origin, app)
        return false
    }

    companion object {
        /**
         * Clave de un pago. Google Wallet y la app del banco avisan el mismo consumo con tarjeta,
         * así que cuentan como la misma fuente.
         */
        fun key(provider: String, type: String, amount: Double): String {
            val source = if (provider == "googlePay") "tarjeta" else provider
            return "$source|$type|${"%.2f".format(java.util.Locale.ROOT, amount)}"
        }
    }
}
