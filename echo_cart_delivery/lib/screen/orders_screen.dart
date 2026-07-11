import 'package:flutter/material.dart';

import '../utils/colors.dart';
import '../models/order_model.dart';
import '../utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/order_service.dart';
import '../services/secure_storage_service.dart';

class OrdersScreen extends StatefulWidget {
  final ValueChanged<OrderModel>? onActiveOrderSelected;
  final String? activeOrderId;

  const OrdersScreen({
    super.key,
    this.onActiveOrderSelected,
    this.activeOrderId,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('dd/MM/yyyy');
  final OrderService _orderService = OrderService();

  late List<OrderModel> _orders;
  String? _activeOrderId; // Track the active/accepted order

  @override
  void initState() {
    super.initState();
    _orders = [];
    _activeOrderId = widget.activeOrderId;
    _loadOrders();
    _restoreActiveOrderId();
  }

  @override
  void didUpdateWidget(covariant OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeOrderId != oldWidget.activeOrderId) {
      setState(() => _activeOrderId = widget.activeOrderId);
    }
  }

  Future<void> _loadOrders() async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() => _orders = []);
        }
        return;
      }

      final list = await _orderService.fetchAvailableOrders(token: token);
      if (mounted) {
        setState(() => _orders = list);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _orders = []);
      }
    }
  }

  Future<void> _restoreActiveOrderId() async {
    final savedOrder = await _orderService.getSavedActiveOrder();
    if (!mounted || savedOrder == null) return;

    setState(() {
      _activeOrderId = savedOrder.id;
      for (final order in _orders) {
        if (order.id == savedOrder.id) {
          order.status = savedOrder.status;
          order.deliveryStatus = savedOrder.deliveryStatus;
        }
      }
    });
  }

  Future<void> _onOrderStatusChanged(
    OrderModel order, {
    required bool isAccepted,
  }) async {
    if (!isAccepted) return;

    final token = await SecureStorageService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        showAppSnackbar(
          context: context,
          type: SnackbarType.error,
          description: 'No token found. Please login again.',
        );
      }
      return;
    }

    final accepted = await _orderService.acceptOrder(
      token: token,
      orderId: order.id,
    );

    if (!accepted) {
      if (mounted) {
        showAppSnackbar(
          context: context,
          type: SnackbarType.error,
          description: 'Unable to accept order right now.',
        );
      }
      return;
    }

    setState(() {
      _activeOrderId = order.id;
      order.status = OrderStatus.accepted;
      order.deliveryStatus = DeliveryStatus.accepted;
    });

    widget.onActiveOrderSelected?.call(order);

    if (mounted) {
      showAppSnackbar(
        context: context,
        type: SnackbarType.success,
        description: 'Order accepted',
      );
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
              child: _orders.isEmpty
                  ? const Center(
                      child: Text(
                        'No orders available right now.',
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final isActiveOrder = _activeOrderId == order.id;
                        final hasActiveOrder = _activeOrderId != null;

                        final card = OrderCard(
                          order: order,
                          isActive: isActiveOrder,
                          hasActiveOrder: hasActiveOrder,
                          onStatusChanged: _onOrderStatusChanged,
                          onViewDetails: widget.onActiveOrderSelected,
                        );

                        Widget item = card;
                        if (order.status != OrderStatus.pending &&
                            order.status != OrderStatus.accepted) {
                          item = Dismissible(
                            key: ValueKey(order.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              color: Colors.redAccent,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
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

class OrderCard extends StatefulWidget {
  final OrderModel order;
  final bool isActive;
  final bool hasActiveOrder;
  final Future<void> Function(OrderModel order, {required bool isAccepted})?
  onStatusChanged;
  final ValueChanged<OrderModel>? onViewDetails;

  const OrderCard({
    super.key,
    required this.order,
    this.isActive = false,
    this.hasActiveOrder = false,
    this.onStatusChanged,
    this.onViewDetails,
  });

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

  Widget _buildDeliveryStatusIndicator() {
    final statuses = [
      (DeliveryStatus.accepted, 'A'),
      (DeliveryStatus.shopping, 'S'),
      (DeliveryStatus.inTransit, 'T'),
      (DeliveryStatus.delivered, 'D'),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(statuses.length, (index) {
        final (status, label) = statuses[index];
        final isCompleted = _isStatusCompleted(status);
        final isCurrent = order.deliveryStatus == status;

        return Padding(
          padding: EdgeInsets.only(right: index < statuses.length - 1 ? 6 : 0),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted
                  ? buttonMainColor
                  : isCurrent
                  ? Colors.orange
                  : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: (isCompleted || isCurrent)
                      ? Colors.white
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  bool _isStatusCompleted(DeliveryStatus status) {
    final statusOrder = [
      DeliveryStatus.accepted,
      DeliveryStatus.shopping,
      DeliveryStatus.inTransit,
      DeliveryStatus.delivered,
    ];
    final currentIndex = statusOrder.indexOf(order.deliveryStatus);
    final statusIndex = statusOrder.indexOf(status);
    return statusIndex < currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isAccepted = order.status == OrderStatus.accepted;
    final isActive = widget.isActive;
    final hasActiveOrder = widget.hasActiveOrder;
    final canAccept = !hasActiveOrder || isActive;

    return Container(
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
        border: isActive ? Border.all(color: buttonMainColor, width: 2) : null,
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
                      if (isAccepted)
                        _buildDeliveryStatusIndicator()
                      else
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isAccepted
                    ? () => widget.onViewDetails?.call(order)
                    : (canAccept
                          ? () async {
                              final callback = widget.onStatusChanged;
                              if (callback != null) {
                                await callback(order, isAccepted: true);
                              }
                            }
                          : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAccepted
                      ? buttonMainColor
                      : (canAccept ? destinationReached : Colors.grey.shade300),
                  foregroundColor: isAccepted
                      ? Colors.white
                      : (canAccept ? iconColor : Colors.grey.shade500),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: Text(
                  isAccepted ? 'View\nDetails' : 'Accept\nOrder',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
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
