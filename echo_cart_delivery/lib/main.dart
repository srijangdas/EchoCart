import 'package:flutter/material.dart';
import 'package:echo_cart_delivery/screen/app_main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       debugShowCheckedModeBanner: false,
      home: const AppMainScreen(),
    );
  }
}
