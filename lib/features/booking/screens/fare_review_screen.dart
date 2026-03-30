import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/booking_form_provider.dart';

class FareReviewScreen extends ConsumerStatefulWidget {
  const FareReviewScreen({super.key});

  @override
  ConsumerState<FareReviewScreen> createState() => _FareReviewScreenState();
}

class _FareReviewScreenState extends ConsumerState<FareReviewScreen> {
  bool _estimated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchEstimate());
  }

  void _fetchEstimate() {
    if (_estimated) return;
    _estimated = true;
    final form = ref.read(bookingFormProvider);
    ref.read(fareEstimateProvider.notifier).estimate(form);
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(bookingFormProvider);
    final fare = ref.watch(fareEstimateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Review')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BookingSummaryCard(form: form),
          const SizedBox(height: 16),
          _FareEstimateCard(
            fare: fare,
            onRetry: () {
              _estimated = false;
              _fetchEstimate();
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: fare.hasFare
                ? () => context
                    .push('/booking/form/${form.bookingType}/review/confirm')
                : null,
            child: const Text('Continue to Confirm'),
          ),
        ],
      ),
    );
  }
}

class _FareEstimateCard extends StatelessWidget {
  final FareEstimateState fare;
  final VoidCallback onRetry;

  const _FareEstimateCard({required this.fare, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (fare.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (fare.fareError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 32),
              const SizedBox(height: 8),
              Text(
                fare.fareError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 14),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final breakdown = fare.breakdown;
    if (breakdown == null) {
      return const SizedBox.shrink();
    }

    final showRange =
        fare.minFare != null && fare.maxFare != null && fare.minFare != fare.maxFare;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estimated Fare',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '৳${breakdown.totalAmount}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (showRange) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '৳${fare.minFare} – ৳${fare.maxFare}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            const Divider(height: 24),
            _FareRow('Base fare', breakdown.baseFare),
            if (breakdown.nightSurcharge > 0)
              _FareRow('Night surcharge', breakdown.nightSurcharge),
            if (breakdown.distanceCharge > 0)
              _FareRow('Distance charge', breakdown.distanceCharge),
            if (breakdown.intercitySurcharge > 0)
              _FareRow('Intercity surcharge', breakdown.intercitySurcharge),
            if (breakdown.airportSurcharge > 0)
              _FareRow('Airport surcharge', breakdown.airportSurcharge),
            if (breakdown.discount > 0)
              _FareRow('Discount', -breakdown.discount),
            const Divider(height: 16),
            _FareRow('Total', breakdown.totalAmount, bold: true),
            if (fare.note != null) ...[
              const SizedBox(height: 8),
              Text(
                fare.note!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool bold;

  const _FareRow(this.label, this.amount, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: amount < 0 ? AppColors.success : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            amount < 0 ? '-৳${amount.abs()}' : '৳$amount',
            style: style,
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
              value: form.pickupAddress.isEmpty
                  ? 'Not specified'
                  : form.pickupAddress,
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
            if (form.scheduledPickup != null)
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Pickup time',
                value: form.scheduledPickup.toString(),
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

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
