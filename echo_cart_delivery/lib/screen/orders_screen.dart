import 'package:flutter/material.dart';

import '../utils/colors.dart';
import '../models/order_model.dart';
import '../utils/utils.dart';
import 'order_detail_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/order_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('dd/MM/yyyy');
  final OrderService _orderService = OrderService();

  late List<OrderModel> _orders;

  @override
  void initState() {
    super.initState();
    _orders = List<OrderModel>.from(_sampleOrders);
  }

  Future<void> _onOrderStatusChanged(OrderModel order) async {
    setState(() {});
    if (order.status == OrderStatus.completed) {
      await _orderService.addCompletedOrder(order);
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = formatter.format(now);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.shopping_cart, color: iconColor, size: 26),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders',
              style: TextStyle(color: iconColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: buttonMainColor,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      'Groceries',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final card = OrderCard(
                    order: order,
                    onStatusChanged: _onOrderStatusChanged,
                  );

                  Widget item = card;
                  if (order.status != OrderStatus.pending &&
                      order.status != OrderStatus.accepted) {
                    item = Dismissible(
                      key: ValueKey(order.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.redAccent,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        setState(() {
                          if (index >= 0 && index < _orders.length) {
                            _orders.removeAt(index);
                          }
                        });
                      },
                      child: card,
                    );
                  }

                  // Add spacing after each item except last
                  return Column(
                    children: [
                      item,
                      if (index != _orders.length - 1)
                        const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final List<OrderModel> _sampleOrders = [
  OrderModel(
    id: '1',
    customerName: 'John Smith',
    customerPhone: '+919876543210',
    item: 'Amul 1L Milk Pouch',
    quantity: 1,
    price: 60,
    deliveryLocation: LatLng(12.9716, 77.5946),
    deliveryAddress: '67 Main St, Bangalore',
  ),
  OrderModel(
    id: '2',
    customerName: 'Jane Doe',
    customerPhone: '+919812345678',
    item: 'Kinder Joy 1Pc',
    quantity: 2,
    price: 150,
    deliveryLocation: LatLng(12.2958, 76.6394),
    deliveryAddress: '45, MG Road, Lonavlawa',
  ),
];

class OrderCard extends StatefulWidget {
  final OrderModel order;
  final void Function(OrderModel order)? onStatusChanged;

  const OrderCard({super.key, required this.order, this.onStatusChanged});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  late OrderModel order;

  @override
  void initState() {
    super.initState();
    order = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.customerName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusChip(),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await _openDialer(context, order.customerPhone);
                        },
                        child: _smallCircleIcon(Icons.call),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final error = await openLocationInMaps(
                            order.deliveryLocation,
                            order.deliveryAddress,
                          );
                          if (error != null && context.mounted) {
                            showAppSnackbar(
                              context: context,
                              type: SnackbarType.error,
                              description: error,
                            );
                          }
                        },
                        child: _smallCircleIcon(Icons.navigation),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item: ${order.item}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Qty: ${order.quantity}  •  Price: ₹${order.price}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Address: ${order.deliveryAddress}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: order.status == OrderStatus.completed
                          ? null
                          : () {
                              setState(() {
                                order.status = OrderStatus.rejected;
                              });
                              widget.onStatusChanged?.call(order);
                              showAppSnackbar(
                                context: context,
                                type: SnackbarType.error,
                                description: 'Order rejected',
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: declineOrder,
                        foregroundColor: Colors.blue.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Reject\nOrder',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: order.status == OrderStatus.completed
                          ? null
                          : () {
                              if (order.status == OrderStatus.accepted) {
                                setState(() {
                                  order.status = OrderStatus.completed;
                                });
                                widget.onStatusChanged?.call(order);
                                showAppSnackbar(
                                  context: context,
                                  type: SnackbarType.success,
                                  description: 'Order completed',
                                );
                              } else {
                                setState(() {
                                  order.status = OrderStatus.accepted;
                                });
                                widget.onStatusChanged?.call(order);
                                showAppSnackbar(
                                  context: context,
                                  type: SnackbarType.success,
                                  description: 'Order accepted',
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: destinationReached,
                        foregroundColor: iconColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        order.status == OrderStatus.accepted
                            ? 'Complete\nOrder'
                            : 'Accept\nOrder',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallCircleIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: pickedUpColor, shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: iconColor),
    );
  }

  Widget _statusChip() {
    String label;
    Color bg;
    switch (order.status) {
      case OrderStatus.accepted:
        label = 'Accepted';
        bg = Colors.green.withAlpha(40);
        break;
      case OrderStatus.rejected:
        label = 'Rejected';
        bg = Colors.red.withAlpha(40);
        break;
      case OrderStatus.completed:
        label = 'Completed';
        bg = Colors.blue.withAlpha(40);
        break;
      default:
        label = 'Pending';
        bg = Colors.orange.withAlpha(40);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Future<void> _openDialer(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        showAppSnackbar(
          context: context,
          type: SnackbarType.error,
          description: 'Could not open dialer.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackbar(
          context: context,
          type: SnackbarType.error,
          description: 'Could not open dialer.',
        );
      }
    }
  }
}
