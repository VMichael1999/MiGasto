package com.example.mi_gasto

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class ParseResult(
    val amount: Double,
    val peer: String,
    val provider: String,
    /** "gasto" o "ingreso" */
    val type: String,
)

/**
 * Lector de pagos y clasificador de categorías.
 *
 * Lee los mismos archivos que Dart (`assets/reader_rules.json` y
 * `assets/category_rules.json`), que Flutter empaqueta en `flutter_assets`,
 * para que ambos lados reconozcan lo mismo.
 */
class ReaderRules private constructor(
    private val rules: JSONObject,
    private val categories: JSONObject,
) {
    private val options = setOf(RegexOption.IGNORE_CASE)
    private val amountRegex = Regex(rules.getString("amount"), options)
    private val incomeRegexes = compileAll(rules.getJSONArray("income"))
    private val expenseRegexes = compileAll(rules.getJSONArray("expense"))
    private val prepositions = strings(rules.getJSONArray("peerPrepositions")).joinToString("|")
    private val cleanPhrases = strings(rules.getJSONArray("cleanPhrases")).sortedByDescending { it.length }
    private val stopWords = strings(rules.getJSONArray("peerStopWords"))
    private val unknownPeer = rules.getString("unknownPeer")

    private val gastoGroups = categoryGroups(categories.getJSONArray("gasto"))
    private val ingresoGroups = categoryGroups(categories.getJSONArray("ingreso"))

    private fun compileAll(array: JSONArray): List<Regex> =
        strings(array).map { Regex(it, options) }

    private fun strings(array: JSONArray): List<String> =
        (0 until array.length()).map { array.getString(it) }

    private fun keywordRegex(keyword: String) =
        Regex("(?<![\\p{L}\\p{N}])" + Regex.escape(keyword) + "(?![\\p{L}\\p{N}])", options)

    private fun categoryGroups(array: JSONArray): List<Pair<String, List<Regex>>> =
        (0 until array.length()).map { i ->
            val group = array.getJSONObject(i)
            group.getString("category") to strings(group.getJSONArray("keywords")).map(::keywordRegex)
        }

    private val operationIdRegex = rules.optString("operationId").takeIf { it.isNotEmpty() }
        ?.let { Regex(it, RegexOption.IGNORE_CASE) }

    /** Número de operación de una constancia (identifica el pago aunque la pantalla se lea otra vez). */
    fun operationId(text: String): String? = operationIdRegex?.find(text)?.groupValues?.get(1)

    /** `null` si el texto no es un pago reconocible. */
    fun parse(text: String): ParseResult? {
        val provider = provider(text) ?: return null
        val match = amountRegex.find(text) ?: return null
        val amount = parseAmount(match.groupValues[1]) ?: return null
        if (amount <= 0.0) return null

        val isIncome = direction(text, provider) ?: return null
        val peer = peer(text, match, isIncome)
        return ParseResult(
            amount = amount,
            peer = if (peer.isEmpty()) unknownPeer else peer,
            provider = provider,
            type = if (isIncome) "ingreso" else "gasto",
        )
    }

    private fun provider(text: String): String? {
        val lower = text.lowercase()
        val providers = rules.getJSONArray("providers")
        for (i in 0 until providers.length()) {
            val p = providers.getJSONObject(i)
            val boundary = p.optBoolean("wordBoundary", false)
            for (k in strings(p.getJSONArray("keywords"))) {
                val found = if (boundary) keywordRegex(k).containsMatchIn(lower) else lower.contains(k)
                if (found) return p.getString("id")
            }
        }
        return null
    }

    /** true ingreso, false gasto, null si no se puede saber. */
    private fun direction(text: String, provider: String): Boolean? {
        // Primero los ingresos: "te yapeó" contiene la raíz de "yapeaste".
        if (incomeRegexes.any { it.containsMatchIn(text) }) return true
        if (expenseRegexes.any { it.containsMatchIn(text) }) return false
        return when (rules.getJSONObject("defaultTypeByProvider").optString(provider)) {
            "gasto" -> false
            "ingreso" -> true
            else -> null
        }
    }

    private fun parseAmount(raw: String): Double? {
        var s = raw.trim()
        s = if (Regex("^\\d{1,3}(,\\d{3})+(\\.\\d+)?$").matches(s)) s.replace(",", "") else s.replace(",", ".")
        return s.toDoubleOrNull()
    }

    private fun peer(text: String, amount: MatchResult, isIncome: Boolean): String {
        val after = text.substring(amount.range.last + 1).trim()
        val before = text.substring(0, amount.range.first).trim()

        fun fromAfter(): String {
            val m = Regex("^($prepositions)\\b(.*)", setOf(RegexOption.IGNORE_CASE, RegexOption.DOT_MATCHES_ALL))
                .find(after) ?: return ""
            return clean(m.groupValues[2])
        }

        // En ingresos el nombre suele ir antes; en gastos, después.
        val first = if (isIncome) clean(before) else fromAfter()
        if (first.isNotEmpty()) return first
        val second = if (isIncome) fromAfter() else clean(before)
        if (second.isNotEmpty() || isIncome) return second
        return fromAfterWithoutPreposition(after)
    }

    /**
     * Constancia de Yape al enviar: el nombre va justo después del monto, sin "a" ni "de"
     * ("¡Yapeaste! S/ 1 Juan Pérez 01 oct. 2026 09:48 a. m. DATOS DE LA TRANSACCIÓN ...").
     * Se toma hasta la primera cifra (la fecha) y se descarta si queda demasiado largo.
     */
    private fun fromAfterWithoutPreposition(after: String): String {
        val cut = Regex("\\d").find(after)?.range?.first ?: after.length
        val name = clean(after.substring(0, cut))
        return if (name.length in 2..60) name else ""
    }

    private fun clean(input: String): String {
        var t = input
        for (stop in stopWords) {
            val i = t.lowercase().indexOf(stop)
            if (i > 0) t = t.substring(0, i)
        }
        for (phrase in cleanPhrases) {
            t = t.replace(
                Regex("(^|[^\\p{L}])" + Regex.escape(phrase) + "(?![\\p{L}])", options),
                " ",
            )
        }
        t = t.replace(Regex("^\\s*($prepositions)\\b", options), "")
        t = t.replace(Regex("\\b($prepositions)\\s*$", options), "")
        t = t.replace(Regex("\\s+"), " ")
        return t.replace(Regex("^[\\s:,\\-¡!.*_]+|[\\s:,\\-¡!.*_]+$"), "")
    }

    /**
     * Categoría sugerida (nombre del enum de Dart). Para gastos se respeta lo que
     * el usuario aprendió en la app (`overrides`: comercio en minúsculas -> categoría).
     */
    fun classify(text: String, peer: String, type: String, overrides: Map<String, String>): String {
        val combined = "$text $peer"
        if (type == "ingreso") {
            return firstMatch(ingresoGroups, combined) ?: categories.getString("ingresoDefault")
        }
        overrides[peer.lowercase().trim()]?.let { learned ->
            if (learned !in INCOME_CATEGORIES) return learned
        }
        return firstMatch(gastoGroups, combined) ?: categories.getString("gastoDefault")
    }

    private fun firstMatch(groups: List<Pair<String, List<Regex>>>, text: String): String? =
        groups.firstOrNull { (_, patterns) -> patterns.any { it.containsMatchIn(text) } }?.first

    companion object {
        private val INCOME_CATEGORIES = setOf("sueldo", "transferenciaRecibida", "venta", "otrosIngresos")

        @Volatile
        private var cached: ReaderRules? = null

        private fun read(context: Context, name: String): JSONObject =
            JSONObject(
                context.assets.open("flutter_assets/assets/$name").bufferedReader(Charsets.UTF_8).use { it.readText() }
            )

        /** Carga las reglas una sola vez. `null` si los archivos no están. */
        fun get(context: Context): ReaderRules? {
            cached?.let { return it }
            return try {
                val loaded = ReaderRules(read(context, "reader_rules.json"), read(context, "category_rules.json"))
                cached = loaded
                loaded
            } catch (e: Exception) {
                android.util.Log.e("ReaderRules", "No se pudieron cargar las reglas del lector", e)
                null
            }
        }

        /** Nombre visible de una categoría. */
        fun categoryLabel(name: String): String = when (name) {
            "alimentacion" -> "Alimentación"
            "transporte" -> "Transporte"
            "compras" -> "Compras"
            "servicios" -> "Servicios"
            "entretenimiento" -> "Entretenimiento"
            "sueldo" -> "Sueldo"
            "transferenciaRecibida" -> "Transferencia recibida"
            "venta" -> "Venta"
            else -> "Otros"
        }
    }
}
