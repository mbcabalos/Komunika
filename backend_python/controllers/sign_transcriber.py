from flask import Blueprint, request, jsonify
import cv2
import numpy as np
import math
from cvzone.HandTrackingModule import HandDetector
from cvzone.ClassificationModule import Classifier
import logging
from flask_cors import CORS

# Blueprint definition
sign_language_blueprint = Blueprint('sign_language', __name__)

# test
import os
print("keras_model.h5 exists:", os.path.exists("models/keras_model.h5"))
print("labels.txt exists:", os.path.exists("models/labels.txt"))

# Initialize hand detector and classifier
detector = HandDetector(maxHands=1)
classifier = Classifier("models/keras_model.h5", "models/labels.txt")
imgSize = 300
labels = ['idle', 'A', 'B', 'C', 'D']

# Gesture detection Route
@sign_language_blueprint.route('/api/detect', methods=['POST'])
def detect_gesture():
    try:
        logging.debug("Received request for gesture detection")
        if 'image' not in request.files:
            return jsonify({'error': 'No image provided'}), 400

        file = request.files['image']
        img = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)
        hands, img = detector.findHands(img)
        print("Detected Hands:", hands) #test

        if hands:
            hand = hands[0]
            x, y, w, h = hand['bbox']
            imgWhite = np.ones((imgSize, imgSize, 3), np.uint8) * 255
            y1, y2 = max(0, y - 20), min(img.shape[0], y + h + 20)
            x1, x2 = max(0, x - 20), min(img.shape[1], x + w + 20)
            imgCrop = img[y1:y2, x1:x2]
            aspectRatio = h / w

            if aspectRatio > 1:
                k = imgSize / h
                wCal = math.ceil(k * w)
                imgResize = cv2.resize(imgCrop, (wCal, imgSize))
                wGap = math.ceil((imgSize - wCal) / 2)
                imgWhite[:, wGap:wGap + imgResize.shape[1]] = imgResize
            else:
                k = imgSize / w
                hCal = math.ceil(k * h)
                imgResize = cv2.resize(imgCrop, (imgSize, hCal))
                hGap = math.ceil((imgSize - hCal) / 2)
                imgWhite[hGap:hGap + imgResize.shape[0], :] = imgResize

            # ✅ Show the final processed image before prediction
            cv2.imshow("Processed Image", imgWhite)
            cv2.waitKey(0)  # Pause execution to view the image
            cv2.destroyAllWindows()  # Close the image window after key press 

            prediction, index = classifier.getPrediction(imgWhite, draw=False)
            # test
            print(f"Raw Model Predictions: {prediction}")  # Print confidence scores
            print(f"Predicted Index: {index}")  # Print predicted index
            print(f"Predicted Label: {labels[index]}")  # Print final label

            # return jsonify({'label': labels[index]})
            return jsonify({'label': labels[index], 'confidence': float(prediction[index])}) #If "confidence" is low (e.g., 0.2 or 0.3), the model is struggling with detection
        else:
            return jsonify({'error': 'No hand detected'}), 400
    except Exception as e:
        logging.error(f"An error occurred: {str(e)}")
        return jsonify({'error': str(e)}), 500
