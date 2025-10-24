import eventlet
eventlet.monkey_patch()

import socket
from flask import Flask
from flask_cors import CORS
from flask_socketio import SocketIO
from controllers.text_to_speech import tts_blueprint
from sockets.audio_socket import register_transcription_events

def create_app():
    app = Flask(__name__)
    CORS(app)

    # Initialize SocketIO (Eventlet-friendly)
    socketio = SocketIO(app, cors_allowed_origins="*", async_mode="eventlet")

    # Blueprints
    app.register_blueprint(tts_blueprint)

    # Register all socket events
    register_transcription_events(socketio)
    
    @app.route("/")
    def home():
        return "🎧 Flask SocketIO Server is Running!"

    return app, socketio


if __name__ == "__main__":
    app, socketio = create_app()

    local_ip = socket.gethostbyname(socket.gethostname())
    print(f"Server running on:")
    print(f"🌐 Local:   http://127.0.0.1:5000")
    print(f"📱 Network: http://{local_ip}:5000 (for mobile access)")

    # Run the socket server
    socketio.run(app, host="0.0.0.0", port=5000, debug=True)
