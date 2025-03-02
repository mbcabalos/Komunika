from flask import Blueprint, request, jsonify
import cv2
import numpy as np
import math
from cvzone.HandTrackingModule import HandDetector
from cvzone.ClassificationModule import Classifier
import logging
from flask_cors import CORS

# Blueprint definition
sign_language_blueprint = Blueprint('gesture', __name__)

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

            prediction, index = classifier.getPrediction(imgWhite, draw=False)
            return jsonify({'label': labels[index]})
        else:
            return jsonify({'error': 'No hand detected'}), 400
    except Exception as e:
        logging.error(f"An error occurred: {str(e)}")
        return jsonify({'error': str(e)}), 500

# import cv2
# from cvzone.HandTrackingModule import HandDetector
# from cvzone.ClassificationModule import Classifier
# import numpy as np
# import math

# cap = cv2.VideoCapture(0)

# detector = HandDetector(maxHands=2)
# classifier = Classifier("models/keras_model.h5", "models/labels.txt")
# offset = 20
# imgSize = 300

# labels = ['idle', 'A', 'B', 'C', 'D']

# while True:
#     success, img = cap.read()
#     imgOutput = img.copy()
#     hands, img = detector.findHands(img)

#     if hands:
#         hand = hands[0]
#         x, y, w, h = hand['bbox']

#         imgWhite = np.ones((imgSize,imgSize,3),np.uint8)*255

#         # Handle boundary checks
#         y1, y2 = max(0, y - offset), min(img.shape[0], y + h + offset)
#         x1, x2 = max(0, x - offset), min(img.shape[1], x + w + offset)

#         imgCrop = img[y1:y2, x1:x2]

#         try:
#             imgCropShape = imgCrop.shape
#             aspectRatio = h / w

#             if aspectRatio > 1:
#                 k = imgSize / h
#                 wCal = math.ceil(k * w)
#                 imgResize = cv2.resize(imgCrop, (wCal, imgSize))
#                 wGap = math.ceil((imgSize - wCal) / 2)
#                 imgWhite[:, wGap:wGap + imgResize.shape[1]] = imgResize
#             else:
#                 k = imgSize / w
#                 hCal = math.ceil(k * h)
#                 imgResize = cv2.resize(imgCrop, (imgSize, hCal))
#                 hGap = math.ceil((imgSize - hCal) / 2)
#                 imgWhite[hGap:hGap + imgResize.shape[0], :] = imgResize

#             prediction, index = classifier.getPrediction(imgWhite, draw=False)
#             print(prediction, index)

#             cv2.putText(imgOutput, labels[index], (x, y - offset), cv2.FONT_HERSHEY_COMPLEX, 2, (255, 0, 255), 2)
#             cv2.rectangle(imgOutput, (x - offset, y - offset), (x + w + offset, y + h + offset), (255, 0, 255), 4)

#         except Exception as e:
#             print(f"Error during processing: {e}")

#         cv2.imshow("ImageCrop", imgCrop)
#         cv2.imshow("ImgWhite", imgWhite)

#     cv2.imshow("Image", imgOutput)
#     cv2.waitKey(1)