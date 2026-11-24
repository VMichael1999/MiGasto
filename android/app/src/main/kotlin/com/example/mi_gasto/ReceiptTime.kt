package com.example.mi_gasto

import java.util.Calendar
import java.util.TimeZone

/**
 * Fecha y hora impresas en una constancia («01 oct. 2026 12:36 p. m.»), en milisegundos.
 *
 * Sirve para no registrar como pago nuevo una constancia antigua que el usuario abre desde el
 * historial de Yape: la pantalla es igual a la de un pago recién hecho, pero la fecha no.
 */
object ReceiptTime {
    /** Una constancia más antigua que esto ya no es un pago recién hecho. */
    const val MAX_AGE_MS = 15 * 60 * 1000L

    private val stampRegex = Regex(
        "(\\d{1,2})\\s+(\\p{L}{3,5})\\.?\\s+(\\d{4})\\s+(\\d{1,2}):(\\d{2})\\s*([ap])\\.?\\s*m\\.?",
        RegexOption.IGNORE_CASE,
    )

    private val months = mapOf(
        "ene" to 0, "feb" to 1, "mar" to 2, "abr" to 3, "may" to 4, "jun" to 5,
        "jul" to 6, "ago" to 7, "sep" to 8, "set" to 8, "oct" to 9, "nov" to 10, "dic" to 11,
    )

    /** `null` si el texto no trae una fecha y hora reconocibles. */
    fun parse(text: String, zone: TimeZone = TimeZone.getDefault()): Long? {
        val m = stampRegex.find(text) ?: return null
        val (day, monthName, year, hour, minute, half) = m.destructured
        val month = months[monthName.lowercase().take(3)] ?: return null
        var h = hour.toInt()
        if (h !in 1..12) return null
        // 12:05 a. m. es medianoche; 12:36 p. m., mediodía.
        h %= 12
        if (half.equals("p", ignoreCase = true)) h += 12
        return Calendar.getInstance(zone).apply {
            clear()
            set(year.toInt(), month, day.toInt(), h, minute.toInt())
        }.timeInMillis
    }

    /** Si la constancia de [text] es de hace más de [MAX_AGE_MS]. Sin fecha, no se puede saber: `false`. */
    fun isOld(text: String, now: Long, zone: TimeZone = TimeZone.getDefault()): Boolean {
        val at = parse(text, zone) ?: return false
        return now - at > MAX_AGE_MS
    }
}
