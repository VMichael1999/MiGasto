package com.example.mi_gasto

import android.Manifest
import android.app.KeyguardManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import java.util.Locale

/**
 * Avisos de MiGasto cuando la ventana flotante no se puede ver: pantalla apagada o
 * bloqueada, o sin el permiso "Mostrar sobre otras apps".
 *
 * - Ingreso por confirmar: canal con sonido ("Pagos detectados").
 * - Gasto o ingreso ya guardado: canal silencioso ("Pagos guardados").
 * - En la pantalla bloqueada se oculta el monto y el nombre, salvo que el usuario lo permita.
 */
object PaymentNotifier {
    private const val PREFS = "FlutterSharedPreferences"
    private const val KEY_SHOW_LOCKED = "flutter.migasto_show_amount_locked"
    private const val CHANNEL_DETECTED = "pagos_detectados"
    private const val CHANNEL_SAVED = "pagos_guardados"

    /** La ventana flotante se puede ver: permiso, pantalla encendida y teléfono desbloqueado. */
    fun canShowOverlay(context: Context): Boolean {
        val overlayOk = Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)
        if (!overlayOk) return false
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val keyguard = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return power.isInteractive && !keyguard.isKeyguardLocked
    }

    fun canNotify(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) return false
        return NotificationManagerCompat.from(context).areNotificationsEnabled()
    }

    private fun showAmountOnLockScreen(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(KEY_SHOW_LOCKED, false)

    private fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_DETECTED, "Pagos detectados", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Ingresos que esperan tu confirmación"
                lockscreenVisibility = android.app.Notification.VISIBILITY_PRIVATE
            },
        )
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_SAVED, "Pagos guardados", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Gastos que MiGasto ya guardó, en silencio"
                lockscreenVisibility = android.app.Notification.VISIBILITY_PRIVATE
            },
        )
    }

    private fun sourceName(provider: String) = when (provider) {
        "yape" -> "Yape"
        "plin" -> "Plin"
        "googlePay" -> "Google Wallet"
        else -> "Manual"
    }

    /** Avisa de un pago detectado. [saved] indica si ya quedó guardado o espera confirmación. */
    fun notify(context: Context, amount: Double, peer: String, provider: String, type: String, saved: Boolean) {
        if (!canNotify(context)) return
        ensureChannels(context)

        val isIncome = type == "ingreso"
        val money = String.format(Locale.US, "S/ %,.2f", amount)
        val title = when {
            isIncome && saved -> "Ingreso guardado: $money"
            isIncome -> "Ingreso por confirmar: $money"
            else -> "Gasto guardado: $money"
        }
        val name = NativeQueue.displayName(context, peer)
        val text = "${if (isIncome) "de" else "a"} $name · ${sourceName(provider)}"

        val open = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentIntent = open?.let {
            PendingIntent.getActivity(context, 0, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }

        val channel = if (saved) CHANNEL_SAVED else CHANNEL_DETECTED
        val builder = NotificationCompat.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_stat_boleta)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setPriority(if (saved) NotificationCompat.PRIORITY_LOW else NotificationCompat.PRIORITY_HIGH)

        if (showAmountOnLockScreen(context)) {
            builder.setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
        } else {
            // En la pantalla bloqueada solo se ve que hubo un pago.
            builder.setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            builder.setPublicVersion(
                NotificationCompat.Builder(context, channel)
                    .setSmallIcon(R.drawable.ic_stat_boleta)
                    .setContentTitle("MiGasto")
                    .setContentText("Pago detectado")
                    .build(),
            )
        }

        try {
            NotificationManagerCompat.from(context).notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), builder.build())
        } catch (e: SecurityException) {
            // Sin permiso en este momento: no es esencial.
        }
    }
}
