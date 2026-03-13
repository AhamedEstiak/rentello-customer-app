import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/booking.dart';
import '../../../core/models/review.dart';
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
          bookingId: bookingId,
          booking: booking,
          onCancel: () => _cancelBooking(context, ref),
        ),
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(bool, String?)>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Cancel Booking?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to cancel this booking?'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'e.g. Change of plans',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop((false, null)),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                final r = controller.text.trim().isEmpty ? null : controller.text.trim();
                Navigator.of(ctx).pop((true, r));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    if (result == null || result.$1 != true || !context.mounted) return;
    final reason = result.$2;

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        ApiEndpoints.bookingCancel(bookingId),
        data: reason != null ? {'reason': reason} : null,
      );
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

class _BookingDetailContent extends ConsumerWidget {
  final String bookingId;
  final Booking booking;
  final VoidCallback onCancel;

  const _BookingDetailContent({
    required this.bookingId,
    required this.booking,
    required this.onCancel,
  });

  bool get _canCancel =>
      booking.status == 'PENDING' ||
      booking.status == 'APPROVED' ||
      booking.status == 'CONFIRMED';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(booking: booking),
        const SizedBox(height: 12),
        _TripDetailsCard(booking: booking),
        if (booking.driver != null) ...[
          const SizedBox(height: 12),
          _DriverCard(driver: booking.driver!),
        ],
        if (booking.route != null) ...[
          const SizedBox(height: 12),
          _RouteCard(route: booking.route!),
        ],
        const SizedBox(height: 12),
        _FareCard(booking: booking),
        const SizedBox(height: 12),
        _PaymentHistoryCard(bookingId: bookingId),
        const SizedBox(height: 12),
        _ViewInvoiceButton(
          bookingId: bookingId,
          onTap: () => context.push('/bookings/$bookingId/invoice'),
        ),
        if (booking.review != null) ...[
          const SizedBox(height: 12),
          _ReviewCard(review: booking.review!),
        ],
        if (booking.status == 'COMPLETED' && booking.review == null) ...[
          const SizedBox(height: 12),
          _RateTripCard(
            bookingId: bookingId,
            onSubmitted: () {
              ref.invalidate(bookingDetailProvider(bookingId));
              ref.invalidate(bookingReviewsProvider(bookingId));
            },
          ),
        ],
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

class _DriverCard extends StatelessWidget {
  final BookingDriver driver;

  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driver',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.person_outline,
              label: 'Name',
              value: driver.name,
            ),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: driver.phone,
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final BookingRoute route;

  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.route, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Route',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    route.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
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

class _ReviewCard extends StatelessWidget {
  final BookingReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Review',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ...List.generate(5, (i) => Icon(
                  i < review.rating ? Icons.star : Icons.star_border,
                  color: AppColors.warning,
                  size: 20,
                )),
                const SizedBox(width: 8),
                Text(
                  '${review.rating}/5',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.comment!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RateTripCard extends ConsumerWidget {
  final String bookingId;
  final VoidCallback onSubmitted;

  const _RateTripCard({
    required this.bookingId,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: () => _showRateDialog(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.star_border, color: AppColors.warning, size: 28),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Rate this trip',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _showRateDialog(BuildContext context, WidgetRef ref) {
    int rating = 0;
    final commentController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Rate this trip'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How was your experience?',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starRating = i + 1;
                      return IconButton(
                        icon: Icon(
                          starRating <= rating ? Icons.star : Icons.star_border,
                          color: AppColors.warning,
                          size: 36,
                        ),
                        onPressed: () => setState(() => rating = starRating),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      labelText: 'Comment (optional)',
                      hintText: 'Share more details...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: rating == 0
                    ? null
                    : () async {
                        final comment = commentController.text.trim();
                        final body = Review(
                          rating: rating,
                          comment: comment.isEmpty ? null : comment,
                        ).toJson();
                        try {
                          final dio = ref.read(dioProvider);
                          await dio.post(
                            ApiEndpoints.bookingReviews(bookingId),
                            data: body,
                          );
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          onSubmitted();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thank you for your review!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } on DioException catch (e) {
                          if (!ctx.mounted) return;
                          final data = e.response?.data;
                          final msg = data is Map && data['error'] != null
                              ? (data['error'] is String
                                  ? data['error'] as String
                                  : 'Failed to submit review')
                              : 'Failed to submit review';
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        } catch (e) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to submit review'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FareCard extends StatelessWidget {
  final Booking booking;

  const _FareCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final price = booking.price;
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
            if (price != null) ...[
              _FareRow('Base Fare', '৳${price.baseFare.toStringAsFixed(0)}'),
              if (price.surcharges > 0)
                _FareRow('Surcharges', '৳${price.surcharges.toStringAsFixed(0)}'),
              if (price.discount > 0)
                _FareRow('Discount', '-৳${price.discount.toStringAsFixed(0)}'),
              if (price.taxes > 0)
                _FareRow('Taxes', '৳${price.taxes.toStringAsFixed(0)}'),
              const Divider(height: 16),
            ],
            _FareRow('Total Amount', '৳${booking.totalAmount.toStringAsFixed(0)}'),
            _FareRow('Paid Amount', '৳${booking.paidAmount.toStringAsFixed(0)}'),
            _FareRow(
              'Payment Status',
              booking.effectivePaymentStatus.replaceAll('_', ' '),
              valueColor: booking.effectivePaymentStatus == 'PAID' ? AppColors.success : AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentHistoryCard extends ConsumerWidget {
  final String bookingId;

  const _PaymentHistoryCard({required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(bookingPaymentsProvider(bookingId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            paymentsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (err, _) => Text(
                'Failed to load payments',
                style: TextStyle(fontSize: 14, color: AppColors.error),
              ),
              data: (payments) {
                if (payments.isEmpty) {
                  return const Text(
                    'No payments yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                return Column(
                  children: payments
                      .map(
                        (p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                p.type.toUpperCase() == 'PAYMENT'
                                    ? Icons.payment
                                    : Icons.receipt_long,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.method,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (p.description != null &&
                                        p.description!.isNotEmpty)
                                      Text(
                                        p.description!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    Text(
                                      DateFormat('dd MMM yyyy, hh:mm a')
                                          .format(p.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '৳${p.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewInvoiceButton extends StatelessWidget {
  final String bookingId;
  final VoidCallback onTap;

  const _ViewInvoiceButton({
    required this.bookingId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.primary, size: 28),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'View Invoice',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
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
