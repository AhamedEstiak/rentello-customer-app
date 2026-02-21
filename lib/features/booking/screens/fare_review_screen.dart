import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/booking.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/booking_form_provider.dart';

class FareReviewScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> args;

  const FareReviewScreen({super.key, required this.args});

  @override
  ConsumerState<FareReviewScreen> createState() => _FareReviewScreenState();
}

class _FareReviewScreenState extends ConsumerState<FareReviewScreen> {
  final _promoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final form = ref.read(bookingFormProvider);
      ref.read(fareEstimateProvider.notifier).estimate(form);
    });
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fareState = ref.watch(fareEstimateProvider);
    final form = ref.watch(bookingFormProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fare Summary')),
      body: fareState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : fareState.breakdown == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text(fareState.error ?? 'Failed to estimate fare'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(fareEstimateProvider.notifier).estimate(form),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _BookingSummaryCard(form: form),
                    const SizedBox(height: 16),
                    _FareCard(breakdown: fareState.breakdown!),
                    const SizedBox(height: 16),
                    _PromoSection(
                      controller: _promoCtrl,
                      promoDiscount: fareState.promoDiscount,
                      error: fareState.error,
                      onApply: () => ref.read(fareEstimateProvider.notifier).applyPromo(
                            _promoCtrl.text.trim(),
                            fareState.breakdown!.subtotal,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _TotalCard(
                      subtotal: fareState.breakdown!.subtotal,
                      promoDiscount: fareState.promoDiscount,
                      baseDiscount: fareState.breakdown!.discount,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        final breakdown = fareState.breakdown!;
                        final totalAmount = (breakdown.totalAmount - fareState.promoDiscount)
                            .clamp(0, double.infinity)
                            .toInt();
                        context.push(
                          '/booking/${form.vehicleId}/form/${form.bookingType}/review/confirm',
                          extra: {
                            'form': form,
                            'breakdown': breakdown,
                            'promoCodeId': fareState.promoCodeId,
                            'totalAmount': totalAmount,
                          },
                        );
                      },
                      child: const Text('Confirm Booking'),
                    ),
                  ],
                ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  final BookingFormState form;
  const _BookingSummaryCard({required this.form});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Pickup',
              value: form.pickupAddress.isEmpty ? 'Not specified' : form.pickupAddress,
            ),
            if (form.dropoffAddress.isNotEmpty)
              _DetailRow(
                icon: Icons.location_on,
                label: 'Drop-off',
                value: form.dropoffAddress,
              ),
            _DetailRow(
              icon: Icons.schedule,
              label: 'Type',
              value: form.bookingType.replaceAll('_', ' '),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _FareCard extends StatelessWidget {
  final FareBreakdown breakdown;
  const _FareCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fare Breakdown',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (breakdown.baseFare > 0)
              _FareRow('Base Fare', breakdown.baseFare),
            if (breakdown.hourlyCharge > 0)
              _FareRow('Hourly Charge', breakdown.hourlyCharge),
            if (breakdown.distanceCharge > 0)
              _FareRow('Distance Charge', breakdown.distanceCharge),
            if (breakdown.nightSurcharge > 0)
              _FareRow('Night Surcharge', breakdown.nightSurcharge),
            if (breakdown.airportSurcharge > 0)
              _FareRow('Airport Surcharge', breakdown.airportSurcharge),
            if (breakdown.intercitySurcharge > 0)
              _FareRow('Intercity Surcharge', breakdown.intercitySurcharge),
            if (breakdown.discount > 0)
              _FareRow('Discount', -breakdown.discount, isDiscount: true),
            const Divider(height: 20),
            _FareRow('Subtotal', breakdown.subtotal, isBold: true),
          ],
        ),
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool isBold;
  final bool isDiscount;

  const _FareRow(this.label, this.amount, {this.isBold = false, this.isDiscount = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isDiscount && amount < 0 ? "-" : ""}৳${amount.abs()}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isDiscount ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoSection extends StatelessWidget {
  final TextEditingController controller;
  final int promoDiscount;
  final String? error;
  final VoidCallback onApply;

  const _PromoSection({
    required this.controller,
    required this.promoDiscount,
    this.error,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Promo Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Enter promo code',
                      prefixIcon: Icon(Icons.local_offer_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(80, 52)),
                  child: const Text('Apply'),
                ),
              ],
            ),
            if (error != null && error!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            if (promoDiscount > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Promo applied! Saving ৳$promoDiscount',
                    style: const TextStyle(color: AppColors.success, fontSize: 13),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final int subtotal;
  final int promoDiscount;
  final int baseDiscount;

  const _TotalCard({
    required this.subtotal,
    required this.promoDiscount,
    required this.baseDiscount,
  });

  @override
  Widget build(BuildContext context) {
    final total = (subtotal - promoDiscount).clamp(0, double.infinity).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '৳$total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
