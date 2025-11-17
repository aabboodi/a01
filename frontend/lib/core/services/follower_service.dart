import 'dart:convert';
import 'package:http/http.dart' as http;

class FollowerService {
  final String _baseUrl = 'http://10.0.2.2:3000'; // Standard emulator localhost

  Future<List<dynamic>> getFollowers() async {
    final response = await http.get(Uri.parse('$_baseUrl/followers'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load followers');
    }
  }

  Future<void> createFollower(String fullName, String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/followers'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(<String, String>{
        'full_name': fullName,
        'phone_number': phoneNumber,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create follower: ${response.body}');
    }
  }

  Future<void> deleteFollower(String followerId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/followers/$followerId'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete follower');
    }
  }
}
