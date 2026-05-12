import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'dashboard.dart';

void main() {
  runApp(const LeanLeapApp());
}

class LeanLeapApp extends StatelessWidget {
  const LeanLeapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeanLeap AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const LeanLeapDashboard(),
      },
    );
  }
}
