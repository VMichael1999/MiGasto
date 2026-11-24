package com.example.mi_gasto

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Widgets de la pantalla de inicio. Muestran lo que Flutter deja con `updateHomeWidgets`
 * (`WidgetSnapshot` en lib/shared/widget_snapshot.dart): no calculan nada, así las cifras son
 * las mismas que en Inicio y que en el iPhone.
 */
object HomeWidgets {
    private const val PREFS = "migasto_widgets"
    private const val KEY = "snapshot"

    /** Guarda lo que mandó Flutter y repinta todos los widgets puestos. */
    fun save(context: Context, json: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, json).apply()
        updateAll(context)
    }

    fun load(context: Context): Snapshot? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)?.let { Snapshot.parse(it) }

    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        for (provider in listOf(SummaryWidget::class.java, RecentWidget::class.java, QuickAddWidget::class.java)) {
            val ids = manager.getAppWidgetIds(ComponentName(context, provider))
            if (ids.isEmpty()) continue
            context.sendBroadcast(
                Intent(context, provider)
                    .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                    .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids),
            )
        }
    }

    /** Abre MiGasto en la pantalla del enlace (`migasto://new`, `migasto://movement/<id>`…). */
    fun open(context: Context, link: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_VIEW)
            .setData(Uri.parse(link))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(
            context, link.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * Arma las vistas según el tamaño: en Android 12 o más el sistema elige entre las dos sin
     * volver a preguntar; antes se usa el tamaño que informa el launcher.
     */
    fun sized(options: Bundle?, compact: RemoteViews, full: RemoteViews, threshold: SizeF): RemoteViews {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return RemoteViews(mapOf(SizeF(0f, 0f) to compact, threshold to full))
        }
        val width = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 0
        val height = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT) ?: 0
        val fits = (threshold.width == 0f || width >= threshold.width) && (threshold.height == 0f || height >= threshold.height)
        return if (fits || (width == 0 && height == 0)) full else compact
    }

    fun parseColor(hex: String, fallback: Int): Int = try {
        Color.parseColor(hex)
    } catch (e: IllegalArgumentException) {
        fallback
    }
}

/** Lo que muestran los widgets (el JSON de `WidgetSnapshot`). */
data class Snapshot(
    val monthKey: String,
    val month: String,
    val balance: String,
    val income: String,
    val spent: String,
    val percent: Int,
    val pending: Int,
    val recent: List<Movement>,
) {
    data class Movement(
        val id: String,
        val title: String,
        val subtitle: String,
        val amount: String,
        val kind: String,
        val color: String,
        val pending: Boolean,
    )

    /** Si el resumen es de un mes anterior (no se abrió la app desde entonces). */
    fun isFromAnotherMonth(now: Date = Date()): Boolean =
        monthKey.isNotEmpty() && monthKey != SimpleDateFormat("yyyy-MM", Locale.US).format(now)

    companion object {
        fun parse(json: String): Snapshot? = try {
            val o = JSONObject(json)
            val list = o.optJSONArray("recent")
            Snapshot(
                monthKey = o.optString("monthKey"),
                month = o.optString("month"),
                balance = o.optString("balance", "S/ 0.00"),
                income = o.optString("income", "S/ 0.00"),
                spent = o.optString("spent", "S/ 0.00"),
                percent = o.optInt("percent", 0).coerceIn(0, 100),
                pending = o.optInt("pending", 0),
                recent = (0 until (list?.length() ?: 0)).mapNotNull { i ->
                    list?.optJSONObject(i)?.let {
                        Movement(
                            id = it.optString("id"),
                            title = it.optString("title"),
                            subtitle = it.optString("subtitle"),
                            amount = it.optString("amount"),
                            kind = it.optString("kind"),
                            color = it.optString("color"),
                            pending = it.optBoolean("pending"),
                        )
                    }
                },
            )
        } catch (e: Exception) {
            null
        }
    }
}

/** Base: repinta al agregarse, al actualizarse y al cambiar de tamaño (Android 11 o menos). */
abstract class MiGastoWidget : AppWidgetProvider() {
    abstract fun render(context: Context, options: Bundle?): RemoteViews

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, render(context, manager.getAppWidgetOptions(id)))
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        manager.updateAppWidget(id, render(context, options))
    }
}

/** «Resumen del mes»: la tarjeta de balance de Inicio. */
class SummaryWidget : MiGastoWidget() {
    override fun render(context: Context, options: Bundle?): RemoteViews {
        val data = HomeWidgets.load(context)
        return HomeWidgets.sized(options, build(context, data, wide = false), build(context, data, wide = true), SizeF(220f, 0f))
    }

    private fun build(context: Context, data: Snapshot?, wide: Boolean): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_summary)
        views.setOnClickPendingIntent(R.id.root, HomeWidgets.open(context, "migasto://dashboard"))
        if (data == null) {
            views.setTextViewText(R.id.label, "MiGasto")
            views.setTextViewText(R.id.balance, "Abre MiGasto")
            views.setTextViewText(R.id.footer, "para ver tu resumen aquí")
            views.setViewVisibility(R.id.bar, View.GONE)
            views.setViewVisibility(R.id.flows, View.GONE)
            return views
        }
        views.setTextViewText(R.id.label, "Disponible")
        views.setTextViewText(R.id.balance, data.balance)
        views.setViewVisibility(R.id.bar, View.VISIBLE)
        views.setProgressBar(R.id.bar, 100, data.percent, false)
        views.setTextViewText(
            R.id.footer,
            if (data.isFromAnotherMonth()) "${data.month} · ábrela para actualizar" else "${data.percent}% · ${data.month}",
        )
        views.setViewVisibility(R.id.flows, if (wide) View.VISIBLE else View.GONE)
        views.setTextViewText(R.id.income, data.income)
        views.setTextViewText(R.id.spent, data.spent)
        return views
    }
}

/** «Últimos movimientos»: 3 filas en tamaño mediano y 6 si se agranda. */
class RecentWidget : MiGastoWidget() {
    private val rows = listOf(
        Row(R.id.row1, R.id.row1_tile, R.id.row1_letter, R.id.row1_title, R.id.row1_dot, R.id.row1_sub, R.id.row1_amount),
        Row(R.id.row2, R.id.row2_tile, R.id.row2_letter, R.id.row2_title, R.id.row2_dot, R.id.row2_sub, R.id.row2_amount),
        Row(R.id.row3, R.id.row3_tile, R.id.row3_letter, R.id.row3_title, R.id.row3_dot, R.id.row3_sub, R.id.row3_amount),
        Row(R.id.row4, R.id.row4_tile, R.id.row4_letter, R.id.row4_title, R.id.row4_dot, R.id.row4_sub, R.id.row4_amount),
        Row(R.id.row5, R.id.row5_tile, R.id.row5_letter, R.id.row5_title, R.id.row5_dot, R.id.row5_sub, R.id.row5_amount),
        Row(R.id.row6, R.id.row6_tile, R.id.row6_letter, R.id.row6_title, R.id.row6_dot, R.id.row6_sub, R.id.row6_amount),
    )

    private data class Row(val row: Int, val tile: Int, val letter: Int, val title: Int, val dot: Int, val sub: Int, val amount: Int)

    override fun render(context: Context, options: Bundle?): RemoteViews {
        val data = HomeWidgets.load(context)
        return HomeWidgets.sized(options, build(context, data, 3), build(context, data, 6), SizeF(0f, 300f))
    }

    private fun build(context: Context, data: Snapshot?, count: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_recent)
        views.setOnClickPendingIntent(R.id.root, HomeWidgets.open(context, "migasto://movements"))
        val movements = data?.recent?.take(count).orEmpty()

        val pending = data?.pending ?: 0
        views.setViewVisibility(R.id.pending, if (pending > 0) View.VISIBLE else View.GONE)
        views.setTextViewText(R.id.pending, if (pending == 1) "1 por confirmar" else "$pending por confirmar")

        views.setViewVisibility(R.id.empty, if (movements.isEmpty()) View.VISIBLE else View.GONE)
        views.setTextViewText(R.id.empty, if (data == null) "Abre MiGasto para ver tus movimientos" else "Aún no hay movimientos")
        views.setViewVisibility(R.id.more, if (count > 3 && movements.isNotEmpty()) View.VISIBLE else View.GONE)
        views.setOnClickPendingIntent(R.id.more, HomeWidgets.open(context, "migasto://movements"))

        rows.forEachIndexed { i, r ->
            val m = movements.getOrNull(i)
            if (m == null) {
                // Con menos movimientos que filas, las que sobran ocupan su lugar sin verse.
                views.setViewVisibility(r.row, if (i < count && movements.isNotEmpty()) View.INVISIBLE else View.GONE)
                return@forEachIndexed
            }
            val tint = HomeWidgets.parseColor(m.color, context.getColor(R.color.widget_ink2))
            views.setViewVisibility(r.row, View.VISIBLE)
            views.setInt(r.tile, "setColorFilter", tint)
            views.setInt(r.tile, "setImageAlpha", 41) // 16 %, como en la app
            views.setTextViewText(r.letter, m.title.take(1).uppercase())
            views.setTextColor(r.letter, tint)
            views.setTextViewText(r.title, m.title)
            views.setViewVisibility(r.dot, if (m.pending) View.VISIBLE else View.GONE)
            views.setTextViewText(r.sub, if (m.pending) "Por confirmar" else m.subtitle)
            views.setTextColor(r.sub, context.getColor(if (m.pending) R.color.widget_warn else R.color.widget_ink2))
            views.setTextViewText(r.amount, m.amount)
            views.setTextColor(r.amount, context.getColor(amountColor(m)))
            views.setOnClickPendingIntent(r.row, HomeWidgets.open(context, "migasto://movement/${Uri.encode(m.id)}"))
        }
        return views
    }

    /** Ingresos en verde, gastos en rojo, entre tus cuentas y por confirmar en gris. */
    private fun amountColor(m: Snapshot.Movement): Int = when {
        m.pending -> R.color.widget_ink2
        m.kind == "ingreso" -> R.color.widget_up
        m.kind == "gasto" -> R.color.widget_down
        else -> R.color.widget_ink2
    }
}

/** «Registrar»: chico abre un gasto nuevo; mediano trae Gasto e Ingreso. */
class QuickAddWidget : MiGastoWidget() {
    override fun render(context: Context, options: Bundle?): RemoteViews {
        val small = RemoteViews(context.packageName, R.layout.widget_quick_add_small).apply {
            setOnClickPendingIntent(R.id.root, HomeWidgets.open(context, "migasto://new"))
        }
        val medium = RemoteViews(context.packageName, R.layout.widget_quick_add).apply {
            setOnClickPendingIntent(R.id.expense, HomeWidgets.open(context, "migasto://new"))
            setOnClickPendingIntent(R.id.income, HomeWidgets.open(context, "migasto://new?type=ingreso"))
        }
        return HomeWidgets.sized(options, small, medium, SizeF(220f, 0f))
    }
}
