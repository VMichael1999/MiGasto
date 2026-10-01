package com.example.mi_gasto

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Canvas
import android.graphics.ColorFilter
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.TextUtils
import android.text.style.StyleSpan
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
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
 * - Gasto: cuenta regresiva de 4 s dentro del botón "Guardar" (se vacía de color fuerte
 *   a tenue); se pausa al tocar la ventana y, al llegar a 0, se guarda.
 * - Deslizar la ventana hacia arriba hace lo mismo que su primer botón (Descartar / Ignorar).
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
        // Botón "Guardar": color fuerte que se vacía hasta el tenue durante la cuenta regresiva.
        val saveStrong = if (night) 0xFF8CE885.toInt() else 0xFF8CE885.toInt()
        val saveSoft = if (night) 0xFF4F8A4C.toInt() else 0xFFD7F3D4.toInt()
        val incomeStrong = if (night) 0xFF7FB6FF.toInt() else 0xFF86B4F5.toInt()
        val incomeFaint = if (night) 0xFF4A7DB8.toInt() else 0xFFD5E4FB.toInt()
        val onSave = 0xFF0F0E13.toInt()
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
    private var closing = false
    private var remainingMs = COUNTDOWN_MS
    private var fill: FillDrawable? = null
    private var timeLabel: TextView? = null

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
            if (!closing) enqueue(confirmed = false)
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

    /** Fondo del botón "Guardar": [strong] llena hasta [progress] y [soft] el resto. */
    private class FillDrawable(
        private val strong: Int,
        private val soft: Int,
        private val radius: Float,
    ) : Drawable() {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val clip = Path()
        var progress = 1f
            set(value) {
                field = value.coerceIn(0f, 1f)
                invalidateSelf()
            }

        override fun draw(canvas: Canvas) {
            val r = RectF(bounds)
            clip.reset()
            clip.addRoundRect(r, radius, radius, Path.Direction.CW)
            canvas.save()
            canvas.clipPath(clip)
            paint.color = soft
            canvas.drawRect(r, paint)
            paint.color = strong
            canvas.drawRect(r.left, r.top, r.left + r.width() * progress, r.bottom, paint)
            canvas.restore()
        }

        override fun setAlpha(alpha: Int) {}
        override fun setColorFilter(colorFilter: ColorFilter?) {}
        @Suppress("OVERRIDE_DEPRECATION")
        override fun getOpacity() = android.graphics.PixelFormat.TRANSLUCENT
    }

    /** Tarjeta que se descarta deslizándola hacia arriba y pausa la cuenta al tocarla. */
    private inner class SwipeCard(context: Context) : LinearLayout(context) {
        private val slop = ViewConfiguration.get(context).scaledTouchSlop
        private var downY = 0f

        override fun dispatchTouchEvent(e: MotionEvent): Boolean {
            if (e.actionMasked == MotionEvent.ACTION_DOWN) {
                downY = e.rawY
                pauseCountdown()
            }
            return super.dispatchTouchEvent(e)
        }

        override fun onInterceptTouchEvent(e: MotionEvent): Boolean =
            e.actionMasked == MotionEvent.ACTION_MOVE && downY - e.rawY > slop

        override fun onTouchEvent(e: MotionEvent): Boolean {
            when (e.actionMasked) {
                MotionEvent.ACTION_MOVE -> translationY = minOf(0f, e.rawY - downY)
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL ->
                    if (translationY < -dp(56)) onSwiped()
                    else animate().translationY(0f).setDuration(150).start()
            }
            return true
        }
    }

    private fun pauseCountdown() {
        if (!autoSave || paused || closing) return
        paused = true
        timeLabel?.text = "En pausa"
    }

    private fun button(text: String, weight: Float, textColor: Int, onClick: () -> Unit) =
        TextView(this).apply {
            this.text = text
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setTextColor(textColor)
            setTypeface(null, Typeface.BOLD)
            gravity = Gravity.CENTER
            isClickable = true
            isFocusable = true
            contentDescription = text
            layoutParams = LinearLayout.LayoutParams(0, dp(52), weight).apply { marginStart = dp(3); marginEnd = dp(3) }
            setOnClickListener { onClick() }
        }

    /** Botón principal: con cuenta regresiva se vacía de color fuerte a tenue. */
    private fun primaryButton(text: String, strong: Int, soft: Int, countdown: Boolean, onClick: () -> Unit): View =
        button(text, 1.7f, palette.onSave, onClick).apply {
            if (countdown) {
                val drawable = FillDrawable(strong, soft, dp(16).toFloat())
                fill = drawable
                background = drawable
                contentDescription = "$text. Se guarda solo en unos segundos"
            } else {
                background = rounded(strong, 16)
            }
        }

    private fun quietButton(text: String, onClick: () -> Unit): View =
        button(text, 1f, palette.muted, onClick).apply {
            background = rounded(0x00000000, 16)
        }

    private fun chip(text: CharSequence, textColor: Int, fill: Int, onClick: (() -> Unit)? = null) =
        TextView(this).apply {
            this.text = text
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12.5f)
            setTextColor(textColor)
            setTypeface(null, Typeface.BOLD)
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(10), dp(5), dp(10), dp(5))
            background = rounded(fill, 20)
            includeFontPadding = false
            if (onClick != null) {
                isClickable = true
                minimumHeight = dp(32)
                setOnClickListener { onClick() }
            }
        }

    private fun spacer(heightDp: Int) = View(this).apply {
        layoutParams = LinearLayout.LayoutParams(1, dp(heightDp))
    }

    private fun showOverlay() {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        closing = false
        fill = null

        val card = SwipeCard(this).apply {
            orientation = LinearLayout.VERTICAL
            background = rounded(palette.surface, 28)
            elevation = dp(16).toFloat()
            clipToOutline = true
            setPadding(dp(18), dp(16), dp(18), dp(14))
        }

        // Fuente (etiqueta de su color) y hora / estado
        val sourceColor = palette.source(provider)
        val top = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        top.addView(
            chip(sourceName(), sourceColor, (sourceColor and 0x00FFFFFF) or 0x24000000),
        )
        top.addView(View(this).apply { layoutParams = LinearLayout.LayoutParams(0, 1, 1f) })
        val time = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
        timeLabel = label(time, 12.5f, palette.muted, bold = true)
        top.addView(timeLabel)
        card.addView(top)
        card.addView(spacer(14))

        // Monto
        val amountColor = if (isIncome) palette.income else palette.ink
        val amountRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.BOTTOM
        }
        amountRow.addView(
            label(if (isIncome) "+ S/ " else "S/ ", 20f, amountColor, bold = true).apply {
                setPadding(0, 0, 0, dp(5))
            },
        )
        amountRow.addView(
            label(String.format(Locale.US, "%,.2f", amount), 42f, amountColor, bold = true).apply {
                contentDescription = String.format(Locale.US, "%,.2f soles", amount)
            },
        )
        card.addView(amountRow)
        card.addView(spacer(6))

        // Comercio (una sola línea) y categoría
        card.addView(
            label(withBold(if (isIncome) "de " else "a ", NativeQueue.displayName(this, merchant)), 16f, palette.ink).apply {
                maxLines = 1
                ellipsize = TextUtils.TruncateAt.END
            },
        )
        card.addView(spacer(12))
        val chipRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val categoryName = ReaderRules.categoryLabel(category)
        chipRow.addView(
            chip("$categoryName  ›", palette.ink, palette.bg) { openEdit() }.apply {
                contentDescription = "${if (isIncome) "Tipo" else "Categoría"}: $categoryName. Cambiar"
            },
        )
        card.addView(chipRow)
        card.addView(spacer(16))

        // Acciones
        val actions = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
                .apply { marginStart = -dp(3); marginEnd = -dp(3) }
        }
        if (isIncome) {
            actions.addView(quietButton("Ignorar") { finishWith(confirmed = false) })
            actions.addView(
                primaryButton("Guardar ingreso", palette.incomeStrong, palette.incomeFaint, autoSave) {
                    finishWith(confirmed = true)
                },
            )
        } else {
            actions.addView(quietButton("Descartar") { discard() })
            actions.addView(quietButton("Editar") { openEdit() })
            actions.addView(
                primaryButton("Guardar", palette.saveStrong, palette.saveSoft, true) {
                    finishWith(confirmed = true)
                },
            )
        }
        card.addView(actions)

        val root = FrameLayout(this).apply {
            setPadding(dp(12), 0, dp(12), dp(12))
            clipChildren = false
            clipToPadding = false
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
            y = statusBarHeight() + dp(6)
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

        vibrateOnce()

        // Entra desde arriba (se omite si las animaciones están desactivadas).
        if (animationsOn()) {
            card.translationY = -dp(140).toFloat()
            card.alpha = 0f
            card.animate().translationY(0f).alpha(1f).setDuration(260)
                .setInterpolator(android.view.animation.DecelerateInterpolator(1.6f)).start()
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
                            fill?.progress = 0f
                            finishWith(confirmed = true)
                            return
                        }
                        fill?.progress = remainingMs.toFloat() / COUNTDOWN_MS
                    }
                    handler.postDelayed(this, TICK_MS)
                }
            }
            handler.postDelayed(tick!!, TICK_MS)
        }
    }

    private fun animationsOn() =
        Settings.Global.getFloat(contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) > 0f

    /** Vibración corta al aparecer, para notarla sin mirar el teléfono. */
    private fun vibrateOnce() {
        try {
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return
            if (!vibrator.hasVibrator()) return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createOneShot(25, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(25)
            }
        } catch (e: Exception) {
            // Sin vibración: no es esencial.
        }
    }

    /** Deslizar hacia arriba: igual que el primer botón (Descartar en gastos, Ignorar en ingresos). */
    private fun onSwiped() {
        if (isIncome) finishWith(confirmed = false) else discard()
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
        if (closing) return
        closing = true
        tick?.let { handler.removeCallbacks(it) }
        dismissIncome?.let { handler.removeCallbacks(it) }
        val view = overlayView
        val card = (view as? FrameLayout)?.getChildAt(0)
        if (card != null && animationsOn()) {
            card.animate().translationY(-dp(140).toFloat()).alpha(0f).setDuration(180)
                .withEndAction {
                    // Si llegó otro pago mientras salía, esa ventana nueva sigue.
                    if (overlayView === view) {
                        removeOverlay()
                        stopSelf()
                    }
                }.start()
        } else {
            removeOverlay()
            stopSelf()
        }
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
