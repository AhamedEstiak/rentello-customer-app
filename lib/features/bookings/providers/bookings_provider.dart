import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/booking.dart';
import '../../../core/models/invoice.dart';
import '../../../core/models/payment.dart';
import '../../../core/models/review.dart';

/// Query parameters for paginated bookings list.
class BookingsQuery {
  final int page;
  final String status;

  const BookingsQuery({this.page = 1, this.status = 'all'});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingsQuery &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          status == other.status;

  @override
  int get hashCode => Object.hash(page, status);
}

final myBookingsProvider =
    FutureProvider.family<BookingsResponse, BookingsQuery>((ref, query) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(
    ApiEndpoints.bookings,
    queryParameters: {
      'page': query.page,
      'pageSize': 20,
      'status': query.status,
    },
  );
  return BookingsResponse.fromJson(res.data as Map<String, dynamic>);
});

final bookingDetailProvider =
    FutureProvider.family<Booking, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.bookingDetail(id));
  // Detail returns root object (no 'booking' wrapper)
  return Booking.fromJson(res.data as Map<String, dynamic>);
});

/// Payments list for a booking (GET /bookings/:id/payments).
final bookingPaymentsProvider =
    FutureProvider.family<List<PaymentEntry>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.bookingPayments(id));
  final list = res.data['payments'] as List<dynamic>? ?? [];
  return list
      .map((e) => PaymentEntry.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Invoice for a booking (GET /bookings/:id/invoice). Response is root object.
final bookingInvoiceProvider =
    FutureProvider.family<Invoice, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.bookingInvoice(id));
  return Invoice.fromJson(res.data as Map<String, dynamic>);
});

/// Reviews for a booking (GET /bookings/:id/reviews). Returns { reviews: [...] }.
final bookingReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.bookingReviews(id));
  final list = res.data['reviews'] as List<dynamic>? ?? [];
  return list
      .map((e) => Review.fromJson(e as Map<String, dynamic>))
      .toList();
});
