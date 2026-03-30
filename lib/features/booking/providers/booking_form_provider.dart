import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/booking.dart';
import '../../auth/providers/auth_provider.dart';

class BookingFormState {
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
  final String? vehicleCategory;
  final bool isNight;
  /// From matched [IntercityRoute] when booking intercity from home; sent to fare/booking APIs.
  final double? distanceKm;

  const BookingFormState({
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
    this.vehicleCategory,
    this.isNight = false,
    this.distanceKm,
  });

  BookingFormState copyWith({
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
    String? vehicleCategory,
    bool? isNight,
    double? distanceKm,
    bool clearRoute = false,
    bool clearVehicleCategory = false,
    bool clearDistanceKm = false,
  }) =>
      BookingFormState(
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
        vehicleCategory: clearVehicleCategory
            ? null
            : vehicleCategory ?? this.vehicleCategory,
        isNight: isNight ?? this.isNight,
        distanceKm: clearDistanceKm ? null : distanceKm ?? this.distanceKm,
      );
}

class BookingFormNotifier extends Notifier<BookingFormState> {
  @override
  BookingFormState build() => const BookingFormState();

  void init(String bookingType) {
    state = BookingFormState(bookingType: bookingType);
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
  final String? matchType;
  final String? routeId;
  final int? minFare;
  final int? maxFare;
  final String? note;

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
    this.matchType,
    this.routeId,
    this.minFare,
    this.maxFare,
    this.note,
  });

  bool get hasFare => breakdown != null;

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
    String? matchType,
    String? routeId,
    int? minFare,
    int? maxFare,
    String? note,
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
        matchType: matchType ?? this.matchType,
        routeId: routeId ?? this.routeId,
        minFare: minFare ?? this.minFare,
        maxFare: maxFare ?? this.maxFare,
        note: note ?? this.note,
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
        'bookingType': form.bookingType,
        'totalHours': form.totalHours,
        'isNight': form.isNight,
        if (form.scheduledPickup != null)
          'scheduledPickup': form.scheduledPickup!.toIso8601String(),
        if (form.distanceKm != null) 'distanceKm': form.distanceKm,
        if (form.vehicleCategory != null && form.vehicleCategory!.isNotEmpty)
          'vehicleCategory': form.vehicleCategory,
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
        matchType: res.data['matchType'] as String?,
        routeId: res.data['routeId'] as String?,
        minFare: (res.data['minFare'] as num?)?.toInt(),
        maxFare: (res.data['maxFare'] as num?)?.toInt(),
        note: res.data['note'] as String?,
        clearError: true,
        clearFareError: true,
      );
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
