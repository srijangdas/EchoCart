import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/order_model.dart';

class OrderService {
  static const _kCompletedKey = 'completed_orders';

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

  void dispose() {
    _changeController.close();
  }
}
