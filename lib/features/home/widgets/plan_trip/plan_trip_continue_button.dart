import 'package:flutter/material.dart';

/// Full-width primary CTA using [ThemeData.elevatedButtonTheme].
class PlanTripContinueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const PlanTripContinueButton({
    super.key,
    this.label = 'Continue to booking',
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
