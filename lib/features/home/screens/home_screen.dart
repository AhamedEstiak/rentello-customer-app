import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/booking.dart';
import '../../../core/models/locations.dart';
import '../../../core/models/vehicle.dart';
import '../../../core/theme/app_theme.dart';
import '../../booking/providers/booking_form_provider.dart';
import '../../booking/widgets/district_upazila_selector_sheet.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/plan_trip/plan_trip_continue_button.dart';
import '../widgets/plan_trip/plan_trip_datetime_tile.dart';
import '../widgets/plan_trip/plan_trip_fare_estimate.dart';
import '../widgets/plan_trip/plan_trip_header.dart';
import '../widgets/plan_trip/plan_trip_location_card.dart';
import '../widgets/plan_trip/plan_trip_models.dart';
import '../widgets/plan_trip/plan_trip_swap_row.dart';
import '../widgets/plan_trip/plan_trip_vehicle_selector.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _bookingType = 'INTERCITY';

  static const _vehicles = [
    VehicleType(label: 'Sedan', emoji: '🚗', categoryCode: 'SEDAN'),
    VehicleType(label: 'SUV', emoji: '🚙', categoryCode: 'SUV'),
    VehicleType(label: 'Microbus', emoji: '🚌', categoryCode: 'MICROBUS'),
    VehicleType(label: 'Hi-Ace', emoji: '🚐', categoryCode: 'PREMIUM'),
  ];

  int _selectedVehicleIndex = 0;
  DateTime _pickupDate = DateTime.now();
  TimeOfDay _pickupTime = TimeOfDay.now();

  LocationSelection? _pickup;
  LocationSelection? _dropoff;

  Timer? _fareDebounce;
  String? _lastFareFingerprint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncBookingFormProvider(),
    );
  }

  @override
  void dispose() {
    _fareDebounce?.cancel();
    super.dispose();
  }

  IntercityRoute? _matchRoute(List<IntercityRoute> routes) {
    if (_pickup == null || _dropoff == null) return null;
    final pu = _pickup!.upazilaId;
    final du = _dropoff!.upazilaId;
    for (final r in routes) {
      final o = r.originUpazilaId;
      final d = r.destinationUpazilaId;
      if (o != null && d != null && o == pu && d == du) {
        return r;
      }
    }
    return null;
  }

  String? _vehicleIdForCategory(List<Vehicle> vehicles, String category) {
    final list = vehicles.where((v) => v.category == category).toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => a.seats.compareTo(b.seats));
    return list.first.id;
  }

  DateTime get _pickupDateTime {
    return DateTime(
      _pickupDate.year,
      _pickupDate.month,
      _pickupDate.day,
      _pickupTime.hour,
      _pickupTime.minute,
    );
  }

  BookingFormState _buildBookingFormState({
    required IntercityRoute? matchedRoute,
    required String? vehicleId,
  }) {
    final pickupDt = _pickupDateTime;
    final hours = matchedRoute != null
        ? matchedRoute.estimatedHours.clamp(0.5, 168.0)
        : 2.0;

    return BookingFormState(
      vehicleId: vehicleId ?? '',
      bookingType: _bookingType,
      pickupAddress: _pickup?.label ?? '',
      dropoffAddress: _dropoff?.label ?? '',
      pickupLocationId: _pickup?.upazilaId,
      dropoffLocationId: _dropoff?.upazilaId,
      scheduledPickup: pickupDt,
      scheduledDropoff: null,
      totalHours: hours,
      routeId: matchedRoute?.id,
      isNight: pickupDt.hour >= 22 || pickupDt.hour < 6,
    );
  }

  String _fareFingerprint(BookingFormState form) {
    final pickupIso = form.scheduledPickup?.toIso8601String() ?? '';
    return [
      form.vehicleId,
      form.bookingType,
      form.pickupLocationId ?? '',
      form.dropoffLocationId ?? '',
      form.totalHours.toStringAsFixed(2),
      form.isNight.toString(),
      form.routeId ?? '',
      pickupIso,
    ].join('|');
  }

  void _syncBookingFormProvider() {
    final routes =
        ref.read(intercityRoutesProvider).asData?.value ?? <IntercityRoute>[];
    final vehicles =
        ref.read(vehicleListProvider('ALL')).asData?.value ?? <Vehicle>[];
    final matched = _matchRoute(routes);
    final category = _vehicles[_selectedVehicleIndex].categoryCode;
    final vid = _vehicleIdForCategory(vehicles, category);
    ref
        .read(bookingFormProvider.notifier)
        .setState(
          _buildBookingFormState(matchedRoute: matched, vehicleId: vid),
        );
  }

  bool _canEstimateFare({
    required IntercityRoute? matchedRoute,
    required String? vehicleId,
  }) {
    if (vehicleId == null || vehicleId.isEmpty) return false;
    if (_pickup == null || _pickup!.upazilaId.isEmpty) return false;
    if (_dropoff == null || _dropoff!.upazilaId.isEmpty) return false;
    if (matchedRoute == null) return false;
    return true;
  }

  void _maybeUpdateFareEstimate() {
    final routes =
        ref.read(intercityRoutesProvider).asData?.value ?? <IntercityRoute>[];
    final vehicles =
        ref.read(vehicleListProvider('ALL')).asData?.value ?? <Vehicle>[];
    final matched = _matchRoute(routes);
    final category = _vehicles[_selectedVehicleIndex].categoryCode;
    final vid = _vehicleIdForCategory(vehicles, category);

    if (!_canEstimateFare(matchedRoute: matched, vehicleId: vid)) {
      _fareDebounce?.cancel();
      _lastFareFingerprint = null;
      ref.invalidate(fareEstimateProvider);
      return;
    }

    final form = _buildBookingFormState(matchedRoute: matched, vehicleId: vid);
    final fp = _fareFingerprint(form);
    if (_lastFareFingerprint == fp) return;
    _lastFareFingerprint = fp;

    _fareDebounce?.cancel();
    _fareDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      ref.invalidate(fareEstimateProvider);
      unawaited(ref.read(fareEstimateProvider.notifier).estimate(form));
    });
  }

  Future<void> _onPickupTap() async {
    final selection = await showModalBottomSheet<LocationSelection>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DistrictUpazilaSelectorSheet(initialSelection: _pickup),
    );
    if (!mounted || selection == null) return;
    setState(() => _pickup = selection);
    _syncBookingFormProvider();
    _maybeUpdateFareEstimate();
  }

  Future<void> _onDestinationTap() async {
    final selection = await showModalBottomSheet<LocationSelection>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DistrictUpazilaSelectorSheet(initialSelection: _dropoff),
    );
    if (!mounted || selection == null) return;
    setState(() => _dropoff = selection);
    _syncBookingFormProvider();
    _maybeUpdateFareEstimate();
  }

  void _onSwap() {
    setState(() {
      final a = _pickup;
      _pickup = _dropoff;
      _dropoff = a;
    });
    _syncBookingFormProvider();
    _maybeUpdateFareEstimate();
  }

  void _onContinue() {
    final routes =
        ref.read(intercityRoutesProvider).asData?.value ?? <IntercityRoute>[];
    final vehicles =
        ref.read(vehicleListProvider('ALL')).asData?.value ?? <Vehicle>[];
    final matched = _matchRoute(routes);
    final category = _vehicles[_selectedVehicleIndex].categoryCode;
    final vid = _vehicleIdForCategory(vehicles, category);

    if (!_canEstimateFare(matchedRoute: matched, vehicleId: vid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            matched == null
                ? 'No intercity route matches this pickup and destination. '
                      'Choose locations that appear on a published route.'
                : 'Could not resolve a vehicle for ${_vehicles[_selectedVehicleIndex].label}. '
                      'Try another type or wait for vehicles to load.',
          ),
        ),
      );
      return;
    }

    final form = _buildBookingFormState(matchedRoute: matched, vehicleId: vid);
    ref.read(bookingFormProvider.notifier).setState(form);
    context.push(
      '/booking/${form.vehicleId}/form/${form.bookingType}/review',
      extra: {'form': form},
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) =>
          Theme(data: AppTheme.pickerDialogTheme, child: child!),
    );
    if (picked != null) setState(() => _pickupDate = picked);
    _syncBookingFormProvider();
    _maybeUpdateFareEstimate();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _pickupTime,
      builder: (context, child) =>
          Theme(data: AppTheme.pickerDialogTheme, child: child!),
    );
    if (picked != null) setState(() => _pickupTime = picked);
    _syncBookingFormProvider();
    _maybeUpdateFareEstimate();
  }

  String _primaryLine(String? label, String placeholder) {
    if (label == null || label.isEmpty) return placeholder;
    final parts = label.split(',');
    return parts.first.trim();
  }

  String _pickupSubtitle() {
    if (_pickup == null) return 'Tap to select district & upazila';
    return _pickup!.label;
  }

  String _destinationSubtitle(
    IntercityRoute? matched,
    List<IntercityRoute> routes,
  ) {
    if (_dropoff == null) return 'Tap to select district & upazila';
    if (matched != null) {
      return '${matched.displayName} · ${matched.distanceKm.round()} km';
    }
    if (_pickup != null && routes.isNotEmpty) {
      return 'No route for this pair — try another destination';
    }
    return _dropoff!.label;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<IntercityRoute>>>(intercityRoutesProvider, (
      prev,
      next,
    ) {
      if (next.hasValue) {
        _syncBookingFormProvider();
        _maybeUpdateFareEstimate();
      }
    });
    ref.listen<AsyncValue<List<Vehicle>>>(vehicleListProvider('ALL'), (
      prev,
      next,
    ) {
      if (next.hasValue) {
        _syncBookingFormProvider();
        _maybeUpdateFareEstimate();
      }
    });

    final routesAsync = ref.watch(intercityRoutesProvider);
    final vehiclesAsync = ref.watch(vehicleListProvider('ALL'));
    final fareState = ref.watch(fareEstimateProvider);

    final routes = routesAsync.asData?.value ?? <IntercityRoute>[];
    final vehicles = vehiclesAsync.asData?.value ?? <Vehicle>[];
    final matched = _matchRoute(routes);
    final category = _vehicles[_selectedVehicleIndex].categoryCode;
    final vehicleId = _vehicleIdForCategory(vehicles, category);

    final bd = fareState.breakdown;
    final canShowNumbers =
        _canEstimateFare(matchedRoute: matched, vehicleId: vehicleId) &&
        bd != null &&
        !fareState.isLoading;

    int totalAmt = bd?.totalAmount ?? 0;
    int base = bd?.baseFare ?? 0;
    final distKm = matched?.distanceKm.round() ?? 0;
    if (totalAmt <= 0 && base > 0) totalAmt = base;
    final fareMin = canShowNumbers ? (totalAmt * 0.9).round() : 0;
    final fareMax = canShowNumbers ? (totalAmt * 1.15).round() : 0;

    final bottomPadding =
        MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 16;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
          children: [
            const PlanTripHeader(),
            const SizedBox(height: 20),
            // const PlanTripSectionLabel('PICKUP LOCATION'),
            const SizedBox(height: 8),
            PlanTripLocationCard(
              iconColor: AppColors.success,
              iconBg: AppColors.success.withValues(alpha: 0.12),
              city: _primaryLine(_pickup?.label, 'Pickup location'),
              subtitle: _pickupSubtitle(),
              trailing: const PlanTripFixedBadge(),
              onTap: _onPickupTap,
            ),
            PlanTripSwapRow(onSwap: _onSwap),
            // const PlanTripSectionLabel('DESTINATION'),
            const SizedBox(height: 8),
            PlanTripLocationCard(
              iconColor: AppColors.error,
              iconBg: AppColors.error.withValues(alpha: 0.12),
              city: _primaryLine(_dropoff?.label, 'Destination'),
              subtitle: _destinationSubtitle(matched, routes),
              onTap: _onDestinationTap,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: PlanTripDateTimeTile(
                      label: 'PICKUP DATE',
                      value:
                          '${_pickupDate.day.toString().padLeft(2, '0')}/${_pickupDate.month.toString().padLeft(2, '0')}/${_pickupDate.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: PlanTripDateTimeTile(
                      label: 'PICKUP TIME',
                      value: _pickupTime.format(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const PlanTripSectionLabel('VEHICLE TYPE'),
            const SizedBox(height: 12),
            PlanTripVehicleSelector(
              vehicles: _vehicles,
              selectedIndex: _selectedVehicleIndex,
              onSelected: (i) {
                setState(() => _selectedVehicleIndex = i);
                _syncBookingFormProvider();
                _maybeUpdateFareEstimate();
              },
            ),
            const SizedBox(height: 16),
            PlanTripFareEstimateCard(
              isLoading:
                  fareState.isLoading &&
                  _canEstimateFare(matchedRoute: matched, vehicleId: vehicleId),
              errorMessage: fareState.fareError,
              hasEstimate: canShowNumbers,
              baseFare: base,
              distanceKm: distKm,
              totalAmount: totalAmt,
              fareMin: fareMin,
              fareMax: fareMax,
            ),
            const SizedBox(height: 24),
            PlanTripContinueButton(onPressed: _onContinue),
          ],
        ),
      ),
    );
  }
}
