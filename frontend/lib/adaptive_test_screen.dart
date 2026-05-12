import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'adaptive_test_analytics.dart';
import 'api_service.dart';

// ─────────────────────────────────────────────────────────────
//  Data model for a single queued question
// ─────────────────────────────────────────────────────────────
class _QuestionItem {
  final int id;
  final String question;
  final List<String> options;
  final String answer;
  final String explanation;
  final int difficulty;
  _QuestionItem({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
    required this.difficulty,
  });
  factory _QuestionItem.fromMap(Map<String, dynamic> m) => _QuestionItem(
        id: (m['question_id'] as num).toInt(),
        question: m['question']?.toString() ?? '',
        options: List<String>.from(m['options'] ?? []),
        answer: m['answer']?.toString() ?? '',
        explanation: m['explanation']?.toString() ?? '',
        difficulty: (m['difficulty'] as num?)?.toInt() ?? 2,
      );
}

// ─────────────────────────────────────────────────────────────
//  Active Test Screen (with local queue for instant transitions)
// ─────────────────────────────────────────────────────────────
class AdaptiveTestScreen extends StatefulWidget {
  final String sessionId;
  final String mode;
  final String topic;
  final int questionLimit; // 20 for Aptitude, 50 for Domain

  const AdaptiveTestScreen({
    Key? key,
    required this.sessionId,
    required this.mode,
    required this.topic,
    required this.questionLimit,
  }) : super(key: key);

  @override
  State<AdaptiveTestScreen> createState() => _AdaptiveTestScreenState();
}

class _AdaptiveTestScreenState extends State<AdaptiveTestScreen> {
  final ApiService _api = ApiService();

  // ── Queue ──────────────────────────────────────────────────
  final List<_QuestionItem> _queue = [];
  bool _isFetching = false;       // background Gemini call running
  bool _initialLoading = true;    // first ever load

  // ── Current displayed question ─────────────────────────────
  _QuestionItem? _current;
  int _difficulty = 2;

  // ── Answer state ───────────────────────────────────────────
  String? _selectedOption;
  bool _isEvaluating = false;
  bool? _wasCorrect;
  String? _shownExplanation;

  // ── Gamification ───────────────────────────────────────────
  int _xp = 0;
  int _streak = 0;
  int _questionsAttempted = 0;

  // ── Timer ──────────────────────────────────────────────────
  int _timeTaken = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchBatch(initial: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Fetch a batch of 3 questions ───────────────────────────
  Future<void> _fetchBatch({bool initial = false}) async {
    if (_isFetching) return;
    setState(() => _isFetching = true);

    try {
      final res = await _api.getNextQuestion(
        widget.sessionId, widget.mode, widget.topic, _difficulty,
        batchSize: 3,
      );
      if (res['success'] == true) {
        final batch = (res['questions'] as List)
            .map((q) => _QuestionItem.fromMap(q as Map<String, dynamic>))
            .toList();
        setState(() {
          _queue.addAll(batch);
          if (initial) {
            _initialLoading = false;
            _advanceToNextQuestion();
          }
        });
      } else {
        _showError('Could not load questions: ${res['error'] ?? ''}');
        if (initial) setState(() => _initialLoading = false);
      }
    } catch (e) {
      _showError('Network error: $e');
      if (initial) setState(() => _initialLoading = false);
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  // ── Pop next question from queue; if running low, prefetch ─
  void _advanceToNextQuestion() {
    // Auto-finish when question limit is reached
    if (_questionsAttempted >= widget.questionLimit) {
      _endTest();
      return;
    }

    setState(() {
      _selectedOption = null;
      _isEvaluating = false;
      _wasCorrect = null;
      _shownExplanation = null;
    });

    if (_queue.isNotEmpty) {
      setState(() => _current = _queue.removeAt(0));
      _restartTimer();
    }

    // Prefetch more when queue has ≤ 1 left (background, no loading spinner)
    if (_queue.length <= 1 && !_isFetching) {
      _fetchBatch();
    }
  }

  // ── Timer ──────────────────────────────────────────────────
  void _restartTimer() {
    _timeTaken = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _timeTaken++);
    });
  }

  // ── Submit answer ──────────────────────────────────────────
  Future<void> _submitAnswer() async {
    if (_selectedOption == null || _current == null) return;
    _timer?.cancel();
    setState(() => _isEvaluating = true);

    try {
      final res = await _api.submitAdaptiveAnswer(
        widget.sessionId, _current!.id, _selectedOption!, _timeTaken);

      if (res['success'] == true) {
        setState(() {
          _wasCorrect = res['is_correct'] as bool?;
          _shownExplanation = res['explanation']?.toString() ?? _current!.explanation;
          _xp = (res['new_xp_total'] as num?)?.toInt() ?? _xp;
          _streak = (res['current_streak'] as num?)?.toInt() ?? _streak;
          _difficulty = (res['next_recommended_difficulty'] as num?)?.toInt() ?? _difficulty;
          _questionsAttempted++;
        });
      } else {
        _showError('Submit failed. Try again.');
        setState(() => _isEvaluating = false);
      }
    } catch (e) {
      _showError('Error: $e');
      setState(() => _isEvaluating = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _endTest() {
    _timer?.cancel();
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => AdaptiveTestAnalyticsScreen(sessionId: widget.sessionId)));
  }

  // ╔══════════════════════════════════════════════════════════╗
  //  UI Helpers
  // ╚══════════════════════════════════════════════════════════╝

  String get _diffLabel => _difficulty <= 1 ? 'EASY' : _difficulty == 2 ? 'MEDIUM' : 'HARD';
  Color get _diffColor => _difficulty <= 1 ? Colors.green : _difficulty == 2 ? Colors.orange : Colors.redAccent;

  Widget _buildGamificationBar() {
    final progress = widget.questionLimit > 0
        ? _questionsAttempted / widget.questionLimit
        : 0.0;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: const Color(0xFF1F2937),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pill(Icons.star_rounded, '$_xp XP', Colors.amber),
              _pill(Icons.local_fire_department, 'x$_streak', Colors.orange),
              // Question progress
              Text(
                '$_questionsAttempted / ${widget.questionLimit}',
                style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              _pill(Icons.timer_outlined, '${_timeTaken}s', Colors.lightBlueAccent),
            ],
          ),
        ),
        // Progress bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[850],
          color: progress < 0.5
              ? Colors.teal
              : progress < 0.8
                  ? Colors.orange
                  : Colors.green,
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _pill(IconData icon, String label, Color color) => Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.outfit(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
      ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: Text(
          '${widget.topic}  •  Q${_questionsAttempted + 1} / ${widget.questionLimit}',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 15)),
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: _endTest,
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent, size: 18),
            label: const Text('Finish', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          _buildGamificationBar(),
          Expanded(
            child: _initialLoading
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const CircularProgressIndicator(color: Colors.teal),
                      const SizedBox(height: 20),
                      Text('Generating first set of questions...',
                          style: GoogleFonts.inter(color: Colors.white54)),
                    ]))
                : _current == null
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const CircularProgressIndicator(color: Colors.teal),
                          const SizedBox(height: 16),
                          Text('Loading next question...', style: GoogleFonts.inter(color: Colors.white54)),
                        ]))
                    : _buildQuestionBody(),
          ),
          if (!_initialLoading && _current != null) _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildQuestionBody() {
    final q = _current!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Difficulty chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: _diffColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _diffColor.withOpacity(0.5)),
            ),
            child: Text(_diffLabel,
                style: GoogleFonts.outfit(color: _diffColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(height: 16),

          // Result banner
          if (_wasCorrect != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: (_wasCorrect! ? Colors.green : Colors.redAccent).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: (_wasCorrect! ? Colors.green : Colors.redAccent).withOpacity(0.5)),
              ),
              child: Row(children: [
                Icon(_wasCorrect! ? Icons.check_circle : Icons.cancel,
                    color: _wasCorrect! ? Colors.green : Colors.redAccent),
                const SizedBox(width: 10),
                Text(_wasCorrect! ? 'Correct! +${_wasCorrect! ? (_timeTaken < 15 ? 15 : 10) : 0} XP' : 'Incorrect. Keep going!',
                    style: GoogleFonts.outfit(
                        color: _wasCorrect! ? Colors.green : Colors.redAccent,
                        fontWeight: FontWeight.bold)),
              ]),
            ),

          // Question
          Text(q.question, style: GoogleFonts.inter(fontSize: 19, color: Colors.white, height: 1.5)),
          const SizedBox(height: 24),

          // Options
          ...q.options.asMap().entries.map((entry) {
            final label = String.fromCharCode(65 + entry.key);
            final opt = entry.value;
            final isSelected = _selectedOption == opt;
            final isCorrectOpt = q.answer == opt;
            final showGreen = _isEvaluating && isCorrectOpt;
            final showRed = _isEvaluating && isSelected && !isCorrectOpt;

            Color border = Colors.grey[800]!;
            Color bg = const Color(0xFF1F2937);
            Color txt = Colors.white70;
            if (showGreen) { border = Colors.green; bg = Colors.green.withOpacity(0.15); txt = Colors.green; }
            else if (showRed) { border = Colors.redAccent; bg = Colors.redAccent.withOpacity(0.15); txt = Colors.redAccent; }
            else if (isSelected) { border = Colors.teal; bg = Colors.teal.withOpacity(0.1); txt = Colors.white; }

            return GestureDetector(
              onTap: _isEvaluating ? null : () => setState(() => _selectedOption = opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: 1.5)),
                child: Row(children: [
                  Container(
                    width: 28, height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: border.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: border)),
                    child: Text(label, style: GoogleFonts.outfit(color: border, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(opt, style: GoogleFonts.inter(color: txt, fontSize: 15, height: 1.4))),
                  if (showGreen) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  if (showRed) const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                ]),
              ),
            );
          }),

          // Explanation
          if (_isEvaluating && (_shownExplanation?.isNotEmpty ?? false))
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('💡 Explanation', style: GoogleFonts.outfit(color: Colors.amber, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(_shownExplanation!, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.4)),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(color: const Color(0xFF1F2937), border: Border(top: BorderSide(color: Colors.grey[800]!))),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isEvaluating
              ? _advanceToNextQuestion     // INSTANT — no network call needed
              : (_selectedOption != null ? _submitAnswer : null),
          icon: Icon(_isEvaluating ? Icons.arrow_forward_rounded : Icons.check_rounded, color: Colors.white),
          label: Text(
            _isEvaluating ? 'Next Question →' : 'Submit Answer',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isEvaluating ? Colors.indigo : Colors.teal,
            disabledBackgroundColor: Colors.grey[700],
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
