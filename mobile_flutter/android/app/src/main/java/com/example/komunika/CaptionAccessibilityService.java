package com.example.komunika.services;

import android.accessibilityservice.AccessibilityService;
import android.media.*;
import android.media.projection.*;
import android.os.*;
import android.view.accessibility.AccessibilityEvent;
import android.content.Intent;
import androidx.core.app.NotificationCompat;

public class CaptionAccessibilityService extends AccessibilityService {
    private MediaRecorder recorder;
    private MediaProjectionManager projectionManager;
    private MediaProjection mediaProjection;
    private AudioPlaybackCaptureConfiguration config;

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        // Detect media play event
        if (event.getEventType() == AccessibilityEvent.TYPE_WINDOWS_CHANGED) {
            if (isMediaPlaying()) {
                startAudioCapture();
            } else {
                stopAudioCapture();
            }
        }
    }




    private boolean isMediaPlaying() {
        AudioManager audioManager = (AudioManager) getSystemService(AUDIO_SERVICE);
        return audioManager.isMusicActive();
    }

    private void startAudioCapture() {
    projectionManager = (MediaProjectionManager) getSystemService(MEDIA_PROJECTION_SERVICE);
    Intent captureIntent = projectionManager.createScreenCaptureIntent();
    
    captureIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    startActivity(captureIntent);  
    }

    @Override
    public void onServiceConnected() {
        super.onServiceConnected();
    }

    @Override
    public void onInterrupt() {}

    private void stopAudioCapture() {
        if (recorder != null) {
            recorder.stop();
            recorder.release();
        }
    }
}
