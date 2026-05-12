import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'adaptive_test_setup.dart';

class AdaptiveTestAnalyticsScreen extends StatefulWidget {
  final String sessionId;
  const AdaptiveTestAnalyticsScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<AdaptiveTestAnalyticsScreen> createState() => _AdaptiveTestAnalyticsScreenState();
}

class _AdaptiveTestAnalyticsScreenState extends State<AdaptiveTestAnalyticsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _analytics;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      final res = await _apiService.getAdaptiveAnalytics(widget.sessionId);
      if (res['success'] == true) {
        setState(() {
          _analytics = res;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load analytics. Try again.')),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: Text('Performance Analysis', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _analytics == null
              ? Center(
                  child: Text('No analytics data found.',
                      style: GoogleFonts.inter(color: Colors.white54)),
                )
              : _buildAnalyticsBody(),
    );
  }

  Widget _buildAnalyticsBody() {
    final data = _analytics!;
    final accuracy = (data['accuracy_percentage'] as num?)?.toStringAsFixed(1) ?? '0.0';
    final avgTime = (data['average_time_per_question'] as num?)?.toStringAsFixed(1) ?? '0.0';
    final correct = data['correct_answers']?.toString() ?? '0';
    final incorrect = data['incorrect_answers']?.toString() ?? '0';
    final summary = data['performance_summary']?.toString() ?? '';
    final strongTopics = (data['strong_topics'] as List?) ?? [];
    final weakTopics = (data['weak_topics'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Summary Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.withOpacity(0.15), Colors.teal.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.teal.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.teal, size: 24),
                    const SizedBox(width: 12),
                    Text('AI Performance Insight',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    summary,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 15, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Accuracy', '$accuracy%', Icons.verified_outlined, Colors.blueAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Avg Pace', '${avgTime}s', Icons.speed_outlined, Colors.orangeAccent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Correct', correct, Icons.check_circle_outline, Colors.teal),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Incorrect', incorrect, Icons.error_outline, Colors.redAccent),
              ),
            ],
          ),

          const SizedBox(height: 40),
          
          _buildTopicSection('💪 Key Strengths', strongTopics, Colors.green),
          const SizedBox(height: 24),
          _buildTopicSection('📌 Areas for Improvement', weakTopics, Colors.orangeAccent),

          const SizedBox(height: 48),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AdaptiveTestSetupScreen()),
                  (route) => route.isFirst,
                );
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                'TAKE ANOTHER TEST',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'RETURN TO DASHBOARD',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.1),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTopicSection(String title, List topics, Color accent) {
    if (topics.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: topics
              .map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withOpacity(0.3)),
                    ),
                    child: Text(t.toString(), style: GoogleFonts.inter(color: accent, fontWeight: FontWeight.w600, fontSize: 13)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
