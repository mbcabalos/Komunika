import json
import base64
import numpy as np
import noisereduce as nr
from flask import request
from flask_socketio import SocketIO
from vosk import Model, KaldiRecognizer
from concurrent.futures import ThreadPoolExecutor

# Globals for reuse
client_recognizers = {}
executor = ThreadPoolExecutor(max_workers=4)

def register_transcription_events(socketio: SocketIO):
    """
    Register real-time audio transcription socket events.
    """
    print("🎧 Initializing audio transcription module...")

    # Load Vosk model once globally
    vosk_model_path = "models/vosk-model-tl-ph-generic-0.6"
    try:
        model = Model(vosk_model_path)
        print("✅ Vosk model loaded successfully!")
    except Exception as e:
        print(f"❌ Model loading failed: {e}")
        return

    def denoise_audio(raw_audio, sample_rate=16000):
        audio_np = np.frombuffer(raw_audio, dtype=np.int16)
        if len(audio_np) == 0:
            return b""
        cleaned_audio_np = nr.reduce_noise(y=audio_np, sr=sample_rate)
        return cleaned_audio_np.tobytes()

    @socketio.on("connect")
    def handle_connect():
        sid = request.sid
        recognizer = KaldiRecognizer(model, 16000)
        recognizer.SetWords(True)
        client_recognizers[sid] = recognizer
        print(f"🟢 Client connected: {sid}")
        socketio.emit("server_status", {"status": "connected"}, room=sid)

    @socketio.on("disconnect")
    def handle_disconnect():
        sid = request.sid
        client_recognizers.pop(sid, None)
        print(f"🔴 Client disconnected: {sid}")

    @socketio.on("audio_stream")
    def handle_audio_stream(audio_data):
        sid = request.sid
        # print(f"🎧 Received audio from {sid}")

        if sid not in client_recognizers:
            print(f"⚠️ No recognizer found for sid {sid}")
            socketio.emit("server_error", {"message": "Recognizer not initialized"}, room=sid)
            return

        # Decode base64 if needed
        if isinstance(audio_data, str):
            try:
                audio_data = base64.b64decode(audio_data)
            except Exception as e:
                print(f"❌ Base64 decode failed: {e}")
                return

        # Process asynchronously
        executor.submit(process_audio_chunk, sid, audio_data)

    def process_audio_chunk(sid, audio_data):
        try:
            recognizer = client_recognizers.get(sid)
            if not recognizer:
                print(f"⚠️ Recognizer missing for sid {sid}")
                return

            denoised_audio = denoise_audio(audio_data)

            if recognizer.AcceptWaveform(denoised_audio):
                result = json.loads(recognizer.Result())
                text = result.get("text", "").strip()
                if text:
                    # print(f"📝 Final: {text}")
                    socketio.emit("transcription_result", {"text": text}, room=sid)
            else:
                partial = json.loads(recognizer.PartialResult())
                partial_text = partial.get("partial", "").strip()
                if partial_text:
                    # print(f"🔄 Partial: {partial_text}")
                    socketio.emit("transcription_preview", {"live_text": partial_text}, room=sid)

        except Exception as e:
            print(f"❌ Error processing audio: {e}")
            socketio.emit("server_error", {"message": str(e)}, room=sid)
