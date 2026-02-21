import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/booking.dart';

class BookingFormState {
  final String vehicleId;
  final String bookingType;
  final String pickupAddress;
  final String dropoffAddress;
  final DateTime? scheduledPickup;
  final DateTime? scheduledDropoff;
  final double totalHours;
  final String flightNumber;
  final String airportCode;
  final String? routeId;
  final bool isNight;

  const BookingFormState({
    this.vehicleId = '',
    this.bookingType = 'HOURLY',
    this.pickupAddress = '',
    this.dropoffAddress = '',
    this.scheduledPickup,
    this.scheduledDropoff,
    this.totalHours = 2,
    this.flightNumber = '',
    this.airportCode = '',
    this.routeId,
    this.isNight = false,
  });

  BookingFormState copyWith({
    String? vehicleId,
    String? bookingType,
    String? pickupAddress,
    String? dropoffAddress,
    DateTime? scheduledPickup,
    DateTime? scheduledDropoff,
    double? totalHours,
    String? flightNumber,
    String? airportCode,
    String? routeId,
    bool? isNight,
    bool clearRoute = false,
  }) =>
      BookingFormState(
        vehicleId: vehicleId ?? this.vehicleId,
        bookingType: bookingType ?? this.bookingType,
        pickupAddress: pickupAddress ?? this.pickupAddress,
        dropoffAddress: dropoffAddress ?? this.dropoffAddress,
        scheduledPickup: scheduledPickup ?? this.scheduledPickup,
        scheduledDropoff: scheduledDropoff ?? this.scheduledDropoff,
        totalHours: totalHours ?? this.totalHours,
        flightNumber: flightNumber ?? this.flightNumber,
        airportCode: airportCode ?? this.airportCode,
        routeId: clearRoute ? null : routeId ?? this.routeId,
        isNight: isNight ?? this.isNight,
      );
}

class BookingFormNotifier extends Notifier<BookingFormState> {
  @override
  BookingFormState build() => const BookingFormState();

  void init(String vehicleId, String bookingType) {
    state = BookingFormState(vehicleId: vehicleId, bookingType: bookingType);
  }

  void setState(BookingFormState newState) {
    state = newState;
  }
}

final bookingFormProvider =
    NotifierProvider<BookingFormNotifier, BookingFormState>(
        BookingFormNotifier.new);

final intercityRoutesProvider =
    FutureProvider<List<IntercityRoute>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiEndpoints.routes);
  final list = res.data['routes'] as List<dynamic>;
  return list
      .map((e) => IntercityRoute.fromJson(e as Map<String, dynamic>))
      .toList();
});

class FareEstimateState {
  final bool isLoading;
  final FareBreakdown? breakdown;
  final String? promoCodeId;
  final String? error;
  final String promoCode;
  final int promoDiscount;

  const FareEstimateState({
    this.isLoading = false,
    this.breakdown,
    this.promoCodeId,
    this.error,
    this.promoCode = '',
    this.promoDiscount = 0,
  });

  FareEstimateState copyWith({
    bool? isLoading,
    FareBreakdown? breakdown,
    String? promoCodeId,
    String? error,
    String? promoCode,
    int? promoDiscount,
    bool clearError = false,
  }) =>
      FareEstimateState(
        isLoading: isLoading ?? this.isLoading,
        breakdown: breakdown ?? this.breakdown,
        promoCodeId: promoCodeId ?? this.promoCodeId,
        error: clearError ? null : error ?? this.error,
        promoCode: promoCode ?? this.promoCode,
        promoDiscount: promoDiscount ?? this.promoDiscount,
      );
}

class FareEstimateNotifier extends Notifier<FareEstimateState> {
  @override
  FareEstimateState build() => const FareEstimateState();

  Future<void> estimate(BookingFormState form) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(dioProvider);
      final body = {
        'vehicleId': form.vehicleId,
        'bookingType': form.bookingType,
        'totalHours': form.totalHours,
        'isNight': form.isNight,
        if (form.routeId != null) 'routeId': form.routeId,
      };
      final res = await dio.post(ApiEndpoints.fareEstimate, data: body);
      final breakdown = FareBreakdown.fromJson(
          res.data['breakdown'] as Map<String, dynamic>);
      state = state.copyWith(
        isLoading: false,
        breakdown: breakdown,
        promoCodeId: res.data['promoCodeId'] as String?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> applyPromo(String code, int subtotal) async {
    if (code.isEmpty) return;
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(ApiEndpoints.promoValidate, data: {
        'code': code,
        'subtotal': subtotal,
      });
      if (res.data['valid'] == true) {
        state = state.copyWith(
          promoCode: code,
          promoCodeId: res.data['promoCodeId'] as String?,
          promoDiscount: (res.data['discount'] as num).toInt(),
        );
      } else {
        state = state.copyWith(
            error: res.data['error'] as String? ?? 'Invalid promo');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to validate promo code');
    }
  }
}

final fareEstimateProvider =
    NotifierProvider<FareEstimateNotifier, FareEstimateState>(
        FareEstimateNotifier.new);
