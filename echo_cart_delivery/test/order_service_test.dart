import 'package:echo_cart_delivery/models/order_model.dart';
import 'package:echo_cart_delivery/services/order_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists and restores active order across app restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final service = OrderService();

    final order = OrderModel(
      id: 'order-123',
      customerName: 'Jane Doe',
      customerPhone: '9876543210',
      item: 'Milk',
      quantity: 2,
      price: 50,
      deliveryLocation: const LatLng(12.9716, 77.5946),
      deliveryAddress: 'Test Address',
      status: OrderStatus.accepted,
      deliveryStatus: DeliveryStatus.shopping,
    );

    await service.saveActiveOrder(order);
    final restored = await service.getSavedActiveOrder();

    expect(restored, isNotNull);
    expect(restored!.id, order.id);
    expect(restored.customerName, order.customerName);
    expect(restored.deliveryStatus, order.deliveryStatus);
  });
}
