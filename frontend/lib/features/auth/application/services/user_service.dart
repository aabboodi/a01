import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String _baseUrl = 'http://10.0.2.2:3000'; // For Android emulator

  // Fetches a list of all users from the backend
  Future<List<dynamic>> getAllUsers() async {
    final url = Uri.parse('$_baseUrl/users');
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

  // Creates a new user
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
}
