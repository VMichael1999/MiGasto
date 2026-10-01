package com.example.mi_gasto

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Botones «Guardar» e «Ignorar» del aviso de un ingreso por confirmar.
 * No escribe en la base: deja la orden en la cola y Flutter la aplica.
 */
class PaymentActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val ref = intent.getStringExtra(EXTRA_REF) ?: return
        val action = when (intent.action) {
            ACTION_CONFIRM -> "confirm"
            ACTION_DISCARD -> "discard"
            else -> return
        }
        NativeQueue.enqueueAction(context, action, ref)
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(intent.getIntExtra(EXTRA_NOTIFICATION_ID, 0))
        MyAccessibilityService.notifyFlutterSaved()
    }

    companion object {
        const val ACTION_CONFIRM = "com.example.mi_gasto.PAYMENT_CONFIRM"
        const val ACTION_DISCARD = "com.example.mi_gasto.PAYMENT_DISCARD"
        const val EXTRA_REF = "ref"
        const val EXTRA_NOTIFICATION_ID = "notificationId"
    }
}
