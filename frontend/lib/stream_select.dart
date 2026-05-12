import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'stream_details.dart';

class StreamSelect extends StatefulWidget {
  const StreamSelect({super.key});

  @override
  State<StreamSelect> createState() => _StreamSelectState();
}

class _StreamSelectState extends State<StreamSelect> {
  final ApiService _apiService = ApiService();
  List streams = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    setState(() => isLoading = true);
    try {
      final results = await _apiService.fetchStreams();
      setState(() {
        streams = results;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading streams: $e");
      setState(() => isLoading = false);
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'engineering': return Icons.engineering;
      case 'palette': return Icons.palette;
      case 'account_balance': return Icons.account_balance;
      case 'medical_services': return Icons.medical_services;
      case 'design_services': return Icons.design_services;
      case 'gavel': return Icons.gavel;
      case 'computer': return Icons.computer;
      case 'agriculture': return Icons.agriculture;
      case 'business': return Icons.business;
      case 'school': return Icons.school;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: Text('Career Explorer',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header gradient banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.teal.withOpacity(0.3)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Discover Your Path',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Explore diverse career streams and find where you belong.',
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.explore, color: Colors.teal, size: 20),
                      const SizedBox(width: 8),
                      Text('Main Streams',
                          style: GoogleFonts.outfit(
                              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),

                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    itemCount: streams.length,
                    itemBuilder: (context, index) {
                      final stream = streams[index];
                      final color = Color(int.parse(stream['color']));

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => StreamDetails(
                                        streamId: stream['id'],
                                        streamName: stream['name'],
                                        color: color,
                                      )));
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                  color: color.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: color.withOpacity(0.3)),
                                ),
                                child: Icon(_getIcon(stream['icon']), color: color, size: 36),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                stream['name'],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stream['description'] ?? '',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
