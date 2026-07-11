import 'package:flutter/material.dart';

import '../utils/colors.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'orders_screen.dart';
import 'active_order_screen.dart';
import 'account_screen.dart';

class AppMainScreen extends StatefulWidget {
  const AppMainScreen({super.key});

  @override
  State<AppMainScreen> createState() => _AppMainScreenState();
}

class _AppMainScreenState extends State<AppMainScreen> {
  int _selectedIndex = 0;
  OrderModel? _activeOrder;
  final OrderService _orderService = OrderService();

  List<Widget> get _pages => [
    OrdersScreen(
      onActiveOrderSelected: _handleActiveOrderSelected,
      activeOrderId: _activeOrder?.id,
    ),
    ActiveOrderScreen(
      order: _activeOrder,
      onActiveOrderCleared: _handleActiveOrderCleared,
    ),
    AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _restoreActiveOrder();
  }

  Future<void> _restoreActiveOrder() async {
    final restored = await _orderService.getSavedActiveOrder();
    if (!mounted) return;
    if (restored != null) {
      setState(() {
        _activeOrder = restored;
        _selectedIndex = 1;
      });
    }
  }

  void _handleActiveOrderSelected(OrderModel order) {
    _orderService.saveActiveOrder(order);
    setState(() {
      _activeOrder = order;
      _selectedIndex = 1;
    });
  }

  void _handleActiveOrderCleared() {
    _orderService.clearActiveOrder();
    setState(() {
      _activeOrder = null;
      _selectedIndex = 0;
    });
  }

  Widget _navIcon(IconData iconData, bool active) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active ? buttonMainColor : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(iconData, size: 22, color: active ? Colors.white : iconColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              offset: Offset(0, 5),
              blurRadius: 10.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            selectedItemColor: buttonMainColor,
            unselectedItemColor: iconColor.withValues(alpha: 0.7),
            selectedFontSize: 15,
            unselectedFontSize: 15,
            items: [
              BottomNavigationBarItem(
                icon: _navIcon(Icons.list_alt_outlined, false),
                activeIcon: _navIcon(Icons.list_alt, true),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: _navIcon(Icons.local_shipping_outlined, false),
                activeIcon: _navIcon(Icons.local_shipping, true),
                label: 'Active Order',
              ),
              BottomNavigationBarItem(
                icon: _navIcon(Icons.person_outline, false),
                activeIcon: _navIcon(Icons.person, true),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
