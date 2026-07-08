import 'dart:convert';
import 'dart:io';

import 'package:echo_cart_delivery/services/driver_service.dart';
import 'package:echo_cart_delivery/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;

import 'package:unique_device_identifier/unique_device_identifier.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  static final String baseUrl = 'https://api.echocart.in/api/auth';
  static final String profileBaseUrl = 'https://api.echocart.in/api/profile';
  final _driverService = DriverService();

  Future<bool> isLoggedIn() async {
    final token = await SecureStorageService.getToken();
    final refreshToken = await SecureStorageService.getRefreshToken();

    String? deviceId = await UniqueDeviceIdentifier.getUniqueIdentifier();

    if (deviceId == null) {
      if (deviceId == null) {
        final uuid = const Uuid().v4();
        deviceId = "DefaultId-$uuid";
        await _driverService.saveDeviceId(deviceId);
      }
    }

    // 4. Save the confirmed device ID to your driver service
    await _driverService.saveDeviceId(deviceId);

    if (token != null && refreshToken != null) {
      return true;
    }

    return false;
  }

  Future<bool> refreshLogin({required String refreshToken}) async {
    final uri = Uri.parse('$baseUrl/login/refresh');

    final deviceId = await _driverService.getDeviceId() ?? '';

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'X-Device-Id': deviceId},
      body: jsonEncode({'refreshToken': refreshToken, "deviceId": deviceId}),
    );

    final body = response.body;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(body) as Map<String, dynamic>;

      await SecureStorageService.saveTokens(
        token: data["token"] as String,
        refreshToken: data["refreshToken"] as String,
      );

      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/login/delivery');

    final deviceId = await _driverService.getDeviceId() ?? '';

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'X-Device-Id': deviceId},
      body: jsonEncode({'phoneNo': phone, 'password': password}),
    );

    final body = response.body;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(body) as Map<String, dynamic>;

      await SecureStorageService.saveTokens(
        token: data["token"] as String,
        refreshToken: data["refreshToken"] as String,
      );

      return data;
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
      final deviceId = await _driverService.getDeviceId() ?? '';
      request.headers.set('X-Device-Id', deviceId);
      request.add(
        utf8.encode(jsonEncode({'phoneNo': phone, 'password': password})),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(body) as Map<String, dynamic>;

        await SecureStorageService.saveTokens(
          token: data["token"] as String,
          refreshToken: data["refreshToken"] as String,
        );

        return data;
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
    print(token);
    final uri = Uri.parse('$profileBaseUrl/delivery');
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
    // GET /api/profile/delivery
    final uri = Uri.parse('$profileBaseUrl/delivery');
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
      return {'error': response.statusCode};
    }
  }
}
