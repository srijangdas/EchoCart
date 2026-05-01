import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class AuthService {
  final String baseUrl;

  AuthService({this.baseUrl = 'http://10.0.2.2:8080/api/auth'});

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {

    final uri = Uri.parse('$baseUrl/login/delivery');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': phone,
        'password': password,
      }),
    );

    final body = response.body;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Login failed: ${response.statusCode} ${response.reasonPhrase} - $body',
      );
    }
  }

  /// Send a signup/register request. Backend should accept {"name":"...","phone":"...","password":"..."}
  Future<Map<String, dynamic>> register({required String name, required String phone, required String password}) async {
    final uri = Uri.parse('$baseUrl/register/delivery');
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode({'email': phone, 'password': password})));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(body) as Map<String, dynamic>;
      } else {
        throw HttpException('Register failed: ${response.statusCode} ${response.reasonPhrase} - $body');
      }
    } finally {
      client.close(force: true);
    }
  }
}
