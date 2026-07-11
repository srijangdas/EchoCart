import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/order_model.dart';
import '../utils/colors.dart';
import '../utils/utils.dart';
import '../services/order_service.dart';
import '../services/secure_storage_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveOrderScreen extends StatefulWidget {
  final OrderModel? order;
  final VoidCallback? onActiveOrderCleared;

  const ActiveOrderScreen({super.key, this.order, this.onActiveOrderCleared});

  @override
  State<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<ActiveOrderScreen> {
  late OrderModel? _activeOrder;
  bool _loading = false;
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _activeOrder = widget.order;
  }

  @override
  void didUpdateWidget(covariant ActiveOrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order != oldWidget.order) {
      setState(() => _activeOrder = widget.order);
    }
  }

  Future<void> _updateDeliveryStatus(DeliveryStatus newStatus) async {
    if (_activeOrder == null) return;

    setState(() => _loading = true);
    try {
      final token = await SecureStorageService.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          showAppSnackbar(
            context: context,
            type: SnackbarType.error,
            description: 'No token found.',
          );
        }
        return;
      }

      final statusMap = {
        DeliveryStatus.accepted: 'ACCEPTED',
        DeliveryStatus.shopping: 'SHOPPING',
        DeliveryStatus.inTransit: 'IN_TRANSIT',
        DeliveryStatus.delivered: 'DELIVERED',
      };

      final success = await _orderService.updateDeliveryStatus(
        token: token,
        orderId: _activeOrder!.id,
        status: statusMap[newStatus] ?? 'ACCEPTED',
      );

      if (success) {
        if (newStatus == DeliveryStatus.delivered) {
          await _orderService.clearActiveOrder();
          if (mounted) {
            showAppSnackbar(
              context: context,
              type: SnackbarType.success,
              description: 'Order marked as delivered. Active order cleared.',
            );
            widget.onActiveOrderCleared?.call();
            setState(() => _activeOrder = null);
          }
          return;
        }

        setState(() {
          _activeOrder?.deliveryStatus = newStatus;
        });
        if (_activeOrder != null) {
          await _orderService.saveActiveOrder(_activeOrder!);
        }
        if (mounted) {
          showAppSnackbar(
            context: context,
            type: SnackbarType.success,
            description: 'Status updated to ${newStatus.name}',
          );
        }
      } else {
        if (mounted) {
          showAppSnackbar(
            context: context,
            type: SnackbarType.error,
            description: 'Failed to update status',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(
          context: context,
          type: SnackbarType.error,
          description: 'Error: ${e.toString()}',
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancelOrder() async {
    if (_activeOrder == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final token = await SecureStorageService.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          showAppSnackbar(
            context: context,
            type: SnackbarType.error,
            description: 'No token found.',
          );
        }
        return;
      }

      final success = await _orderService.cancelOrder(
        token: token,
        orderId: _activeOrder!.id,
      );

      if (success) {
        await _orderService.clearActiveOrder();
        if (mounted) {
          showAppSnackbar(
            context: context,
            type: SnackbarType.success,
            description: 'Order cancelled successfully.',
          );
          widget.onActiveOrderCleared?.call();
          setState(() => _activeOrder = null);
        }
      } else {
        if (mounted) {
          showAppSnackbar(
            context: context,
            type: SnackbarType.error,
            description: 'Failed to cancel order.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(
          context: context,
          type: SnackbarType.error,
          description: 'Error: ${e.toString()}',
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildStatusButton(DeliveryStatus status, String label) {
    final statusOrder = [
      DeliveryStatus.accepted,
      DeliveryStatus.shopping,
      DeliveryStatus.inTransit,
      DeliveryStatus.delivered,
    ];
    final currentIndex = statusOrder.indexOf(
      _activeOrder?.deliveryStatus ?? DeliveryStatus.accepted,
    );
    final statusIndex = statusOrder.indexOf(status);
    final isCompleted = statusIndex < currentIndex;
    final isCurrent = statusIndex == currentIndex;
    final isNext = statusIndex == currentIndex + 1;

    return Expanded(
      child: GestureDetector(
        onTap: isNext && !_loading ? () => _updateDeliveryStatus(status) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isCompleted
                ? buttonMainColor
                : isCurrent
                ? Colors.white
                : Colors.grey.shade200,
            border: Border.all(
              color: isCompleted || isCurrent
                  ? buttonMainColor
                  : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : isCurrent
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isCompleted ? Colors.white : iconColor,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isStatusCompleted(DeliveryStatus status) {
    final statusOrder = [
      DeliveryStatus.accepted,
      DeliveryStatus.shopping,
      DeliveryStatus.inTransit,
      DeliveryStatus.delivered,
    ];
    final currentIndex = statusOrder.indexOf(
      _activeOrder?.deliveryStatus ?? DeliveryStatus.accepted,
    );
    final statusIndex = statusOrder.indexOf(status);
    return statusIndex < currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    if (_activeOrder == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: iconColor),
          title: Text('Active Order', style: TextStyle(color: iconColor)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No active order',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accept an order from the Orders tab',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    final order = _activeOrder!;
    final CameraPosition initialCamera = CameraPosition(
      target: order.deliveryLocation,
      zoom: 14,
    );

    final Marker marker = Marker(
      markerId: MarkerId(order.id),
      position: order.deliveryLocation,
      infoWindow: InfoWindow(
        title: order.customerName,
        snippet: order.deliveryAddress,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: iconColor),
        title: Text('Active Order', style: TextStyle(color: iconColor)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with customer info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: buttonMainColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  order.customerPhone,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.paste,
                                  size: 16,
                                  color: buttonMainColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Order Id:  ${order.id}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Status Progress Indicator
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Status',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatusButton(
                              DeliveryStatus.accepted,
                              'Accepted',
                            ),
                            const SizedBox(width: 8),
                            _buildStatusButton(
                              DeliveryStatus.shopping,
                              'Shopping',
                            ),
                            const SizedBox(width: 8),
                            _buildStatusButton(
                              DeliveryStatus.inTransit,
                              'In Transit',
                            ),
                            const SizedBox(width: 8),
                            _buildStatusButton(
                              DeliveryStatus.delivered,
                              'Delivered',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order Items Section
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Items',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.item,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Qty: ${order.quantity}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${order.price}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: buttonMainColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cancel Order Button
                  Row(
                    children: [
                      // 1. Call Customer Button (Outlined style, left side)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () async {
                                  final Uri launchUri = Uri(
                                    scheme: 'tel',
                                    path: order.customerPhone,
                                  );
                                  if (await canLaunchUrl(launchUri)) {
                                    await launchUrl(launchUri);
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Call Customer',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ), // Spacer between the two buttons
                      // 2. Cancel Order Button (Solid red fill background style, right side)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loading ? null : _cancelOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.red.shade600, // Solid fill color
                            foregroundColor: Colors.white, // Text color
                            disabledBackgroundColor: Colors
                                .red
                                .shade200, // Background color when loading/disabled
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation:
                                0, // Keeps it flat to align styling cleanly with the outlined button
                          ),
                          child: Text(
                            'Cancel Order',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Delivery Address Section
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: buttonMainColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Delivery Address',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          order.deliveryAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
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
                            icon: const Icon(Icons.navigation),
                            label: const Text('Navigate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonMainColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Map Section with reduced height
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 280,
                  child: GoogleMap(
                    initialCameraPosition: initialCamera,
                    markers: {marker},
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
