import 'dart:convert';
import 'dart:io';

/// A minimal HTTP-based auth service using dart:io HttpClient so no extra
/// pub dependency is required. Your backend team can point `baseUrl` to the
/// running Spring Boot server.
class AuthService {
  final String baseUrl;

  AuthService({this.baseUrl = 'http://localhost:8080/api'});

  /// Send a login request. Expects backend to accept JSON: {"phone": "...", "password": "..."}
  /// Returns decoded JSON on success, or throws an exception.
  Future<Map<String, dynamic>> login({required String phone, required String password}) async {
    final uri = Uri.parse('$baseUrl/login');
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode({'phone': phone, 'password': password}))); 
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(body) as Map<String, dynamic>;
      } else {
        throw HttpException('Login failed: ${response.statusCode} ${response.reasonPhrase} - $body');
      }
    } finally {
      client.close(force: true);
    }
  }

  /// Send a signup/register request. Backend should accept {"name":"...","phone":"...","password":"..."}
  Future<Map<String, dynamic>> register({required String name, required String phone, required String password}) async {
    final uri = Uri.parse('$baseUrl/register');
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode({'name': name, 'phone': phone, 'password': password})));
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
