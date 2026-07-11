import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/order_model.dart';
import '../utils/colors.dart';
import '../utils/utils.dart';
import '../services/order_service.dart';
import '../services/secure_storage_service.dart';
import 'orders_screen.dart';

class ActiveOrderScreen extends StatefulWidget {
  final OrderModel? order;
  const ActiveOrderScreen({super.key, this.order});

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

  Widget _buildStatusButton(
    DeliveryStatus status,
    String label,
    bool isActive,
    bool isCompleted,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: isActive && !_loading
            ? () => _updateDeliveryStatus(status)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isCompleted
                ? buttonMainColor
                : isActive
                ? Colors.white
                : Colors.grey.shade200,
            border: Border.all(
              color: isActive ? buttonMainColor : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
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

  bool _isStatusActive(DeliveryStatus status) {
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
    return statusIndex == currentIndex + 1;
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
        title: Text(
          'Active Order ${order.id}',
          style: TextStyle(color: iconColor),
        ),
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
                              _isStatusActive(DeliveryStatus.accepted) ||
                                  order.deliveryStatus ==
                                      DeliveryStatus.accepted,
                              _isStatusCompleted(DeliveryStatus.accepted),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusButton(
                              DeliveryStatus.shopping,
                              'Shopping',
                              _isStatusActive(DeliveryStatus.shopping),
                              _isStatusCompleted(DeliveryStatus.shopping),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusButton(
                              DeliveryStatus.inTransit,
                              'In Transit',
                              _isStatusActive(DeliveryStatus.inTransit),
                              _isStatusCompleted(DeliveryStatus.inTransit),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusButton(
                              DeliveryStatus.delivered,
                              'Delivered',
                              _isStatusActive(DeliveryStatus.delivered),
                              _isStatusCompleted(DeliveryStatus.delivered),
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
