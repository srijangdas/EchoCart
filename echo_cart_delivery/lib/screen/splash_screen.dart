import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:echo_cart_delivery/screen/login_screen.dart';
import 'package:echo_cart_delivery/screen/app_main_screen.dart';
import 'package:echo_cart_delivery/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 1));

    final loggedIn = await AuthService.instance.isLoggedIn();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => loggedIn ? const AppMainScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFACB1),
      body: Center(
        child: Lottie.asset('assets/animations/Echocart_logo.json', width: 300),
      ),
    );
  }
}
