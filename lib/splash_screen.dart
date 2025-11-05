import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // This is the corrected approach.
    // The navigation logic is now scheduled to run after the first frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    // A short delay can still be useful for a smoother visual transition
    await Future.delayed(const Duration(milliseconds: 500));

    // The 'mounted' check is still a good practice.
    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        developer.log('User is authenticated, navigating to /devices', name: 'SplashScreen');
        context.go('/devices');
      } else {
        developer.log('User is not authenticated, navigating to /landing', name: 'SplashScreen');
        context.go('/landing');
      }
    } catch (e, s) {
      developer.log(
        'Error during auth check, navigating to /landing as a fallback.',
        name: 'SplashScreen',
        error: e,
        stackTrace: s,
      );
      // If any error occurs, we still safely navigate to the landing page.
      if (mounted) {
        context.go('/landing');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        // Using a more visually appealing indicator
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Initializing...'),
          ],
        ),
      ),
    );
  }
}
