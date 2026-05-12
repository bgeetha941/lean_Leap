import os
from google import genai
from dotenv import load_dotenv

load_dotenv()
api_key = os.environ.get("GEMINI_API_KEY")

print(f"Testing with API Key: {api_key[:10]}...")

client = genai.Client(api_key=api_key)
try:
    response = client.models.generate_content(
        model='gemini-1.5-flash',
        contents="Hello, say 'API is working'"
    )
    print(f"SUCCESS: {response.text}")
except Exception as e:
    print(f"FAILED: {e}")
