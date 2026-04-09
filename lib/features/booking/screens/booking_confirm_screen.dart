import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/booking.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/booking_form_provider.dart';

const _paymentMethods = [
  _PaymentOption(value: 'CASH', label: 'Cash', icon: Icons.money),
  _PaymentOption(value: 'BKASH', label: 'bKash', icon: Icons.phone_android),
  _PaymentOption(value: 'NAGAD', label: 'Nagad', icon: Icons.account_balance_wallet),
];

class _PaymentOption {
  final String value;
  final String label;
  final IconData icon;
  const _PaymentOption({required this.value, required this.label, required this.icon});
}

class BookingConfirmScreen extends ConsumerStatefulWidget {
  const BookingConfirmScreen({super.key});

  @override
  ConsumerState<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends ConsumerState<BookingConfirmScreen> {
  String _paymentMethod = 'CASH';
  bool _isSubmitting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(bookingFormProvider);
    final fare = ref.watch(fareEstimateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummarySection(form: form, fare: fare),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ..._paymentMethods.map((opt) => InkWell(
                        onTap: () => setState(() => _paymentMethod = opt.value),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Icon(opt.icon, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(child: Text(opt.label)),
                              Radio<String>(
                                value: opt.value,
                                groupValue: _paymentMethod,
                                onChanged: (v) =>
                                    setState(() => _paymentMethod = v!),
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      )),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Payment is collected by the driver at the time of service.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, style: const TextStyle(color: AppColors.error)),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () => _submitBooking(
                      context,
                      form,
                    ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Place Booking'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBooking(
    BuildContext context,
    BookingFormState form,
  ) async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(ApiEndpoints.bookings, data: {
        'type': form.bookingType,
        'pickupAddress': form.pickupAddress,
        if (form.pickupLocationId != null) ...{
          // Backward/forward compatible keys: the backend plan uses *UpazilaId.
          'pickupLocationId': form.pickupLocationId,
          'pickupUpazilaId': form.pickupLocationId,
        },
        if (form.dropoffAddress.isNotEmpty) 'dropoffAddress': form.dropoffAddress,
        if (form.dropoffLocationId != null) ...{
          'dropoffLocationId': form.dropoffLocationId,
          'dropoffUpazilaId': form.dropoffLocationId,
        },
        'scheduledPickup': form.scheduledPickup?.toIso8601String(),
        if (form.scheduledDropoff != null)
          'scheduledDropoff': form.scheduledDropoff!.toIso8601String(),
        'totalHours': form.totalHours,
        if (form.flightNumber.isNotEmpty) 'flightNumber': form.flightNumber,
        if (form.airportCode.isNotEmpty) 'airportCode': form.airportCode,
        if (form.routeId != null) 'routeId': form.routeId,
        if (form.vehicleTypeId != null && form.vehicleTypeId!.isNotEmpty)
          'vehicleTypeId': form.vehicleTypeId,
        if (form.vehicleCategory != null && form.vehicleCategory!.isNotEmpty)
          'vehicleCategory': form.vehicleCategory,
        if (form.distanceKm != null) 'distanceKm': form.distanceKm,
        'paymentMethod': _paymentMethod,
      });

      final booking = Booking.fromJson(res.data['booking'] as Map<String, dynamic>);
      if (!context.mounted) return;
      setState(() => _isSubmitting = false);
      _showSuccessDialog(context, booking);
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['error'] as String? ?? 'Failed to place booking';
        _isSubmitting = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
      debugPrint('Booking place error: $e\n$stackTrace');
    }
  }

  void _showSuccessDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Placed!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              booking.bookingNumber,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ৳${booking.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            if (booking.price != null) ...[
              const SizedBox(height: 6),
              Text(
                'Base: ৳${booking.price!.baseFare.toStringAsFixed(0)}  '
                'Surcharge: ৳${booking.price!.surcharges.toStringAsFixed(0)}  '
                'Discount: ৳${booking.price!.discount.toStringAsFixed(0)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Your booking is pending confirmation. You\'ll be notified once approved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/bookings/${booking.id}');
            },
            child: const Text('View booking'),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final BookingFormState form;
  final FareEstimateState fare;

  const _SummarySection({required this.form, required this.fare});

  @override
  Widget build(BuildContext context) {
    final breakdown = fare.breakdown;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(height: 20),
            _Row('Type', form.bookingType.replaceAll('_', ' ')),
            _Row('Pickup', form.pickupAddress.isEmpty ? '-' : form.pickupAddress),
            if (form.dropoffAddress.isNotEmpty) _Row('Drop-off', form.dropoffAddress),
            if (breakdown != null) ...[
              const Divider(height: 20),
              _Row('Estimated fare', '৳${breakdown.totalAmount}'),
              if (breakdown.baseFare != breakdown.totalAmount)
                _Row('Base fare', '৳${breakdown.baseFare}'),
              if (breakdown.discount > 0)
                _Row('Discount', '-৳${breakdown.discount}'),
            ],
            if (breakdown == null) ...[
              const Divider(height: 20),
              const Text(
                'Final fare will be calculated when you place the booking.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
