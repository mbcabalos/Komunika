#  Create a env first by typing python -m venv .venv, Activate the env first using venv\Scripts\activate before using pip install -r flask_modules.txt.
# To know if you have install the modules type pip freeze and if you added a new modules type pip freeze > flask_modules.txt

from flask import Flask
from flask_cors import CORS
from flask_socketio import SocketIO
import pyttsx3
import os

from datetime import datetime
socketio = SocketIO(cors_allowed_origins="*")

def create_app():
    app = Flask(__name__)
    CORS(app)  # Enable CORS for all routes

    # Import and register blueprints
    from controllers.text_to_speech import tts_blueprint
    from controllers.speech_to_text import stt_blueprint
    app.register_blueprint(tts_blueprint)
    app.register_blueprint(stt_blueprint)

    return app



if __name__ == '__main__':
    app = create_app()
    # Use HTTPS in production
    # To create a self-signed certificate type openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
    #ssl_context=('cert.pem', 'key.pem')
    app.run(host='0.0.0.0', ssl_context=('cert.pem', 'key.pem')) 
