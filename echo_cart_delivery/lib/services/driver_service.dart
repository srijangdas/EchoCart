import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_model.dart';

class DriverService {
  static const String _driverKey = 'driver_data';
  static const String _tokenKey = 'auth_token';

  /// Save driver data locally
  Future<void> saveDriver(DriverModel driver) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_driverKey, jsonEncode(driver.toJson()));
  }

  /// Get driver data from local storage
  Future<DriverModel?> getDriver() async {
    final prefs = await SharedPreferences.getInstance();
    final driverJson = prefs.getString(_driverKey);

    if (driverJson != null) {
      return DriverModel.fromJson(jsonDecode(driverJson));
    }
    return null;
  }

  /// Save auth token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get auth token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Clear driver data (logout)
  Future<void> clearDriver() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_driverKey);
    await prefs.remove(_tokenKey);
  }

  /// Check if driver is logged in
  Future<bool> isLoggedIn() async {
    final driver = await getDriver();
    return driver != null;
  }
}
