import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Shown while [AuthNotifier] restores the session from secure storage.
/// Does not watch customer API providers.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
