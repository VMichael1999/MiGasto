package com.example.mi_gasto

import android.content.Context
import org.json.JSONArray

/** Identificadores de lo que ya se leyó, para no registrarlo dos veces. Sobrevive a reinicios. */
object HandledStore {
    private const val STATE_PREFS = "migasto_native_state"
    private const val KEY_HANDLED = "handled_notifications"
    private const val MAX_HANDLED = 200
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
}
