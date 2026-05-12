import os
from dotenv import load_dotenv
from google import genai

load_dotenv()
API_KEY = os.environ.get("GEMINI_API_KEY")

client = genai.Client(api_key=API_KEY)

batch_size = 3
topic = "General"
mode = "Aptitude"
dif_label = "Medium"
weak_topics_str = "None"
past_accuracy = 0.0

prompt = f"""Generate exactly {batch_size} different MCQ questions for placement preparation.
Topic: {topic}
Domain: {mode}
Difficulty: {dif_label}
Weak areas to focus: {weak_topics_str}
User accuracy so far: {past_accuracy:.1f}%

Rules:
- All {batch_size} questions must be unique and different from each other
- Real exam-style questions only
- Exactly 4 options per question
- The "answer" field must be the EXACT text of the correct option
- Short, clear explanation

Return ONLY a valid JSON array with exactly {batch_size} objects. No markdown, no extra text:
[{{"question":"...","options":["A text","B text","C text","D text"],"answer":"exact option text","explanation":"...","difficulty":"{dif_label}"}}]"""

models_to_try = ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-2.0-flash-001', 'gemini-1.5-flash']

for model_name in models_to_try:
    try:
        print(f"Trying {model_name}...")
        response = client.models.generate_content(model=model_name, contents=prompt)
        text_clean = response.text
        print(f"Success! Response text:\n{text_clean}")
        break
    except Exception as e:
        print(f"Failed {model_name}: {e}")
