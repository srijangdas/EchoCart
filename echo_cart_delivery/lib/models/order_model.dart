import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String item;
  final int quantity;
  final int price;
  final LatLng deliveryLocation;
  final String deliveryAddress;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.item,
    required this.quantity,
    required this.price,
    required this.deliveryLocation,
    required this.deliveryAddress,
  });
}