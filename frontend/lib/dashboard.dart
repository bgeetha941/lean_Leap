import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'adaptive_test_setup.dart';
import 'stream_select.dart';
import 'profile_screen.dart';

class LeanLeapDashboard extends StatefulWidget {
  const LeanLeapDashboard({super.key});

  @override
  State<LeanLeapDashboard> createState() => _LeanLeapDashboardState();
}

class _LeanLeapDashboardState extends State<LeanLeapDashboard> {
  String userName = "User";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? "User";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: Text("LeanLeap Dashboard",
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.teal),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome back,",
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 16)),
            Text(userName,
                style: GoogleFonts.outfit(
                    fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),

            _buildFeatureCard(
              context,
              "Resume Analysis",
              "Get AI-powered feedback on your resume matching a job description.",
              Icons.description_outlined,
              Colors.indigoAccent,
              () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const HomeScreen())),
            ),
            const SizedBox(height: 16),

            _buildFeatureCard(
              context,
              "Mock Tests",
              "Adaptive AI-powered tests that adjust difficulty in real-time. Earn XP, streaks & badges!",
              Icons.psychology,
              Colors.redAccent,
              () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AdaptiveTestSetupScreen())),
            ),
            const SizedBox(height: 16),



            _buildFeatureCard(
              context,
              "Career Streams",
              "Explore educational streams, career paths, and trending technologies.",
              Icons.explore_outlined,
              Colors.tealAccent,
              () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const StreamSelect())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String desc,
      IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.4))),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(desc,
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
