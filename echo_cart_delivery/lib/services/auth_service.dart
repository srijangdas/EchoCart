import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl;
  final String profileBaseUrl;

  AuthService({
    this.baseUrl = 'http://10.0.2.2:8080/api/auth',
    this.profileBaseUrl = 'http://10.0.2.2:8080/api',
  });

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/login/delivery');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'X-Device-Id': 'sgdevice'},
      body: jsonEncode({'phoneNo': phone, 'password': password}),
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

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/register/delivery');
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set('X-Device-Id', 'sgdevice');
      request.add(
        utf8.encode(jsonEncode({'phoneNo': phone, 'password': password})),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(body) as Map<String, dynamic>;
      } else {
        throw HttpException(
          'Register failed: ${response.statusCode} ${response.reasonPhrase} - $body',
        );
      }
    } finally {
      client.close(force: true);
    }
  }

  Map<String, dynamic> buildProfilePayload({
    required String name,
    required String address,
    required String city,
    required String aadhaarNumber,
    required String panNumber,
    required String licenseNumber,
    required String vehicleNumber,
    required String bankAccountNumber,
    required String profilePicture,
  }) {
    String trimToMax(String value, [int maxLength = 255]) {
      final trimmed = value.trim();
      if (trimmed.length <= maxLength) return trimmed;
      return trimmed.substring(0, maxLength);
    }

    return {
      'name': trimToMax(name),
      'address': trimToMax(address),
      'city': trimToMax(city),
      'aadhaarNumber': trimToMax(aadhaarNumber),
      'panNumber': trimToMax(panNumber),
      'licenseNumber': trimToMax(licenseNumber),
      'vehicleNumber': trimToMax(vehicleNumber),
      'bankAccountNumber': trimToMax(bankAccountNumber),
      'profilePicture': trimToMax(profilePicture, 10000),
    };
  }

  Future<Map<String, dynamic>> submitDeliveryProfile({
    required String token,
    required Map<String, dynamic> profileData,
  }) async {
    final uri = Uri.parse('$profileBaseUrl/profile/delivery');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(profileData),
    );

    final body = response.body;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Profile submission failed: ${response.statusCode} ${response.reasonPhrase} - $body',
      );
    }
  }

  Future<Map<String, dynamic>> getDeliveryProfile({
    required String token,
  }) async {
    final uri = Uri.parse('$profileBaseUrl/profile/delivery');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = response.body;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Profile fetch failed: ${response.statusCode} ${response.reasonPhrase} - $body',
      );
    }
  }
}
