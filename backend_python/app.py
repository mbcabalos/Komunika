import eventlet
import socket
from flask import Flask
from flask_cors import CORS
from flask_socketio import SocketIO
import pyttsx3
import os
from datetime import datetime

from sockets.stt_socket import register_transcription_events

def create_app():
    app = Flask(__name__)  # App instance should only be created here
    CORS(app)

    # Initialize SocketIO inside the function
    socketio = SocketIO(app, cors_allowed_origins="*", async_mode="eventlet")

    # Import and register blueprints
    from controllers.text_to_speech import tts_blueprint
    app.register_blueprint(tts_blueprint)

    # Sockets
    register_transcription_events(socketio)

    @app.route("/")
    def home():
        return "Flask SocketIO Server is Running!"

    @socketio.on("connect")
    def handle_connect():
        print("Client Connected!")
        socketio.emit("message", {"data": "Connected Successfully!"})

    @socketio.on("disconnect")
    def handle_disconnect():
        print("Client Disconnected!")

    return app, socketio  # Return both app and socketio

if __name__ == '__main__':
    app, socketio = create_app()
    local_ip = socket.gethostbyname(socket.gethostname())
    print(f"Server running on:")
    print(f"Local: http://127.0.0.1:5000")
    print(f"Network: http://{local_ip}:5000 (for mobile access)")
    socketio.run(app, host="0.0.0.0", port=6000, use_reloader=False)
    eventlet.monkey_patch() 
