import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ClassService {
  final String _baseUrl = baseUrl;

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<List<dynamic>> getAllClasses() async {
    final token = await _getAccessToken();
    final url = Uri.parse('$_baseUrl/classes');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load classes');
    }
  }

  Future<void> createClass(String name, String teacherId) async {
    final token = await _getAccessToken();
    final url = Uri.parse('$_baseUrl/classes');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'class_name': name, 'teacher_id': teacherId}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create class');
    }
  }

  Future<void> deleteClass(String classId) async {
    final token = await _getAccessToken();
    final url = Uri.parse('$_baseUrl/classes/$classId');
    final response = await http.delete(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 204) {
      throw Exception('Failed to delete class');
    }
  }

  Future<void> enrollStudents(String classId, List<String> studentIds) async {
    final token = await _getAccessToken();
    final url = Uri.parse('$_baseUrl/classes/$classId/enroll');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'student_ids': studentIds}),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to enroll students');
    }
  }

  Future<List<dynamic>> getClassesForTeacher(String teacherId) async {
    final token = await _getAccessToken();
    final url = Uri.parse('$_baseUrl/classes?teacherId=$teacherId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load classes for teacher.');
    }
  }

  Future<List<dynamic>> getClassesForStudent(String studentId) async {
    final token = await _getAccessToken();
    final url = Uri.parse('$_baseUrl/classes/student/$studentId'); // Use the new, efficient endpoint

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load classes for student.');
    }
  }

  Future<List<dynamic>> getEnrolledStudents(String classId) async {
    final token = await _getAccessToken();
    final url = Uri.parse('$_baseUrl/classes/$classId/enrolled-students');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load enrolled students');
    }
  }
}
