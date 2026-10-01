package com.example.mi_gasto

/**
 * Decide si un pago leído es el mismo que otro que ya llegó por OTRA vía (por ejemplo, la
 * notificación y la pantalla de la constancia), dentro de [windowMs].
 *
 * Dos notificaciones del servicio de notificaciones nunca se frenan entre sí: cada una ya se
 * descarta sola si se repite, así que dos yapes del mismo monto seguidos valen los dos.
 */
class DuplicateGuard(
    private val windowMs: Long,
    private val clock: () -> Long = System::currentTimeMillis,
) {
    private val recent = LinkedHashMap<String, Pair<Long, String>>()

    @Synchronized
    fun isDuplicate(key: String, origin: String, listenerOrigin: String): Boolean {
        val now = clock()
        recent.entries.removeAll { now - it.value.first > windowMs }
        val previous = recent[key]
        val bothFromListener =
            previous != null && previous.second == listenerOrigin && origin == listenerOrigin
        if (previous != null && !bothFromListener) return true
        recent[key] = now to origin
        return false
    }
}
