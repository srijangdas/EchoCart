import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:echo_cart_delivery/services/secure_storage_service.dart';

const _ordersBaseUrl = 'https://api.echocart.in/api/orders';

class OrderService {
  static const _kCompletedKey = 'completed_orders';
  static const _kActiveOrderKey = 'active_order';

  final StreamController<void> _changeController =
      StreamController<void>.broadcast();

  Stream<void> get onChange => _changeController.stream;

  Future<List<OrderModel>> getCompletedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kCompletedKey) ?? [];
    return raw
        .map((e) => OrderModel.fromJson(json.decode(e) as Map<String, dynamic>))
        .toList();
  }

  /// Fetch available orders from backend
  Future<List<OrderModel>> fetchAvailableOrders({required String token}) async {
    final uri = Uri.parse('$_ordersBaseUrl/available');
    final resp = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final body = jsonDecode(resp.body);
      if (body is List) {
        return body.map<OrderModel>((e) {
          final orderId = e['orderId']?.toString() ?? '';
          final customerName = e['customerName']?.toString() ?? 'Unknown';
          final customerNumber = e['customerNumber']?.toString() ?? '';
          final orderStatus = e['orderStatus']?.toString() ?? 'PENDING';
          final orderJson = e['orderJson'] as Map<String, dynamic>? ?? {};
          final itemList = (orderJson['itemList'] is List)
              ? orderJson['itemList'] as List
              : <dynamic>[];

          return OrderModel(
            id: orderId,
            customerName: customerName,
            customerPhone: customerNumber,
            item: _buildItemSummary(itemList, orderJson),
            quantity: _buildQuantity(itemList, orderJson),
            price: _buildPrice(e['estimatedPrice'], itemList, orderJson),
            deliveryLocation: _latLngFromJson(
              e['deliveryCoordinates'] ?? orderJson['deliveryCoordinates'],
            ),
            deliveryAddress: _buildDeliveryAddress(e, orderJson),
            status: _mapOrderStatus(orderStatus),
          );
        }).toList();
      }
    }
    return [];
  }

  static String _buildItemSummary(
    List<dynamic> itemList,
    Map<String, dynamic> orderJson,
  ) {
    if (itemList.isNotEmpty) {
      final summary = itemList
          .map<String>((item) {
            if (item is Map<String, dynamic>) {
              final name = item['name']?.toString() ?? 'Item';
              final qty = (item['quantity'] is num)
                  ? (item['quantity'] as num).toInt()
                  : 1;
              return '$name ×$qty';
            }
            return item.toString();
          })
          .join(', ');
      return summary.isEmpty ? 'Items' : summary;
    }

    return orderJson['item']?.toString() ??
        orderJson['items']?.toString() ??
        'Items';
  }

  static int _buildQuantity(
    List<dynamic> itemList,
    Map<String, dynamic> orderJson,
  ) {
    if (itemList.isNotEmpty) {
      return itemList.fold<int>(0, (sum, item) {
        if (item is Map<String, dynamic>) {
          final qty = (item['quantity'] is num)
              ? (item['quantity'] as num).toInt()
              : 1;
          return sum + qty;
        }
        return sum + 1;
      });
    }

    return (orderJson['quantity'] is num)
        ? (orderJson['quantity'] as num).toInt()
        : 1;
  }

  static int _buildPrice(
    dynamic estimatedPrice,
    List<dynamic> itemList,
    Map<String, dynamic> orderJson,
  ) {
    if (itemList.isNotEmpty) {
      final total = itemList.fold<double>(0.0, (sum, item) {
        if (item is Map<String, dynamic>) {
          final price = (item['price'] is num)
              ? (item['price'] as num).toDouble()
              : 0.0;
          final qty = (item['quantity'] is num)
              ? (item['quantity'] as num).toInt()
              : 1;
          return sum + (price * qty);
        }
        return sum;
      });
      return total.toInt();
    }

    if (estimatedPrice is num) return estimatedPrice.toInt();
    return (orderJson['price'] is num)
        ? (orderJson['price'] as num).toInt()
        : 0;
  }

  static String _buildDeliveryAddress(
    Map<String, dynamic> response,
    Map<String, dynamic> orderJson,
  ) {
    return response['deliveryLocation']?.toString() ??
        orderJson['deliveryAddress']?.toString() ??
        orderJson['address']?.toString() ??
        'Address not provided';
  }

  static LatLng _latLngFromJson(dynamic json) {
    try {
      if (json is Map<String, dynamic>) {
        final lat = (json['lat'] as num).toDouble();
        final lng = (json['lng'] as num).toDouble();
        return LatLng(lat, lng);
      }
      if (json is Map) {
        final lat = (json['lat'] as num).toDouble();
        final lng = (json['lng'] as num).toDouble();
        return LatLng(lat, lng);
      }
      if (json is String) {
        final parts = json.split(',');
        if (parts.length >= 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) {
            return LatLng(lat, lng);
          }
        }
      }
      if (json is List) {
        if (json.length >= 2) {
          final lat = double.tryParse(json[0].toString());
          final lng = double.tryParse(json[1].toString());
          if (lat != null && lng != null) {
            return LatLng(lat, lng);
          }
        }
      }
    } catch (_) {}
    // fallback to GCELT
    return const LatLng(22.560080, 88.411070);
  }

  static OrderStatus _mapOrderStatus(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('accept')) return OrderStatus.accepted;
    if (lower.contains('complete') || lower.contains('delivered')) {
      return OrderStatus.completed;
    }
    if (lower.contains('reject') || lower.contains('rejected')) {
      return OrderStatus.rejected;
    }
    return OrderStatus.pending;
  }

  /// Cancel an order via backend
  Future<bool> cancelOrder({
    required String token,
    required String orderId,
  }) async {
    final uri = Uri.parse('$_ordersBaseUrl/$orderId/cancel');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  Future<void> addCompletedOrder(OrderModel order) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kCompletedKey) ?? [];
    raw.add(json.encode(order.toJson()));
    await prefs.setStringList(_kCompletedKey, raw);
    _changeController.add(null);
  }

  Future<void> clearCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCompletedKey);
    _changeController.add(null);
  }

  Future<void> saveActiveOrder(OrderModel order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveOrderKey, json.encode(order.toJson()));
    _changeController.add(null);
  }

  Future<OrderModel?> getSavedActiveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kActiveOrderKey);
    if (raw == null || raw.isEmpty) return null;
    return OrderModel.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  Future<void> clearActiveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kActiveOrderKey);
    _changeController.add(null);
  }

  /// Fetch active orders for the delivery partner
  Future<List<OrderModel>> getActiveOrders({required String token}) async {
    final uri = Uri.parse('$_ordersBaseUrl/partner/active');
    final resp = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final body = jsonDecode(resp.body);
      if (body is List) {
        return body.map<OrderModel>((e) {
          final orderId = e['orderId']?.toString() ?? e['id']?.toString() ?? '';
          final customerName = e['customerName']?.toString() ?? 'Unknown';
          final customerNumber = e['customerNumber']?.toString() ?? '';
          final orderStatus = e['orderStatus']?.toString() ?? 'PENDING';
          final deliveryStatus = e['deliveryStatus']?.toString() ?? 'ACCEPTED';
          final orderJson = e['orderJson'] as Map<String, dynamic>? ?? {};
          final itemList = (orderJson['itemList'] is List)
              ? orderJson['itemList'] as List
              : <dynamic>[];

          return OrderModel(
            id: orderId,
            customerName: customerName,
            customerPhone: customerNumber,
            item: _buildItemSummary(itemList, orderJson),
            quantity: _buildQuantity(itemList, orderJson),
            price: _buildPrice(e['estimatedPrice'], itemList, orderJson),
            deliveryLocation: _latLngFromJson(
              e['deliveryCoordinates'] ?? orderJson['deliveryCoordinates'],
            ),
            deliveryAddress: _buildDeliveryAddress(e, orderJson),
            status: _mapOrderStatus(orderStatus),
            deliveryStatus: _mapDeliveryStatus(deliveryStatus),
          );
        }).toList();
      }
    }
    return [];
  }

  /// Fetch order history for the delivery partner
  Future<List<OrderModel>> getOrderHistory({required String token}) async {
    final uri = Uri.parse('$_ordersBaseUrl/partner/history');
    final resp = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final body = jsonDecode(resp.body);
      if (body is List) {
        return body.map<OrderModel>((e) {
          final orderId = e['orderId']?.toString() ?? e['id']?.toString() ?? '';
          final customerName = e['customerName']?.toString() ?? 'Unknown';
          final customerNumber = e['customerNumber']?.toString() ?? '';
          final orderStatus = e['orderStatus']?.toString() ?? 'COMPLETED';
          final deliveryStatus = e['deliveryStatus']?.toString() ?? 'DELIVERED';
          final orderJson = e['orderJson'] as Map<String, dynamic>? ?? {};
          final itemList = (orderJson['itemList'] is List)
              ? orderJson['itemList'] as List
              : <dynamic>[];

          return OrderModel(
            id: orderId,
            customerName: customerName,
            customerPhone: customerNumber,
            item: _buildItemSummary(itemList, orderJson),
            quantity: _buildQuantity(itemList, orderJson),
            price: _buildPrice(e['estimatedPrice'], itemList, orderJson),
            deliveryLocation: _latLngFromJson(
              e['deliveryCoordinates'] ?? orderJson['deliveryCoordinates'],
            ),
            deliveryAddress: _buildDeliveryAddress(e, orderJson),
            status: _mapOrderStatus(orderStatus),
            deliveryStatus: _mapDeliveryStatus(deliveryStatus),
          );
        }).toList();
      }
    }
    return [];
  }

  /// Accept an order
  Future<bool> acceptOrder({
    required String token,
    required String orderId,
  }) async {
    final uri = Uri.parse('$_ordersBaseUrl/$orderId/accept');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  /// Update delivery status of an order
  Future<bool> updateDeliveryStatus({
    required String token,
    required String orderId,
    required String status,
  }) async {
    final uri = Uri.parse('$_ordersBaseUrl/$orderId/status');
    final resp = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  static DeliveryStatus _mapDeliveryStatus(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('shopping')) return DeliveryStatus.shopping;
    if (lower.contains('transit') || lower.contains('in_transit')) {
      return DeliveryStatus.inTransit;
    }
    if (lower.contains('deliver')) return DeliveryStatus.delivered;
    return DeliveryStatus.accepted;
  }

  void dispose() {
    _changeController.close();
  }
}
