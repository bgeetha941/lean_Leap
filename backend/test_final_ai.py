import requests
import json

# Try to get a question directly from your backend
url = "http://localhost:5000/api/adaptive-test/next-question"
headers = {"Content-Type": "application/json"}
data = {
    "topic": "Python",
    "difficulty": "Easy",
    "mode": "Mock Test"
}

try:
    print("Sending test request to your backend...")
    response = requests.post(url, headers=headers, json=data, timeout=30)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")
