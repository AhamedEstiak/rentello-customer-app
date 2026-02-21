import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(authProvider).customer;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer?.name ?? '',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'SERVICES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  _ServiceCard(
                    title: 'Airport Transfer',
                    subtitle: 'Fast and reliable\nrides to/from airport',
                    icon: Icons.flight,
                    backgroundColor: const Color(0xFFE8F0FE),
                    iconBackgroundColor: const Color(0xFF1E3A8A),
                    buttonLabel: 'Book Now',
                    onTap: () => context.push('/vehicles/AIRPORT_TRANSFER'),
                  ),
                  const SizedBox(height: 16),
                  _ServiceCard(
                    title: 'Private Rental',
                    subtitle: 'Hourly rental for your\nconvenience',
                    icon: Icons.directions_car,
                    backgroundColor: const Color(0xFFE6F4EF),
                    iconBackgroundColor: const Color(0xFF065F46),
                    buttonLabel: 'Rent Now',
                    onTap: () => context.push('/vehicles/HOURLY'),
                  ),
                  const SizedBox(height: 16),
                  _ServiceCard(
                    title: 'Intercity',
                    subtitle: 'Comfortable rides\nbetween cities',
                    icon: Icons.route,
                    backgroundColor: const Color(0xFFFEF3C7),
                    iconBackgroundColor: const Color(0xFF92400E),
                    buttonLabel: 'Book Now',
                    onTap: () => context.push('/vehicles/INTERCITY'),
                  ),
                  const SizedBox(height: 16),
                  _ServiceCard(
                    title: 'Multi-day Rental',
                    subtitle: 'Daily hire at\ncompetitive rates',
                    icon: Icons.calendar_month,
                    backgroundColor: const Color(0xFFF3E8FF),
                    iconBackgroundColor: const Color(0xFF5B21B6),
                    buttonLabel: 'Rent Now',
                    onTap: () => context.push('/vehicles/MULTI_DAY'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final String buttonLabel;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.iconBackgroundColor,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: iconBackgroundColor.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconBackgroundColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
