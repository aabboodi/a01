import 'dart:convert';
import 'package:http/http.dart' as http;

class MessagingService {
  final String _baseUrl = 'http://10.0.2.2:3000';

  Future<Map<String, dynamic>> sendBulkMessage(String message) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/messaging/send-bulk'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({'message': message}),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }
}
