import 'package:flutter/material.dart';

import '../utils/colors.dart';
import '../services/auth_service.dart';
import '../services/driver_service.dart';
import '../models/driver_model.dart';
import 'profile_completion_screen.dart';
import 'app_main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  final _auth = AuthService.instance;
  final _driverService = DriverService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _driverService.clearDriver();

      final registerResponse = await _auth.register(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      String? token;
      if (registerResponse.containsKey('token')) {
        token = registerResponse['token']?.toString();
        if (token != null && token.isNotEmpty) {
          await _driverService.saveToken(token);
        }
      }

      if (registerResponse.containsKey('driver') &&
          registerResponse['driver'] != null) {
        final driverData = DriverModel.fromJson(registerResponse['driver']);
        await _driverService.saveDriver(driverData);
      } else {
        final loginResponse = await _auth.login(
          phone: _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
        if (loginResponse.containsKey('driver') &&
            loginResponse['driver'] != null) {
          final driverData = DriverModel.fromJson(loginResponse['driver']);
          await _driverService.saveDriver(driverData);
        }
        if (loginResponse.containsKey('token')) {
          token = loginResponse['token']?.toString();
          if (token != null && token.isNotEmpty) {
            await _driverService.saveToken(token);
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account created')));

      bool profileCompleted =
          registerResponse['profileCompleted'] == true ||
          registerResponse['driver']?['profileCompleted'] == true;

      if (!profileCompleted && token != null && token.isNotEmpty) {
        try {
          final profileResponse = await _auth.getDeliveryProfile(token: token);
          profileCompleted =
              profileResponse['profileCompleted'] == true ||
              (profileResponse['name']?.toString().isNotEmpty ?? false) ||
              (profileResponse['address']?.toString().isNotEmpty ?? false) ||
              (profileResponse['city']?.toString().isNotEmpty ?? false) ||
              (profileResponse['licenseNumber']?.toString().isNotEmpty ??
                  false) ||
              (profileResponse['vehicleNumber']?.toString().isNotEmpty ??
                  false);
        } catch (_) {}
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => profileCompleted
              ? const AppMainScreen()
              : const ProfileCompletionScreen(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Register failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Builder(
              builder: (context) {
                final height = MediaQuery.of(context).size.height;
                final topHeight = (height * 0.6).clamp(260.0, height);
                return Container(
                  width: double.infinity,
                  height: topHeight,
                  padding: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [buttonMainColor, backgroundColor],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 55),
                      SizedBox(
                        height: topHeight * 0.65,
                        child: Image.asset(
                          'assets/images/delivery.png',
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'Create account',
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            Builder(
              builder: (context) {
                final height = MediaQuery.of(context).size.height;
                final topHeight = (height * 0.5).clamp(260.0, height);
                return Transform.translate(
                  offset: Offset(0, -topHeight * 0.12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Full name',
                                  filled: true,
                                  fillColor: declineOrder,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Enter name'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'Phone number',
                                  filled: true,
                                  fillColor: declineOrder,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Enter phone'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  filled: true,
                                  fillColor: declineOrder,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (v) => (v == null || v.length < 6)
                                    ? 'Password too short'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonMainColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Create account',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
