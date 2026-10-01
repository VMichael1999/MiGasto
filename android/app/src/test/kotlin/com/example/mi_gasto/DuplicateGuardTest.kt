package com.example.mi_gasto

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DuplicateGuardTest {
    private val window = 2 * 60 * 1000L
    private var now = 1_000_000L
    private val guard = DuplicateGuard(window) { now }
    private val key = "yape|ingreso|1.00"
    private val listener = MyAccessibilityService.ORIGIN_LISTENER
    private val access = MyAccessibilityService.ORIGIN_ACCESS
    private val screen = MyAccessibilityService.ORIGIN_SCREEN

    private fun dup(origin: String, k: String = key) = guard.isDuplicate(k, origin, listener)

    @Test fun primerPagoNoEsDuplicado() {
        assertFalse(dup(listener))
    }

    @Test fun dosYapesDelMismoMontoSeguidosValenLosDos() {
        assertFalse(dup(listener))
        now += 60_000
        assertFalse(dup(listener))
        now += 30_000
        assertFalse(dup(listener))
    }

    @Test fun lanotificacionYLaPantallaDeLaConstanciaSonElMismoPago() {
        assertFalse(dup(listener))
        now += 5_000
        assertTrue(dup(screen))
    }

    @Test fun laPantallaYLaNotificacionTambien() {
        assertFalse(dup(screen))
        now += 5_000
        assertTrue(dup(listener))
    }

    @Test fun laAccesibilidadYElServicioDeNotificacionesSonElMismoPago() {
        assertFalse(dup(listener))
        now += 1_000
        assertTrue(dup(access))
    }

    @Test fun dosAvisosDeAccesibilidadDelMismoMontoSiguenFrenados() {
        assertFalse(dup(access))
        now += 10_000
        assertTrue(dup(access))
    }

    @Test fun pasadaLaVentanaYaNoEsDuplicado() {
        assertFalse(dup(screen))
        now += window + 1
        assertFalse(dup(listener))
    }

    @Test fun otroMontoOtroTipoOOtraFuenteNoSeFrena() {
        assertFalse(dup(listener))
        assertFalse(dup(screen, "yape|ingreso|2.00"))
        assertFalse(dup(screen, "yape|gasto|1.00"))
        assertFalse(dup(screen, "plin|ingreso|1.00"))
    }

    @Test fun unaConstanciaLeidaDosVecesSeFrena() {
        assertFalse(dup(screen))
        now += 20_000
        assertTrue(dup(screen))
    }
}
