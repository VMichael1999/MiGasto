package com.example.mi_gasto

/**
 * Qué notificaciones de la barra leer al reconectarse el lector de notificaciones.
 *
 * El sistema suelta el lector a veces (ahorro de batería, actualización de la app). Lo que llegó
 * en ese rato sigue en la barra: se lee al volver, siempre que se haya publicado después de la
 * última vez que el lector estaba escuchando y no sea de hace más de [MAX_AGE_MS].
 */
object ListenerCatchUp {
    const val MAX_AGE_MS = 24 * 60 * 60 * 1000L

    /**
     * [lastSeen] es la última hora en que el lector estaba escuchando; 0 si nunca escuchó (la
     * primera vez no se recupera nada: lo que está en la barra es de antes de activar la lectura).
     */
    fun shouldRead(postTime: Long, now: Long, lastSeen: Long): Boolean =
        lastSeen > 0 && postTime > lastSeen && now - postTime <= MAX_AGE_MS
}
