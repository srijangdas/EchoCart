import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/order_model.dart';
import '../utils/colors.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final CameraPosition initialCamera = CameraPosition(
      target: order.deliveryLocation,
      zoom: 14,
    );

    final Marker marker = Marker(
      markerId: MarkerId(order.id),
      position: order.deliveryLocation,
      infoWindow: InfoWindow(title: order.customerName, snippet: order.deliveryAddress),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: iconColor),
        title: Text('Order ${order.id}', style: TextStyle(color: iconColor)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.customerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 18, color: iconColor),
                    const SizedBox(width: 8),
                    Text(order.customerPhone, style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Item: ${order.item}', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 6),
                        Text('Quantity: ${order.quantity}', style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 6),
                        Text('Price: ₹${order.price}', style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Delivery Address', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(order.deliveryAddress),
              ],
            ),
          ),

          // Embedded Google Map
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: GoogleMap(
                initialCameraPosition: initialCamera,
                markers: {marker},
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
