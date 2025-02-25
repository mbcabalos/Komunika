package com.example.komunika

import android.content.Intent
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.AudioAttributes
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

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
                "stopForegroundService" -> {
                    stopForegroundService()
                    result.success("Foreground service stopped")
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
        stopForegroundService()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE && resultCode == RESULT_OK && data != null) {
            mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data)
            Log.d("AudioCapture", "MediaProjection initialized successfully")
            startForegroundService()
            startAudioStreaming()
        } else {
            Log.e("AudioCapture", "Failed to initialize MediaProjection")
        }
    }

    private fun startAudioStreaming() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && mediaProjection != null) {
            // Configure audio playback capture
            val captureConfig = AudioPlaybackCaptureConfiguration.Builder(mediaProjection!!)
                .addMatchingUsage(AudioAttributes.USAGE_MEDIA) // Capture media audio
                .addMatchingUsage(AudioAttributes.USAGE_GAME)   // Capture game audio
                .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN) // Capture other audio
                .build()

            val sampleRate = 16000
            val channelConfig = AudioFormat.CHANNEL_IN_MONO
            val audioFormat = AudioFormat.ENCODING_PCM_16BIT
            val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

            Log.d("AudioCapture", "Audio configuration:")
            Log.d("AudioCapture", "Sample rate: $sampleRate Hz")
            Log.d("AudioCapture", "Channels: ${if (channelConfig == AudioFormat.CHANNEL_IN_STEREO) "Stereo" else "Mono"}")
            Log.d("AudioCapture", "Audio format: ${if (audioFormat == AudioFormat.ENCODING_PCM_16BIT) "16-bit PCM" else "Unknown"}")
            Log.d("AudioCapture", "Buffer size: $bufferSize bytes")

            audioRecord = AudioRecord.Builder()
                .setAudioPlaybackCaptureConfig(captureConfig) // Use playback capture config
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(audioFormat)
                        .setSampleRate(sampleRate)
                        .setChannelMask(channelConfig)
                        .build()
                )
                .setBufferSizeInBytes(bufferSize)
                .build()

            if (audioRecord?.state == AudioRecord.STATE_INITIALIZED) {
                Log.d("AudioCapture", "AudioRecord initialized successfully")
                audioRecord?.startRecording()
                isRecording = true

                // Start a thread to read and process audio data
                Thread {
                    val buffer = ByteArray(bufferSize)
                    while (isRecording) {
                        val bytesRead = audioRecord?.read(buffer, 0, bufferSize) ?: 0
                        if (bytesRead > 0) {
                            // Log the audio data for debugging
                            Log.d("AudioCapture", "Captured audio data: $bytesRead bytes")
                            Log.d("AudioCapture", "First 10 bytes: ${buffer.sliceArray(0..10).joinToString()}")

                            // Send the audio data to Flutter for processing
                            sendAudioToFlutter(buffer, bytesRead)
                        } else {
                            Log.e("AudioCapture", "Failed to read audio data")
                        }
                    }
                }.start()
            } else {
                Log.e("AudioCapture", "Failed to initialize AudioRecord")
            }
        } else {
            Log.e("AudioCapture", "MediaProjection or Android version not supported")
        }
    }

    private fun sendAudioToFlutter(buffer: ByteArray, bytesRead: Int) {
        // Use runOnUiThread to ensure the method is called on the main thread
        runOnUiThread {
            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("onAudioData", buffer)
            Log.d("AudioCapture", "Sent $bytesRead bytes of audio data to Flutter")
        }
    }

    private fun startForegroundService() {
        val serviceIntent = Intent(this, ForegroundService::class.java)
        ContextCompat.startForegroundService(this, serviceIntent)
        Log.d("AudioCapture", "Foreground service started")
    }

    private fun stopForegroundService() {
        val serviceIntent = Intent(this, ForegroundService::class.java)
        stopService(serviceIntent)
        Log.d("AudioCapture", "Foreground service stopped")
    }

    companion object {
        private const val REQUEST_CODE = 100
    }
}