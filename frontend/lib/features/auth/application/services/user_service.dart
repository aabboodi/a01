import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final String _baseUrl = 'http://10.0.2.2:3000'; // For Android emulator

  Future<List<dynamic>> getUsersByRole(String role) async {
    final cacheKey = 'cached_users_by_role_$role';
    try {
      final response = await http.get(Uri.parse('$_baseUrl/users?role=$role'));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, response.body);
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load users from network');
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

  Future<Map<String, dynamic>> createUser(String fullName, String loginCode, String role) async {
    final url = Uri.parse('$_baseUrl/users');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_name': fullName,
          'login_code': loginCode,
          'role': role,
        }),
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
