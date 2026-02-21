import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/booking.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/bookings_provider.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(bookingDetailProvider(bookingId)),
          ),
        ],
      ),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (booking) => _BookingDetailContent(
          booking: booking,
          onCancel: () => _cancelBooking(context, ref),
        ),
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final dio = ref.read(dioProvider);
      await dio.post('${ApiEndpoints.bookings}/$bookingId/cancel');
      ref.invalidate(bookingDetailProvider(bookingId));
      ref.invalidate(myBookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel booking'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _BookingDetailContent extends StatelessWidget {
  final Booking booking;
  final VoidCallback onCancel;

  const _BookingDetailContent({required this.booking, required this.onCancel});

  bool get _canCancel =>
      booking.status == 'PENDING' || booking.status == 'APPROVED';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(booking: booking),
        const SizedBox(height: 12),
        _TripDetailsCard(booking: booking),
        const SizedBox(height: 12),
        _FareCard(booking: booking),
        if (booking.statusLog.isNotEmpty) ...[
          const SizedBox(height: 12),
          _StatusTimeline(statusLog: booking.statusLog),
        ],
        if (_canCancel) ...[
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Booking booking;

  const _HeaderCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Number',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        booking.bookingNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 12),
            if (booking.vehicle != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      '${booking.vehicle!.brand} ${booking.vehicle!.model}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    _CategoryBadge(category: booking.vehicle!.category),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TripDetailsCard extends StatelessWidget {
  final Booking booking;

  const _TripDetailsCard({required this.booking});

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
              icon: Icons.category_outlined,
              label: 'Type',
              value: booking.type.replaceAll('_', ' '),
            ),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Pickup',
              value: booking.pickupAddress,
            ),
            if (booking.dropoffAddress != null)
              _DetailRow(
                icon: Icons.location_on,
                label: 'Drop-off',
                value: booking.dropoffAddress!,
              ),
            _DetailRow(
              icon: Icons.schedule,
              label: 'Pickup Time',
              value: DateFormat('dd MMM yyyy, hh:mm a').format(booking.scheduledPickup),
            ),
            if (booking.scheduledDropoff != null)
              _DetailRow(
                icon: Icons.event,
                label: 'Drop-off Time',
                value: DateFormat('dd MMM yyyy, hh:mm a').format(booking.scheduledDropoff!),
              ),
          ],
        ),
      ),
    );
  }
}

class _FareCard extends StatelessWidget {
  final Booking booking;

  const _FareCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _FareRow('Total Amount', '৳${booking.totalAmount.toStringAsFixed(0)}'),
            _FareRow('Paid Amount', '৳${booking.paidAmount.toStringAsFixed(0)}'),
            _FareRow(
              'Payment Status',
              booking.paymentStatus.replaceAll('_', ' '),
              valueColor: booking.paymentStatus == 'PAID' ? AppColors.success : AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _FareRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final List<BookingStatusEntry> statusLog;

  const _StatusTimeline({required this.statusLog});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Timeline',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...statusLog.asMap().entries.map((entry) {
              final index = entry.key;
              final log = entry.value;
              final isLast = index == statusLog.length - 1;
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLast ? AppColors.primary : AppColors.border,
                              border: Border.all(
                                color: isLast ? AppColors.primary : AppColors.border,
                                width: 2,
                              ),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: AppColors.border,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.toStatus.replaceAll('_', ' '),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isLast ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a').format(log.changedAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (log.note != null && log.note!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                log.note!,
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
                    ),
                  ],
                ),
              );
            }),
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
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFF59E0B);
      case 'APPROVED':
      case 'CONFIRMED':
        return AppColors.primary;
      case 'IN_PROGRESS':
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _color),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
