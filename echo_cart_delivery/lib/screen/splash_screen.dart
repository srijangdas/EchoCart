import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:echo_cart_delivery/screen/login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Center(
        child: Lottie.asset('assets/animations/Echocart_logo.json'),
      ),
      nextScreen: LoginScreen(),
      splashIconSize: 300,
      backgroundColor: const Color(0xFFFFACB1),
      duration: 1000,
    );
  }
}
