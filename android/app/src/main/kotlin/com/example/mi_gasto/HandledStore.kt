package com.example.mi_gasto

import android.content.Context
import org.json.JSONArray

/** Identificadores de lo que ya se leyó, para no registrarlo dos veces. Sobrevive a reinicios. */
object HandledStore {
    private const val STATE_PREFS = "migasto_native_state"
    private const val KEY_HANDLED = "handled_notifications"
    private const val MAX_HANDLED = 200
    private const val KEY_RECENT = "recent_notifications"
    private val lock = Any()

    /** Guarda [id]; devuelve `false` si ya estaba (es decir, ya se había leído). */
    fun markHandled(context: Context, id: String): Boolean = synchronized(lock) {
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

    /**
     * Guarda [id] con la hora [now]; devuelve `false` si ya se vio hace menos de [windowMs].
     * Sirve para la misma notificación que la app vuelve a publicar con el mismo texto.
     */
    fun markRecent(context: Context, id: String, windowMs: Long, now: Long = System.currentTimeMillis()): Boolean =
        synchronized(lock) {
            val prefs = context.getSharedPreferences(STATE_PREFS, Context.MODE_PRIVATE)
            val (isNew, stored) = recent(prefs.getString(KEY_RECENT, "") ?: "", id, now, windowMs)
            prefs.edit().putString(KEY_RECENT, stored).commit()
            isNew
        }

    /**
     * Lógica de [markRecent] sin Android: [stored] tiene una línea «hora id» por cada aviso.
     * Devuelve si [id] es nuevo y lo que hay que guardar (sin lo que ya salió de la ventana).
     */
    internal fun recent(stored: String, id: String, now: Long, windowMs: Long): Pair<Boolean, String> {
        val kept = stored.lineSequence()
            .mapNotNull { line ->
                val at = line.substringBefore(' ').toLongOrNull() ?: return@mapNotNull null
                if (now - at > windowMs) null else at to line.substringAfter(' ')
            }
            .toList()
        val isNew = kept.none { it.second == id }
        val lines = kept.map { "${it.first} ${it.second}" } + if (isNew) listOf("$now $id") else emptyList()
        return isNew to lines.joinToString("\n")
    }
}
