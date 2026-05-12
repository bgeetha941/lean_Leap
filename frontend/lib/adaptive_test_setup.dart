import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'adaptive_test_screen.dart';
import 'api_service.dart';

const Map<String, Map<String, List<String>>> _aptitudeTree = {
  "Quantitative Aptitude": {
    "Arithmetic": ["Number System", "LCM & HCF", "Simplification", "Percentages",
        "Profit & Loss", "Simple Interest", "Compound Interest", "Ratio & Proportion",
        "Average", "Mixtures & Alligations"],
    "Time & Work": ["Time and Work", "Pipes and Cisterns"],
    "Speed & Distance": ["Time, Speed & Distance", "Trains", "Boats & Streams"],
    "Algebra": ["Linear Equations", "Quadratic Equations", "Inequalities"],
    "Advanced": ["Permutations & Combinations", "Probability"],
    "Geometry": ["Area & Perimeter", "Volume & Surface Area", "Triangles", "Circles"],
  },
  "Logical Reasoning": {
    "Verbal": ["Coding & Decoding", "Blood Relations", "Direction Sense",
        "Order & Ranking", "Alphabet Series"],
    "Non-Verbal": ["Number Series", "Pattern Analogy", "Classification", "Odd One Out"],
    "Analytical": ["Seating Arrangement", "Puzzles", "Syllogism",
        "Statement & Assumption", "Cause & Effect"],
  },
  "Data Interpretation": {
    "Chart Types": ["Tables", "Bar Graphs", "Pie Charts", "Line Graphs",
        "Caselets", "Data Sufficiency"],
  },
  "Verbal Ability": {
    "Grammar": ["Tenses & Articles", "Sentence Correction", "Error Detection"],
    "Comprehension": ["Reading Comprehension"],
    "Vocabulary": ["Synonyms & Antonyms", "Idioms & Phrases"],
    "Sentence Skills": ["Para Jumbles", "Fill in the Blanks"],
  },
};

const List<String> _domainTopics = [
  "Python", "Data Structures", "Algorithms", "DBMS", "SQL",
  "Operating Systems", "Computer Networks", "OOPs Concepts",
  "Java", "C++", "Machine Learning", "Cloud Computing",
  "Web Development", "Cybersecurity", "Embedded Systems",
];

class AdaptiveTestSetupScreen extends StatefulWidget {
  const AdaptiveTestSetupScreen({Key? key}) : super(key: key);

  @override
  State<AdaptiveTestSetupScreen> createState() => _AdaptiveTestSetupScreenState();
}

class _AdaptiveTestSetupScreenState extends State<AdaptiveTestSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _selectedTopic = '';
  bool _isLoading = false;
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      setState(() {
        _selectedTopic = '';
        _searchController.clear();
        _searchQuery = '';
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tab.dispose();
    super.dispose();
  }

  String get _mode => _tab.index == 0 ? 'Aptitude' : 'Domain Specific';

  void _startTest() async {
    if (_selectedTopic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a topic first')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await _api.generateAdaptiveTest(_mode, _selectedTopic);
      if (res['success'] == true && mounted) {
        final int limit = _mode == 'Aptitude' ? 20 : 50;
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AdaptiveTestScreen(
            sessionId: res['session_id'],
            mode: _mode,
            topic: _selectedTopic,
            questionLimit: limit,
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: Text('Test Configuration', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.teal,
          indicatorWeight: 3,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.calculate_outlined), text: 'APTITUDE'),
            Tab(icon: Icon(Icons.code_rounded), text: 'DOMAIN'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [_buildAptitudeTab(), _buildDomainTab()],
            ),
          ),
          
          _buildBottomCTA(),
        ],
      ),
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.auto_awesome, color: Colors.teal, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedTopic.isEmpty 
                    ? 'Select a topic to start' 
                    : 'Level Up: $_selectedTopic',
                  style: GoogleFonts.inter(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
              Text(
                _tab.index == 0 ? '20 Questions' : '50 Questions',
                style: GoogleFonts.inter(color: Colors.teal.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ]),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : ElevatedButton.icon(
                    onPressed: _selectedTopic.isNotEmpty ? _startTest : null,
                    icon: const Icon(Icons.bolt, color: Colors.white, size: 20),
                    label: Text(
                      'START ADAPTIVE TEST',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      disabledBackgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAptitudeTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _aptitudeTree.length,
      itemBuilder: (_, i) {
        final mainCat = _aptitudeTree.keys.elementAt(i);
        final subs = _aptitudeTree[mainCat]!;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: ExpansionTile(
            iconColor: Colors.teal,
            collapsedIconColor: Colors.white24,
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(mainCat,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            leading: Icon(Icons.psychology_outlined, color: Colors.teal.withOpacity(0.6), size: 24),
            children: subs.entries.map((sub) {
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: ExpansionTile(
                  iconColor: Colors.orangeAccent,
                  collapsedIconColor: Colors.white12,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(sub.key,
                      style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      child: Wrap(
                        spacing: 10, runSpacing: 10,
                        children: sub.value.map((topic) => _topicChip(topic)).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDomainTab() {
    List<String> displayTopics = _domainTopics
        .where((topic) => topic.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    bool isCustom = _searchQuery.isNotEmpty && 
        !_domainTopics.any((t) => t.toLowerCase() == _searchQuery.trim().toLowerCase());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.code_rounded, color: Colors.teal, size: 24),
              const SizedBox(width: 12),
              Text('Technical Domains', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Select your specialized field or search to add a custom domain.',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 24),
          
          TextField(
            controller: _searchController,
            style: GoogleFonts.inter(color: Colors.white),
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search or type a custom domain...',
              hintStyle: GoogleFonts.inter(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1F2937),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[800]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.teal),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              if (isCustom) _topicChip(_searchQuery.trim()),
              ...displayTopics.map(_topicChip).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topicChip(String topic) {
    final isSelected = _selectedTopic == topic;
    return GestureDetector(
      onTap: () => setState(() => _selectedTopic = topic),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.teal : Colors.grey[700]!),
          boxShadow: isSelected ? [BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 10)] : [],
        ),
        child: Text(topic,
            style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13)),
      ),
    );
  }
}
