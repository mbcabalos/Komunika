import io
import wave
from flask import json
import numpy as np
import noisereduce as nr
import speech_recognition as sr
from flask_socketio import SocketIO
from vosk import Model, KaldiRecognizer
import sounddevice as sd

import time

socketio = SocketIO()
print("Hello")
from vosk import Model

# vosk_model_path = r"D:\VS Code for Flutter\Large Project\Komunika\backend_python\models\vosk-model-tl-ph-generic-0.6"
vosk_model_path = "models/vosk-model-tl-ph-generic-0.6"

try:
    model = Model(vosk_model_path)
    print("✅ Model loaded successfully!")
except Exception as e:
    print(f"❌ Model loading failed: {e}")


recognizer = sr.Recognizer()
recognizer = KaldiRecognizer(model, 16000)
recognizer.SetWords(True)
audio_buffer = bytearray()  # ✅ Collect chunks in a buffer

def denoise_audio(raw_audio, sample_rate=16000):

    # Convert raw audio bytes to a numpy array
    audio_np = np.frombuffer(raw_audio, dtype=np.int16)

    # Apply noise reduction using noisereduce library
    cleaned_audio_np = nr.reduce_noise(y=audio_np, sr=sample_rate)

    # Convert cleaned audio numpy array back to bytes
    cleaned_audio = cleaned_audio_np.tobytes()

    return cleaned_audio

def play_pcm(audio_bytes, sample_rate=16000):
    audio = np.frombuffer(audio_bytes, dtype=np.int16).astype(np.float32) / 32768.0
    sd.play(audio, samplerate=sample_rate, blocking=False)

def register_transcription_events(socketio):
    @socketio.on("audio_stream")
    def handle_audio_stream(audio_data):
        denoised_audio = denoise_audio(audio_data)
        try:
            if recognizer.AcceptWaveform(denoised_audio):
                # ✅ Process and send interim results
                result = json.loads(recognizer.Result())
                text = result.get("text", "").strip()

                if text:
                    print(f"📝 Partial Transcription: {text}")
                    socketio.emit("transcription_result", {"text": text})

            else:
                # ✅ Send continuous partial transcriptions
                partial_result = json.loads(recognizer.PartialResult())
                partial_text = partial_result.get("partial", "").strip()

                if partial_text:
                    print(f"🔄 Streaming Transcription: {partial_text}")
                    socketio.emit("transcription_preview", {"live_text": partial_text})

        except Exception as e:
            print(f"❌ Error processing audio: {e}")
            socketio.emit("server_error", {"message": str(e)})


