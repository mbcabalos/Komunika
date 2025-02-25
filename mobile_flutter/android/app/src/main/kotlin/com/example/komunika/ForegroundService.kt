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
            NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Screen Recorder")
                .setContentText("Recording in progress")
                .setSmallIcon(R.drawable.ic_notification)
                .setPriority(NotificationCompat.PRIORITY_LOW) // Match the channel importance
                .build()
        } else {
            NotificationCompat.Builder(this)
                .setContentTitle("Screen Recorder")
                .setContentText("Recording in progress")
                .setSmallIcon(R.drawable.ic_notification)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build()
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // For Android 10 and above, specify the foreground service type
                startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
            } else {
                // For older versions, start the service without specifying the type
                startForeground(1, notification)
            }
        } catch (e: SecurityException) {
            Log.e("ForegroundService", "SecurityException: ${e.message}")
            // Handle the exception (e.g., show a message to the user)
        }
    }
}