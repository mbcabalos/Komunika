import os
import pickle
import cv2
import mediapipe as mp
import numpy as np

# Load the gesture recognition model
script_dir = os.path.dirname(os.path.abspath(__file__))
model_path = os.path.join(script_dir, '..', 'models', 'model.p')
model_dict = pickle.load(open(model_path, 'rb'))
model = model_dict['model']

# Initialize MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False, min_detection_confidence=0.3)

# Labels for gesture recognition
labels_dict = {
    0: 'A', 1: 'B', 2: 'C', 3: 'D', 4: 'E', 5: 'F', 6: 'G', 7: 'H', 8: 'I', 9: 'J',
    10: 'K', 11: 'L', 12: 'M', 13: 'N', 14: 'O', 15: 'P', 16: 'Q', 17: 'R', 18: 'S',
    19: 'T', 20: 'U', 21: 'V', 22: 'W', 23: 'X', 24: 'Y', 25: 'Z'
}

def recognize_gesture_from_camera():
    try:
        cap = cv2.VideoCapture(0)  # 0 for the default webcam
        if not cap.isOpened():
            print("Error: Could not open video stream.")
            return "Error: Camera not found"

        while True:
            ret, frame = cap.read()
            if not ret:
                print("Error: Failed to capture image.")
                break

            data_aux = []
            x_ = []
            y_ = []

            H, W, _ = frame.shape
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = hands.process(frame_rgb)

            if results.multi_hand_landmarks:
                for hand_landmarks in results.multi_hand_landmarks:
                    # Limit the features to the number expected by the model (e.g., 42 features)
                    for i in range(21):  # Extract positions only for 21 landmarks (or whatever the model was trained on)
                        x = hand_landmarks.landmark[i].x
                        y = hand_landmarks.landmark[i].y
                        x_.append(x)
                        y_.append(y)

                # Ensure only 42 features are passed
                data_aux = []
                for i in range(21):
                    data_aux.append(x_[i] - min(x_))  # Normalize or process as needed
                    data_aux.append(y_[i] - min(y_))  # Normalize or process as needed

                # Predict the gesture
                prediction = model.predict([np.asarray(data_aux)])
                predicted_character = labels_dict[int(prediction[0])]

                # Display the predicted gesture on the frame
                cv2.putText(frame, predicted_character, (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2)

            else:
                cv2.putText(frame, "No hand detected", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)

            # Show the frame with the gesture prediction
            cv2.imshow('Hand Gesture Recognition', frame)

            # Break the loop when 'q' is pressed
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

        # Release the camera and close any open windows
        cap.release()
        cv2.destroyAllWindows()

    except Exception as e:
        print(f"Error: {e}")
        return "Error in gesture recognition"


# Example usage: Start the camera and detect gestures
recognize_gesture_from_camera()
