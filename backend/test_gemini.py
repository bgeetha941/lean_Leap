import os
from dotenv import load_dotenv
from google import genai

load_dotenv()
API_KEY = os.environ.get("GEMINI_API_KEY")
print(f"Using API Key: {API_KEY[:10]}...")

try:
    client = genai.Client(api_key=API_KEY)
    prompt = "Hello"
    models_to_try = ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-2.0-flash-001', 'gemini-1.5-flash']
    
    for model_name in models_to_try:
        try:
            print(f"Trying {model_name}...")
            response = client.models.generate_content(model=model_name, contents=prompt)
            print(f"Success with {model_name}! Response: {response.text}")
            break
        except Exception as e:
            print(f"Failed {model_name}: {e}")
except Exception as e:
    print(f"Client init failed: {e}")
