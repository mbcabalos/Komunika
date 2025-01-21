from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

@app.route('/')
def index():
    return "Hello World"

@app.route('/api/data', methods=['GET'])
def get_data():
    # Example of sending data to the Flutter app
    data = {
        "message": "Hello from Flask!",
        "status": "success"
    }
    return jsonify(data)

@app.route('/api/submit', methods=['POST'])
def submit_data():
    # Example of receiving data from the Flutter app
    input_data = request.json
    return jsonify({
        "message": "Data received!",
        "received": input_data
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
