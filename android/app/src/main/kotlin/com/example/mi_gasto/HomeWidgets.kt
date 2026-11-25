package com.example.mi_gasto

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.text.style.RelativeSizeSpan
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Widgets de la pantalla de inicio. Muestran lo que Flutter deja con `updateHomeWidgets`
 * (`WidgetSnapshot` en lib/shared/widget_snapshot.dart): no calculan nada, así las cifras son
 * las mismas que en Inicio y que en el iPhone. El diseño sigue las maquetas aprobadas
 * («Widgets MiGasto»): sin logo, saldo anclado abajo y anillo del mes. Los widgets de Android no
 * pueden usar fuentes de la app, así que van con la del sistema en los mismos pesos.
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
     * Elige las vistas según el tamaño: en Android 12 o más se le dan todas al sistema y él usa
     * la que entra; antes se usa el tamaño que informa el launcher.
     */
    fun sized(options: Bundle?, variants: List<Pair<SizeF, RemoteViews>>): RemoteViews {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) return RemoteViews(variants.toMap())
        val width = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 0
        val height = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT) ?: 0
        if (width == 0 && height == 0) return variants.last().second
        return variants.lastOrNull { (size, _) -> width >= size.width && height >= size.height }?.second
            ?: variants.first().second
    }

    /** El anillo del mes, dibujado (RemoteViews no deja dibujar): pista tenue y avance redondeado. */
    fun ring(context: Context, percent: Int, sizeDp: Float, strokeDp: Float, dashed: Boolean = false): Bitmap {
        val density = context.resources.displayMetrics.density
        val size = (sizeDp * density).toInt().coerceAtLeast(1)
        val stroke = strokeDp * density
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val rect = RectF(stroke / 2, stroke / 2, size - stroke / 2, size - stroke / 2)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = stroke
            color = Color.argb(64, 255, 255, 255)
            if (dashed) pathEffect = DashPathEffect(floatArrayOf(4 * density, 5 * density), 0f)
        }
        canvas.drawArc(rect, 0f, 360f, false, paint)
        if (!dashed && percent > 0) {
            paint.pathEffect = null
            paint.color = Color.WHITE
            paint.strokeCap = Paint.Cap.ROUND
            canvas.drawArc(rect, -90f, 360f * percent.coerceIn(0, 100) / 100f, false, paint)
        }
        return bitmap
    }

    /** «S/ 16,056.54» con «S/» y los decimales más chicos y tenues, como en Inicio. */
    fun balance(data: Snapshot): CharSequence {
        val text = SpannableStringBuilder()
        val faint = Color.argb(204, 255, 255, 255)
        fun part(value: String, scale: Float?) {
            val start = text.length
            text.append(value)
            if (scale != null) {
                text.setSpan(RelativeSizeSpan(scale), start, text.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
                text.setSpan(ForegroundColorSpan(faint), start, text.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            }
        }
        part("${data.balanceSign}S/ ", 0.52f)
        part(data.balanceInt, null)
        part(data.balanceDec, 0.6f)
        return text
    }

    fun parseColor(hex: String, fallback: Int): Int = try {
        Color.parseColor(hex)
    } catch (e: IllegalArgumentException) {
        fallback
    }

    /** Ícono de cada categoría, el mismo dibujo que en la app. */
    fun categoryIcon(icon: String): Int = when (icon) {
        "alimentacion" -> R.drawable.widget_cat_alimentacion
        "transporte" -> R.drawable.widget_cat_transporte
        "servicios" -> R.drawable.widget_cat_servicios
        "compras" -> R.drawable.widget_cat_compras
        "entretenimiento" -> R.drawable.widget_cat_entretenimiento
        "sueldo" -> R.drawable.widget_cat_sueldo
        "transferenciaRecibida", "propia" -> R.drawable.widget_cat_propia
        "venta" -> R.drawable.widget_cat_venta
        "otrosIngresos" -> R.drawable.widget_cat_otros_ingresos
        else -> R.drawable.widget_cat_otros
    }

    /** «HOY», «AYER» o «DOM 22 NOV», según la fecha del teléfono (no la del resumen). */
    fun dayLabel(key: String, now: Date = Date()): String {
        val date = try {
            SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(key)
        } catch (e: Exception) {
            null
        } ?: return key.uppercase()
        val day = Calendar.getInstance().apply { time = date }
        val today = Calendar.getInstance().apply { time = now }
        fun same(a: Calendar, b: Calendar) = a.get(Calendar.YEAR) == b.get(Calendar.YEAR) && a.get(Calendar.DAY_OF_YEAR) == b.get(Calendar.DAY_OF_YEAR)
        if (same(day, today)) return "HOY"
        today.add(Calendar.DAY_OF_YEAR, -1)
        if (same(day, today)) return "AYER"
        return SimpleDateFormat("EEE d MMM", Locale("es", "PE")).format(date).replace(".", "").uppercase()
    }
}

/** Lo que muestran los widgets (el JSON de `WidgetSnapshot`). */
data class Snapshot(
    val monthKey: String,
    val month: String,
    val monthShort: String,
    val balanceSign: String,
    val balanceInt: String,
    val balanceDec: String,
    val negative: Boolean,
    val income: String,
    val spent: String,
    val todaySpent: String,
    val percent: Int,
    val pending: Int,
    val recent: List<Movement>,
    val days: Map<String, String>,
) {
    data class Movement(
        val id: String,
        val title: String,
        val subtitle: String,
        val amount: String,
        val kind: String,
        val icon: String,
        val color: String,
        val pending: Boolean,
        val day: String,
    )

    /** Si el resumen es de un mes anterior (no se abrió la app desde entonces). */
    fun isFromAnotherMonth(now: Date = Date()): Boolean =
        monthKey.isNotEmpty() && monthKey != SimpleDateFormat("yyyy-MM", Locale.US).format(now)

    companion object {
        /** `null` si no hay datos o son de un formato anterior (la app los reenvía al abrirse). */
        fun parse(json: String): Snapshot? = try {
            val o = JSONObject(json)
            if (o.optInt("v") < 2) {
                null
            } else {
                val list = o.optJSONArray("recent")
                val days = o.optJSONObject("days")
                Snapshot(
                    monthKey = o.optString("monthKey"),
                    month = o.optString("month"),
                    monthShort = o.optString("monthShort"),
                    balanceSign = o.optString("balanceSign"),
                    balanceInt = o.optString("balanceInt", "0"),
                    balanceDec = o.optString("balanceDec", ".00"),
                    negative = o.optBoolean("negative"),
                    income = o.optString("income", "S/ 0.00"),
                    spent = o.optString("spent", "S/ 0.00"),
                    todaySpent = o.optString("todaySpent", "S/ 0.00"),
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
                                icon = it.optString("icon"),
                                color = it.optString("color"),
                                pending = it.optBoolean("pending"),
                                day = it.optString("day"),
                            )
                        }
                    },
                    days = days?.keys()?.asSequence()?.associateWith { days.optString(it) }.orEmpty(),
                )
            }
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

/** «Resumen del mes»: la tarjeta de balance de Inicio, con el anillo del mes. */
class SummaryWidget : MiGastoWidget() {
    override fun render(context: Context, options: Bundle?): RemoteViews {
        val data = HomeWidgets.load(context)
        return HomeWidgets.sized(
            options,
            listOf(
                SizeF(0f, 0f) to build(context, data, medium = false),
                SizeF(220f, 0f) to build(context, data, medium = true),
            ),
        )
    }

    private fun build(context: Context, data: Snapshot?, medium: Boolean): RemoteViews {
        val views = RemoteViews(context.packageName, if (medium) R.layout.widget_summary else R.layout.widget_summary_small)
        views.setOnClickPendingIntent(android.R.id.background, HomeWidgets.open(context, "migasto://dashboard"))
        val ringDp = if (medium) 58f else 46f
        val strokeDp = if (medium) 6f else 5f

        if (data == null) {
            // Recién puesto: nada de «S/ 0.00» inventado, se pide abrir la app.
            views.setImageViewBitmap(R.id.ring, HomeWidgets.ring(context, 0, ringDp, strokeDp, dashed = true))
            views.setTextViewText(R.id.ring_text, "")
            views.setViewVisibility(R.id.refresh, View.GONE)
            views.setTextViewText(R.id.caption, "Abre MiGasto para ver tu saldo aquí")
            views.setTextViewTextSize(R.id.caption, android.util.TypedValue.COMPLEX_UNIT_SP, 15f)
            views.setTextColor(R.id.caption, Color.WHITE)
            views.setViewVisibility(R.id.balance, View.GONE)
            if (medium) views.setViewVisibility(R.id.flows, View.GONE) else views.setTextViewText(R.id.month, "")
            return views
        }

        val stale = data.isFromAnotherMonth()
        val dim = if (stale) 140 else 255
        views.setImageViewBitmap(R.id.ring, HomeWidgets.ring(context, data.percent, ringDp, strokeDp))
        views.setInt(R.id.ring, "setImageAlpha", dim)
        views.setTextViewText(R.id.ring_text, "${data.percent}%")
        views.setTextColor(R.id.ring_text, Color.argb(dim, 255, 255, 255))
        views.setViewVisibility(R.id.balance, View.VISIBLE)
        views.setTextViewText(R.id.balance, HomeWidgets.balance(data))
        views.setTextColor(R.id.balance, Color.argb(if (stale) 153 else 255, 255, 255, 255))

        // «Disponible», «Te pasaste» o, con un mes viejo, «Toca para actualizar».
        views.setViewVisibility(R.id.refresh, if (stale) View.VISIBLE else View.GONE)
        val label = if (data.negative) "Te pasaste" else "Disponible"
        views.setTextViewText(
            R.id.caption,
            when {
                stale -> "Toca para actualizar"
                medium -> "$label · ${data.month}"
                else -> label
            },
        )
        views.setTextColor(R.id.caption, if (stale) Color.WHITE else context.getColor(R.color.widget_white_82))

        if (medium) {
            views.setViewVisibility(R.id.flows, View.VISIBLE)
            views.setTextViewText(R.id.income, data.income)
            views.setTextViewText(R.id.spent, data.spent)
        } else {
            views.setTextViewText(R.id.month, data.monthShort)
        }
        return views
    }
}

/** «Últimos movimientos»: 3 filas en 4 × 2 y, al agrandarlo, las que entren con el título de cada día. */
class RecentWidget : MiGastoWidget() {
    private data class Slot(
        val slot: Int, val day: Int, val dayLabel: Int, val dayTotal: Int,
        val row: Int, val tile: Int, val icon: Int, val title: Int, val sub: Int, val amount: Int,
    )

    private val slots = listOf(
        Slot(R.id.slot1, R.id.day1, R.id.day1_label, R.id.day1_total, R.id.row1, R.id.row1_tile, R.id.row1_icon, R.id.row1_title, R.id.row1_sub, R.id.row1_amount),
        Slot(R.id.slot2, R.id.day2, R.id.day2_label, R.id.day2_total, R.id.row2, R.id.row2_tile, R.id.row2_icon, R.id.row2_title, R.id.row2_sub, R.id.row2_amount),
        Slot(R.id.slot3, R.id.day3, R.id.day3_label, R.id.day3_total, R.id.row3, R.id.row3_tile, R.id.row3_icon, R.id.row3_title, R.id.row3_sub, R.id.row3_amount),
        Slot(R.id.slot4, R.id.day4, R.id.day4_label, R.id.day4_total, R.id.row4, R.id.row4_tile, R.id.row4_icon, R.id.row4_title, R.id.row4_sub, R.id.row4_amount),
        Slot(R.id.slot5, R.id.day5, R.id.day5_label, R.id.day5_total, R.id.row5, R.id.row5_tile, R.id.row5_icon, R.id.row5_title, R.id.row5_sub, R.id.row5_amount),
        Slot(R.id.slot6, R.id.day6, R.id.day6_label, R.id.day6_total, R.id.row6, R.id.row6_tile, R.id.row6_icon, R.id.row6_title, R.id.row6_sub, R.id.row6_amount),
    )

    override fun render(context: Context, options: Bundle?): RemoteViews {
        val data = HomeWidgets.load(context)
        // Alto disponible para las filas en cada tamaño (alto del widget menos bordes, título y botón).
        return HomeWidgets.sized(
            options,
            listOf(
                SizeF(0f, 0f) to build(context, data, budgetDp = null, compactRows = 3),
                SizeF(0f, 220f) to build(context, data, budgetDp = null, compactRows = 4),
                SizeF(0f, 300f) to build(context, data, budgetDp = 204f),
                SizeF(0f, 380f) to build(context, data, budgetDp = 284f),
                SizeF(0f, 460f) to build(context, data, budgetDp = 364f),
            ),
        )
    }

    /** `budgetDp` nulo: tamaño mediano, `compactRows` filas sin títulos de día ni «Ver todos». */
    private fun build(context: Context, data: Snapshot?, budgetDp: Float?, compactRows: Int = 3): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_recent)
        views.setOnClickPendingIntent(android.R.id.background, HomeWidgets.open(context, "migasto://movements"))
        views.setTextViewTextSize(R.id.title, android.util.TypedValue.COMPLEX_UNIT_SP, if (budgetDp == null) 14f else 15f)

        val pending = data?.pending ?: 0
        views.setViewVisibility(R.id.pending, if (pending > 0) View.VISIBLE else View.GONE)
        views.setTextViewText(R.id.pending, if (pending == 1) "1 por confirmar" else "$pending por confirmar")

        val movements = data?.recent.orEmpty()
        val empty = movements.isEmpty()
        views.setViewVisibility(R.id.empty, if (empty) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.list, if (empty) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.more, if (!empty && budgetDp != null) View.VISIBLE else View.GONE)
        views.setOnClickPendingIntent(R.id.more, HomeWidgets.open(context, "migasto://movements"))
        if (data == null) {
            views.setTextViewText(R.id.empty_text, "Abre MiGasto para ver tus movimientos aquí")
            views.setViewVisibility(R.id.empty_button, View.GONE)
        } else {
            views.setTextViewText(R.id.empty_text, "Aún no hay movimientos este mes")
            views.setViewVisibility(R.id.empty_button, View.VISIBLE)
            views.setOnClickPendingIntent(R.id.empty_button, HomeWidgets.open(context, "migasto://new"))
        }

        // Filas que entran: 40 dp cada una, más 24 dp por el título de cada día nuevo.
        var used = 0f
        var lastDay: String? = null
        slots.forEachIndexed { i, s ->
            val m = movements.getOrNull(i)
            val newDay = budgetDp != null && m != null && m.day != lastDay
            val cost = if (budgetDp == null) 1f else 40f + if (newDay) 24f else 0f
            val fits = m != null && (if (budgetDp == null) i < compactRows else used + cost <= budgetDp)
            if (!fits || m == null) {
                views.setViewVisibility(s.slot, View.GONE)
                // Una vez que una no entra, tampoco las siguientes.
                used = Float.MAX_VALUE / 2
                return@forEachIndexed
            }
            used += cost
            lastDay = m.day
            views.setViewVisibility(s.slot, View.VISIBLE)
            views.setViewVisibility(s.day, if (newDay) View.VISIBLE else View.GONE)
            if (newDay) {
                views.setTextViewText(s.dayLabel, HomeWidgets.dayLabel(m.day))
                views.setTextViewText(s.dayTotal, data?.days?.get(m.day).orEmpty())
            }
            val tint = if (m.icon == "propia") context.getColor(R.color.widget_slate)
            else HomeWidgets.parseColor(m.color, context.getColor(R.color.widget_ink2))
            views.setInt(s.tile, "setColorFilter", tint)
            views.setInt(s.tile, "setImageAlpha", 41) // 16 %, como en la app
            views.setImageViewResource(s.icon, HomeWidgets.categoryIcon(m.icon))
            views.setInt(s.icon, "setColorFilter", tint)
            views.setTextViewText(s.title, m.title)
            views.setTextViewText(s.sub, if (m.pending) "Por confirmar" else m.subtitle)
            views.setTextColor(s.sub, context.getColor(if (m.pending) R.color.widget_warn else R.color.widget_ink2))
            views.setTextViewText(s.amount, m.amount)
            views.setTextColor(s.amount, context.getColor(amountColor(m)))
            views.setOnClickPendingIntent(s.row, HomeWidgets.open(context, "migasto://movement/${Uri.encode(m.id)}"))
        }
        return views
    }

    /** Ingresos en verde, gastos en rojo; entre tus cuentas y lo que espera confirmación, en gris. */
    private fun amountColor(m: Snapshot.Movement): Int = when {
        m.pending -> R.color.widget_ink2
        m.kind == "ingreso" -> R.color.widget_up_text
        m.kind == "gasto" -> R.color.widget_down_text
        else -> R.color.widget_ink2
    }
}

/** «Registrar»: chico abre un gasto nuevo; mediano trae lo gastado hoy y Gasto e Ingreso. */
class QuickAddWidget : MiGastoWidget() {
    override fun render(context: Context, options: Bundle?): RemoteViews {
        val data = HomeWidgets.load(context)
        val small = RemoteViews(context.packageName, R.layout.widget_quick_add_small).apply {
            setOnClickPendingIntent(android.R.id.background, HomeWidgets.open(context, "migasto://new"))
        }
        val medium = RemoteViews(context.packageName, R.layout.widget_quick_add).apply {
            setOnClickPendingIntent(R.id.expense, HomeWidgets.open(context, "migasto://new"))
            setOnClickPendingIntent(R.id.income, HomeWidgets.open(context, "migasto://new?type=ingreso"))
            setTextViewText(R.id.today_label, if (data == null) "Registrar" else "Hoy gastaste")
            setViewVisibility(R.id.today, if (data == null) View.GONE else View.VISIBLE)
            setTextViewText(R.id.today, data?.todaySpent.orEmpty())
        }
        return HomeWidgets.sized(options, listOf(SizeF(0f, 0f) to small, SizeF(220f, 0f) to medium))
    }
}
