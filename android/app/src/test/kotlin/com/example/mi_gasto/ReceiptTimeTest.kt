package com.example.mi_gasto

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class ReceiptTimeTest {
    private val lima = TimeZone.getTimeZone("America/Lima")

    private fun at(year: Int, month: Int, day: Int, hour: Int, minute: Int): Long =
        Calendar.getInstance(lima).apply {
            clear()
            set(year, month, day, hour, minute)
        }.timeInMillis

    @Test fun leeLaFechaDeUnaConstanciaRealDeYape() {
        val text = "¡Yapeaste el servicio! S/ 134.85 BanBif 01 oct. 2026 12:36 p. m. DATOS DE LA TRANSACCIÓN"
        assertEquals(at(2026, Calendar.OCTOBER, 1, 12, 36), ReceiptTime.parse(text, lima))
    }

    @Test fun lasDoceDeLaNocheSonLaHoraCero() {
        assertEquals(at(2026, Calendar.NOVEMBER, 24, 0, 5), ReceiptTime.parse("24 nov. 2026 12:05 a. m.", lima))
        assertEquals(at(2026, Calendar.NOVEMBER, 24, 21, 48), ReceiptTime.parse("24 nov 2026 09:48 p.m.", lima))
    }

    @Test fun septiembreSeEscribeDeDosManeras() {
        assertEquals(at(2026, Calendar.SEPTEMBER, 3, 9, 0), ReceiptTime.parse("3 set. 2026 09:00 a. m.", lima))
        assertEquals(at(2026, Calendar.SEPTEMBER, 3, 9, 0), ReceiptTime.parse("3 sept. 2026 09:00 a. m.", lima))
    }

    @Test fun sinFechaNoSeInventaUna() {
        assertNull(ReceiptTime.parse("¡Yapeaste! S/ 1 Juan Pérez DATOS DE LA TRANSACCIÓN", lima))
        assertFalse(ReceiptTime.isOld("¡Yapeaste! S/ 1 Juan Pérez", now = Long.MAX_VALUE, zone = lima))
    }

    @Test fun unaConstanciaRecienHechaNoEsAntigua() {
        val now = at(2026, Calendar.OCTOBER, 1, 12, 40)
        assertFalse(ReceiptTime.isOld("01 oct. 2026 12:36 p. m.", now, lima))
    }

    @Test fun unaConstanciaAbiertaDesdeElHistorialEsAntigua() {
        val now = at(2026, Calendar.NOVEMBER, 24, 10, 0)
        assertTrue(ReceiptTime.isOld("01 oct. 2026 12:36 p. m.", now, lima))
        assertTrue(ReceiptTime.isOld("24 nov. 2026 09:30 a. m.", now, lima))
    }
}
