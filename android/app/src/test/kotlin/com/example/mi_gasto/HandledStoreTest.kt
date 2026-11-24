package com.example.mi_gasto

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class HandledStoreTest {
    private val window = 60_000L

    @Test fun laMismaNotificacionRepublicadaEnseguidaSeVeUnaVez() {
        val (first, stored) = HandledStore.recent("", "c|yape|1", 1_000, window)
        assertTrue(first)
        val (again, _) = HandledStore.recent(stored, "c|yape|1", 20_000, window)
        assertFalse(again)
    }

    @Test fun pasadaLaVentanaVuelveAContar() {
        val (_, stored) = HandledStore.recent("", "c|yape|1", 1_000, window)
        val (later, kept) = HandledStore.recent(stored, "c|yape|1", 1_000 + window + 1, window)
        assertTrue(later)
        // Lo vencido se borra: solo queda la entrada nueva.
        assertTrue(kept.lines().size == 1)
    }

    @Test fun otroTextoEsOtroAviso() {
        val (_, stored) = HandledStore.recent("", "c|yape|1", 1_000, window)
        assertTrue(HandledStore.recent(stored, "c|yape|2", 2_000, window).first)
    }

    @Test fun unValorDanadoNoRompeNada() {
        assertTrue(HandledStore.recent("basura\n12 \n", "c|yape|1", 1_000, window).first)
    }
}
