package com.example.mi_gasto

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.StyleSpan
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Ventana flotante "Pago detectado".
 *
 * - Gasto: cuenta regresiva de 4 s que se pausa al tocar; al llegar a 0 se guarda.
 * - Ingreso: sin cuenta regresiva. Por defecto no se guarda solo: espera "Guardar
 *   ingreso"; si se ignora, queda en "Por confirmar" dentro de la app. Si en Ajustes
 *   está activado "Guardar ingresos automáticamente", sigue la misma cuenta regresiva
 *   que un gasto.
 *
 * No escribe en la base de datos: deja el pago en [NativeQueue] y Flutter lo guarda.
 */
class OverlayService : Service() {

    private class Palette(night: Boolean) {
        val bg = if (night) 0xFF0F0E13.toInt() else 0xFFF4F3F6.toInt()
        val surface = if (night) 0xFF1B1922.toInt() else 0xFFFFFFFF.toInt()
        val ink = if (night) 0xFFF2F0F5.toInt() else 0xFF16141B.toInt()
        val muted = if (night) 0xFFA5A1B0.toInt() else 0xFF5B5866.toInt()
        val line = if (night) 0xFF2A2733.toInt() else 0xFFE1DFE6.toInt()
        val brand = 0xFF8CE885.toInt()
        val onBrand = 0xFF0F0E13.toInt()
        val brandInk = if (night) 0xFF8CE885.toInt() else 0xFF1E7A36.toInt()
        val income = if (night) 0xFF7FB6FF.toInt() else 0xFF2458C6.toInt()
        val incomeSoft = if (night) 0xFF18233A.toInt() else 0xFFE3EBFA.toInt()
        private val yape = if (night) 0xFF9B4FD6.toInt() else 0xFF742284.toInt()
        private val plin = if (night) 0xFF10BFAF.toInt() else 0xFF00857A.toInt()
        private val gpay = if (night) 0xFF5B9BF8.toInt() else 0xFF1A73E8.toInt()
        private val other = if (night) 0xFF8A8794.toInt() else 0xFF6B6876.toInt()

        fun source(provider: String) = when (provider) {
            "yape" -> yape
            "plin" -> plin
            "googlePay" -> gpay
            else -> other
        }
    }

    private lateinit var palette: Palette
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())
    private var tick: Runnable? = null
    private var dismissIncome: Runnable? = null
    private var paused = false
    private var remainingMs = COUNTDOWN_MS

    private var amount = 0.0
    private var merchant = ""
    private var provider = "manual"
    private var type = "gasto"
    private var category = "otros"
    private var rawText = ""

    private val isIncome get() = type == "ingreso"

    /** Hay cuenta regresiva y se guarda solo: siempre en gastos; en ingresos solo si el usuario lo activó. */
    private val autoSave by lazy { !isIncome || NativeQueue.autoSaveIncome(this) }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_NOT_STICKY

        // Si había otra ventana sin resolver, ese pago queda pendiente en vez de perderse.
        if (overlayView != null) {
            enqueue(confirmed = false)
            removeOverlay()
        }

        amount = intent.getDoubleExtra("amount", 0.0)
        merchant = intent.getStringExtra("merchant") ?: "Desconocido"
        provider = intent.getStringExtra("provider") ?: "manual"
        type = intent.getStringExtra("type") ?: "gasto"
        category = intent.getStringExtra("category") ?: "otros"
        rawText = intent.getStringExtra("rawText") ?: ""

        if (amount <= 0.0) {
            stopSelf()
            return START_NOT_STICKY
        }

        val night = (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
            Configuration.UI_MODE_NIGHT_YES
        palette = Palette(night)
        showOverlay()
        return START_NOT_STICKY
    }

    // ------------------------------------------------------------------ UI

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()

    private fun rounded(color: Int, radiusDp: Int, strokeColor: Int? = null, strokeDp: Float = 0f) =
        GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(radiusDp).toFloat()
            if (strokeColor != null) setStroke((strokeDp * resources.displayMetrics.density).toInt(), strokeColor)
        }

    private fun label(
        text: CharSequence,
        sp: Float,
        color: Int,
        bold: Boolean = false,
    ) = TextView(this).apply {
        this.text = text
        setTextSize(TypedValue.COMPLEX_UNIT_SP, sp)
        setTextColor(color)
        if (bold) setTypeface(null, Typeface.BOLD)
        includeFontPadding = false
    }

    private fun withBold(prefix: String, bold: String): CharSequence =
        SpannableStringBuilder(prefix + bold).apply {
            setSpan(StyleSpan(Typeface.BOLD), prefix.length, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }

    private fun sourceName() = when (provider) {
        "yape" -> "Yape"
        "plin" -> "Plin"
        "googlePay" -> "Google Wallet"
        else -> "Manual"
    }

    private fun button(text: String, weight: Float, fill: Int?, textColor: Int, onClick: () -> Unit) =
        TextView(this).apply {
            this.text = text
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14.5f)
            setTextColor(textColor)
            setTypeface(null, Typeface.BOLD)
            gravity = Gravity.CENTER
            minimumHeight = dp(48)
            isClickable = true
            isFocusable = true
            contentDescription = text
            background = if (fill != null) rounded(fill, 13) else rounded(0x00000000, 13, palette.line, 1.5f)
            layoutParams = LinearLayout.LayoutParams(0, dp(48), weight).apply { marginStart = dp(4); marginEnd = dp(4) }
            setOnClickListener { onClick() }
        }

    private fun pickRow(prefix: String, value: String): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(12), dp(10), dp(12), dp(10))
            background = rounded(palette.bg, 12)
            isClickable = true
            minimumHeight = dp(48)
            contentDescription = "$prefix$value. Cambiar"
            setOnClickListener { openEdit() }
        }
        row.addView(
            label(withBold(prefix, value), 13.5f, palette.ink).apply {
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            },
        )
        row.addView(label("Cambiar", 13f, palette.brandInk, bold = true))
        return row
    }

    private fun spacer(heightDp: Int) = View(this).apply {
        layoutParams = LinearLayout.LayoutParams(1, dp(heightDp))
    }

    private fun showOverlay() {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = rounded(palette.surface, 22)
            elevation = dp(12).toFloat()
            clipToOutline = true
        }

        // Barra de tiempo (solo gastos): se vacía de forma lineal.
        var timeline: View? = null
        if (autoSave) {
            val track = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                weightSum = 1f
                setBackgroundColor(palette.line)
                layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(4))
            }
            timeline = View(this).apply {
                setBackgroundColor(palette.brand)
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f)
            }
            track.addView(timeline)
            card.addView(track)
        }

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(14), dp(16), dp(16))
        }

        // Fuente y hora (+ cuenta regresiva)
        val time = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
        val srcRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        srcRow.addView(View(this).apply {
            background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(palette.source(provider)) }
            layoutParams = LinearLayout.LayoutParams(dp(8), dp(8)).apply { marginEnd = dp(7) }
        })
        srcRow.addView(label("${sourceName()} · $time", 12.5f, palette.muted, bold = true).apply {
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        })
        var countdownText: TextView? = null
        if (autoSave) {
            countdownText = label("Se guarda en 4 s", 12.5f, palette.muted)
            srcRow.addView(countdownText)
        }
        content.addView(srcRow)
        content.addView(spacer(12))

        // Monto
        val amountRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.BOTTOM
        }
        val amountColor = if (isIncome) palette.income else palette.ink
        amountRow.addView(
            label(if (isIncome) "+ S/ " else "S/ ", 19f, amountColor, bold = true),
        )
        amountRow.addView(
            label(String.format(Locale.US, "%,.2f", amount), 38f, amountColor, bold = true).apply {
                contentDescription = String.format(Locale.US, "%,.2f soles", amount)
            },
        )
        content.addView(amountRow)
        content.addView(spacer(4))
        content.addView(label(withBold(if (isIncome) "de " else "a ", merchant), 16f, palette.ink))
        content.addView(spacer(12))

        // Categoría o tipo
        content.addView(
            if (isIncome) pickRow("Tipo: ", ReaderRules.categoryLabel(category))
            else pickRow("Categoría: ", ReaderRules.categoryLabel(category)),
        )
        content.addView(spacer(12))

        if (isIncome) {
            content.addView(
                LinearLayout(this).apply {
                    orientation = LinearLayout.HORIZONTAL
                    setPadding(dp(12), dp(10), dp(12), dp(10))
                    background = rounded(palette.incomeSoft, 12)
                    addView(
                        label(withBold("Es dinero que ", "recibiste") .let {
                            SpannableStringBuilder(it).append(
                                if (autoSave) ". Se guarda solo en unos segundos."
                                else ". No se guarda hasta que lo confirmes.",
                            )
                        }, 13f, palette.ink),
                    )
                },
            )
            content.addView(spacer(12))
        }

        // Acciones
        val actions = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
                .apply { marginStart = -dp(4); marginEnd = -dp(4) }
        }
        if (isIncome) {
            actions.addView(button("Ignorar", 1f, null, palette.ink) { finishWith(confirmed = false) })
            actions.addView(button("Guardar ingreso", 1.4f, palette.income, palette.bg) { finishWith(confirmed = true) })
        } else {
            actions.addView(button("Descartar", 1f, null, palette.ink) { discard() })
            actions.addView(button("Editar", 1f, null, palette.ink) { openEdit() })
            actions.addView(button("Guardar", 1.4f, palette.brand, palette.onBrand) { finishWith(confirmed = true) })
        }
        content.addView(actions)

        // Pie
        var footLeft: TextView? = null
        if (autoSave) {
            content.addView(spacer(12))
            val foot = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            footLeft = label("Toca para pausar", 12f, palette.muted).apply {
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            }
            foot.addView(footLeft)
            foot.addView(label("MiGasto", 12f, palette.muted))
            content.addView(foot)
        }

        card.addView(content)

        // Tocar la ventana pausa la cuenta regresiva.
        card.setOnTouchListener { _, event ->
            if (autoSave && event.action == MotionEvent.ACTION_DOWN && !paused) {
                paused = true
                timeline?.setBackgroundColor(palette.muted)
                footLeft?.text = "En pausa"
                countdownText?.text = "En pausa"
            }
            false
        }

        val root = FrameLayout(this).apply {
            setPadding(dp(10), 0, dp(10), 0)
            addView(card, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT))
        }
        overlayView = root

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            y = statusBarHeight() + dp(8)
        }

        try {
            windowManager?.addView(root, params)
        } catch (e: Exception) {
            // Sin permiso de superposición: el pago queda pendiente en la app.
            overlayView = null
            enqueue(confirmed = false)
            stopSelf()
            return
        }

        // Entra desde arriba (se omite si las animaciones están desactivadas).
        val animationsOn = Settings.Global.getFloat(contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) > 0f
        if (animationsOn) {
            card.translationY = -dp(120).toFloat()
            card.animate().translationY(0f).setDuration(200).start()
        }

        if (!autoSave) {
            // Un ingreso sin respuesta queda pendiente después de un rato.
            dismissIncome = Runnable { finishWith(confirmed = false) }
            handler.postDelayed(dismissIncome!!, INCOME_TIMEOUT_MS)
        } else {
            paused = false
            remainingMs = COUNTDOWN_MS
            tick = object : Runnable {
                override fun run() {
                    if (!paused) {
                        remainingMs -= TICK_MS
                        if (remainingMs <= 0) {
                            finishWith(confirmed = true)
                            return
                        }
                        val bar = timeline?.layoutParams as? LinearLayout.LayoutParams
                        bar?.let {
                            it.weight = remainingMs.toFloat() / COUNTDOWN_MS
                            timeline?.layoutParams = it
                        }
                        val seconds = (remainingMs + 999) / 1000
                        countdownText?.text = "Se guarda en $seconds s"
                    }
                    handler.postDelayed(this, TICK_MS)
                }
            }
            handler.postDelayed(tick!!, TICK_MS)
        }
    }

    private fun statusBarHeight(): Int {
        val id = resources.getIdentifier("status_bar_height", "dimen", "android")
        return if (id > 0) resources.getDimensionPixelSize(id) else dp(24)
    }

    // ------------------------------------------------------------- acciones

    /** Deja el pago en la cola para que Flutter lo guarde (confirmado o pendiente). */
    private fun enqueue(confirmed: Boolean) {
        if (amount <= 0.0) return
        NativeQueue.enqueue(this, amount, merchant, provider, type, rawText, confirmed)
        MyAccessibilityService.notifyFlutterSaved()
    }

    private fun finishWith(confirmed: Boolean) {
        enqueue(confirmed)
        close()
    }

    private fun discard() = close()

    /**
     * "Editar" / "Cambiar": el pago queda pendiente (nada se guarda solo) y se abre
     * la app para revisarlo en Movimientos > Por confirmar.
     */
    private fun openEdit() {
        enqueue(confirmed = false)
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        if (openIntent != null) startActivity(openIntent)
        close()
    }

    private fun close() {
        removeOverlay()
        stopSelf()
    }

    private fun removeOverlay() {
        tick?.let { handler.removeCallbacks(it) }
        dismissIncome?.let { handler.removeCallbacks(it) }
        tick = null
        dismissIncome = null
        overlayView?.let {
            try {
                windowManager?.removeView(it)
            } catch (e: Exception) {
                // Ya no estaba en pantalla.
            }
        }
        overlayView = null
    }

    override fun onDestroy() {
        removeOverlay()
        super.onDestroy()
    }

    companion object {
        private const val COUNTDOWN_MS = 4000L
        private const val TICK_MS = 100L
        private const val INCOME_TIMEOUT_MS = 60_000L
    }
}
