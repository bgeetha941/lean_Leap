import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

class StreamDetails extends StatefulWidget {
  final String streamId;
  final String streamName;
  final Color color;

  const StreamDetails({
    super.key,
    required this.streamId,
    required this.streamName,
    required this.color,
  });

  @override
  State<StreamDetails> createState() => _StreamDetailsState();
}

class _StreamDetailsState extends State<StreamDetails> {
  final ApiService _apiService = ApiService();
  List subStreams = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubStreams();
  }

  Future<void> _loadSubStreams() async {
    setState(() => isLoading = true);
    try {
      final results = await _apiService.fetchSubStreams(widget.streamId);
      setState(() {
        subStreams = results;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading sub-streams: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF1F2937),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.streamName,
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color.withOpacity(0.3), const Color(0xFF111827)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.school, size: 80, color: widget.color.withOpacity(0.3)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: widget.color, size: 20),
                      const SizedBox(width: 12),
                      Text('Explore Specializations',
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Select a domain to view detailed career roadmaps and industry-required skills.',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
          ),
          isLoading
              ? const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: CircularProgressIndicator(color: Colors.teal),
                  )))
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ss = subStreams[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: widget.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.psychology, color: widget.color, size: 20),
                            ),
                            title: Text(ss['name'],
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, color: Colors.white)),
                            trailing: Icon(Icons.chevron_right, color: Colors.white24),
                            onTap: () => _showSubStreamInfo(ss),
                          ),
                        );
                      },
                      childCount: subStreams.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  void _showSubStreamInfo(Map<String, dynamic> ss) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white12, borderRadius: BorderRadius.circular(2)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(ss['name'],
                                  style: GoogleFonts.outfit(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                            IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close, color: Colors.white38)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(ss['description'] ?? '',
                            style: GoogleFonts.inter(color: Colors.white38, fontSize: 13, height: 1.5)),
                        const SizedBox(height: 32),

                        _buildHeader(Icons.payments_outlined, "INDUSTRY SALARY", Colors.greenAccent),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.greenAccent.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.insights, color: Colors.greenAccent, size: 28),
                              const SizedBox(width: 16),
                              Text(ss['average_salary'] ?? 'Competitive', 
                                  style: GoogleFonts.outfit(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 20)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        if (ss['career_paths_detailed'] != null) ...[
                          _buildHeader(Icons.route, "ADAPTIVE ROADMAPS", const Color(0xFF6366F1)),
                          const SizedBox(height: 20),
                          ...(ss['career_paths_detailed'] as List)
                              .map<Widget>((cp) => _buildCareerRoadmapCard(cp, setModalState))
                              .toList(),
                        ] else ...[
                           _buildHeader(Icons.work_outline, "CORE CAREER PATHS", Colors.blueAccent),
                           const SizedBox(height: 12),
                           Wrap(
                             spacing: 12, runSpacing: 12,
                             children: (ss['career_paths'] as List? ?? [])
                                 .map<Widget>((cp) => _tag(cp.toString(), Colors.blueAccent))
                                 .toList(),
                           ),
                        ],

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildHeader(IconData icon, String title, Color accent) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8)),
      ],
    );
  }

  Widget _buildCareerRoadmapCard(Map<String, dynamic> cp, StateSetter setModalState) {
    // Local state for progress tracking inside the bottom sheet
    cp['progress'] ??= {}; 

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
        title: Text(cp['title'] ?? 'Role', 
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              _dotBadge("Advanced", Colors.purpleAccent),
              const SizedBox(width: 20),
              _dotBadge("6-12 Months", Colors.teal),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        children: [
          Divider(color: Colors.white.withOpacity(0.05), height: 32),
          
          Row(
            children: [
              const Icon(Icons.terminal, color: Colors.orangeAccent, size: 16),
              const SizedBox(width: 12),
              Text("ESSENTIAL SKILLS", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: (cp['skills_expanded'] as List? ?? [])
                .map<Widget>((s) => _tag(s.toString(), Colors.orangeAccent))
                .toList(),
          ),
          
          const SizedBox(height: 32),
          Row(
            children: [
              const Icon(Icons.alt_route, color: Colors.teal, size: 16),
              const SizedBox(width: 12),
              Text("INTERACTIVE STEPS", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 24),
          
          ...(cp['courses_roadmap'] as List? ?? []).asMap().entries.map((entry) {
            final idx = entry.key;
            final stepData = entry.value;
            final isLast = idx == (cp['courses_roadmap'] as List).length - 1;
            final isDone = cp['progress'][idx.toString()] == true;
            
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setModalState(() {
                            cp['progress'][idx.toString()] = !isDone;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28, height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDone ? Colors.teal : const Color(0xFF6366F1).withOpacity(0.1), 
                            shape: BoxShape.circle,
                            border: Border.all(color: isDone ? Colors.teal : const Color(0xFF6366F1).withOpacity(0.3))
                          ),
                          child: Icon(isDone ? Icons.check : Icons.play_arrow, size: 14, color: isDone ? Colors.white : const Color(0xFF6366F1)),
                        ),
                      ),
                      if (!isLast)
                        Expanded(child: Container(width: 2, color: isDone ? Colors.teal.withOpacity(0.3) : Colors.white.withOpacity(0.05))),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: InkWell(
                         onTap: () {
                          setModalState(() {
                            cp['progress'][idx.toString()] = !isDone;
                          });
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stepData['step'] ?? '', 
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 14, 
                                  color: isDone ? Colors.tealAccent : Colors.white,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                )),
                            const SizedBox(height: 4),
                            Text((stepData['items'] as List? ?? []).join(" • "), 
                                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, height: 1.4)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.public, size: 18),
              label: Text("GET FREE RESOURCES", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              onPressed: () => _launchFreeResources(cp['title'] ?? ''),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color.withOpacity(0.1),
                foregroundColor: widget.color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                side: BorderSide(color: widget.color.withOpacity(0.2)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _dotBadge(String text, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.inter(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _tag(String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: accent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.2))),
      child: Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _launchFreeResources(String careerTitle) async {
    final query = Uri.encodeComponent('$careerTitle free courses certifications Roadmap.sh Coursera');
    final url = Uri.parse('https://www.google.com/search?q=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
