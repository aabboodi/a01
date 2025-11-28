import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;

class UserService {
  final String _baseUrl = baseUrl; // For Android emulator

  Future<List<dynamic>> getUsersByRole(String role) async {
    final url = Uri.parse('$_baseUrl/users?role=$role');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('A network error occurred: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    final url = Uri.parse('$_baseUrl/users');
    try {
      // Ensure role is always set
      userData.putIfAbsent('role', () => 'student');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to create user.');
      }
    } catch (e) {
      throw Exception('A network error occurred: ${e.toString()}');
    }
  }

  Future<void> deleteUser(String userId) async {
    final url = Uri.parse('$_baseUrl/users/$userId');
    try {
      final response = await http.delete(url);
      if (response.statusCode != 204) {
        throw Exception('Failed to delete user.');
      }
    } catch (e) {
      throw Exception('A network error occurred: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> findUserByLoginCode(String loginCode) async {
    final url = Uri.parse('$_baseUrl/users/by-code/$loginCode');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('User not found.');
      }
    } catch (e) {
      throw Exception('A network error occurred: ${e.toString()}');
    }
  }

  Future<List<dynamic>> getUsersByClass(String classId) async {
    final url = Uri.parse('$_baseUrl/classes/$classId/students');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load students for class');
      }
    } catch (e) {
      throw Exception('A network error occurred: ${e.toString()}');
    }
  }
}
