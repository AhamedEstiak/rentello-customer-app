import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/booking.dart';
import '../../auth/providers/auth_provider.dart';

class BookingFormState {
  final String vehicleId;
  final String bookingType;
  final String pickupAddress;
  final String dropoffAddress;
  // Location IDs used by the backend for fare calculation / booking validation.
  // Display strings (e.g. `pickupAddress`) are kept separately for UI.
  final String? pickupLocationId;
  final String? dropoffLocationId;
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
    this.pickupLocationId,
    this.dropoffLocationId,
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
    String? pickupLocationId,
    String? dropoffLocationId,
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
        pickupLocationId: pickupLocationId ?? this.pickupLocationId,
        dropoffLocationId: dropoffLocationId ?? this.dropoffLocationId,
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
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) {
    return <IntercityRoute>[];
  }

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
  final String? appliedFareRuleId;
  final String? promoCodeId;
  final String? error;
  final String? fareError;
  final String? promoError;
  final String promoCode;
  final int promoDiscount;

  const FareEstimateState({
    this.isLoading = false,
    this.breakdown,
    this.appliedFareRuleId,
    this.promoCodeId,
    this.error,
    this.fareError,
    this.promoError,
    this.promoCode = '',
    this.promoDiscount = 0,
  });

  FareEstimateState copyWith({
    bool? isLoading,
    FareBreakdown? breakdown,
    String? appliedFareRuleId,
    String? promoCodeId,
    String? error,
    String? fareError,
    String? promoError,
    String? promoCode,
    int? promoDiscount,
    bool clearError = false,
    bool clearFareError = false,
    bool clearPromoError = false,
  }) =>
      FareEstimateState(
        isLoading: isLoading ?? this.isLoading,
        breakdown: breakdown ?? this.breakdown,
        appliedFareRuleId: appliedFareRuleId ?? this.appliedFareRuleId,
        promoCodeId: promoCodeId ?? this.promoCodeId,
        error: clearError ? null : error ?? this.error,
        fareError: clearFareError ? null : fareError ?? this.fareError,
        promoError: clearPromoError ? null : promoError ?? this.promoError,
        promoCode: promoCode ?? this.promoCode,
        promoDiscount: promoDiscount ?? this.promoDiscount,
      );
}

class FareEstimateNotifier extends Notifier<FareEstimateState> {
  @override
  FareEstimateState build() => const FareEstimateState();

  String _mapErrorMessage(
    Object error, {
    required String fallback,
  }) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['error'] is String) {
        return data['error'] as String;
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }
    return fallback;
  }

  void _setFareError(Object error) {
    final message =
        _mapErrorMessage(error, fallback: 'Failed to estimate fare');
    state = state.copyWith(
      isLoading: false,
      error: message,
      fareError: message,
    );
  }

  void _setPromoError(Object error) {
    final message =
        _mapErrorMessage(error, fallback: 'Failed to validate promo code');
    state = state.copyWith(
      error: message,
      promoError: message,
    );
  }

  Future<void> estimate(BookingFormState form) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearFareError: true,
    );
    try {
      final dio = ref.read(dioProvider);
      final body = {
        'vehicleId': form.vehicleId,
        'bookingType': form.bookingType,
        'totalHours': form.totalHours,
        'isNight': form.isNight,
        if (form.pickupLocationId != null) ...{
          // Backward/forward compatible keys: the backend plan uses *UpazilaId.
          'pickupLocationId': form.pickupLocationId,
          'pickupUpazilaId': form.pickupLocationId,
        },
        if (form.dropoffLocationId != null) ...{
          'dropoffLocationId': form.dropoffLocationId,
          'dropoffUpazilaId': form.dropoffLocationId,
        },
        if (form.routeId != null) 'routeId': form.routeId,
      };
      final res = await dio.post(ApiEndpoints.fareEstimate, data: body);
      final breakdown = FareBreakdown.fromJson(
          res.data['breakdown'] as Map<String, dynamic>);
      state = state.copyWith(
          isLoading: false,
          breakdown: breakdown,
          appliedFareRuleId: res.data['appliedFareRuleId'] as String?,
          promoCodeId: res.data['promoCodeId'] as String?,
          clearError: true,
          clearFareError: true);
    } catch (e) {
      _setFareError(e);
    }
  }

  Future<void> applyPromo(String code, int subtotal) async {
    if (code.isEmpty) return;
    state = state.copyWith(
      clearError: true,
      clearPromoError: true,
    );
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
          clearError: true,
          clearPromoError: true,
        );
      } else {
        state = state.copyWith(
          error: res.data['error'] as String? ?? 'Invalid promo',
          promoError: res.data['error'] as String? ?? 'Invalid promo',
        );
      }
    } catch (e) {
      _setPromoError(e);
    }
  }
}

final fareEstimateProvider =
    NotifierProvider<FareEstimateNotifier, FareEstimateState>(
        FareEstimateNotifier.new);
