import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/booking.dart';
import '../../../core/models/locations.dart';
import '../../../core/theme/app_theme.dart';
import '../../booking/providers/booking_form_provider.dart';
import '../../booking/widgets/location_selector_sheet.dart';
import '../widgets/plan_trip/plan_trip_continue_button.dart';
import '../widgets/plan_trip/plan_trip_datetime_tile.dart';
import '../widgets/plan_trip/plan_trip_header.dart';
import '../widgets/plan_trip/plan_trip_location_card.dart';
import '../widgets/plan_trip/plan_trip_swap_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _bookingType = 'INTERCITY';

  DateTime _pickupDate = DateTime.now();
  TimeOfDay _pickupTime = TimeOfDay.now();

  LocationSelection? _pickup;
  LocationSelection? _dropoff;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncBookingFormProvider(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  IntercityRoute? _matchRoute(List<IntercityRoute> routes) {
    if (_pickup == null || _dropoff == null) return null;
    final pu = _pickup!.locationId;
    final du = _dropoff!.locationId;
    for (final r in routes) {
      final o = r.originUpazilaId;
      final d = r.destinationUpazilaId;
      if (o != null && d != null && o == pu && d == du) {
        return r;
      }
    }
    return null;
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
  }) {
    final pickupDt = _pickupDateTime;
    final hours = matchedRoute != null
        ? matchedRoute.estimatedHours.clamp(0.5, 168.0)
        : 2.0;

    return BookingFormState(
      bookingType: _bookingType,
      pickupAddress: _pickup?.label ?? '',
      dropoffAddress: _dropoff?.label ?? '',
      pickupLocationId: _pickup?.locationId,
      dropoffLocationId: _dropoff?.locationId,
      scheduledPickup: pickupDt,
      scheduledDropoff: null,
      totalHours: hours,
      routeId: matchedRoute?.id,
      isNight: pickupDt.hour >= 22 || pickupDt.hour < 6,
      distanceKm: matchedRoute?.distanceKm,
    );
  }

  void _syncBookingFormProvider() {
    final routes =
        ref.read(intercityRoutesProvider).asData?.value ?? <IntercityRoute>[];
    final matched = _matchRoute(routes);
    ref
        .read(bookingFormProvider.notifier)
        .setState(_buildBookingFormState(matchedRoute: matched));
  }

  Future<void> _onPickupTap() async {
    final selection = await showModalBottomSheet<LocationSelection>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          LocationSelectorSheet(initialSelection: _pickup, forPickup: true),
    );
    if (!mounted || selection == null) return;
    setState(() => _pickup = selection);
    _syncBookingFormProvider();
  }

  Future<void> _onDestinationTap() async {
    final selection = await showModalBottomSheet<LocationSelection>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          LocationSelectorSheet(initialSelection: _dropoff, forPickup: false),
    );
    if (!mounted || selection == null) return;
    setState(() => _dropoff = selection);
    _syncBookingFormProvider();
  }

  void _onSwap() {
    setState(() {
      final a = _pickup;
      _pickup = _dropoff;
      _dropoff = a;
    });
    _syncBookingFormProvider();
  }

  void _onContinue() {
    final routes =
        ref.read(intercityRoutesProvider).asData?.value ?? <IntercityRoute>[];
    final matched = _matchRoute(routes);
    if (_pickup == null || _pickup!.locationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup location.')),
      );
      return;
    }
    if (_dropoff == null || _dropoff!.locationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination location.')),
      );
      return;
    }

    final form = _buildBookingFormState(matchedRoute: matched);
    ref.read(bookingFormProvider.notifier).setState(form);
    context.push('/booking/form/${form.bookingType}/review');
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
      }
    });

    final routesAsync = ref.watch(intercityRoutesProvider);

    final routes = routesAsync.asData?.value ?? <IntercityRoute>[];
    final matched = _matchRoute(routes);

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
            PlanTripContinueButton(onPressed: _onContinue),
          ],
        ),
      ),
    );
  }
}
