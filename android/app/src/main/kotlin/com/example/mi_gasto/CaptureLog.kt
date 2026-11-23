package com.example.mi_gasto

import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Modo captura: guarda en el teléfono el texto de las notificaciones y pantallas de las apps de
 * pago, con lo que entendió el lector, para escribir reglas con textos reales (constancias de
 * BCP, BBVA, Interbank…). Se activa en Ajustes y nunca sale del teléfono salvo que el usuario
 * lo comparta.
 *
 * Cada entrada es un bloque de texto que empieza con [HEADER]:
 * ```
 * == 23/11/2026 14:05:12 · com.bbva.nxt_peru · pantalla
 * lectura: sin pago
 * ¡Operación exitosa! …
 * ```
 */
class CaptureLog(
    private val file: File,
    private val maxEntries: Int = 100,
    private val maxTextLength: Int = 2000,
    private val clock: () -> Long = System::currentTimeMillis,
) {
    @Synchronized
    fun add(app: String?, via: String, text: String, reading: String) {
        val body = text.trim().take(maxTextLength)
        if (body.isEmpty()) return
        val entries = entries().toMutableList()
        // La lectura de pantalla repite la misma pantalla mientras cambia: se guarda una vez.
        if (entries.lastOrNull()?.let { bodyOf(it) == body && sourceOf(it) == "${app ?: "?"} · $via" } == true) return
        val stamp = SimpleDateFormat("dd/MM/yyyy HH:mm:ss", Locale.ROOT).format(Date(clock()))
        entries += "$HEADER$stamp · ${app ?: "?"} · $via\nlectura: $reading\n$body"
        file.parentFile?.mkdirs()
        file.writeText(entries.takeLast(maxEntries).joinToString("\n\n"))
    }

    @Synchronized
    fun read(): String = if (file.exists()) file.readText() else ""

    @Synchronized
    fun count(): Int = entries().size

    @Synchronized
    fun clear() {
        file.delete()
    }

    private fun entries(): List<String> {
        val raw = read()
        if (raw.isBlank()) return emptyList()
        return raw.split(Regex("\n\n(?=$HEADER)")).filter { it.startsWith(HEADER) }
    }

    /** «app · vía» de la cabecera de una entrada. */
    private fun sourceOf(entry: String): String = entry.lineSequence().first().substringAfter(" · ")

    /** El texto de una entrada, sin la cabecera ni la lectura. */
    private fun bodyOf(entry: String): String = entry.lines().drop(2).joinToString("\n")

    companion object {
        const val HEADER = "== "
        private const val FILE_NAME = "modo_captura.txt"

        fun of(context: android.content.Context) = CaptureLog(File(context.filesDir, FILE_NAME))
    }
}
