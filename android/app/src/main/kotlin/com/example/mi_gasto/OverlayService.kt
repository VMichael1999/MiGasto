package com.example.mi_gasto

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

class OverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var progressHandler = Handler(Looper.getMainLooper())
    private var progressRunnable: Runnable? = null
    private var currentStep = 50 // 5 seconds (50 steps of 100ms)
    private val totalSteps = 50

    private var currentAmount = 0.0
    private var currentMerchant = ""
    private var currentProvider = ""
    private var currentRawText = ""

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_NOT_STICKY

        currentAmount = intent.getDoubleExtra("amount", 0.0)
        currentMerchant = intent.getStringExtra("merchant") ?: "Establecimiento"
        currentProvider = intent.getStringExtra("provider") ?: "manual"
        currentRawText = intent.getStringExtra("rawText") ?: ""

        // Remove previous overlay if exists
        removeOverlay()

        showOverlay()
        return START_NOT_STICKY
    }

    private fun showOverlay() {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val density = resources.displayMetrics.density
        val dp = { value: Int -> (value * density).toInt() }

        // Container view
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(16), dp(16), dp(16), dp(16))
        }

        // Slate-dark card view
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackground(GradientDrawable().apply {
                setColor(Color.parseColor("#131219")) // AppTheme.cardBg slate-dark
                cornerRadius = dp(16).toFloat()
                setStroke(dp(1), Color.parseColor("#2E2B38"))
            })
            setPadding(dp(16), dp(16), dp(16), dp(16))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        // 1. Shriniking Progress Bar Container
        val progressContainer = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            weightSum = 1.0f
            setBackgroundColor(Color.parseColor("#1E1D24"))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(4)
            ).apply {
                setMargins(0, 0, 0, dp(12))
            }
        }

        // Progress bar itself
        val progressBar = View(this).apply {
            setBackgroundColor(Color.parseColor("#39FF14")) // Neon Green
            layoutParams = LinearLayout.LayoutParams(
                0,
                LinearLayout.LayoutParams.MATCH_PARENT,
                1.0f
            )
        }
        progressContainer.addView(progressBar)
        card.addView(progressContainer)

        // Pause timer on card touch/click
        card.setOnTouchListener { _, _ ->
            progressRunnable?.let { progressHandler.removeCallbacks(it) }
            progressBar.setBackgroundColor(Color.parseColor("#AEAEB2")) // Turn grey to show paused
            false
        }

        // 2. Header Layout (Provider & Title)
        val headerLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, dp(8))
            }
        }

        val providerBadge = TextView(this).apply {
            text = currentProvider.uppercase(Locale.getDefault())
            textSize = 10f
            setTypeface(null, android.graphics.Typeface.BOLD)
            setTextColor(when (currentProvider.lowercase()) {
                "yape" -> Color.parseColor("#7B2CBF") // Yape purple
                "plin" -> Color.parseColor("#00B4D8") // Plin teal
                else -> Color.parseColor("#4285F4") // GPay blue
            })
            setPadding(dp(8), dp(4), dp(8), dp(4))
            background = GradientDrawable().apply {
                setColor(when (currentProvider.lowercase()) {
                    "yape" -> Color.parseColor("#1A7B2CBF")
                    "plin" -> Color.parseColor("#1A00B4D8")
                    else -> Color.parseColor("#1A4285F4")
                })
                cornerRadius = dp(6).toFloat()
            }
        }

        val headerTitle = TextView(this).apply {
            text = "  Pago Detectado"
            textSize = 12f
            setTextColor(Color.parseColor("#8E8E93"))
        }

        headerLayout.addView(providerBadge)
        headerLayout.addView(headerTitle)
        card.addView(headerLayout)

        // 3. Amount Text
        val amountText = TextView(this).apply {
            text = String.format("S/ %.2f", currentAmount)
            textSize = 24f
            setTypeface(null, android.graphics.Typeface.BOLD)
            setTextColor(Color.WHITE)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        card.addView(amountText)

        // 4. Merchant Text
        val merchantText = TextView(this).apply {
            text = "a $currentMerchant"
            textSize = 14f
            setTextColor(Color.parseColor("#AEAEB2"))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, dp(16))
            }
        }
        card.addView(merchantText)

        // 5. Action Buttons Row
        val buttonsLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        val editButton = Button(this).apply {
            text = "Editar"
            textSize = 12f
            setTextColor(Color.WHITE)
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#1E1D24"))
                cornerRadius = dp(8).toFloat()
                setStroke(dp(1), Color.parseColor("#3E3B48"))
            }
            layoutParams = LinearLayout.LayoutParams(
                0,
                dp(40),
                1f
            ).apply {
                setMargins(0, 0, dp(8), 0)
            }
            setOnClickListener {
                progressRunnable?.let { progressHandler.removeCallbacks(it) }

                // Open App with intent triggers edit mode
                val openIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("action", "edit_expense")
                    putExtra("amount", currentAmount)
                    putExtra("merchant", currentMerchant)
                    putExtra("provider", currentProvider)
                    putExtra("rawText", currentRawText)
                }
                if (openIntent != null) {
                    startActivity(openIntent)
                }

                removeOverlay()
                stopSelf()
            }
        }

        val confirmButton = Button(this).apply {
            text = "Confirmar"
            textSize = 12f
            setTextColor(Color.BLACK)
            setTypeface(null, android.graphics.Typeface.BOLD)
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#39FF14")) // Neon Green
                cornerRadius = dp(8).toFloat()
            }
            layoutParams = LinearLayout.LayoutParams(
                0,
                dp(40),
                1.5f
            )
            setOnClickListener {
                confirmTransaction()
            }
        }

        val dismissButton = Button(this).apply {
            text = "Descartar"
            textSize = 12f
            setTextColor(Color.parseColor("#8E8E93")) // Grey text
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#1E1D24")) // Dark background
                cornerRadius = dp(8).toFloat()
                setStroke(dp(1), Color.parseColor("#3E3B48"))
            }
            layoutParams = LinearLayout.LayoutParams(
                0,
                dp(40),
                1f
            ).apply {
                setMargins(0, 0, dp(8), 0)
            }
            setOnClickListener {
                progressRunnable?.let { progressHandler.removeCallbacks(it) }
                removeOverlay()
                stopSelf()
            }
        }

        buttonsLayout.addView(editButton)
        buttonsLayout.addView(dismissButton)
        buttonsLayout.addView(confirmButton)
        card.addView(buttonsLayout)

        container.addView(card)
        overlayView = container

        // Window params
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            y = dp(50) // Margin from bottom
        }

        windowManager?.addView(overlayView, params)

        // 6. Start 5s Countdown Timer
        currentStep = totalSteps
        progressRunnable = object : Runnable {
            override fun run() {
                currentStep--
                if (currentStep <= 0) {
                    confirmTransaction()
                } else {
                    val p = progressBar.layoutParams as LinearLayout.LayoutParams
                    p.weight = currentStep.toFloat() / totalSteps
                    progressBar.layoutParams = p
                    progressHandler.postDelayed(this, 100)
                }
            }
        }
        progressHandler.postDelayed(progressRunnable!!, 100)
    }

    private fun confirmTransaction() {
        progressRunnable?.let { progressHandler.removeCallbacks(it) }

        val category = classify(currentMerchant)
        saveExpenseToSharedPrefs(currentAmount, currentMerchant, currentProvider, category, currentRawText)
        notifyFlutterTransactionSaved()

        removeOverlay()
        stopSelf()
    }

    private fun classify(merchant: String): String {
        val m = merchant.lowercase(Locale.getDefault())
        return when {
            m.contains("tambo") || m.contains("metro") || m.contains("plaza vea") || m.contains("wong") || m.contains("tottus") || m.contains("saga") || m.contains("ripley") || m.contains("falabella") -> "compras"
            m.contains("starbucks") || m.contains("mcdonald") || m.contains("kfc") || m.contains("burger") || m.contains("chifa") || m.contains("restaurant") || m.contains("cafeteria") || m.contains("dunkin") || m.contains("bembos") || m.contains("pardo") -> "alimentacion"
            m.contains("uber") || m.contains("cabify") || m.contains("taxi") || m.contains("independencia") || m.contains("di di") || m.contains("didi") || m.contains("grifo") || m.contains("primax") || m.contains("repsol") || m.contains("petroperu") -> "transporte"
            m.contains("netflix") || m.contains("spotify") || m.contains("disney") || m.contains("prime") || m.contains("hbo") || m.contains("cineplanet") || m.contains("cinemark") || m.contains("cine") -> "entretenimiento"
            m.contains("enel") || m.contains("luz") || m.contains("sedapal") || m.contains("agua") || m.contains("movistar") || m.contains("claro") || m.contains("entel") || m.contains("internet") || m.contains("recibo") -> "servicios"
            else -> "otros"
        }
    }

    private fun saveExpenseToSharedPrefs(amount: Double, merchant: String, provider: String, category: String, rawText: String) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val rawExpenses = prefs.getString("flutter.migasto_fallback_expenses", "[]") ?: "[]"

        try {
            val jsonArray = JSONArray(rawExpenses)

            val transaction = JSONObject().apply {
                put("id", UUID.randomUUID().toString())
                put("amount", amount)
                put("merchant", merchant)
                put("category", category)
                put("source", provider)
                val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US)
                put("date", dateFormat.format(Date()))
                put("notes", rawText)
                put("isConfirmed", true)
            }

            val newArray = JSONArray()
            newArray.put(transaction)
            for (i in 0 until jsonArray.length()) {
                newArray.put(jsonArray.get(i))
            }

            prefs.edit().putString("flutter.migasto_fallback_expenses", newArray.toString()).apply()
        } catch (e: Exception) {
            // Ignore
        }
    }

    private fun notifyFlutterTransactionSaved() {
        Handler(Looper.getMainLooper()).post {
            MyAccessibilityService.getChannel()?.invokeMethod("onTransactionSaved", mapOf(
                "amount" to currentAmount,
                "peerName" to currentMerchant,
                "provider" to currentProvider,
                "category" to classify(currentMerchant),
                "rawText" to currentRawText
            ))
        }
    }

    private fun removeOverlay() {
        if (overlayView != null && windowManager != null) {
            try {
                windowManager?.removeView(overlayView)
            } catch (e: Exception) {
                // Ignore
            }
            overlayView = null
        }
        progressRunnable?.let { progressHandler.removeCallbacks(it) }
    }

    override fun onDestroy() {
        removeOverlay()
        super.onDestroy()
    }
}
