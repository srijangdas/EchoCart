import 'package:flutter/material.dart';

import '../utils/colors.dart';
import 'orders_screen.dart';
import 'account_screen.dart';

class AppMainScreen extends StatefulWidget {
  const AppMainScreen({super.key});

  @override
  State<AppMainScreen> createState() => _AppMainScreenState();
}

class _AppMainScreenState extends State<AppMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [OrdersScreen(), AccountScreen()];

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
