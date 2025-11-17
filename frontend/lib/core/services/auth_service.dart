import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  final String _baseUrl = 'http://10.0.2.2:3000'; // Standard emulator localhost

  Future<Map<String, dynamic>?> login(String loginCode) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'login_code': loginCode}),
    );

    if (response.statusCode == 201) {
      final body = json.decode(response.body);
      final accessToken = body['access_token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);

      Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
      return decodedToken;
    } else {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null && !JwtDecoder.isExpired(token)) {
      return JwtDecoder.decode(token);
    }
    return null;
  }
}
