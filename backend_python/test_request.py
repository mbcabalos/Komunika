import requests

url = "http://127.0.0.1:5000/api/detect"
files = {"image": open("test_images/A.jpg", "rb")}  # Adjust path if needed

response = requests.post(url, files=files)
print(response.json())  # Should print {"label": "A"} or another letter
