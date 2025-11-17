import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ClassService {
  final String _baseUrl = 'http://10.0.2.2:3000'; // Standard emulator localhost

  Future<List<dynamic>> getAllClasses() async {
    const cacheKey = 'cached_all_classes';
    try {
      final response = await http.get(Uri.parse('$_baseUrl/classes'));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, response.body);
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load classes from network');
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

  Future<void> createClass(String className, String teacherId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/classes'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'class_name': className,
        'teacher_id': teacherId,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create class: ${response.body}');
    }
  }

  Future<void> deleteClass(String classId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/classes/$classId'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete class');
    }
  }

  Future<void> enrollStudents(String classId, List<String> studentIds) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/classes/$classId/enroll'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'student_ids': studentIds}),
    );
    if (response.statusCode != 201) { // Assuming 201 Created from backend
      throw Exception('Failed to enroll students: ${response.body}');
    }
  }
}
