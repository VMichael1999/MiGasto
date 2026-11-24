package com.example.mi_gasto

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class HiddenNotificationTest {
    @Test fun reconoceElMensajeDelSistemaEnElIdiomaDelTelefono() {
        assertTrue(HiddenNotification.isHidden("Se ocultó contenido sensible de la notificación", systemMessage = null))
        assertTrue(HiddenNotification.isHidden("Contenido sensible de la notificación oculto", systemMessage = null))
        assertTrue(HiddenNotification.isHidden("Sensitive notification content hidden", systemMessage = null))
    }

    @Test fun usaElTextoQueTraeElPropioTelefono() {
        assertTrue(HiddenNotification.isHidden("Conteúdo da notificação oculto", systemMessage = "Conteúdo da notificação oculto"))
    }

    @Test fun unAvisoNormalNoEstaOculto() {
        assertFalse(HiddenNotification.isHidden("Sasha Sal* te envió un pago por S/ 5.5", systemMessage = null))
        assertFalse(HiddenNotification.isHidden("", systemMessage = null))
        assertFalse(HiddenNotification.isHidden("Yape", systemMessage = "Se ocultó contenido sensible de la notificación"))
    }
}
