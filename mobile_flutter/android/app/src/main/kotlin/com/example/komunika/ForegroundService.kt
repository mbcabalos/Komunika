package com.example.komunika

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.content.pm.ServiceInfo
import androidx.core.app.NotificationCompat
import android.util.Log

class ForegroundService : Service() {

    private val CHANNEL_ID = "ScreenRecorderChannel"

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForegroundService()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Screen Recorder Service",
                NotificationManager.IMPORTANCE_LOW // Use LOW or DEFAULT to avoid intrusive notifications
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
    
    private fun startForegroundService() {
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Screen Recording",
                NotificationManager.IMPORTANCE_DEFAULT // Keeps notification persistent
            ).apply {
                setShowBadge(false)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
    
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
    
            NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Screen Recorder")
                .setContentText("Recording in progress")
                .setSmallIcon(R.drawable.ic_notification)
                .setPriority(NotificationCompat.PRIORITY_HIGH) // Keep it high priority
                .setOngoing(true) // ✅ Makes it unswipeable
                .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE) // Stronger persistence
                .setCategory(Notification.CATEGORY_SERVICE)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC) // Ensures it stays visible
                .build()
        } else {
            NotificationCompat.Builder(this)
                .setContentTitle("Screen Recorder")
                .setContentText("Recording in progress")
                .setSmallIcon(R.drawable.ic_notification)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setOngoing(true) // ✅ Ensures it's unswipeable
                .build()
        }
    
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
            } else {
                startForeground(1, notification)
            }
        } catch (e: SecurityException) {
            Log.e("ForegroundService", "SecurityException: ${e.message}")
        }
    }
    
}