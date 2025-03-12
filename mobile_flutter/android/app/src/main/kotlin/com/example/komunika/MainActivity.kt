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
import android.os.Handler
import android.os.Looper
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.komunika/recorder"
    private lateinit var mediaProjectionManager: MediaProjectionManager
    private var mediaProjection: MediaProjection? = null
    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private lateinit var platform: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        platform = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
        platform.setMethodCallHandler { call, result ->
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
                "updateText" -> {
                    val updatedText = call.argument<String>("updatedText")
                    handleUpdatedText(updatedText)
                    result.success(null)
                }"updateCaptionPreferences" -> {
                    val sharedPrefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                    val editor = sharedPrefs.edit()
                    
                    val size = call.argument<Double>("size")?.toFloat() ?: 50.0f
                    val textColor = call.argument<String>("textColor") ?: "black"
                    val backgroundColor = call.argument<String>("backgroundColor") ?: "white"
                    
                    editor.putFloat("captionSize", size)
                    editor.putString("captionTextColor", textColor)
                    editor.putString("captionBackgroundColor", backgroundColor)
                    editor.apply()
                    
                    result.success(null)
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
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE && resultCode == RESULT_OK && data != null) {
            mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data)
            Log.d("AudioCapture", "MediaProjection initialized successfully")
            // startForegroundService()
            startAudioStreaming()
            Handler(Looper.getMainLooper()).postDelayed({
            startFloatingWindow()}, 1000) // 2 seconds delay
            
        } else {
            Log.e("AudioCapture", "Failed to initialize MediaProjection")
            stopForegroundService()
            stopFloatingWindow()
            platform.invokeMethod("toggleAutoCaption", false)
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
        runOnUiThread {
            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("onAudioData", buffer)
            // Log.d("AudioCapture", "Sent $bytesRead bytes of audio data to Flutter")
        }
    }

    private fun startForegroundService() {
        val serviceIntent = Intent(this, ForegroundService::class.java)
        ContextCompat.startForegroundService(this, serviceIntent)
        Log.d("AudioCapture", "Foreground service started")
        startRecording()
    }

    private fun stopForegroundService() {
        val serviceIntent = Intent(this, ForegroundService::class.java)
        val intent = Intent(this, FloatingWindowService::class.java)
        stopRecording()
        stopService(intent)
        stopService(serviceIntent)
        Log.d("AudioCapture", "Foreground service stopped")

    }

    private fun startFloatingWindow() {
        val intent = Intent(this, FloatingWindowService::class.java)
        startService(intent)
        Log.d("FloatingWindow", "Floating window service started")
    }

    private fun stopFloatingWindow() {
        val intent = Intent(this, FloatingWindowService::class.java)
        stopService(intent)
        Log.d("FloatingWindow", "Floating window service started")
    }

    private fun handleUpdatedText(updatedText: String?) {
        println("Received updated text: $updatedText")

        // Send the updated text via local broadcast
        val intent = Intent("com.example.komunika.UPDATE_TEXT")
        intent.putExtra("transcribedText", updatedText)
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
    }

    companion object {
        private const val REQUEST_CODE = 100
    }
}