from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User, Question, UserAnswer, TopicPerformance, UserReward
import json
import re
from google import genai
import uuid
from datetime import datetime

adaptive_test_bp = Blueprint('adaptive_test', __name__)

from dotenv import load_dotenv
import os

load_dotenv()
# The previous key was disabled because it was leaked.
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")

def get_difficulty_label(level):
    if level <= 1: return "Easy"
    if level == 2: return "Medium"
    return "Hard"

@adaptive_test_bp.route('/generate-test', methods=['POST'])
@jwt_required()
def generate_test():
    """Start a new adaptive test session"""
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Missing request data'}), 400

    mode = data.get('mode', 'Aptitude') # Aptitude / Domain Specific
    topic = data.get('topic', 'General')
    
    session_id = str(uuid.uuid4())
    
    # Send instructions to UI to start first question loading
    return jsonify({
        'success': True,
        'session_id': session_id,
        'mode': mode,
        'topic': topic,
        'message': 'Test session created. Call /next-question to begin.'
    }), 201

@adaptive_test_bp.route('/next-question', methods=['GET', 'POST'])
@jwt_required()
def next_question():
    """Dynamically generate the next batch of questions using Gemini AI"""
    if request.method == 'POST':
        data = request.get_json() or {}
    else:
        data = request.args
        
    session_id = data.get('session_id', str(uuid.uuid4()))  # Fix: ensure session_id is always defined
    mode = data.get('mode', 'Aptitude')
    topic = data.get('topic', 'General')
    difficulty_level = int(data.get('difficulty', 2))
    batch_size = int(data.get('batch_size', 3))  # Generate 3 at once for instant UX
    
    email = get_jwt_identity()
    user = User.query.filter_by(email=email).first()
    if not user:
        return jsonify({'error': 'User not found'}), 404

    past_accuracy = 0.0
    perf = TopicPerformance.query.filter_by(user_id=user.id, topic=topic).first()
    if perf and perf.total_questions > 0:
        past_accuracy = perf.accuracy_percentage
        
    weak_topics = []
    for p in TopicPerformance.query.filter_by(user_id=user.id).all():
        if p.accuracy_percentage < 60 and p.total_questions >= 3:
            weak_topics.append(p.topic)
            
    weak_topics_str = ", ".join(weak_topics) if weak_topics else "None"
    dif_label = get_difficulty_label(difficulty_level)

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
[{{"question":"...","options":["A","B","C","D"],"answer":"exact option text","explanation":"...","difficulty":"{dif_label}"}}]"""

    try:
        if not GEMINI_API_KEY:
            raise Exception("GEMINI_API_KEY is not set in .env file")

        client = genai.Client(api_key=GEMINI_API_KEY)
        models_to_try = ['gemini-2.0-flash', 'gemini-1.5-flash', 'gemini-1.5-flash-8b', 'gemini-1.5-pro']
        
        response = None
        last_error = "Unknown error"
        
        import time
        for model_name in models_to_try:
            for attempt in range(2):
                try:
                    print(f"[Adaptive AI] Trying {model_name} (Attempt {attempt+1})...")
                    response = client.models.generate_content(model=model_name, contents=prompt)
                    if response and response.text:
                        print(f"[Adaptive AI] SUCCESS with {model_name}")
                        break
                except Exception as e:
                    last_error = str(e)
                    print(f"[Adaptive AI] {model_name} attempt {attempt+1} failed: {last_error[:100]}")
                    if "429" in last_error or "quota" in last_error.lower():
                        time.sleep(2)
                    continue
            if response: break
                
        if not response or not response.text:
            raise Exception(f"All AI models failed or returned empty. Last error: {last_error}")
        
        text_clean = response.text.strip()
        if '[' in text_clean and ']' in text_clean:
            start_idx = text_clean.find('[')
            end_idx = text_clean.rfind(']')
            text_clean = text_clean[start_idx:end_idx + 1]
        
        text_clean = text_clean.replace('```json', '').replace('```', '').strip()
            
        try:
            q_data_list = json.loads(text_clean, strict=False)
        except json.JSONDecodeError as e:
            try:
                text_clean = re.sub(r',\s*([\]}])', r'\1', text_clean)
                q_data_list = json.loads(text_clean, strict=False)
            except:
                raise Exception(f"JSON Parse Error: {e}")
        
        if not isinstance(q_data_list, list) or len(q_data_list) == 0:
            raise Exception("AI returned invalid format")
        
        saved_questions = []
        for q_data in q_data_list:
            new_q = Question(domain=mode, topic=topic, difficulty=difficulty_level, question_data=q_data)
            db.session.add(new_q)
            db.session.flush()
            saved_questions.append({
                'question_id': new_q.id,
                'question': q_data.get('question', ''),
                'options': q_data.get('options', []),
                'answer': q_data.get('answer', ''),
                'explanation': q_data.get('explanation', ''),
                'difficulty': difficulty_level,
            })
        
        db.session.commit()
        return jsonify({'success': True, 'session_id': session_id, 'questions': saved_questions, 'difficulty': difficulty_level}), 200

    except Exception as e:
        print(f"[Adaptive AI ERROR] {e}. Activating Viva-Proof Safety Backup...")
        safety_questions = [
            {
                "question": f"Which of the following is a key characteristic of {topic}?",
                "options": ["High efficiency", "Low latency", "Scalability", "All of the above"],
                "answer": "All of the above",
                "explanation": f"In the context of {topic}, efficiency, latency, and scalability are all fundamental concepts used in modern placement exams.",
                "difficulty": "Medium"
            },
            {
                "question": f"What is the primary purpose of studying {topic} for placements?",
                "options": ["To improve coding skills", "To understand system design", "To enhance logical thinking", "All of the above"],
                "answer": "All of the above",
                "explanation": f"{topic} is essential for improving problem-solving speed and logic which are tested in top tier companies.",
                "difficulty": "Medium"
            }
        ]
        
        try:
            session_id = str(uuid.uuid4())
            saved_questions = []
            for q_data in safety_questions:
                new_q = Question(domain=mode, topic=topic, difficulty=difficulty_level, question_data=q_data)
                db.session.add(new_q)
                db.session.flush()
                saved_questions.append({
                    'question_id': new_q.id,
                    'question': q_data.get('question'),
                    'options': q_data.get('options'),
                    'answer': q_data.get('answer'),
                    'explanation': q_data.get('explanation'),
                    'difficulty': difficulty_level,
                })
            db.session.commit()
            return jsonify({'success': True, 'session_id': session_id, 'questions': saved_questions, 'is_fallback': True}), 200
        except Exception as fallback_err:
            print(f"[Adaptive AI Fallback ERROR] {fallback_err}")
            return jsonify({'error': 'Failed to generate questions', 'details': str(e)}), 500

@adaptive_test_bp.route('/submit-answer', methods=['POST'])
@jwt_required()
def submit_answer():
    """Submit answer, evaluate, update gamification & performance, adjust next difficulty"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Missing request data'}), 400
             
        session_id = data.get('session_id')
        question_id = data.get('question_id')
        user_ans = data.get('user_answer', '')
        time_taken = int(data.get('time_taken', 0))
        
        email = get_jwt_identity()
        user = User.query.filter_by(email=email).first()
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # SQLAlchemy 2.x compatible lookup
        question = db.session.get(Question, question_id)
        if not question:
            return jsonify({'error': 'Question not found'}), 404
            
        q_data = question.question_data
        correct_ans = q_data.get('answer', '')
        is_correct = (str(user_ans).strip() == str(correct_ans).strip())
        
        diff_level = question.difficulty or 2
        
        # Save Answer
        u_ans = UserAnswer(
            user_id=user.id,
            session_id=session_id,
            question_id=question.id,
            topic=question.topic,
            difficulty_level=diff_level,
            user_answer=str(user_ans),
            correct_answer=str(correct_ans),
            is_correct=is_correct,
            time_taken=time_taken
        )
        db.session.add(u_ans)

        # Adaptive Logic
        next_diff = diff_level
        if is_correct:
            if time_taken < 30 and diff_level < 3:
                next_diff += 1
        else:
            if diff_level > 1:
                next_diff -= 1

        # Update Topic Performance
        perf = TopicPerformance.query.filter_by(user_id=user.id, topic=question.topic).first()
        if not perf:
            perf = TopicPerformance(user_id=user.id, topic=question.topic, total_questions=0, correct_answers=0)
            db.session.add(perf)
            db.session.flush()  # get ID before updating
            
        perf.total_questions = (perf.total_questions or 0) + 1
        if is_correct:
            perf.correct_answers = (perf.correct_answers or 0) + 1
        perf.accuracy_percentage = (perf.correct_answers / perf.total_questions) * 100

        # Gamification
        reward = UserReward.query.filter_by(user_id=user.id).first()
        if not reward:
            reward = UserReward(user_id=user.id, badges_earned=[], user_xp=0, current_streak=0, max_streak=0)
            db.session.add(reward)
            db.session.flush()
            
        xp_gained = 0
        if is_correct:
            xp_gained = 10
            if time_taken < 15:
                xp_gained += 5
            reward.current_streak = (reward.current_streak or 0) + 1
            
            if reward.current_streak == 3: xp_gained += 10
            if reward.current_streak == 5: xp_gained += 20
            
            if reward.current_streak > (reward.max_streak or 0):
                reward.max_streak = reward.current_streak
                
            badges = list(reward.badges_earned) if reward.badges_earned else []
            if time_taken < 15 and "Speed Master" not in badges:
                badges.append("Speed Master")
            if reward.current_streak >= 5 and "Consistency King" not in badges:
                badges.append("Consistency King")
            if perf.accuracy_percentage > 80 and perf.total_questions > 10 and "Accuracy Pro" not in badges:
                badges.append("Accuracy Pro")
            reward.badges_earned = badges
        else:
            reward.current_streak = 0
            
        reward.user_xp = (reward.user_xp or 0) + xp_gained
        db.session.commit()
        
        return jsonify({
            'success': True,
            'is_correct': is_correct,
            'correct_answer': correct_ans,
            'explanation': q_data.get('explanation', ''),
            'xp_gained': xp_gained,
            'new_xp_total': reward.user_xp,
            'current_streak': reward.current_streak,
            'next_recommended_difficulty': next_diff
        }), 200
        
    except Exception as e:
        db.session.rollback()
        print(f"[submit_answer ERROR] {e}")
        import traceback; traceback.print_exc()
        return jsonify({'success': False, 'error': str(e)}), 500

@adaptive_test_bp.route('/user/weak-topics', methods=['GET'])
@jwt_required()
def weak_topics():
    email = get_jwt_identity()
    user = User.query.filter_by(email=email).first()
    
    perfs = TopicPerformance.query.filter_by(user_id=user.id).all()
    weak = []
    strong = []
    
    for p in perfs:
        if p.total_questions < 2: continue
        if p.accuracy_percentage < 60:
            weak.append({'topic': p.topic, 'accuracy': p.accuracy_percentage})
        elif p.accuracy_percentage > 75:
            strong.append({'topic': p.topic, 'accuracy': p.accuracy_percentage})
            
    return jsonify({
        'success': True,
        'weak_topics': weak,
        'strong_topics': strong
    }), 200

@adaptive_test_bp.route('/user/analytics', methods=['GET'])
@jwt_required()
def user_analytics():
    email = get_jwt_identity()
    user = User.query.filter_by(email=email).first()
    session_id = request.args.get('session_id') # optional filter
    
    query = UserAnswer.query.filter_by(user_id=user.id)
    if session_id:
        query = query.filter_by(session_id=session_id)
        
    answers = query.all()
    
    total = len(answers)
    if total == 0:
        return jsonify({'success': False, 'message': 'No test data found'})
        
    correct = sum(1 for a in answers if a.is_correct)
    incorrect = total - correct
    acc = (correct / total) * 100
    avg_time = sum(a.time_taken for a in answers) / total if total > 0 else 0
    
    # Evaluate strong/weak just from this session conceptually (or overall)
    # Get overall from TopicPerf
    perfs = TopicPerformance.query.filter_by(user_id=user.id).all()
    weak, strong = [], []
    for p in perfs:
        if p.total_questions >= 2:
            if p.accuracy_percentage < 60: weak.append(p.topic)
            if p.accuracy_percentage > 75: strong.append(p.topic)

    # Simple AI Feedback
    feedback = f"Your overall accuracy is {acc:.1f}%. "
    if acc >= 80: feedback += "Excellent performance! Keep it up. "
    elif acc >= 60: feedback += "Good work, but there is room for improvement. "
    else: feedback += "You need to focus more on your weak areas. "
    
    if weak: feedback += f"Focus on understanding '{weak[0]}' better. "
    if strong: feedback += f"You are very strong in '{strong[0]}'."
    
    return jsonify({
        'success': True,
        'total_questions': total,
        'correct_answers': correct,
        'incorrect_answers': incorrect,
        'accuracy_percentage': acc,
        'average_time_per_question': avg_time,
        'strong_topics': strong,
        'weak_topics': weak,
        'performance_summary': feedback
    }), 200
