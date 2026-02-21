import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class _BookingType {
  final String value;
  final String label;
  final String description;
  final IconData icon;

  const _BookingType({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const _types = [
  _BookingType(
    value: 'HOURLY',
    label: 'Hourly',
    description: 'Book by the hour, ideal for short trips',
    icon: Icons.access_time,
  ),
  _BookingType(
    value: 'MULTI_DAY',
    label: 'Multi-day',
    description: 'Book for multiple days at a daily rate',
    icon: Icons.calendar_month,
  ),
  _BookingType(
    value: 'AIRPORT_TRANSFER',
    label: 'Airport Transfer',
    description: 'Pickup or drop-off at the airport',
    icon: Icons.flight,
  ),
  _BookingType(
    value: 'INTERCITY',
    label: 'Intercity',
    description: 'Travel between cities at fixed rates',
    icon: Icons.route,
  ),
];

class BookingTypeScreen extends StatefulWidget {
  final String vehicleId;

  const BookingTypeScreen({super.key, required this.vehicleId});

  @override
  State<BookingTypeScreen> createState() => _BookingTypeScreenState();
}

class _BookingTypeScreenState extends State<BookingTypeScreen> {
  String _selected = 'HOURLY';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Booking Type')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How would you like to book?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _types.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final type = _types[index];
                  final isSelected = type.value == _selected;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = type.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              type.icon,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type.label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  type.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: AppColors.primary),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push(
                '/booking/${widget.vehicleId}/form/$_selected',
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
