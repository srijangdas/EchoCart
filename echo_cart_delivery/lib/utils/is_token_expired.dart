import 'dart:convert';

bool isTokenExpired(String token, {int leewaySeconds = 10}) {
  try {
    final parts = token.split('.');
    if (parts.length < 2) return true;

    String payload = parts[1];
    // Normalize base64
    payload = payload.replaceAll('-', '+').replaceAll('_', '/');
    final pad = payload.length % 4;
    if (pad > 0) payload += '=' * (4 - pad);

    final decoded = utf8.decode(base64Url.decode(payload));
    final map = json.decode(decoded) as Map<String, dynamic>;

    if (!map.containsKey('exp')) return false;

    final expVal = map['exp'];
    int exp;
    if (expVal is int) {
      exp = expVal;
    } else if (expVal is String) {
      exp = int.tryParse(expVal) ?? 0;
    } else {
      return true;
    }

    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final nowWithLeeway = DateTime.now().add(Duration(seconds: leewaySeconds));
    return expiry.isBefore(nowWithLeeway);
  } catch (_) {
    return true;
  }
}
