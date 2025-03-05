import cv2
import mediapipe as mp
import numpy as np
import math
from flask_socketio import SocketIO
from cvzone.ClassificationModule import Classifier
from cvzone.HandTrackingModule import HandDetector  # ✅ Added missing import

# Initialize MediaPipe Hand Detection
mp_hands = mp.solutions.hands
hands = mp_hands.Hands()

# Initialize Hand Detector and Classifier
detector = HandDetector(maxHands=1)
classifier = Classifier("models/keras_model.h5", "models/labels.txt")

# Constants
IMG_SIZE = 300
LABELS = ['idle', 'A', 'B', 'C', 'D']

def register_sign_transcriber(socketio):
    @socketio.on("frame")
    def handle_frame(data):
        try:
            print("📸 Frame received from client")  # Print frame reception

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

            # Encode the processed frame as JPEG and send it back
            _, jpeg = cv2.imencode('.jpg', frame)
            frame_bytes = jpeg.tobytes()
            socketio.emit('frame_response', {'frame': frame_bytes})

        except Exception as e:
            print(f"❌ Error processing frame: {str(e)}")
