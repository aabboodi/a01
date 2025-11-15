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
    final response = await http.get(
      Uri.parse('$_baseUrl/grades/class/$classId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load grades.');
    }
  }
}
