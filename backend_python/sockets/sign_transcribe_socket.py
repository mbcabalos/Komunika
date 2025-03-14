import os
import pickle
import cv2
import numpy as np
import mediapipe as mp
from flask_socketio import SocketIO, emit

# Initialize Flask-SocketIO
socketio = SocketIO()

# Load the gesture recognition model
script_dir = os.path.dirname(os.path.abspath(__file__))
model_path = os.path.join(script_dir, '..', 'models', 'model.p')
model_dict = pickle.load(open(model_path, 'rb'))
model = model_dict['model']

# Initialize MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False, min_detection_confidence=0.3)

# Labels for gesture recognition
labels = {
    0: 'A', 1: 'B', 2: 'C', 3: 'D', 4: 'E', 5: 'F', 6: 'G', 7: 'H', 8: 'I', 9: 'J',
    10: 'K', 11: 'L', 12: 'M', 13: 'N', 14: 'O', 15: 'P', 16: 'Q', 17: 'R', 18: 'S',
    19: 'T', 20: 'U', 21: 'V', 22: 'W', 23: 'X', 24: 'Y', 25: 'Z'
}

def register_sign_transcriber(socketio):
    @socketio.on("frame")
    def handle_frame(data):
        try:
            print(f"Received data size: {len(data)} bytes")

            # Convert the incoming data (Uint8) into a frame (image)
            np_arr = np.frombuffer(data, np.uint8)
            frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

            if frame is None:
                print("⚠️ Failed to decode frame!")
                return
            
            frame = cv2.rotate(frame, cv2.ROTATE_90_COUNTERCLOCKWISE)

            print(f"✅ Frame successfully decoded: {frame.shape}")  # Print frame shape

            # Process the frame for gesture recognition
            data_aux = []
            x_ = []
            y_ = []

            H, W, _ = frame.shape

            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = hands.process(frame_rgb)

            translation = "No hand detected"

            if results.multi_hand_landmarks:
                print(f"Hands detected: {len(results.multi_hand_landmarks)}")
                for hand_landmarks in results.multi_hand_landmarks:
                    for i in range(len(hand_landmarks.landmark)):
                        x = hand_landmarks.landmark[i].x
                        y = hand_landmarks.landmark[i].y
                        x_.append(x)
                        y_.append(y)

                    for i in range(len(hand_landmarks.landmark)):
                        x = hand_landmarks.landmark[i].x
                        y = hand_landmarks.landmark[i].y
                        data_aux.append(x - min(x_))
                        data_aux.append(y - min(y_))

                x1 = int(min(x_) * W) - 10
                y1 = int(min(y_) * H) - 10
                x2 = int(max(x_) * W) - 10
                y2 = int(max(y_) * H) - 10

                # Predict the gesture
                print(f"Data features shape: {len(data_aux)}") 
                prediction = model.predict([np.asarray(data_aux)])
                translation = labels[int(prediction[0])]
                print(f"🖐️ Detected Sign: {translation}")

            # # Display the frame with the detected gesture
            # cv2.putText(frame, translation, (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2)

            # # Show the frame with the prediction
            # cv2.imshow('Received Frame - Gesture Recognition', frame)

            # # Emit translation update to the client
            emit('translationupdate', {'translation': translation})

            # # Close the window when the user presses 'q'
            # if cv2.waitKey(1) & 0xFF == ord('q'):
            #     cv2.destroyAllWindows()

        except Exception as e:
            print(f"❌ Error processing frame: {str(e)}")
            emit('translationupdate', {'translation': "Error processing frame"})
