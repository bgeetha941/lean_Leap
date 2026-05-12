import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _jdController = TextEditingController();
  final ApiService _apiService = ApiService();
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _analyze() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a resume PDF')),
      );
      return;
    }

    if (_jdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Job Description')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.analyzeResume(
        _selectedFile!,
        _jdController.text
      );

      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(data: result['data'] ?? {}),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: Text('Career Analysis',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // STEP 1: UPLOAD RESUME
            _buildNumberedStepContainer(
              stepNumber: "1",
              title: "Upload Your Resume",
              subtitle: "Upload your resume to get started",
              child: Column(
                children: [
                  InkWell(
                    onTap: _pickFile,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.teal.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.post_add, color: Colors.teal, size: 24),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _selectedFile == null ? "Select Resume (PDF)" : _selectedFile!.name,
                              style: GoogleFonts.inter(
                                  color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _selectedFile == null ? 0 : 1.0,
                    backgroundColor: Colors.grey[800],
                    color: Colors.teal,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // STEP 2: PASTE JD
            _buildNumberedStepContainer(
              stepNumber: "2",
              title: "Paste Job Description",
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  border: Border.all(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _jdController,
                  maxLines: 12,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                    hintText: "Paste the complete job description here...\n\nExample:\nJob Title: Senior Software Engineer\n\nRequired Skills:\n- Python, Java\n- REST API, Microservices\n- Docker, Kubernetes",
                    hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ANALYZE BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _analyze,
                icon: _isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.analytics, color: Colors.white, size: 20),
                label: _isLoading
                    ? const SizedBox(
                        height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("Analyze My Career Fit",
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  disabledBackgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberedStepContainer({required String stepNumber, required String title, String? subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: Text(stepNumber,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.amber)),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
