import 'package:echo_cart_delivery/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService profile payload', () {
    test('builds the delivery-profile payload with all required fields', () {
      final service = AuthService(baseUrl: 'https://example.test/api/auth');

      final payload = service.buildProfilePayload(
        name: 'John Doe',
        address: '1 Main St',
        city: 'Bengaluru',
        aadhaarNumber: '1234 5678 9012',
        panNumber: 'ABCDE1234F',
        licenseNumber: 'DL-123456',
        vehicleNumber: 'KA01AB1234',
        bankAccountNumber: '1234567890',
        profilePicture: 'data:image/png;base64,abc123',
      );

      expect(payload['name'], 'John Doe');
      expect(payload['address'], '1 Main St');
      expect(payload['city'], 'Bengaluru');
      expect(payload['aadhaarNumber'], '1234 5678 9012');
      expect(payload['panNumber'], 'ABCDE1234F');
      expect(payload['licenseNumber'], 'DL-123456');
      expect(payload['vehicleNumber'], 'KA01AB1234');
      expect(payload['bankAccountNumber'], '1234567890');
      expect(payload['profilePicture'], 'data:image/png;base64,abc123');
    });
  });
}
