package com.example.mi_gasto

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class DeviceTweaksTest {
    @Test fun reconoceLasMarcasConInicioAutomatico() {
        assertEquals("xiaomi", DeviceTweaks.autostartVendor("Xiaomi", "Redmi"))
        assertEquals("xiaomi", DeviceTweaks.autostartVendor("Xiaomi", "POCO"))
        assertEquals("huawei", DeviceTweaks.autostartVendor("HONOR", "HONOR"))
        assertEquals("oppo", DeviceTweaks.autostartVendor("realme", "realme"))
        assertEquals("oppo", DeviceTweaks.autostartVendor("OnePlus", "OnePlus"))
        assertEquals("vivo", DeviceTweaks.autostartVendor("vivo", "iQOO"))
    }

    @Test fun samsungYPixelNoTienenInicioAutomaticoAparte() {
        assertNull(DeviceTweaks.autostartVendor("samsung", "samsung"))
        assertNull(DeviceTweaks.autostartVendor("Google", "google"))
        assertNull(DeviceTweaks.autostartVendor("motorola", "motorola"))
    }

    @Test fun cadaMarcaTieneAlMenosUnaPantallaQueProbar() {
        for (vendor in listOf("xiaomi", "huawei", "oppo", "vivo")) {
            assertTrue(vendor, DeviceTweaks.autostartScreens(vendor).isNotEmpty())
        }
    }
}
