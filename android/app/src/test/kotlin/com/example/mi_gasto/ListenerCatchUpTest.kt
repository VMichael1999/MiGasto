package com.example.mi_gasto

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ListenerCatchUpTest {
    private val hour = 60 * 60 * 1000L
    private val now = 100 * hour

    @Test fun loQueLlegoMientrasEstabaDesconectadoSeLee() {
        assertTrue(ListenerCatchUp.shouldRead(postTime = now - 2 * hour, now = now, lastSeen = now - 3 * hour))
    }

    @Test fun loQueYaSeVioAntesDeDesconectarseNoSeRepite() {
        assertFalse(ListenerCatchUp.shouldRead(postTime = now - 4 * hour, now = now, lastSeen = now - 3 * hour))
    }

    @Test fun laPrimeraVezNoSeRecuperaNada() {
        assertFalse(ListenerCatchUp.shouldRead(postTime = now - hour, now = now, lastSeen = 0))
    }

    @Test fun unAvisoDeHaceMasDeUnDiaNoSeRecupera() {
        assertFalse(ListenerCatchUp.shouldRead(postTime = now - 25 * hour, now = now, lastSeen = now - 30 * hour))
    }
}
