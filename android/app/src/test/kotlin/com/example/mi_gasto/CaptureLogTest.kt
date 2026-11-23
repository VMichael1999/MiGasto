package com.example.mi_gasto

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

class CaptureLogTest {
    @get:Rule val folder = TemporaryFolder()

    private var now = 1_800_000_000_000L
    private fun log(max: Int = 100) = CaptureLog(folder.root.resolve("captura.txt"), maxEntries = max) { now }

    @Test fun guardaLaAppLaViaLaLecturaYElTexto() {
        val log = log()
        log.add("com.bbva.nxt_peru", "pantalla", "¡Operación exitosa!\nS/ 12.00", "sin pago")
        val text = log.read()
        assertTrue(text.startsWith("== "))
        assertTrue(text.contains(" · com.bbva.nxt_peru · pantalla\nlectura: sin pago\n¡Operación exitosa!\nS/ 12.00"))
        assertEquals(1, log.count())
    }

    @Test fun laMismaPantallaSeguidaSeGuardaUnaVez() {
        val log = log()
        log.add("com.bcp.bank.bcp", "pantalla", "Constancia S/ 5", "sin pago")
        now += 500
        log.add("com.bcp.bank.bcp", "pantalla", "Constancia S/ 5", "sin pago")
        assertEquals(1, log.count())
        // El mismo texto por otra vía sí se guarda (notificación y pantalla del mismo pago).
        log.add("com.bcp.bank.bcp", "notificación", "Constancia S/ 5", "sin pago")
        assertEquals(2, log.count())
    }

    @Test fun guardaSoloLasUltimasEntradas() {
        val log = log(max = 3)
        for (i in 1..5) log.add("app", "notificación", "pago $i", "sin pago")
        assertEquals(3, log.count())
        val text = log.read()
        assertFalse(text.contains("pago 2"))
        assertTrue(text.contains("pago 3") && text.contains("pago 5"))
    }

    @Test fun unTextoVacioNoSeGuardaYBorrarLoDejaVacio() {
        val log = log()
        log.add("app", "pantalla", "   ", "sin pago")
        assertEquals(0, log.count())
        log.add("app", "pantalla", "S/ 1", "gasto")
        log.clear()
        assertEquals("", log.read())
        assertEquals(0, log.count())
    }
}
