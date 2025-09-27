package com.komunika.app

import android.app.Service
import android.content.Intent
import android.content.IntentFilter
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.util.DisplayMetrics
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import android.widget.ScrollView
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import android.content.BroadcastReceiver
import android.content.Context


class FloatingWindowService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var floatingView: View
    private lateinit var layoutParams: WindowManager.LayoutParams
    private lateinit var textView: TextView
    private lateinit var scrollView: ScrollView

    private val textUpdateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val updatedText = intent?.getStringExtra("transcribedText")
            if (updatedText != null) {
                updateText(updatedText)
            }
        }
    }

    private fun updateCaptionStyle(size: Float, textColor: Int, backgroundColor: Int) {
        textView.textSize = size
        textView.setTextColor(textColor)
        val transparentBackground = android.graphics.Color.argb(180, 
            android.graphics.Color.red(backgroundColor),
            android.graphics.Color.green(backgroundColor),
            android.graphics.Color.blue(backgroundColor)
        )
        floatingView.setBackgroundColor(transparentBackground)
        windowManager.updateViewLayout(floatingView, layoutParams)
    }


    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        Log.d("FloatingWindowService", "Service created")

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        Log.d("FloatingWindowService", "WindowManager initialized")

        floatingView = LayoutInflater.from(this).inflate(R.layout.floating_window_layout, null)
        Log.d("FloatingWindowService", "Layout inflated")

        // Set up layout parameters
        layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        Log.d("FloatingWindowService", "LayoutParams configured")

        // Set initial size of the window (rectangle)
        layoutParams.width = 700 // Initial width in pixels
        layoutParams.height = 400 // Initial height in pixels

        // Set initial position to the center of the screen
        val displayMetrics = DisplayMetrics()
        windowManager.defaultDisplay.getMetrics(displayMetrics)
        layoutParams.gravity = Gravity.TOP or Gravity.START
        layoutParams.x = (displayMetrics.widthPixels - layoutParams.width) / 2 // Center horizontally
        layoutParams.y = (displayMetrics.heightPixels - layoutParams.height) / 2 // Center vertically

        windowManager.addView(floatingView, layoutParams)
        Log.d("FloatingWindowService", "View added to WindowManager")

        // Initialize the TextView for transcribed text
        scrollView = floatingView.findViewById(R.id.scroll_view)
        textView = floatingView.findViewById(R.id.text_view)

        val filter = IntentFilter("com.komunika.app.UPDATE_TEXT")
        LocalBroadcastManager.getInstance(this).registerReceiver(textUpdateReceiver, filter)
        // Make the window draggable
        floatingView.setOnTouchListener(object : View.OnTouchListener {
            private var initialX: Int = 0
            private var initialY: Int = 0
            private var initialTouchX: Float = 0f
            private var initialTouchY: Float = 0f

            override fun onTouch(v: View?, event: MotionEvent?): Boolean {
                when (event?.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = layoutParams.x
                        initialY = layoutParams.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        layoutParams.x = initialX + (event.rawX - initialTouchX).toInt()
                        layoutParams.y = initialY + (event.rawY - initialTouchY).toInt()
                        windowManager.updateViewLayout(floatingView, layoutParams)
                        return true
                    }
                }
                return false
            }
        })

        // Make the window resizable (bottom-right corner)
        val resizeHandle = floatingView.findViewById<View>(R.id.resize_handle)
        resizeHandle.setOnTouchListener(object : View.OnTouchListener {
            private var initialWidth: Int = layoutParams.width
            private var initialHeight: Int = layoutParams.height
            private var initialTouchX: Float = 0f
            private var initialTouchY: Float = 0f

            override fun onTouch(v: View?, event: MotionEvent?): Boolean {
                when (event?.action) {
                    MotionEvent.ACTION_DOWN -> {
                        // Save initial dimensions and touch coordinates
                        initialWidth = layoutParams.width
                        initialHeight = layoutParams.height
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        // Calculate new dimensions
                        val newWidth = initialWidth + (event.rawX - initialTouchX).toInt()
                        val newHeight = initialHeight + (event.rawY - initialTouchY).toInt()

                        // Ensure minimum size
                        val minWidth = 300 // Minimum width in pixels
                        val minHeight = 200 // Minimum height in pixels
                        layoutParams.width = newWidth.coerceAtLeast(minWidth)
                        layoutParams.height = newHeight.coerceAtLeast(minHeight)

                        // Update layout parameters
                        windowManager.updateViewLayout(floatingView, layoutParams)
                        return true
                    }
                }
                return false
            }
        })
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val transcribedText = intent?.getStringExtra("transcribedText")
        if (transcribedText != null) {
            updateText(transcribedText)
        }

        val sharedPrefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val captionSize = sharedPrefs.getFloat("captionSize", 50.0f)
        val textColorName = sharedPrefs.getString("captionTextColor", "black") ?: "black"
        val backgroundColorName = sharedPrefs.getString("captionBackgroundColor", "white") ?: "white"

        val textColor = getColorFromName(textColorName)
        val backgroundColor = getColorFromName(backgroundColorName)

        updateCaptionStyle(captionSize, textColor, backgroundColor)

        return START_STICKY
    }

    private fun getColorFromName(colorName: String): Int {
        return when (colorName.lowercase()) {
            "red" -> android.graphics.Color.RED
            "blue" -> android.graphics.Color.BLUE
            "black" -> android.graphics.Color.BLACK
            "white" -> android.graphics.Color.WHITE
            "grey" -> android.graphics.Color.GRAY
            else -> android.graphics.Color.BLACK // Default
        }
    }

    private fun updateText(text: String) {
        textView.append("\n$text")  // Append new text
        scrollView.post {
            scrollView.fullScroll(View.FOCUS_DOWN)  // Scroll to the bottom
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::floatingView.isInitialized) {
            windowManager.removeView(floatingView)
        }
    }
}