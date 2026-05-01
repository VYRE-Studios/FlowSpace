import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _baseUrl = 'https://flowspace-backend.onrender.com/api/ai';

  static Future<String> generateCompletion({
    required String prompt,
    String? channelId,
    String? workspaceId,
    List<Map<String, String>>? conversationHistory,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/completion'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prompt': prompt,
        'channelId': channelId,
        'workspaceId': workspaceId,
        'history': conversationHistory,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['completion'] as String;
    } else {
      throw Exception('AI request failed: ${response.statusCode}');
    }
  }

  static Future<String> summarizeConversation({
    required String channelId,
    int? messageCount,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/summarize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'channelId': channelId,
        'messageCount': messageCount ?? 50,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['summary'] as String;
    } else {
      throw Exception('Summarization failed: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> generateInsights({
    required String workspaceId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/insights'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'workspaceId': workspaceId,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Insights generation failed: ${response.statusCode}');
    }
  }

  static Future<List<String>> suggestActions({
    required String context,
    String? channelId,
    String? workspaceId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/suggest'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'context': context,
        'channelId': channelId,
        'workspaceId': workspaceId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['suggestions'] as List);
    } else {
      throw Exception('Suggestion failed: ${response.statusCode}');
    }
  }
}
