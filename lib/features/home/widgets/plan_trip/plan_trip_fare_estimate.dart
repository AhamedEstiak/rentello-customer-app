import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'plan_trip_formatters.dart';

class PlanTripFareEstimateCard extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  /// When false, shows a hint instead of numeric mock data.
  final bool hasEstimate;
  final int baseFare;
  final int distanceKm;
  final int totalAmount;
  final int fareMin;
  final int fareMax;

  const PlanTripFareEstimateCard({
    super.key,
    this.isLoading = false,
    this.errorMessage,
    this.hasEstimate = false,
    this.baseFare = 0,
    this.distanceKm = 0,
    this.totalAmount = 0,
    this.fareMin = 0,
    this.fareMax = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasEstimate && errorMessage == null
                      ? AppColors.success
                      : AppColors.textSecondary.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Fare estimate',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (errorMessage != null && errorMessage!.isNotEmpty) ...[
            Text(
              errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ] else if (!hasEstimate) ...[
            Text(
              'Select pickup, destination, vehicle, and schedule. '
              'We will show a fare when the route and vehicle are available.',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.95),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ] else ...[
            _fareRow('Base fare', '৳${formatPlanTripNumber(baseFare)}'),
            const SizedBox(height: 8),
            _fareRow('Distance', '$distanceKm km'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.border, thickness: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated total',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '৳${formatPlanTripNumber(totalAmount > 0 ? totalAmount : baseFare)}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Final fare: ৳${formatPlanTripNumber(fareMin)} – ৳${formatPlanTripNumber(fareMax)} depending on traffic & time',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fareRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
