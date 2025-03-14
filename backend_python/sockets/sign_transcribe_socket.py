import cv2
import mediapipe as mp
import numpy as np
import math
from flask_socketio import SocketIO
from cvzone.ClassificationModule import Classifier
from cvzone.HandTrackingModule import HandDetector 

# Initialize MediaPipe Hand Detection
mp_hands = mp.solutions.hands
hands = mp_hands.Hands()

# Initialize Hand Detector and Classifier
detector = HandDetector(maxHands=1)
classifier = Classifier("models/A-D_model.h5", "models/A-D_labels.txt")

# Constants
IMG_SIZE = 300
LABELS = ['A', 'B', 'C', 'D']


def register_sign_transcriber(socketio):
    @socketio.on("frame")
    def handle_frame(data):
        try:
            print("📸 Frame received from client") 

            if not data:
                print("⚠️ Received empty frame data!")
                return

            # Decode the frame from the client
            np_arr = np.frombuffer(data, np.uint8)
            frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

            if frame is None:
                print("⚠️ Failed to decode frame!")
                return
            
            print(f"✅ Frame successfully decoded: {frame.shape}")  # Print frame shape
            
            # Convert frame to RGB for MediaPipe processing
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = hands.process(frame_rgb)

            # Default translation if no hands are detected
            translation = "No hand detected"

            if results.multi_hand_landmarks:
                print(f"🖐️ {len(results.multi_hand_landmarks)} hand(s) detected.")  # Print hand count

                for hand_landmarks in results.multi_hand_landmarks:
                    # Extract landmarks
                    hand_data = np.array([[lm.x, lm.y, lm.z] for lm in hand_landmarks.landmark]).flatten()

                    if len(hand_data) == 63:
                        print("📌 Hand landmarks successfully extracted.")

                        # Detect hands in the image
                        hands_detected, img = detector.findHands(frame, draw=False)

                        if hands_detected:
                            hand = hands_detected[0]
                            x, y, w, h = hand['bbox']

                            print(f"📏 Hand Bounding Box: x={x}, y={y}, w={w}, h={h}")

                            # Crop and preprocess the hand region
                            img_crop = frame[max(0, y - 20):y + h + 20, max(0, x - 20):x + w + 20]
                            img_white = np.ones((IMG_SIZE, IMG_SIZE, 3), np.uint8) * 255

                            aspect_ratio = h / w

                            if aspect_ratio > 1:
                                scale_factor = IMG_SIZE / h
                                new_width = math.ceil(scale_factor * w)
                                img_resized = cv2.resize(img_crop, (new_width, IMG_SIZE))
                                w_gap = math.ceil((IMG_SIZE - new_width) / 2)
                                img_white[:, w_gap:w_gap + new_width] = img_resized
                            else:
                                scale_factor = IMG_SIZE / w
                                new_height = math.ceil(scale_factor * h)
                                img_resized = cv2.resize(img_crop, (IMG_SIZE, new_height))
                                h_gap = math.ceil((IMG_SIZE - new_height) / 2)
                                img_white[h_gap:h_gap + new_height, :] = img_resized

                            # Get prediction from the classifier
                            prediction, index = classifier.getPrediction(img_white, draw=False)
                            translation = LABELS[index]
                            print(f"🖐️ Detected Sign: {translation}")

            # Emit translation update
            socketio.emit('translationupdate', {'translation': translation})


        except Exception as e:
            print(f"❌ Error processing frame: {str(e)}")


# from flask import Blueprint, jsonify, request
# import os
# import pickle
# import cv2
# import mediapipe as mp
# import numpy as np

# # Initialize the Blueprint for gesture routes
# touch_routes = Blueprint('touch_routes', __name__)

# # Load the gesture recognition model
# script_dir = os.path.dirname(os.path.abspath(__file__))
# model_path = os.path.join(script_dir, '..', 'Model', 'model.p')
# model_dict = pickle.load(open(model_path, 'rb'))
# model = model_dict['model']

# # Initialize MediaPipe Hands
# mp_hands = mp.solutions.hands
# hands = mp_hands.Hands(static_image_mode=True, min_detection_confidence=0.3)

# # Labels for gesture recognition
# labels_dict = {
#     0: 'A', 1: 'B', 2: 'C', 3: 'D', 4: 'E', 5: 'F', 6: 'G', 7: 'H', 8: 'I', 9: 'J',
#     10: 'K', 11: 'L', 12: 'M', 13: 'N', 14: 'O', 15: 'P', 16: 'Q', 17: 'R', 18: 'S',
#     19: 'T', 20: 'U', 21: 'V', 22: 'W', 23: 'X', 24: 'Y', 25: 'Z'
# }

# @touch_routes.route('/hands', methods=['POST'])
# def recognize_gesture():
#     if 'file' not in request.files:
#         return jsonify({"status": "error", "message": "No file part"}), 400

#     file = request.files['file']
#     if file.filename == '':
#         return jsonify({"status": "error", "message": "No selected file"}), 400

#     try:
#         # Read the image file
#         file_bytes = np.frombuffer(file.read(), np.uint8)
#         frame = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)

#         # Process the frame for gesture recognition
#         data_aux = []
#         x_ = []
#         y_ = []

#         H, W, _ = frame.shape
#         frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
#         results = hands.process(frame_rgb)

#         if results.multi_hand_landmarks:
#             for hand_landmarks in results.multi_hand_landmarks:
#                 for i in range(len(hand_landmarks.landmark)):
#                     x = hand_landmarks.landmark[i].x
#                     y = hand_landmarks.landmark[i].y
#                     x_.append(x)
#                     y_.append(y)

#                 for i in range(len(hand_landmarks.landmark)):
#                     x = hand_landmarks.landmark[i].x
#                     y = hand_landmarks.landmark[i].y
#                     data_aux.append(x - min(x_))
#                     data_aux.append(y - min(y_))

#             x1 = int(min(x_) * W) - 10
#             y1 = int(min(y_) * H) - 10
#             x2 = int(max(x_) * W) - 10
#             y2 = int(max(y_) * H) - 10

#             # Predict the gesture
#             prediction = model.predict([np.asarray(data_aux)])
#             predicted_character = labels_dict[int(prediction[0])]

#             return jsonify({
#                 "status": "success",
#                 "predicted_character": predicted_character,
#                 "bounding_box": [x1, y1, x2, y2]
#             })
#         else:
#             return jsonify({"status": "error", "message": "No hand detected"}), 404

#     except Exception as e:
#         return jsonify({"status": "error", "message": str(e)}), 500

# def create_touch_routes(app):
#     app.register_blueprint(touch_routes, url_prefix='/gesture')