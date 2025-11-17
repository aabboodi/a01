import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final String _baseUrl = 'http://10.0.2.2:3000'; // Standard emulator localhost

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

  Future<void> createUser(String fullName, String loginCode, String role, {String? phoneNumber}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'full_name': fullName,
        'login_code': loginCode,
        'role': role,
        'phone_number': phoneNumber,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create user: ${response.body}');
    }
  }

  Future<void> deleteUser(String userId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/users/$userId'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete user');
    }
  }
}
