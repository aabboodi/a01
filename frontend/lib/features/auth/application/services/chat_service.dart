import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiChatService {
  final String _baseUrl = baseUrl; // Standard emulator IP for localhost

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<List<dynamic>> getChatHistory(String classId) async {
    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('Access token not found');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/chat/$classId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load chat history: ${response.body}');
    }
  }
}
