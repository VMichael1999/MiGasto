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

    private fun dup(origin: String, k: String = key, app: String? = null) = guard.isDuplicate(k, origin, listener, app)

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

    @Test fun elMismoConsumoPorGoogleWalletYPorElBancoCuentaUnaVez() {
        val wallet = DuplicateGuard.key("googlePay", "gasto", 35.0)
        val banco = DuplicateGuard.key("tarjeta", "gasto", 35.0)
        assertFalse(dup(listener, wallet, "com.google.android.apps.walletnfcrel"))
        now += 4_000
        assertTrue(dup(listener, banco, "pe.com.interbank.mobilebanking"))
    }

    @Test fun dosConsumosIgualesSeguidosDelMismoBancoValenLosDos() {
        val banco = DuplicateGuard.key("tarjeta", "gasto", 12.5)
        assertFalse(dup(listener, banco, "pe.com.interbank.mobilebanking"))
        now += 30_000
        assertFalse(dup(listener, banco, "pe.com.interbank.mobilebanking"))
    }

    @Test fun dosYapesIgualesCuandoLaAccesibilidadSeAdelantaValenLosDos() {
        val yape = "com.bcp.innovacxion.yapeapp"
        assertFalse(dup(access, app = yape)) // 1.º yape, por accesibilidad
        assertTrue(dup(listener, app = yape)) // el mismo, por el servicio
        now += 20_000
        assertTrue(dup(access, app = yape)) // 2.º yape, por accesibilidad: lo trae el servicio
        assertFalse(dup(listener, app = yape)) // 2.º yape, por el servicio: vale
    }

    @Test fun dosYapesIgualesConLasDosVueltasDeAccesibilidadPrimero() {
        val yape = "com.bcp.innovacxion.yapeapp"
        assertFalse(dup(access, app = yape))
        now += 5_000
        assertTrue(dup(access, app = yape))
        assertTrue(dup(listener, app = yape))
        assertFalse(dup(listener, app = yape))
    }

    @Test fun laConstanciaEnPantallaYLuegoDosNotificacionesIguales() {
        val yape = "com.bcp.innovacxion.yapeapp"
        assertFalse(dup(screen, app = yape))
        assertTrue(dup(listener, app = yape))
        now += 30_000
        assertFalse(dup(listener, app = yape))
    }

    @Test fun otraAppNoHeredaElAvisoDeLaAccesibilidad() {
        val banco = DuplicateGuard.key("tarjeta", "gasto", 35.0)
        assertFalse(dup(access, banco, "com.google.android.apps.walletnfcrel"))
        assertTrue(dup(listener, banco, "pe.com.interbank.mobilebanking"))
        assertTrue(dup(listener, banco, "pe.com.interbank.mobilebanking"))
    }

    @Test fun laClaveUsaPuntoDecimalSinImportarElIdioma() {
        assertTrue(DuplicateGuard.key("yape", "ingreso", 1.0) == "yape|ingreso|1.00")
    }
}
