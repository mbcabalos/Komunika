#  Create a env first by typing python -m venv .venv, Activate the env first using venv\Scripts\activate before using pip install -r flask_modules.
# To know if you have install the modules type pip freeze and if you added a new modules type pip freeze > flask_modules.txt

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import pyttsx3
import os

from datetime import datetime

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

@app.route('/')
def index():
    return "Text-to-Speech API is running!"

# Directory for saving generated audio files
AUDIO_DIR = "audio_files"
os.makedirs(AUDIO_DIR, exist_ok=True)

@app.route('/api/text-to-speech', methods=['POST'])
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

if __name__ == '__main__':
    # Use HTTPS in production
    # To create a self-signed certificate type openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
    #ssl_context=('cert.pem', 'key.pem')
    app.run(host='0.0.0.0', ssl_context=('cert.pem', 'key.pem') ) 
