import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  final String _baseUrl = 'http://10.0.2.2:3000';
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String loginCode) async {
    final url = Uri.parse('$_baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'login_code': loginCode}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final String accessToken = body['access_token'];

        // Store the token securely
        await _storage.write(key: 'access_token', value: accessToken);

        // Decode the token to get user data (role, etc.)
        Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
        return decodedToken;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to login.');
      }
    } catch (e) {
      throw Exception('A network error occurred: ${e.toString()}');
    }
  }
}
