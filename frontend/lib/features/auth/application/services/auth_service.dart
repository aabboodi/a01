import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Use 10.0.2.2 for the Android emulator to connect to the host's localhost
  final String _baseUrl = 'http://10.0.2.2:3000';

  Future<Map<String, dynamic>> login(String loginCode) async {
    final url = Uri.parse('$_baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'login_code': loginCode}),
      );

      if (response.statusCode == 200) {
        // Successfully logged in
        return json.decode(response.body);
      } else {
        // Handle errors like 401 Unauthorized, 404, etc.
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to login.');
      }
    } catch (e) {
      // Handle network errors or other exceptions
      throw Exception('A network error occurred: ${e.toString()}');
    }
  }
}
