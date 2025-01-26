from flask import Blueprint, jsonify
import sounddevice as sd
import queue
import json
from vosk import Model, KaldiRecognizer
from threading import Thread

# Define Blueprint
stt_blueprint = Blueprint('stt_app', __name__)

# Path to the Vosk model
# MODEL_PATH = "./models/vosk-model-small-en-us-0.15"
MODEL_PATH = "./models/vosk-model-tl-ph-generic-0.6"

# Load Vosk model
model = Model(MODEL_PATH)

# Recognizer and audio queue
recognizer = KaldiRecognizer(model, 16000)
audio_queue = queue.Queue()

# Callback function for capturing audio
def audio_callback(indata, frames, time, status):
    if status:
        print(f"Audio status: {status}")
    audio_queue.put(bytes(indata))

# Real-time transcription logic
def run_transcription():
    print("Listening... Press Ctrl+C to stop.")
    try:
        with sd.RawInputStream(samplerate=16000, blocksize=8000, dtype="int16",
                               channels=1, callback=audio_callback):
            while True:
                data = audio_queue.get()
                if recognizer.AcceptWaveform(data):
                    result = json.loads(recognizer.Result())
                    print(f"Transcription: {result.get('text')}")
    except Exception as e:
        print(f"Error: {e}")

# Flask route for real-time transcription
@stt_blueprint.route('/api/live-transcription', methods=['POST'])
def live_transcription():
    try:
        # Start transcription in a new thread
        transcription_thread = Thread(target=run_transcription)
        transcription_thread.start()
        return jsonify({"message": "Real-time transcription started. Check console for output."}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
