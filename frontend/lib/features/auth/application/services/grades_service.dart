import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GradesService {
  final String _baseUrl = 'http://10.0.2.2:3000';

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<List<dynamic>> getGradesForClass(String classId) async {
    final token = await _getAccessToken();
    final url = Uri.parse('$_baseUrl/grades/class/$classId');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load grades');
    }
  }

  Future<void> upsertGrade(Map<String, dynamic> gradeData) async {
    final token = await _getAccessToken();
    final url = Uri.parse('$_baseUrl/grades');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(gradeData),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save grade');
    }
  }
}
