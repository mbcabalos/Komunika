package com.example.komunika

import android.content.Intent
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioAttributes
import android.media.AudioPlaybackCaptureConfiguration
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.komunika/recorder"
    private lateinit var mediaProjectionManager: MediaProjectionManager
    private var mediaProjection: MediaProjection? = null
    private var audioRecord: AudioRecord? = null
    private var isRecording = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    startForegroundService()
                    result.success("Foreground service started")
                }
                "startRecording" -> {
                    startRecording()
                    result.success("Recording started")
                }
                "stopRecording" -> {
                    stopRecording()
                    result.success("Recording stopped")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startRecording() {
        mediaProjectionManager = getSystemService(MediaProjectionManager::class.java)
        val captureIntent = mediaProjectionManager.createScreenCaptureIntent()
        startActivityForResult(captureIntent, REQUEST_CODE)
    }

    private fun stopRecording() {
        isRecording = false
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        mediaProjection?.stop()
        mediaProjection = null

        // Stop the foreground service
        val serviceIntent = Intent(this, ForegroundService::class.java)
        stopService(serviceIntent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE && resultCode == RESULT_OK && data != null) {
            // Start the foreground service before using MediaProjection
            startForegroundService()

            // Now get the MediaProjection instance
            mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data)

            // Start capturing media audio instead of microphone
            startAudioStreaming()
        }
    }

    private fun startAudioStreaming() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Create an AudioPlaybackCaptureConfiguration to capture media audio
            val captureConfig = AudioPlaybackCaptureConfiguration.Builder(mediaProjection!!)
                .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
                .build()

            // Initialize audio record with the new configuration
            val sampleRate = 44100 // 44.1 kHz
            val channelConfig = AudioFormat.CHANNEL_IN_STEREO
            val audioFormat = AudioFormat.ENCODING_PCM_16BIT
            val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.DEFAULT, // Use DEFAULT for capturing media audio
                sampleRate,
                channelConfig,
                audioFormat,
                bufferSize
            )

            // Start recording audio from media output
            audioRecord?.startRecording()
            isRecording = true

            // Start a thread to read and process audio data
            Thread {
                val buffer = ByteArray(bufferSize)
                while (isRecording) {
                    val bytesRead = audioRecord?.read(buffer, 0, bufferSize) ?: 0
                    if (bytesRead > 0) {
                        // Process the audio data (e.g., send it to a transcriber)
                        processAudioData(buffer, bytesRead)
                    }
                }
            }.start()
        }
    }

    private fun processAudioData(buffer: ByteArray, bytesRead: Int) {
        // Here, you can send the audio data to a transcriber or another service
        // For example, you can use a WebSocket or HTTP request to stream the data
        println("Audio data received: $bytesRead bytes")
    }

    private fun startForegroundService() {
        val serviceIntent = Intent(this, ForegroundService::class.java)
        ContextCompat.startForegroundService(this, serviceIntent)
    }

    private fun stopForegroundService() {
        val serviceIntent = Intent(this, ForegroundService::class.java)
        stopService(serviceIntent)
    }

    companion object {
        private const val REQUEST_CODE = 100
    }
}
