package com.example.mi_gasto

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.TextUtils
import android.text.style.ForegroundColorSpan
import android.text.style.RelativeSizeSpan
import android.text.style.TypefaceSpan
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
 * Ventana flotante "Pago detectado", con el mismo diseño oscuro y violeta que el aviso dentro
 * de la app (`OverlayTimerWidget`).
 *
 * No se cierra sola ni guarda nada por su cuenta: el usuario decide.
 * - Gasto: Descartar, Editar o Guardar.
 * - Ingreso: Ignorar (queda en "Por confirmar") o Guardar ingreso.
 * - Deslizarla hacia arriba la quita de la pantalla y el pago queda en "Por confirmar".
 * - Si llega otro pago con la ventana abierta, el anterior también queda en "Por confirmar".
 *
 * No escribe en la base de datos: deja el pago en [NativeQueue] y Flutter lo guarda.
 */
class OverlayService : Service() {

    /** Colores de `MgColors` (lib/core/theme/mg_colors.dart). La app es oscura siempre. */
    private object Mg {
        const val CARD = 0xFF15151B.toInt() // opaca: sobre otras apps el texto de atrás estorba
        const val SOFT = 0xFF1F1F27.toInt()
        const val LINE = 0xFF26262F.toInt()
        const val BORDER = 0x14FFFFFF // blanco al 8 %
        const val INK = 0xFFF4F3F7.toInt()
        const val INK2 = 0xFF8B8898.toInt()
        const val INK3 = 0xFF585666.toInt()
        const val ACC = 0xFF7C5CFF.toInt()
        const val ACC2 = 0xFF9B82FF.toInt()
        const val ACC_SOFT = 0xFF1E1935.toInt()
        const val ACC_LINE = 0xFF3A2F6B.toInt()
        const val UP = 0xFF2FD98A.toInt()
        const val WHITE = 0xFFFFFFFF.toInt()
        const val BLACK = 0xFF000000.toInt()

        fun source(provider: String) = when (provider) {
            "yape" -> 0xFF7C5CFF.toInt()
            "plin" -> 0xFF00D1FF.toInt()
            "googlePay" -> 0xFF4285F4.toInt()
            "tarjeta" -> 0xFFFF8A3D.toInt()
            else -> ACC2
        }

        fun category(id: String) = when (id) {
            "alimentacion" -> 0xFFFF5C8A.toInt()
            "transporte" -> 0xFF22D3EE.toInt()
            "compras" -> 0xFFF5A524.toInt()
            "servicios" -> 0xFF7C5CFF.toInt()
            "entretenimiento" -> 0xFFFF8A3D.toInt()
            "sueldo" -> 0xFF2FD98A.toInt()
            "transferenciaRecibida" -> 0xFF34D399.toInt()
            "venta" -> 0xFF60A5FA.toInt()
            else -> 0xFF94A3B8.toInt()
        }

        /** [color] con la opacidad [alpha] (0–1). */
        fun alpha(color: Int, alpha: Float) = (color and 0x00FFFFFF) or ((alpha * 255).toInt() shl 24)
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var closing = false

    private var amount = 0.0
    private var merchant = ""
    private var provider = "manual"
    private var type = "gasto"
    private var category = "otros"
    private var rawText = ""

    /** Id del movimiento pendiente que se guardó al abrir la ventana; los botones se refieren a él. */
    private var ref = ""

    private val isIncome get() = type == "ingreso"

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_NOT_STICKY

        // Si había otra ventana sin resolver, ese pago ya está guardado como pendiente: solo se
        // cierra la ventana.
        if (overlayView != null) removeOverlay()

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

        // El pago se guarda como pendiente apenas aparece la ventana, con la hora en que llegó:
        // si el sistema cierra la ventana o se apaga el teléfono antes de que el usuario elija,
        // queda en Movimientos > Por confirmar en vez de perderse.
        ref = java.util.UUID.randomUUID().toString()
        NativeQueue.enqueue(this, amount, merchant, provider, type, rawText, confirmed = false, ref = ref)

        showOverlay()
        return START_NOT_STICKY
    }

    // ------------------------------------------------------------------ UI

    private fun dp(value: Float) = (value * resources.displayMetrics.density).toInt()
    private fun dp(value: Int) = dp(value.toFloat())

    private fun rounded(color: Int, radiusDp: Float, strokeColor: Int? = null) =
        GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(radiusDp).toFloat()
            if (strokeColor != null) setStroke(dp(1).coerceAtLeast(1), strokeColor)
        }

    /** Fondo con onda al tocar, como los botones de la app. */
    private fun pressable(fill: Drawable, rippleColor: Int = 0x33FFFFFF) =
        RippleDrawable(ColorStateList.valueOf(rippleColor), fill, null)

    /** Peso de letra como en la app (600 seminegrita, 700 negrita, 800 extra). */
    private fun font(weight: Int): Typeface = when {
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.P -> Typeface.create(Typeface.DEFAULT, weight, false)
        weight >= 700 -> Typeface.DEFAULT_BOLD
        weight >= 500 -> Typeface.create("sans-serif-medium", Typeface.NORMAL)
        else -> Typeface.DEFAULT
    }

    private fun label(text: CharSequence, sp: Float, color: Int, weight: Int = 400) =
        TextView(this).apply {
            this.text = text
            setTextSize(TypedValue.COMPLEX_UNIT_SP, sp)
            setTextColor(color)
            typeface = font(weight)
            includeFontPadding = false
        }

    /** «prefijo **resaltado** resto»: el resaltado va en [color] y negrita. */
    private fun highlighted(prefix: String, bold: String, color: Int, suffix: String = ""): CharSequence =
        SpannableStringBuilder(prefix + bold + suffix).apply {
            val end = prefix.length + bold.length
            setSpan(ForegroundColorSpan(color), prefix.length, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                setSpan(TypefaceSpan(font(700)), prefix.length, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            } else {
                setSpan(android.text.style.StyleSpan(Typeface.BOLD), prefix.length, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            }
        }

    private fun sourceName() = when (provider) {
        "yape" -> "Yape"
        "plin" -> "Plin"
        "googlePay" -> "Google Wallet"
        "tarjeta" -> "Tarjeta"
        else -> "Manual"
    }

    /** Monto como `MoneyText`: signo y «S/» al 68 %, cifras tabulares. */
    private fun amountText(color: Int): CharSequence {
        val sign = if (isIncome) "+ " else "− "
        val number = String.format(Locale.US, "%,.2f", amount)
        return SpannableStringBuilder().apply {
            append(sign, RelativeSizeSpan(0.68f), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            append("S/ ", RelativeSizeSpan(0.68f), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            setSpan(ForegroundColorSpan(Mg.alpha(color, 0.85f)), sign.length, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            append(number)
        }
    }

    /** Tarjeta que se quita deslizándola hacia arriba (el pago queda por confirmar). */
    private inner class SwipeCard(context: Context) : LinearLayout(context) {
        private val slop = ViewConfiguration.get(context).scaledTouchSlop
        private var downY = 0f

        override fun dispatchTouchEvent(e: MotionEvent): Boolean {
            if (e.actionMasked == MotionEvent.ACTION_DOWN) downY = e.rawY
            return super.dispatchTouchEvent(e)
        }

        override fun onInterceptTouchEvent(e: MotionEvent): Boolean =
            e.actionMasked == MotionEvent.ACTION_MOVE && downY - e.rawY > slop

        override fun onTouchEvent(e: MotionEvent): Boolean {
            when (e.actionMasked) {
                MotionEvent.ACTION_MOVE -> translationY = minOf(0f, e.rawY - downY)
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL ->
                    if (translationY < -dp(56)) finishWith(confirmed = false)
                    else animate().translationY(0f).setDuration(150).start()
            }
            return true
        }
    }

    private fun button(text: String, weight: Float, fill: Int, textColor: Int, onClick: () -> Unit) =
        TextView(this).apply {
            this.text = text
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            setTextColor(textColor)
            typeface = font(600)
            gravity = Gravity.CENTER
            maxLines = 1
            isClickable = true
            isFocusable = true
            contentDescription = text
            background = pressable(rounded(fill, 13f), if (fill == Mg.SOFT) 0x22FFFFFF else 0x33000000)
            layoutParams = LinearLayout.LayoutParams(0, dp(44), weight).apply {
                marginStart = dp(3.5f)
                marginEnd = dp(3.5f)
            }
            setOnClickListener {
                performHapticFeedback(android.view.HapticFeedbackConstants.VIRTUAL_KEY)
                onClick()
            }
        }

    private fun row(gravity: Int = Gravity.CENTER_VERTICAL) = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        this.gravity = gravity
    }

    private fun spacer(heightDp: Int) = View(this).apply {
        layoutParams = LinearLayout.LayoutParams(1, dp(heightDp))
    }

    private fun flexible() = View(this).apply { layoutParams = LinearLayout.LayoutParams(0, 1, 1f) }

    /** Fila «Categoría: X · Cambiar ›», igual que en la app. Abre la app para revisarlo. */
    private fun categoryRow(): View {
        val color = Mg.category(category)
        val name = ReaderRules.categoryLabel(category)
        return row().apply {
            setPadding(dp(12), dp(10), dp(12), dp(10))
            background = pressable(rounded(Mg.SOFT, 14f, Mg.LINE))
            isClickable = true
            contentDescription = "${if (isIncome) "Tipo" else "Categoría"}: $name. Cambiar"
            setOnClickListener { openEdit() }

            addView(FrameLayout(context).apply {
                background = rounded(Mg.alpha(color, 0.16f), 9f)
                addView(
                    View(context).apply { background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(color) } },
                    FrameLayout.LayoutParams(dp(10), dp(10), Gravity.CENTER),
                )
            }, LinearLayout.LayoutParams(dp(28), dp(28)))
            addView(
                label(highlighted(if (isIncome) "Tipo: " else "Categoría: ", name, Mg.INK), 13f, Mg.INK2).apply {
                    maxLines = 1
                    ellipsize = TextUtils.TruncateAt.END
                },
                LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply { marginStart = dp(10) },
            )
            addView(label("Cambiar ›", 12.5f, Mg.ACC2, 600))
        }
    }

    /** Aviso verde de los ingresos: no se guardan hasta que el usuario lo confirme. */
    private fun incomeNote() = label(
        highlighted("Es dinero que ", "recibiste", Mg.UP, ". No se guardará hasta que lo confirmes."),
        12.5f,
        Mg.INK,
    ).apply {
        setLineSpacing(0f, 1.3f)
        setPadding(dp(12), dp(10), dp(12), dp(10))
        background = rounded(Mg.alpha(Mg.UP, 0.10f), 13f, Mg.alpha(Mg.UP, 0.20f))
    }

    /** Etiqueta pequeña del encabezado: «Gasto» en violeta o «Ingreso» en verde. */
    private fun kindChip() = label(if (isIncome) "Ingreso" else "Gasto", 11f, if (isIncome) Mg.UP else Mg.ACC2, 700).apply {
        setPadding(dp(8), dp(3.5f), dp(8), dp(3.5f))
        background = if (isIncome) {
            rounded(Mg.alpha(Mg.UP, 0.10f), 8f, Mg.alpha(Mg.UP, 0.25f))
        } else {
            rounded(Mg.ACC_SOFT, 8f, Mg.ACC_LINE)
        }
    }

    private fun showOverlay() {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        closing = false

        val card = SwipeCard(this).apply {
            orientation = LinearLayout.VERTICAL
            background = rounded(Mg.CARD, 22f, Mg.BORDER)
            elevation = dp(16).toFloat()
            clipToOutline = true
            setPadding(dp(18), dp(14), dp(18), dp(14))
            contentDescription = if (isIncome) "Ingreso detectado" else "Gasto detectado"
        }

        // Encabezado: punto del color de la fuente, «Yape · 14:05» y el tipo.
        val sourceColor = Mg.source(provider)
        val time = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
        card.addView(row().apply {
            addView(View(context).apply {
                background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(sourceColor) }
            }, LinearLayout.LayoutParams(dp(8), dp(8)))
            addView(
                label("${sourceName()} · $time", 12.5f, Mg.INK2, 600),
                LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply { marginStart = dp(8) },
            )
            addView(kindChip())
        })
        card.addView(spacer(12))

        // Monto grande
        val amountColor = if (isIncome) Mg.UP else Mg.INK
        card.addView(label(amountText(amountColor), 34f, amountColor, 800).apply {
            letterSpacing = -0.03f
            fontFeatureSettings = "tnum"
            contentDescription = String.format(Locale.US, "%s%,.2f soles", if (isIncome) "más " else "", amount)
        })
        card.addView(spacer(6))

        // Destinatario / comercio (una sola línea)
        card.addView(
            label(
                highlighted(if (isIncome) "de " else "a ", NativeQueue.displayName(this, merchant), Mg.INK),
                14.5f,
                Mg.INK2,
            ).apply {
                maxLines = 1
                ellipsize = TextUtils.TruncateAt.END
            },
        )
        card.addView(spacer(14))

        card.addView(categoryRow())
        card.addView(spacer(12))

        if (isIncome) {
            card.addView(incomeNote())
            card.addView(spacer(12))
        }

        // Acciones: el usuario decide; nada se guarda solo.
        card.addView(row().apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { marginStart = -dp(3.5f); marginEnd = -dp(3.5f) }
            if (isIncome) {
                addView(button("Ignorar", 10f, Mg.SOFT, Mg.INK) { finishWith(confirmed = false) })
                addView(button("Guardar ingreso", 14f, Mg.UP, Mg.BLACK) { finishWith(confirmed = true) })
            } else {
                addView(button("Descartar", 10f, Mg.SOFT, Mg.INK) { discard() })
                addView(button("Editar", 10f, Mg.SOFT, Mg.INK) { openEdit() })
                addView(button("Guardar", 14f, Mg.ACC, Mg.WHITE) { finishWith(confirmed = true) })
            }
        })
        card.addView(spacer(10))

        // Pie: qué hace el gesto y la marca, como en la app.
        card.addView(row().apply {
            addView(
                label("Desliza arriba para verlo luego", 11f, Mg.INK3).apply {
                    maxLines = 1
                    ellipsize = TextUtils.TruncateAt.END
                },
                LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f),
            )
            addView(label("MiGasto · Detección", 11f, Mg.INK3, 500).apply { setPadding(dp(8), 0, 0, 0) })
        })

        val root = FrameLayout(this).apply {
            setPadding(dp(14), 0, dp(14), dp(16))
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
            y = statusBarHeight() + dp(8)
        }

        try {
            windowManager?.addView(root, params)
        } catch (e: Exception) {
            // Sin permiso de superposición: el pago ya quedó pendiente en la app.
            overlayView = null
            MyAccessibilityService.notifyFlutterSaved()
            stopSelf()
            return
        }

        vibrateOnce()

        // Entra desde arriba (se omite si las animaciones están desactivadas).
        if (animationsOn()) {
            card.translationY = -dp(140).toFloat()
            card.alpha = 0f
            card.animate().translationY(0f).alpha(1f).setDuration(320)
                .setInterpolator(android.view.animation.OvershootInterpolator(1.1f)).start()
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

    private fun statusBarHeight(): Int {
        val id = resources.getIdentifier("status_bar_height", "dimen", "android")
        return if (id > 0) resources.getDimensionPixelSize(id) else dp(24)
    }

    // ------------------------------------------------------------- acciones

    /**
     * Cierra la ventana. `confirmed` true confirma el pago pendiente; false lo deja en
     * Movimientos > Por confirmar, donde ya está.
     */
    private fun finishWith(confirmed: Boolean) {
        if (confirmed) act("confirm") else MyAccessibilityService.notifyFlutterSaved()
        close()
    }

    /** «Descartar»: borra el pago pendiente. */
    private fun discard() {
        act("discard")
        close()
    }

    /** Pide a Flutter confirmar o descartar el pago pendiente de esta ventana. */
    private fun act(action: String) {
        if (ref.isEmpty()) return
        NativeQueue.enqueueAction(this, action, ref)
        MyAccessibilityService.notifyFlutterSaved()
    }

    /**
     * "Editar" / "Cambiar": el pago queda pendiente y se abre la app para revisarlo en
     * Movimientos > Por confirmar.
     */
    private fun openEdit() {
        MyAccessibilityService.notifyFlutterSaved()
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        if (openIntent != null) startActivity(openIntent)
        close()
    }

    private fun close() {
        if (closing) return
        closing = true
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
}
