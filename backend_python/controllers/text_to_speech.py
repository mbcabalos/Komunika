from flask import Blueprint, request, jsonify, send_file
import pyttsx3
import os

tts_app = Blueprint('tts_app', __name__)

@tts_app.route('/')
def index():
    return "Text-to-Speech API is running!"

# Directory for saving generated audio files
AUDIO_DIR = "audio_files"
os.makedirs(AUDIO_DIR, exist_ok=True)

@tts_app.route('/api/text-to-speech', methods=['POST'])
def text_to_speech():
    try:
        # Get the text from the request
        data = request.json
        text = data.get('text', '')

        if not text:
            return jsonify({"error": "No text provided"}), 400

        # Initialize pyttsx3 and generate audio
        engine = pyttsx3.init()
        filename = os.path.join(AUDIO_DIR, "output.mp3")
        engine.save_to_file(text, filename)
        engine.runAndWait()

        return send_file(filename, mimetype='audio/mpeg')

    except Exception as e:
        return jsonify({"error": str(e)}), 500