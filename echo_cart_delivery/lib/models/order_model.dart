import 'package:google_maps_flutter/google_maps_flutter.dart';

enum OrderStatus { pending, accepted, rejected, completed }

class OrderModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String item;
  final int quantity;
  final int price;
  final LatLng deliveryLocation;
  final String deliveryAddress;
  OrderStatus status;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.item,
    required this.quantity,
    required this.price,
    required this.deliveryLocation,
    required this.deliveryAddress,
    this.status = OrderStatus.pending,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'item': item,
    'quantity': quantity,
    'price': price,
    'deliveryLocation': {
      'lat': deliveryLocation.latitude,
      'lng': deliveryLocation.longitude,
    },
    'deliveryAddress': deliveryAddress,
    'status': status.name,
  };

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final loc = json['deliveryLocation'] as Map<String, dynamic>;
    return OrderModel(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      item: json['item'] as String,
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toInt(),
      deliveryLocation: LatLng(
        (loc['lat'] as num).toDouble(),
        (loc['lng'] as num).toDouble(),
      ),
      deliveryAddress: json['deliveryAddress'] as String,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
    );
  }
}
