package com.komunika.app

import android.content.Intent
import android.media.*
import android.media.audiofx.NoiseSuppressor
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.komunika.app/recorder"
    private val EVENT_CHANNEL = "native_audio_stream"
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var platform: MethodChannel

    private var audioRecord: AudioRecord? = null
    private var audioThread: Thread? = null
    private var isRecording = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        platform = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Stream for sending live audio chunks to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        // Flutter → Android method channel for starting/stopping service or recording
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        val intent = Intent(this, ForegroundService::class.java)
                        startForegroundService(intent)
                        result.success(null)
                    }
                    "stopService" -> {
                        val intent = Intent(this, ForegroundService::class.java)
                        stopService(intent)
                        result.success(null)
                    }
                    "startRecording" -> {
                        startNativeRecording()
                        result.success(null)
                    }
                    "stopRecording" -> {
                        stopNativeRecording()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // 🎙 Start microphone recording
    private fun startNativeRecording() {
        if (isRecording) return

        val sampleRate = 16000
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_16BIT
        val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            channelConfig,
            audioFormat,
            bufferSize
        )

        val buffer = ByteArray(bufferSize)
        val mainHandler = Handler(Looper.getMainLooper())

        isRecording = true
        audioRecord?.startRecording()

        audioThread = Thread {
            try {
                while (isRecording) {
                    val read = audioRecord?.read(buffer, 0, buffer.size) ?: -1
                    if (read > 0) {
                        val chunk = buffer.copyOf(read)
                        mainHandler.post {
                            eventSink?.success(chunk)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("AudioRecord", "Exception during recording", e)
            }
        }
        audioThread?.start()

        Log.d("AudioRecord", "🎙 Microphone recording started")
    }

    // 🛑 Stop microphone recording
    private fun stopNativeRecording() {
        isRecording = false
        try {
            audioThread?.join()
        } catch (_: Exception) { }
        audioThread = null
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        Log.d("AudioRecord", "🛑 Recording stopped")
    }

    // 🧱 Foreground service control
    private fun startForegroundService() {
        val serviceIntent = Intent(this, ForegroundService::class.java)
        ContextCompat.startForegroundService(this, serviceIntent)
        Log.d("ForegroundService", "Foreground service started")
    }

    private fun stopForegroundService() {
        val serviceIntent = Intent(this, ForegroundService::class.java)
        stopService(serviceIntent)
        Log.d("ForegroundService", "Foreground service stopped")
    }

    private fun handleUpdatedText(updatedText: String?) {
        val intent = Intent("com.komunika.app.UPDATE_TEXT")
        intent.putExtra("transcribedText", updatedText)
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
    }
}
