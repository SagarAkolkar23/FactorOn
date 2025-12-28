import 'package:flutter/material.dart';
import 'package:frontend/core/secureStorage.dart';
import 'package:go_router/go_router.dart';

/// SplashScreen
/// - App entry point
/// - Decides where user should go
/// - NO UI logic, only routing logic
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  /// This function decides navigation based on auth state
  Future<void> _handleNavigation() async {
    // Small delay for splash feel (optional)
    await Future.delayed(const Duration(seconds: 2));

    final token = await SecureStorage.getToken();

    // If token does not exist → go to login
    if (token == null) {
      if (!mounted) return;
      context.go("/login");
      return;
    }

    // Token exists → check role
    final role = await SecureStorage.getRole();

    if (!mounted) return;

    if (role == "operator") {
      context.go("/operatorHome");
    } else if (role == "supervisor") {
      context.go("/supervisorHome");
    } else {
      // Safety fallback
      context.go("/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Factory Monitor",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
