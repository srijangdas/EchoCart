import 'package:flutter/material.dart';

import '../utils/colors.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'app_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  final _auth = AuthService(); // change baseUrl if needed

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => FocusScope.of(context).unfocus(),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.login(
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login successful')));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppMainScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _demoLogin() async {
    setState(() => _loading = true);
    try {
      // simulate network delay
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Demo login')));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppMainScreen()),
      );
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
                  padding: EdgeInsets.only(bottom: 24,),
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
                      const SizedBox(height: 8),
                      const Text(
                        'Welcome back',
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
                  offset: Offset(0, -topHeight * 0.19),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Enter Mobile Number',
                                style: TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 9876543210',
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
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Enter password'
                                    : null,
                              ),
                              const SizedBox(height: 14),
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
                                        'Sign in',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: _loading ? null : _demoLogin,
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Use demo account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 250, 39, 39),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const SignupScreen(),
                                        ),
                                      ),
                                child: const Text(
                                  'Don\'t have an account? Sign up',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 251, 42, 42),
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
          ],
        ),
      ),
    );
  }
}
