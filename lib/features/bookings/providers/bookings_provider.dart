import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/booking.dart';

final myBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.bookings, queryParameters: {'limit': '20'});
  final list = res.data['bookings'] as List<dynamic>;
  return list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
});

final bookingDetailProvider = FutureProvider.family<Booking, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('${ApiEndpoints.bookings}/$id');
  return Booking.fromJson(res.data['booking'] as Map<String, dynamic>);
});
