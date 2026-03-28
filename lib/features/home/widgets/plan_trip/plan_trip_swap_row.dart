import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class PlanTripSwapRow extends StatelessWidget {
  final VoidCallback? onSwap;

  const PlanTripSwapRow({super.key, this.onSwap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.border, thickness: 1)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSwap,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const Icon(
                Icons.swap_vert,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        ],
      ),
    );
  }
}
