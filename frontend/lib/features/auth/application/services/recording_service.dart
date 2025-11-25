import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RecordingService {
  final String _baseUrl = baseUrl;

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, dynamic>> startRecording(String classId) async {
    final token = await _getAccessToken();
    final url = Uri.parse('$_baseUrl/recordings/start');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'classId': classId}),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to start recording');
    }
  }

  Future<void> stopRecording(String recordingId) async {
    final token = await _getAccessToken();
    final url = Uri.parse('$_baseUrl/recordings/$recordingId/stop');
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to stop recording');
    }
  }

  Future<void> uploadRecording(String recordingId, String filePath) async {
    final token = await _getAccessToken();
    final url = Uri.parse('$_baseUrl/recordings/$recordingId/upload');
    var request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', filePath));
    var response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to upload recording');
    }
  }

  Future<List<dynamic>> getRecordingsForClass(String classId) async {
    final token = await _getAccessToken();
    final url = Uri.parse('$_baseUrl/recordings/class/$classId');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load recordings');
    }
  }
}
