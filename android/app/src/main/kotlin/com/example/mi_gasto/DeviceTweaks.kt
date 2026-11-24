package com.example.mi_gasto

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log

/**
 * Ajustes propios de cada fabricante y del origen de la instalación que la app no puede leer,
 * solo abrir para que el usuario los revise.
 */
object DeviceTweaks {
    private const val TAG = "DeviceTweaks"

    /** Marcas que además de la batería tienen su propio «inicio automático» (si está apagado, cierran la lectura). */
    fun autostartVendor(manufacturer: String = Build.MANUFACTURER, brand: String = Build.BRAND): String? {
        val m = "${manufacturer.lowercase()} ${brand.lowercase()}"
        return when {
            listOf("xiaomi", "redmi", "poco").any { it in m } -> "xiaomi"
            listOf("huawei", "honor").any { it in m } -> "huawei"
            listOf("oppo", "realme", "oneplus").any { it in m } -> "oppo"
            listOf("vivo", "iqoo").any { it in m } -> "vivo"
            else -> null
        }
    }

    /**
     * Pantallas de inicio automático conocidas, de la más nueva a la más vieja. Cambian entre
     * versiones del sistema, así que se prueban en orden.
     */
    fun autostartScreens(vendor: String): List<ComponentName> = when (vendor) {
        "xiaomi" -> listOf(
            ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
            ComponentName("com.miui.securitycenter", "com.miui.powercenter.autostart.AutoStartManagementActivity"),
        )
        "huawei" -> listOf(
            ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
            ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"),
            ComponentName("com.hihonor.systemmanager", "com.hihonor.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
        )
        "oppo" -> listOf(
            ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
            ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"),
            ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
        )
        "vivo" -> listOf(
            ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
            ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"),
            ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"),
        )
        else -> emptyList()
    }

    /** Abre el inicio automático de la marca; si ninguna pantalla existe, la ficha de la app. */
    fun openAutostart(context: Context): Boolean {
        val vendor = autostartVendor() ?: return openAppDetails(context).let { false }
        for (component in autostartScreens(vendor)) {
            try {
                context.startActivity(Intent().setComponent(component).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return true
            } catch (e: Exception) {
                // No existe en esta versión o no se deja abrir: se prueba la siguiente.
                Log.d(TAG, "sin $component")
            }
        }
        openAppDetails(context)
        return false
    }

    fun openAppDetails(context: Context): Boolean = try {
        context.startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
        true
    } catch (e: Exception) {
        false
    }

    /** Tiendas que instalan con la API de sesiones (Android no les restringe los ajustes). */
    private val stores = setOf("com.android.vending", "com.sec.android.app.samsungapps", "com.huawei.appmarket", "com.xiaomi.market", "com.xiaomi.mipicks")

    /**
     * Desde Android 13, una app instalada desde un archivo (descargado o compartido) no puede
     * activar la Accesibilidad ni el acceso a notificaciones hasta que el usuario, en la ficha
     * de la app, toca ⋮ > «Permitir ajustes restringidos». No hay forma de saber si ya lo hizo.
     */
    fun mayNeedRestrictedSettings(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return false
        val installer = try {
            context.packageManager.getInstallSourceInfo(context.packageName).installingPackageName
        } catch (e: Exception) {
            null
        }
        return installer != null && installer !in stores
    }
}
