import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RecordingService {
  final String _baseUrl = 'http://10.0.2.2:3000';

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, dynamic>> startRecording(String classId) async {
    final token = await _getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/recordings/start'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'classId': classId}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start recording.');
    }
  }

  Future<void> stopRecording(String recordingId) async {
    final token = await _getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/recordings/$recordingId/stop'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) { // Should be 200 for update
      throw Exception('Failed to stop recording.');
    }
  }

  Future<void> uploadRecording(String recordingId, String filePath) async {
    final token = await _getAccessToken();
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/recordings/$recordingId/upload'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    var res = await request.send();
    if (res.statusCode != 201) {
      throw Exception('Failed to upload recording.');
    }
  }

  Future<List<dynamic>> getRecordingsForClass(String classId) async {
    final token = await _getAccessToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/recordings/class/$classId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load recordings.');
    }
  }
}
