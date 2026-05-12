import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'adaptive_test_screen.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ResultScreen({super.key, required this.data});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Map<String, dynamic> sessionData;
  late List learningPaths;

  @override
  void initState() {
    super.initState();
    sessionData = Map<String, dynamic>.from(widget.data);
    learningPaths = List.from(sessionData['learning_paths'] ?? []);
    
    // Normalize status if not present
    for (var path in learningPaths) {
      if (path is Map) {
        path['status'] ??= 'available';
        for (var step in (path['plan'] as List? ?? [])) {
          if (step is Map) step['status'] ??= 'not_started';
        }
      }
    }
  }

  bool _isLoadingTest = false;

  void _startTestForSkill(String skill) async {
    setState(() => _isLoadingTest = true);
    try {
      final res = await ApiService().generateAdaptiveTest('Domain Specific', skill);
      if (res['success'] == true && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AdaptiveTestScreen(
            sessionId: res['session_id'],
            mode: 'Domain Specific',
            topic: skill,
            questionLimit: 50, 
          ),
        ));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${res['message'] ?? 'Unknown'}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingTest = false);
    }
  }

  void _generateProjectPrompt(String skill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber),
            const SizedBox(width: 10),
            Text("AI Project Concept", style: GoogleFonts.outfit(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("For mastering $skill, here is a unique portfolio project idea:", 
                 style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: Text(
                "Build a 'Smart $skill Dashboard' that visualizes real-time data using professional best practices. Include features like automated reporting and secure authentication.",
                style: GoogleFonts.inter(color: Colors.amberAccent, height: 1.5, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Awesome!", style: GoogleFonts.inter(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchSearch(String query) async {
    final encoded = Uri.encodeComponent(query);
    final url = Uri.parse("https://www.google.com/search?q=$encoded");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _toggleStep(int pathIdx, int stepIdx) {
    setState(() {
      final path = learningPaths[pathIdx];
      final plan = path['plan'] as List;
      final step = plan[stepIdx];

      if (step['status'] == 'completed') {
        step['status'] = 'in_progress';
      } else if (step['status'] == 'in_progress') {
        step['status'] = 'completed';
      } else {
        step['status'] = 'in_progress';
      }

      bool allDone = plan.every((s) => s['status'] == 'completed');
      bool someDone = plan.any((s) => s['status'] == 'completed' || s['status'] == 'in_progress');
      
      if (allDone) {
        path['status'] = 'completed';
      } else if (someDone) {
        path['status'] = 'in_progress';
      } else {
        path['status'] = 'available';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int jdFitScore = int.tryParse(sessionData['jd_fit_score']?.toString() ?? '0') ?? 0;
    final int atsScore = int.tryParse(sessionData['ats_score']?.toString() ?? '0') ?? 0;
    final String fitLevel = sessionData['fit_level']?.toString() ?? "Analyzing...";
    
    final Map<String, dynamic> categorizedSkills = Map<String, dynamic>.from(sessionData['categorized_resume_skills'] ?? {});
    final List matchedSkills = List.from(sessionData['matched_skills'] ?? []);
    final List missingSkills = List.from(sessionData['missing_skills'] ?? []);
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: Text("Career Analysis", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // SCORING
            _buildScoringHeader(jdFitScore, atsScore, fitLevel),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(Icons.check_circle, "MATCHED SKILLS"),
                  const SizedBox(height: 16),
                  _buildSkillList(matchedSkills, Colors.greenAccent),

                  const SizedBox(height: 32),
                  _buildSectionTitle(Icons.error, "MISSING SKILLS"),
                  const SizedBox(height: 16),
                  _buildSkillList(missingSkills, Colors.redAccent),

                  const SizedBox(height: 32),

                  // SKILLS
                  _buildSectionTitle(Icons.psychology, "PROFILED SKILLSET ARCHITECTURE"),
                  const SizedBox(height: 20),
                  ...categorizedSkills.entries.map((entry) {
                    if ((entry.value as List).isEmpty) return const SizedBox.shrink();
                    return _buildSkillCategory(entry.key, entry.value as List);
                  }).toList(),

                  const SizedBox(height: 32),

                  // CAREER ROADMAP
                  if (learningPaths.isNotEmpty) ...[
                    _buildSectionTitle(Icons.map_outlined, "🏆 AI CAREER ROADMAP"),
                    const SizedBox(height: 8),
                    Text("A structured week-wise learning journey tailored to your profile.", 
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
                    const SizedBox(height: 20),
                    ...learningPaths.asMap().entries.map((entry) => _buildImprovedPathCard(entry.key, entry.value)),
                    const SizedBox(height: 32),
                  ],

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoringHeader(int jdScore, int atsScore, String level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildScoreCard("JD Fit", "$jdScore%", Icons.business_center, Colors.blueAccent)),
              const SizedBox(width: 16),
              Expanded(child: _buildScoreCard("ATS Score", "$atsScore%", Icons.verified, Colors.greenAccent)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Text(level.toUpperCase(), style: GoogleFonts.outfit(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 24),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8)),
      ],
    );
  }

  Widget _buildImprovedPathCard(int pathIdx, dynamic pathData) {
    String skillName = "Skill";
    String rationale = "Loading rationale...";
    List plan = [];
    String difficulty = "Medium";
    String hours = "10";
    String status = "available";

    String marketPulse = "High Demand";
    if (pathData is Map) {
      skillName = pathData['skill']?.toString() ?? "Skill";
      marketPulse = pathData['demand_pulse']?.toString() ?? "High Demand";
      plan = List.from(pathData['plan'] ?? []);
      difficulty = pathData['difficulty']?.toString() ?? "Medium";
      hours = pathData['estimated_hours']?.toString() ?? "10";
      status = pathData['status']?.toString() ?? "available";
    }

    int completedSteps = plan.where((s) => (s is Map && s['status'] == 'completed')).length;
    int masteryTotal = plan.isEmpty ? 0 : ((completedSteps / plan.length) * 100).toInt();

    Color statusColor = status == 'completed' ? Colors.greenAccent : (status == 'in_progress' ? Colors.blueAccent : (status == 'locked' ? Colors.white24 : Colors.teal));
    IconData statusIcon = status == 'completed' ? Icons.check_circle : (status == 'in_progress' ? Icons.play_circle_filled : (status == 'locked' ? Icons.lock : Icons.radio_button_unchecked));

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        iconColor: Colors.white54,
        collapsedIconColor: Colors.white24,
        title: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(skillName, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10, left: 30),
          child: Row(
            children: [
              _statusBadge(difficulty, Colors.orange, Icons.bar_chart),
              const SizedBox(width: 16),
              _statusBadge("$hours Hrs", Colors.teal, Icons.schedule),
              const SizedBox(width: 16),
              _statusBadge(marketPulse, Colors.purpleAccent, Icons.trending_up),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          Divider(color: Colors.white.withOpacity(0.05), height: 32),

          ...plan.asMap().entries.map((planEntry) {
            final stepIdx = planEntry.key;
            final step = planEntry.value;
            final isLast = stepIdx == plan.length - 1;
            final stepStatus = step['status']?.toString() ?? 'not_started';
            
            bool isDone = stepStatus == 'completed';
            bool isDoing = stepStatus == 'in_progress';

            return Stack(
              children: [
                if (!isLast)
                  Positioned(
                    left: 21,
                    top: 28,
                    bottom: 0,
                    child: Container(width: 2, color: isDone ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _toggleStep(pathIdx, stepIdx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: isDone ? Colors.green : (isDoing ? Colors.blueAccent : Colors.white10), 
                            shape: BoxShape.circle,
                            border: Border.all(color: isDone ? Colors.green : (isDoing ? Colors.blueAccent : Colors.white24))
                          ),
                          child: Icon(isDone ? Icons.check : (isDoing ? Icons.play_arrow : Icons.radio_button_unchecked), 
                                     size: 14, color: isDone || isDoing ? Colors.white : Colors.white24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4), 
                            Text("WEEK ${step['week'] ?? (stepIdx + 1)}: ${step['focus']?.toString()?.toUpperCase() ?? ''}", 
                                style: GoogleFonts.outfit(
                                  fontSize: 13, 
                                  fontWeight: FontWeight.bold, 
                                  color: isDone ? Colors.greenAccent : (isDoing ? Colors.blueAccent : Colors.white), 
                                  letterSpacing: 0.5,
                                )),
                            const SizedBox(height: 8),
                            
                            if (step['objective'] != null)
                               Text("🎯 Objective: ${step['objective']}", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                            
                            const SizedBox(height: 12),
                            
                            // HANDS-ON TASKS
                            if (step['tasks'] != null && (step['tasks'] as List).isNotEmpty) ...[
                              Text("🛠️ HANDS-ON TASKS:", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                              const SizedBox(height: 6),
                              ...(step['tasks'] as List).map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text("• $t", style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                              )),
                              const SizedBox(height: 12),
                            ],

                            // INNOVATIVE LEARNING ASSETS
                            if (step['resources'] != null && (step['resources'] as List).isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text("🚀 LEARNING ASSETS:", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 1)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                clipBehavior: Clip.none, // Prevents 1px overflow bar
                                children: (step['resources'] as List).map((r) {
                                  String resStr = r.toString();
                                  IconData resIcon = Icons.link;
                                  Color resColor = Colors.indigoAccent;
                                  String typeLabel = "Link";

                                  if (resStr.toLowerCase().contains("guvi")) {
                                    resIcon = Icons.rocket_launch;
                                    resColor = Colors.greenAccent;
                                    typeLabel = "GUVI";
                                  } else if (resStr.toLowerCase().contains("youtube")) {
                                    resIcon = Icons.play_circle_fill;
                                    resColor = Colors.redAccent;
                                    typeLabel = "Video";
                                  } else if (resStr.toLowerCase().contains("github")) {
                                    resIcon = Icons.code;
                                    resColor = Colors.tealAccent;
                                    typeLabel = "Repo";
                                  } else if (resStr.toLowerCase().contains("doc") || resStr.toLowerCase().contains("official")) {
                                    resIcon = Icons.auto_stories;
                                    resColor = Colors.blueAccent;
                                    typeLabel = "Docs";
                                  } else if (resStr.toLowerCase().contains("course") || resStr.toLowerCase().contains("udemy") || resStr.toLowerCase().contains("coursera")) {
                                    resIcon = Icons.school;
                                    resColor = Colors.orangeAccent;
                                    typeLabel = "Course";
                                  }

                                  return InkWell(
                                    onTap: () {
                                      _launchSearch(resStr);
                                      setState(() => pathData['resource_visited'] = true);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 160,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: resColor.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: resColor.withOpacity(0.2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(resIcon, size: 16, color: resColor),
                                              const SizedBox(width: 8),
                                              Text(typeLabel.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: resColor)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(resStr, 
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text("Launch", style: GoogleFonts.inter(fontSize: 9, color: resColor, fontWeight: FontWeight.bold)),
                                              const SizedBox(width: 4),
                                              Icon(Icons.open_in_new, size: 10, color: resColor),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),

          const SizedBox(height: 8),
          
          // DYNAMIC MILESTONE REWARD (Innovative Idea)
          if (masteryTotal == 100) ...[
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.amber.withOpacity(0.2), Colors.orange.withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
                  const SizedBox(height: 12),
                  Text("MILESTONE REACHED!", style: GoogleFonts.outfit(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text("You've mastered $skillName. AI has generated a unique portfolio project for you.", 
                       textAlign: TextAlign.center,
                       style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _generateProjectPrompt(skillName),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                    child: const Text("GENERATE PORTFOLIO PROJECT PROMPT"),
                  ),
                ],
              ),
            ),
          ],

          // INNOVATIVE PRACTICE TRIGGER
          if (pathData['resource_visited'] == true) ...[
             Container(
               padding: const EdgeInsets.all(12),
               margin: const EdgeInsets.only(bottom: 16),
               decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.greenAccent.withOpacity(0.2))),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 16),
                   const SizedBox(width: 8),
                   Text("READY FOR ASSESSMENT: PREPARATION COMPLETE", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.greenAccent, letterSpacing: 0.5)),
                 ],
               ),
             ),
          ],

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isLoadingTest ? null : () => _startTestForSkill(skillName),
              icon: _isLoadingTest 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(pathData['resource_visited'] == true ? Icons.bolt : Icons.lock_open, color: Colors.white),
              label: Text(pathData['resource_visited'] == true ? "LAUNCH DOMAIN ASSESSMENT" : "START PRACTICE MCQS", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: pathData['resource_visited'] == true ? Colors.green : const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text("Validate your learning from the courses above with 50 AI MCQs.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }


  Widget _statusBadge(String text, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildScoreCard(String title, String score, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title.toUpperCase(), style: GoogleFonts.inter(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
          const SizedBox(height: 4),
          Text(score, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }


  Widget _buildSkillCategory(String category, List skills) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _buildSkillList(skills, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildSkillList(List skills, Color color) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: skills.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(s.toString(), style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      )).toList(),
    );
  }
}
