import 'package:flutter/material.dart';

class NavigationHelper {
  static void push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
  static void pushReplacement(BuildContext context, Widget screen) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => screen));
  }
}