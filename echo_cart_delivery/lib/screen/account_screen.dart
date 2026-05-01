import 'package:flutter/material.dart';

import '../utils/colors.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          'Account',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: buttonMainColor,
          ),
        ),
      ),
    );
  }
}
