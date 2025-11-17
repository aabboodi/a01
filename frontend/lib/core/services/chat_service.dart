import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  final String _baseUrl = 'http://10.0.2.2:3000';

  Future<List<dynamic>> getChatHistory(String classId) async {
    final cacheKey = 'cached_chat_history_$classId';
    try {
      final token = await _getAccessToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/$classId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, response.body);
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load chat history from network');
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        return json.decode(cachedData);
      } else {
        throw Exception('A network error occurred and no cached data is available.');
      }
    }
  }

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
}
