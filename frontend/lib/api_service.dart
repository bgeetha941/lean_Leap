import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use localhost for Web, and local IP for physical devices/emulators
  static const String baseUrl = 'https://lean-leap-backend.onrender.com/api'; 

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/profile/update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> analyzeResume(PlatformFile file, String jdText) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/resume/upload'));
    request.headers['Authorization'] = 'Bearer $token';

    if (file.bytes != null) {
      request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
    }
    request.fields['jd_text'] = jdText;

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }



  // --- Stream Selection Methods ---
  
  Future<List<dynamic>> fetchStreams() async {
    final response = await http.get(Uri.parse('$baseUrl/streams/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> fetchSubStreams(String streamId) async {
    final response = await http.get(Uri.parse('$baseUrl/streams/$streamId/sub-streams'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchSubStreamDetails(String streamId, String subStreamId) async {
    final response = await http.get(Uri.parse('$baseUrl/streams/$streamId/$subStreamId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }



  // --- Adaptive Mock Test Methods ---

  Future<Map<String, dynamic>> generateAdaptiveTest(String mode, String topic) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/adaptive-test/generate-test'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'mode': mode, 'topic': topic}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getNextQuestion(
      String sessionId, String mode, String topic, int difficulty, {int batchSize = 3}) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/adaptive-test/next-question'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'session_id': sessionId,
        'mode': mode,
        'topic': topic,
        'difficulty': difficulty,
        'batch_size': batchSize,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> submitAdaptiveAnswer(
      String sessionId, int questionId, String userAnswer, int timeTaken) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/adaptive-test/submit-answer'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'session_id': sessionId,
        'question_id': questionId,
        'user_answer': userAnswer,
        'time_taken': timeTaken,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAdaptiveAnalytics(String sessionId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/adaptive-test/user/analytics?session_id=$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }
}
