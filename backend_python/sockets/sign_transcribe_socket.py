import cv2
import tensorflow as tf
import mediapipe as mp
import numpy as np
import eventlet
from flask import json
import speech_recognition as sr
from flask_socketio import SocketIO

socketio = SocketIO()
print("Hello")

model = tf.keras.models.load_model("sign_language_model.h5")

# English and Filipino translations
sign_dict_en = {
    0: "Hello",
    1: "Thank You",
    2: "Sorry",
    3: "Yes",
    4: "No"
}

sign_dict_fil = {
    0: "Kamusta",
    1: "Salamat",
    2: "Paumanhin",
    3: "Oo",
    4: "Hindi"
}

# Initialize MediaPipe Hand Detection
mp_hands = mp.solutions.hands
hands = mp_hands.Hands()

# Initialize Video Capture
cap = cv2.VideoCapture(0)
def register_sign_transcriber(socketio):
    @socketio.on("sign_transcriber")
    def generate_frames():
            while True:
                success, frame = cap.read()
                if not success:
                    break

                frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                results = hands.process(frame_rgb)

                if results.multi_hand_landmarks:
                    for hand_landmarks in results.multi_hand_landmarks:
                        hand_data = np.array([[lm.x, lm.y, lm.z] for lm in hand_landmarks.landmark]).flatten()

                        if len(hand_data) == 63:
                            hand_data = np.expand_dims(hand_data, axis=0)
                            prediction = model.predict(hand_data)
                            predicted_class = np.argmax(prediction)

                            translation = sign_dict_en.get(predicted_class, "Unknown Sign")
                            socketio.emit('translationupdate', {'translation': translation})

                jpeg = cv2.imencode('.jpg', frame)
                frame_bytes = jpeg.tobytes()
                yield (b'--frame\r\n'
                    b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')