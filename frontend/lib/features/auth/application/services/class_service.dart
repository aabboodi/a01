import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ClassService {
  final String _baseUrl = 'http://10.0.2.2:3000'; // For Android emulator

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
      // Network error, try to load from cache
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        return json.decode(cachedData);
      } else {
        throw Exception('A network error occurred and no cached data is available.');
      }
    }
  }

  Future<List<dynamic>> getClassesByTeacher(String teacherId) async {
    final cacheKey = 'cached_teacher_classes_$teacherId';
    try {
      final response = await http.get(Uri.parse('$_baseUrl/classes?teacherId=$teacherId'));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, response.body);
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load classes for teacher from network');
      }
    } catch (e) {
      // Network error, try to load from cache
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        return json.decode(cachedData);
      } else {
        throw Exception('A network error occurred and no cached data is available.');
      }
    }
  }

  Future<Map<String, dynamic>> createClass(String className, String teacherId) async {
    // ... (createClass implementation remains the same)
        final url = Uri.parse('$_baseUrl/classes');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'class_name': className,
          'teacher_id': teacherId,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to create class.');
      }
    } catch (e) {
      throw Exception('A network error occurred: ${e.toString()}');
    }
  }

  Future<void> enrollStudents(String classId, List<String> studentIds) async {
    final url = Uri.parse('$_baseUrl/classes/$classId/enroll');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'student_ids': studentIds}),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to enroll students.');
      }
    } catch (e) {
      throw Exception('A network error occurred: ${e.toString()}');
    }
  }

  Future<void> deleteClass(String classId) async {
    final url = Uri.parse('$_baseUrl/classes/$classId');
    try {
      final response = await http.delete(url);
      if (response.statusCode != 204) {
        throw Exception('Failed to delete class.');
      }
    } catch (e) {
      throw Exception('A network error occurred: ${e.toString()}');
    }
  }
}
