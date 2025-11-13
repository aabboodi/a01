import 'dart:convert';
import 'package:http/http.dart' as http;

class ClassService {
  final String _baseUrl = 'http://10.0.2.2:3000'; // For Android emulator

  Future<List<dynamic>> getAllClasses() async {
    final url = Uri.parse('$_baseUrl/classes');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load classes');
      }
    } catch (e) {
      throw Exception('A network error occurred: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createClass(String className, String teacherId) async {
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

  // NOTE: enrollStudents and getStudentsByClass will be added later when needed.
}
