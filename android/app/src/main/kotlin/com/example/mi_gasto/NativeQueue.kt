package com.example.mi_gasto

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Cola de pagos detectados por el código nativo. Flutter es el único que escribe
 * en la base de datos: la vacía con `takeNativeQueue` al abrir la app, al volver
 * a ella y cada vez que se guarda algo, así nada se pierde aunque la app esté
 * cerrada cuando llega el pago.
 */
object NativeQueue {
    private const val PREFS = "FlutterSharedPreferences"
    private const val KEY_QUEUE = "flutter.migasto_native_queue"
    private const val KEY_PROVIDERS = "flutter.migasto_providers_enabled_v2"
    private const val KEY_AUTO_INCOME = "flutter.migasto_auto_save_income"
    private const val KEY_ALIASES = "flutter.migasto_aliases_v1"
    private const val KEY_OVERRIDES = "flutter.migasto_category_overrides_v2"
    private val lock = Any()

    /** Agrega un pago. `confirmed` false lo deja pendiente. */
    fun enqueue(
        context: Context,
        amount: Double,
        peer: String,
        provider: String,
        type: String,
        rawText: String,
        confirmed: Boolean,
        ref: String? = null,
    ) {
        val item = JSONObject().apply {
            // Con `ref`, Flutter usa ese id para el movimiento y la notificación puede referirse a él.
            if (ref != null) put("id", ref)
            put("amount", amount)
            put("peer", peer)
            put("provider", provider)
            put("type", type)
            put("rawText", rawText)
            put("confirmed", confirmed)
            // Lo que llega de Android ya pasó por los frenos de duplicados nativos.
            put("origin", "android")
            put("at", System.currentTimeMillis())
        }
        synchronized(lock) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val array = try {
                JSONArray(prefs.getString(KEY_QUEUE, "[]") ?: "[]")
            } catch (e: Exception) {
                JSONArray()
            }
            array.put(item)
            // commit(): se escribe antes de seguir, por si el proceso termina.
            prefs.edit().putString(KEY_QUEUE, array.toString()).commit()
        }
    }

    /** Pide a Flutter confirmar ("confirm") o descartar ("discard") el movimiento pendiente [ref]. */
    fun enqueueAction(context: Context, action: String, ref: String) {
        val item = JSONObject().apply {
            put("action", action)
            put("id", ref)
            put("at", System.currentTimeMillis())
        }
        synchronized(lock) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val array = try {
                JSONArray(prefs.getString(KEY_QUEUE, "[]") ?: "[]")
            } catch (e: Exception) {
                JSONArray()
            }
            array.put(item)
            prefs.edit().putString(KEY_QUEUE, array.toString()).commit()
        }
    }

    /** Devuelve la cola como JSON y la vacía. */
    fun take(context: Context): String = synchronized(lock) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_QUEUE, "[]") ?: "[]"
        prefs.edit().remove(KEY_QUEUE).commit()
        raw
    }

    /** Si la fuente está activada en Ajustes (por defecto sí). */
    fun isProviderEnabled(context: Context, provider: String): Boolean {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_PROVIDERS, null)
            ?: return true
        return try {
            JSONObject(raw).optBoolean(provider, true)
        } catch (e: Exception) {
            true
        }
    }

    /** Si los ingresos se guardan solos (Ajustes; por defecto no). */
    fun autoSaveIncome(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(KEY_AUTO_INCOME, false)

    /** Nombre con el que el usuario quiere ver a [merchant]; si no puso uno, el original. */
    fun displayName(context: Context, merchant: String): String {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_ALIASES, null)
            ?: return merchant
        return try {
            // Misma clave que `aliasKey` en Dart: minúsculas, sin espacios de más.
            val key = merchant.lowercase().trim().replace(Regex("\\s+"), " ")
            JSONObject(raw).optString(key, "").trim().ifEmpty { merchant }
        } catch (e: Exception) {
            merchant
        }
    }

    /** Categorías que el usuario cambió a mano: comercio en minúsculas -> categoría. */
    fun categoryOverrides(context: Context): Map<String, String> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_OVERRIDES, null)
            ?: return emptyMap()
        return try {
            val json = JSONObject(raw)
            json.keys().asSequence().associateWith { json.getString(it) }
        } catch (e: Exception) {
            emptyMap()
        }
    }
}
