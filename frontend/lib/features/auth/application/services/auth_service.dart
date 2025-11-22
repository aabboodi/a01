import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  final String _baseUrl = 'http://10.0.2.2:3000';
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String loginCode) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    print('🔥🔥🔥 Attempting to login to: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'login_code': loginCode}),
      );

      print('🔥🔥🔥 Server Response Status Code: ${response.statusCode}');
      print('🔥🔥🔥 Server Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final String accessToken = body['access_token'];

        await _storage.write(key: 'access_token', value: accessToken);
        Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
        return decodedToken;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception('Server Error: ${errorBody['message'] ?? 'Failed to login.'}');
      }
    } catch (e) {
      print('🔥🔥🔥 Network or Parsing Error: ${e.toString()}');
      throw Exception('Network Error: Could not connect to the server. ${e.toString()}');
    }
  }
}
