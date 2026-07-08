import 'dart:async';

import 'package:echo_cart_delivery/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/driver_model.dart';
import '../services/auth_service.dart';
import '../services/driver_service.dart';
import '../utils/colors.dart';
import 'login_screen.dart';
import 'profile_completion_screen.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Future<DriverModel?> _driverFuture = Future.value(null);
  final DriverService _driverService = DriverService();
  final AuthService _authService = AuthService.instance;
  final OrderService _orderService = OrderService();
  Future<List<OrderModel>> _completedFuture = Future.value(<OrderModel>[]);
  StreamSubscription<void>? _orderSub;

  @override
  void initState() {
    super.initState();
    _driverFuture = _driverService.getDriver();
    _refreshDriver();
    _completedFuture = _orderService.getCompletedOrders();
    _orderSub = _orderService.onChange.listen((_) {
      if (!mounted) return;
      setState(() {
        _completedFuture = _orderService.getCompletedOrders();
      });
    });
  }

  Future<void> _refreshDriver() async {
    final cachedDriver = await _driverService.getDriver();
    final token = await SecureStorageService.getToken();

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      setState(() {
        _driverFuture = Future.value(cachedDriver);
      });
      return;
    }

    try {
      final profile = await _authService.getDeliveryProfile(token: token);
      final hasProfileData = _hasProfileData(profile);

      if (hasProfileData) {
        final refreshedDriver =
            (cachedDriver ??
                    DriverModel(
                      id: '',
                      name: '',
                      phone: '',
                      email: '',
                      licenseNumber: '',
                      vehicleNumber: '',
                      vehicleType: '',
                    ))
                .copyWith(
                  phone: cachedDriver?.phone ?? '',
                  name: profile['name']?.toString() ?? cachedDriver?.name ?? '',
                  address:
                      profile['address']?.toString() ??
                      cachedDriver?.address ??
                      '',
                  city: profile['city']?.toString() ?? cachedDriver?.city ?? '',
                  licenseNumber:
                      profile['licenseNumber']?.toString() ??
                      cachedDriver?.licenseNumber ??
                      '',
                  vehicleNumber:
                      profile['vehicleNumber']?.toString() ??
                      cachedDriver?.vehicleNumber ??
                      '',
                  profileImage:
                      profile['profilePictureUrl']?.toString() ??
                      profile['profilePicture']?.toString() ??
                      cachedDriver?.profileImage ??
                      '',
                  profileCompleted: profile['profileCompleted'] == true,
                  profilePictureUrl:
                      profile['profilePictureUrl']?.toString() ??
                      profile['profilePicture']?.toString() ??
                      cachedDriver?.profilePictureUrl ??
                      '',
                );
        await _driverService.saveDriver(refreshedDriver);
        setState(() {
          _driverFuture = Future.value(refreshedDriver);
        });
      } else if (cachedDriver != null) {
        setState(() {
          _driverFuture = Future.value(cachedDriver);
        });
      } else {
        setState(() {
          _driverFuture = Future.value(null);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _driverFuture = Future.value(cachedDriver);
        });
      }
    }
  }

  bool _hasProfileData(Map<String, dynamic> profile) {
    return profile['profileCompleted'] == true ||
        (profile['name']?.toString().trim().isNotEmpty ?? false) ||
        (profile['address']?.toString().trim().isNotEmpty ?? false) ||
        (profile['city']?.toString().trim().isNotEmpty ?? false) ||
        (profile['licenseNumber']?.toString().trim().isNotEmpty ?? false) ||
        (profile['vehicleNumber']?.toString().trim().isNotEmpty ?? false) ||
        (profile['aadhaarNumber']?.toString().trim().isNotEmpty ?? false) ||
        (profile['panNumber']?.toString().trim().isNotEmpty ?? false);
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Account',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: buttonMainColor,
          ),
        ),
      ),
      body: FutureBuilder<DriverModel?>(
        future: _driverFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: buttonMainColor),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: buttonMainColor),
                  const SizedBox(height: 16),
                  Text(
                    'No driver information found',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final token = await SecureStorageService.getToken();
                      if (!mounted) return;
                      if (token == null || token.isEmpty) {
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      } else {
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileCompletionScreen(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonMainColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Add details',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          final driver = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Image
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: backgroundColor,
                          border: Border.all(color: buttonMainColor, width: 3),
                        ),
                        child: Center(
                          child: driver.profileImage.isEmpty
                              ? FaIcon(
                                  FontAwesomeIcons.user,
                                  size: 50,
                                  color: buttonMainColor,
                                )
                              : ClipOval(
                                  child: Image.network(
                                    driver.profileImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return FaIcon(
                                        FontAwesomeIcons.user,
                                        size: 50,
                                        color: buttonMainColor,
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Driver Name
                      Text(
                        driver.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(driver.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(driver.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Basic account summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat(
                            icon: FontAwesomeIcons.phone,
                            value: driver.phone.isEmpty ? 'N/A' : driver.phone,
                            label: 'Phone',
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          _buildStat(
                            icon: FontAwesomeIcons.box,
                            value: driver.totalDeliveries.toString(),
                            label: 'Deliveries',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Profile Details Section
                _buildSection(
                  title: 'Profile Details',
                  children: [
                    _buildInfoTile(
                      icon: FontAwesomeIcons.locationDot,
                      label: 'Address',
                      value: driver.address.isEmpty
                          ? 'Not provided'
                          : driver.address,
                    ),
                    _buildInfoTile(
                      icon: FontAwesomeIcons.city,
                      label: 'City',
                      value: driver.city.isEmpty ? 'Not provided' : driver.city,
                    ),
                    _buildInfoTile(
                      icon: FontAwesomeIcons.car,
                      label: 'Vehicle Number',
                      value: driver.vehicleNumber.isEmpty
                          ? 'Not provided'
                          : driver.vehicleNumber,
                    ),
                    _buildInfoTile(
                      icon: FontAwesomeIcons.circleCheck,
                      label: 'Profile Status',
                      value: driver.profileCompleted ? 'Completed' : 'Pending',
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Delivery History Section
                FutureBuilder<List<OrderModel>>(
                  future: _completedFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }

                    final items = snapshot.data ?? [];
                    return _buildSection(
                      title: 'Delivery History',
                      children: items.isEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No completed deliveries yet',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            ]
                          : items
                                .map(
                                  (o) => ListTile(
                                    title: Text(o.item),
                                    subtitle: Text(
                                      '${o.customerName} • ₹${o.price}',
                                    ),
                                    trailing: Text(
                                      o.deliveryAddress,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                    );
                  },
                ),

                const SizedBox(height: 30),
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: FaIcon(
                      FontAwesomeIcons.arrowRightFromBracket,
                      size: 18,
                    ),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        FaIcon(icon, color: buttonMainColor, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, color: buttonMainColor, size: 18),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'on_delivery':
        return buttonMainColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'on_delivery':
        return 'On Delivery';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              await _driverService.clearDriver();
              await SecureStorageService.deleteTokens();
              if (!mounted) return;
              navigator.pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red[600]),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
